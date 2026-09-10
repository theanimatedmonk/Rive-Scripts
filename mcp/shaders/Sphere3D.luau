-- Sphere3D node: drives Card3DShader (same WGSL as the card).
-- Drop a face artboard; it is drawn on the FRONT of the sphere (+Z). The back
-- uses edgeColor. Cursor tilt turns that front face toward the pointer.
-- Radius follows the face: max(width, height) / 2.
--
-- Shader: Card3DShader with params.z = 1 (geometric sphere normals).

local DEFAULT_W = 180
local DEFAULT_H = 180
local TEX_SCALE = 2
local MAX_TEX = 1024
local MSAA = 4
local VSTRIDE = 24
local LAT_SEGS = 18
local LON_SEGS = 28
local MAX_VERTS = LAT_SEGS * LON_SEGS * 6
local VBYTES = VSTRIDE * MAX_VERTS
local UBO_SIZE = 208
local TILT_SMOOTH = 10
local CIRCLE_K = 0.5522847498307936

type Sphere3D = {
  rotX: Input<number>,
  rotY: Input<number>,
  scale: Input<number>,
  maxTilt: Input<number>,
  tiltArea: Input<number>,
  edgeColor: Input<Color>,
  face: Input<Artboard<nil>>,
  viewModelProperty: Input<string>,
  properties: Input<string>,
  shadowColor: Input<Color>,
  shadowOpacity: Input<number>,
  shadowOffsetX: Input<number>,
  shadowOffsetY: Input<number>,
  shadowSoftness: Input<number>,
  lightAngle: Input<number>,
  lightIntensity: Input<number>,
  glossIntensity: Input<number>,
  glossSharpness: Input<number>,
  lightColor: Input<Color>,
  ambient: Input<number>,
  foilIntensity: Input<number>,
  foilStripes: Input<number>,
  foilShift: Input<number>,
  foilAngle: Input<number>,
  _canvas: Canvas?,
  _gpu: GPUCanvas?,
  _msaaColor: GPUTexture?,
  _msaaView: GPUTextureView?,
  _depthTex: GPUTexture?,
  _depthView: GPUTextureView?,
  _pipe: GPUPipeline?,
  _samples: number,
  _ubo: GPUBuffer?,
  _ubuf: buffer,
  _vbo: GPUBuffer?,
  _vdata: buffer,
  _gpuSamp: GPUSampler?,
  _imgSamp: ImageSampler,
  _dummyView: GPUTextureView?,
  _inst: Artboard<nil>?,
  _faceVm: ViewModel?,
  _lastFace: Artboard<nil>?,
  _lastPath: string,
  _lastProps: string,
  _didWatch: boolean,
  _dt: number,
  _lastR: number,
  _lastW: number,
  _lastH: number,
  _faceW: number,
  _faceH: number,
  _radius: number,
  _gpuPx: number,
  _texW: number,
  _texH: number,
  _vcount: number,
  _ctx: Context?,
  _hover: boolean,
  _tiltX: number,
  _tiltY: number,
  _tgtX: number,
  _tgtY: number,
  _shadowPath: Path,
  _shadowPathB: Path,
  _shadowFlip: boolean,
  _shadowPaint: Paint,
}

local function faceDims(self: Sphere3D): (number, number)
  local inst = self._inst
  if inst then
    local w = inst.width
    local h = inst.height
    if type(w) == 'number' and type(h) == 'number' and w > 1 and h > 1 then
      return w, h
    end
  end
  local src = self.face
  if src then
    local w = src.width
    local h = src.height
    if type(w) == 'number' and type(h) == 'number' and w > 1 and h > 1 then
      return w, h
    end
  end
  return DEFAULT_W, DEFAULT_H
end

local function radiusOf(fw: number, fh: number): number
  return math.max(8, math.max(fw, fh) * 0.5)
end

local function gpuPxFor(r: number): number
  return math.max(64, math.ceil(r * 2 + 64))
end

local function texSize(fw: number, fh: number): (number, number)
  local tw = math.clamp(math.floor(fw * TEX_SCALE + 0.5), 32, MAX_TEX)
  local th = math.clamp(math.floor(fh * TEX_SCALE + 0.5), 32, MAX_TEX)
  return tw, th
end

local function writeVert(
  data: buffer,
  i: number,
  x: number,
  y: number,
  z: number,
  u: number,
  v: number,
  kind: number
)
  local o = i * VSTRIDE
  buffer.writef32(data, o + 0, x)
  buffer.writef32(data, o + 4, y)
  buffer.writef32(data, o + 8, z)
  buffer.writef32(data, o + 12, u)
  buffer.writef32(data, o + 16, v)
  buffer.writef32(data, o + 20, kind)
end

local function writeQuad(
  data: buffer,
  i: number,
  ax: number,
  ay: number,
  az: number,
  au: number,
  av: number,
  bx: number,
  by: number,
  bz: number,
  bu: number,
  bv: number,
  cx: number,
  cy: number,
  cz: number,
  cu: number,
  cv: number,
  dx: number,
  dy: number,
  dz: number,
  du: number,
  dv: number,
  kind: number
): number
  writeVert(data, i + 0, ax, ay, az, au, av, if az < 0 then 1 else kind)
  writeVert(data, i + 1, bx, by, bz, bu, bv, if bz < 0 then 1 else kind)
  writeVert(data, i + 2, cx, cy, cz, cu, cv, if cz < 0 then 1 else kind)
  writeVert(data, i + 3, ax, ay, az, au, av, if az < 0 then 1 else kind)
  writeVert(data, i + 4, cx, cy, cz, cu, cv, if cz < 0 then 1 else kind)
  writeVert(data, i + 5, dx, dy, dz, du, dv, if dz < 0 then 1 else kind)
  return i + 6
end

local function sph(
  theta: number,
  phi: number,
  r: number
): (number, number, number, number, number)
  local st = math.sin(theta)
  local x = r * st * math.sin(phi)
  local y = r * math.cos(theta)
  local z = r * st * math.cos(phi)
  -- Front-facing: artboard center at +Z, top toward +Y.
  local u = 0.5 + x / (r * 2)
  local v = 0.5 - y / (r * 2)
  return x, y, z, u, v
end

local function buildSphere(data: buffer, r: number): number
  local vi = 0
  for i = 0, LAT_SEGS - 1 do
    local t0 = (i / LAT_SEGS) * math.pi
    local t1 = ((i + 1) / LAT_SEGS) * math.pi
    for j = 0, LON_SEGS - 1 do
      local p0 = (j / LON_SEGS) * math.pi * 2
      local p1 = ((j + 1) / LON_SEGS) * math.pi * 2
      local ax, ay, az, au, av = sph(t0, p0, r)
      local bx, by, bz, bu, bv = sph(t0, p1, r)
      local cx, cy, cz, cu, cv = sph(t1, p1, r)
      local dx, dy, dz, du, dv = sph(t1, p0, r)
      vi = writeQuad(
        data,
        vi,
        ax,
        ay,
        az,
        au,
        av,
        bx,
        by,
        bz,
        bu,
        bv,
        cx,
        cy,
        cz,
        cu,
        cv,
        dx,
        dy,
        dz,
        du,
        dv,
        0
      )
    end
  end
  return vi
end

local function num(v: any, fallback: number): number
  if type(v) == 'number' then
    return v
  end
  return fallback
end

local function addCircle(path: Path, cx: number, cy: number, r: number)
  local k = CIRCLE_K * r
  path:moveTo(Vector.xy(cx + r, cy))
  path:cubicTo(
    Vector.xy(cx + r, cy + k),
    Vector.xy(cx + k, cy + r),
    Vector.xy(cx, cy + r)
  )
  path:cubicTo(
    Vector.xy(cx - k, cy + r),
    Vector.xy(cx - r, cy + k),
    Vector.xy(cx - r, cy)
  )
  path:cubicTo(
    Vector.xy(cx - r, cy - k),
    Vector.xy(cx - k, cy - r),
    Vector.xy(cx, cy - r)
  )
  path:cubicTo(
    Vector.xy(cx + k, cy - r),
    Vector.xy(cx + r, cy - k),
    Vector.xy(cx + r, cy)
  )
  path:close()
end

local function drawSphereShadow(self: Sphere3D, renderer: Renderer, r: number)
  local opacity = math.clamp(num(self.shadowOpacity, 45), 0, 100) / 100
  if opacity <= 0.001 then
    return
  end
  if self._shadowPath == nil then
    self._shadowPath = Path.new()
    self._shadowPathB = Path.new()
    self._shadowPaint = Paint.with({ style = 'fill', color = Color.rgb(20, 12, 40) })
    self._shadowFlip = false
  end
  if self._shadowPathB == nil then
    self._shadowPathB = Path.new()
  end
  local softness = math.max(0, num(self.shadowSoftness, 28))
  local ox = num(self.shadowOffsetX, 0)
  local oy = num(self.shadowOffsetY, 18)
  local tiltX = self._tiltX
  local tiltY = self._tiltY
  if type(tiltX) ~= 'number' then
    tiltX = 0
  end
  if type(tiltY) ~= 'number' then
    tiltY = 0
  end
  ox += tiltY * 0.85
  oy += -tiltX * 0.85
  local col = self.shadowColor
  if type(col) ~= 'number' then
    col = Color.rgb(20, 12, 40)
  end
  local tint = Color.opacity(col, opacity)
  if type(tint) ~= 'number' then
    return
  end

  self._shadowFlip = not self._shadowFlip
  local path = self._shadowPath
  if self._shadowFlip then
    path = self._shadowPathB
  end
  path:reset()
  addCircle(path, 0, 0, r)

  local paint = self._shadowPaint
  paint.style = 'fill'
  paint.color = tint
  paint.feather = softness

  renderer:save()
  renderer:transform(Mat2D.withTranslation(ox, oy))
  renderer:drawPath(path, paint)
  renderer:restore()
end

local function easeToward(current: number, target: number, dt: number): number
  local a = 1 - math.exp(-TILT_SMOOTH * math.max(dt, 0))
  return current + (target - current) * a
end

local function setPointer(self: Sphere3D, event: PointerEvent)
  event:hit()
  self._hover = true
  local fw = self._faceW
  local fh = self._faceH
  if type(fw) ~= 'number' or fw < 1 then
    fw = DEFAULT_W
  end
  if type(fh) ~= 'number' or fh < 1 then
    fh = DEFAULT_H
  end
  local area = math.max(8, num(self.tiltArea, math.max(fw, fh)))
  local maxTilt = num(self.maxTilt, 18)
  local nx = math.clamp(event.position.x / area, -1, 1)
  local ny = math.clamp(event.position.y / area, -1, 1)
  self._tgtY = nx * maxTilt
  self._tgtX = ny * maxTilt
  local ctx = self._ctx
  if ctx then
    ctx:markNeedsUpdate()
  end
end

local function pointerMove(self: Sphere3D, event: PointerEvent)
  setPointer(self, event)
end

local function pointerDown(self: Sphere3D, event: PointerEvent)
  setPointer(self, event)
end

local function pointerExit(self: Sphere3D, event: PointerEvent)
  self._hover = false
  self._tgtX = 0
  self._tgtY = 0
  local ctx = self._ctx
  if ctx then
    ctx:markNeedsUpdate()
  end
end

local function kick(self: Sphere3D)
  local ctx = self._ctx
  if ctx then
    ctx:markNeedsUpdate()
  end
end

local function splitNames(list: string): { string }
  local names: { string } = {}
  for part in string.gmatch(list, '[^,]+') do
    local name = string.gsub(part, '^%s+', '')
    name = string.gsub(name, '%s+$', '')
    if name ~= '' then
      table.insert(names, name)
    end
  end
  return names
end

local function vmKeys(self: Sphere3D, source: ViewModel, clone: ViewModel): { string }
  local seen: { [string]: boolean } = {}
  local keys: { string } = {}
  local function add(name: string)
    if name == '' or name == 'new' or seen[name] then
      return
    end
    seen[name] = true
    table.insert(keys, name)
  end
  local function from(vm: ViewModel)
    pcall(function()
      for k, _ in pairs(vm :: any) do
        if type(k) == 'string' then
          add(k)
        end
      end
    end)
  end
  from(source)
  from(clone)
  local listed = self.properties
  if type(listed) == 'string' then
    for _, name in ipairs(splitNames(listed)) do
      add(name)
    end
  end
  return keys
end

local function bindViewModel(self: Sphere3D, source: ViewModel, clone: ViewModel)
  local function readValue(prop: any): any
    local ok, val = pcall(function()
      return prop.value
    end)
    if ok then
      return val
    end
    return nil
  end
  local function bindValue(srcProp: any, dstProp: any): boolean
    if not (srcProp and dstProp) then
      return false
    end
    local val = readValue(srcProp)
    if val == nil and readValue(dstProp) == nil then
      return false
    end
    local okSet = pcall(function()
      dstProp.value = srcProp.value
    end)
    if not okSet then
      return false
    end
    srcProp:addListener(self, function(_anchor: any)
      pcall(function()
        dstProp.value = srcProp.value
      end)
      kick(self)
    end)
    return true
  end
  for _, name in ipairs(vmKeys(self, source, clone)) do
    local st = source:getTrigger(name)
    local ct = clone:getTrigger(name)
    if st and ct then
      st:addListener(self, function(_anchor: any)
        ct:fire()
        kick(self)
      end)
    elseif bindValue(source:getNumber(name), clone:getNumber(name)) then
    elseif bindValue(source:getBoolean(name), clone:getBoolean(name)) then
    elseif bindValue(source:getString(name), clone:getString(name)) then
    elseif bindValue(source:getColor(name), clone:getColor(name)) then
    elseif bindValue(source:getEnum(name), clone:getEnum(name)) then
    else
      local svm = source:getViewModel(name)
      local cvm = clone:getViewModel(name)
      if svm and cvm then
        local sv = readValue(svm)
        local cv = readValue(cvm)
        if sv and cv then
          bindViewModel(self, sv, cv)
        end
      end
    end
  end
end

local function boundSource(self: Sphere3D): ViewModel?
  local ctx = self._ctx
  if not ctx then
    return nil
  end
  local path = self.viewModelProperty
  if type(path) ~= 'string' then
    path = ''
  end
  local function from(card: ViewModel?): ViewModel?
    if not card then
      return nil
    end
    if path ~= '' then
      local prop = card:getViewModel(path)
      if prop then
        return prop.value
      end
      return nil
    end
    return card
  end
  local found = from(ctx:viewModel())
  if found then
    return found
  end
  found = from(ctx:rootViewModel())
  if found then
    return found
  end
  local dc = ctx:dataContext()
  while dc do
    found = from(dc:viewModel())
    if found then
      return found
    end
    dc = dc:parent()
  end
  return nil
end

local function watchFaceData(self: Sphere3D, source: ViewModel, clone: ViewModel)
  if self._didWatch then
    return
  end
  self._didWatch = true
  bindViewModel(self, source, clone)
end

local function ensureInstance(self: Sphere3D)
  local src = self.face
  if not src then
    self._inst = nil
    self._faceVm = nil
    return
  end
  if not self._inst then
    local inst = src:instance()
    if inst then
      inst.frameOrigin = true
      self._inst = inst
    end
  end
  local inst = self._inst
  if not inst then
    return
  end
  local clone = inst.data :: any
  self._faceVm = clone
  local source = boundSource(self)
  if source and clone then
    watchFaceData(self, source, clone)
  end
end

local function renderFace(self: Sphere3D)
  local canvas = self._canvas
  local inst = self._inst
  if not (canvas and inst) then
    return
  end
  inst:advance(0)
  local tw = math.max(1, self._texW)
  local th = math.max(1, self._texH)
  local iw = math.max(1, inst.width)
  local ih = math.max(1, inst.height)
  local sx = tw / iw
  local sy = th / ih
  local r = canvas:beginFrame({ clearColor = 0x00000000 })
  r:save()
  r:transform(Mat2D.withScaleAndTranslation(sx, sy, 0, 0))
  inst:draw(r)
  r:restore()
  canvas:endFrame()
end

local function initGpu(self: Sphere3D, ctx: Context): boolean
  local sh = ctx:shader('Card3DShader')
  if not sh then
    print('[Sphere3D] Card3DShader missing')
    return false
  end

  local samples = MSAA
  local feats = ctx:features()
  if feats.maxSamples < samples then
    samples = math.max(1, feats.maxSamples)
  end

  local gpuPx = self._gpuPx
  if type(gpuPx) ~= 'number' or gpuPx < 8 then
    gpuPx = gpuPxFor(radiusOf(DEFAULT_W, DEFAULT_H))
    self._gpuPx = gpuPx
  end

  local gc = ctx:gpuCanvas({ width = gpuPx, height = gpuPx })
  local fmt = gc.format

  local msaaColor: GPUTexture? = nil
  local msaaView: GPUTextureView? = nil
  if samples > 1 then
    msaaColor = GPUTexture.new({
      width = gpuPx,
      height = gpuPx,
      format = fmt,
      renderTarget = true,
      sampleCount = samples,
    })
    msaaView = msaaColor:view()
  end

  local depth = GPUTexture.new({
    width = gpuPx,
    height = gpuPx,
    format = 'depth16unorm',
    renderTarget = true,
    sampleCount = samples,
  })

  local pipe = GPUPipeline.new({
    vertex = sh,
    fragment = sh,
    vertexLayout = {
      {
        stride = VSTRIDE,
        attributes = {
          { format = 'float32x3', slot = 0, offset = 0 },
          { format = 'float32x2', slot = 1, offset = 12 },
          { format = 'float32', slot = 2, offset = 20 },
        },
      },
    },
    colorTargets = {
      {
        format = fmt,
        blend = {
          srcColor = 'src-alpha',
          dstColor = 'one-minus-src-alpha',
          colorOp = 'add',
          srcAlpha = 'one',
          dstAlpha = 'one-minus-src-alpha',
          alphaOp = 'add',
        },
      },
    },
    depthStencil = { format = 'depth16unorm', compare = 'less', write = true },
    cullMode = 'none',
    sampleCount = samples,
  })

  local dummy = GPUTexture.new({ width = 1, height = 1, format = 'rgba8unorm' })
  local px = buffer.create(4)
  buffer.writeu8(px, 0, 255)
  buffer.writeu8(px, 1, 255)
  buffer.writeu8(px, 2, 255)
  buffer.writeu8(px, 3, 255)
  dummy:upload({ data = px })

  self._gpuSamp = GPUSampler.new({
    min = 'linear',
    mag = 'linear',
    wrapU = 'repeat',
    wrapV = 'clamp-to-edge',
  })

  self._gpu = gc
  self._msaaColor = msaaColor
  self._msaaView = msaaView
  self._depthTex = depth
  self._depthView = depth:view()
  self._samples = samples
  self._pipe = pipe
  self._ubo = GPUBuffer.new({ size = UBO_SIZE, usage = 'uniform' })
  self._ubuf = buffer.create(UBO_SIZE)
  self._vbo = GPUBuffer.new({ size = VBYTES, usage = 'vertex' })
  self._vdata = buffer.create(VBYTES)
  self._dummyView = dummy:view()
  self._lastR = -1
  self._lastW = -1
  self._lastH = -1
  self._vcount = 0
  return true
end

local function rebuildRt(self: Sphere3D, gpuPx: number)
  local gc = self._gpu
  if not gc then
    return
  end
  local samples = self._samples
  if type(samples) ~= 'number' then
    samples = MSAA
  end
  local fmt = gc.format
  local msaaColor: GPUTexture? = nil
  local msaaView: GPUTextureView? = nil
  if samples > 1 then
    msaaColor = GPUTexture.new({
      width = gpuPx,
      height = gpuPx,
      format = fmt,
      renderTarget = true,
      sampleCount = samples,
    })
    msaaView = msaaColor:view()
  end
  local depth = GPUTexture.new({
    width = gpuPx,
    height = gpuPx,
    format = 'depth16unorm',
    renderTarget = true,
    sampleCount = samples,
  })
  self._msaaColor = msaaColor
  self._msaaView = msaaView
  self._depthTex = depth
  self._depthView = depth:view()
end

local function ensureGpuSize(self: Sphere3D, fw: number, fh: number)
  local ctx = self._ctx
  if not ctx then
    return
  end
  local r = radiusOf(fw, fh)
  local gpx = gpuPxFor(r)
  local tw, th = texSize(fw, fh)
  self._faceW = fw
  self._faceH = fh
  self._radius = r
  self._texW = tw
  self._texH = th

  local canvas = self._canvas
  if not canvas then
    self._canvas = ctx:canvas({ width = tw, height = th })
  elseif canvas.width ~= tw or canvas.height ~= th then
    canvas:resize(tw, th)
  end

  if not self._gpu then
    self._gpuPx = gpx
    initGpu(self, ctx)
    return
  end
  if self._gpuPx == gpx and self._gpu.width == gpx then
    return
  end
  self._gpuPx = gpx
  self._gpu:resize(gpx, gpx)
  rebuildRt(self, gpx)
end

local function init(self: Sphere3D, ctx: Context): boolean
  self._ctx = ctx
  self._dt = 0
  self._tiltX = 0
  self._tiltY = 0
  self._tgtX = 0
  self._tgtY = 0
  self._hover = false
  self._didWatch = false
  self._lastPath = ''
  self._lastProps = ''
  self._imgSamp = ImageSampler('clamp', 'clamp', 'bilinear')
  self._faceW = DEFAULT_W
  self._faceH = DEFAULT_H
  self._radius = radiusOf(DEFAULT_W, DEFAULT_H)
  self._gpuPx = gpuPxFor(self._radius)
  local tw, th = texSize(DEFAULT_W, DEFAULT_H)
  self._texW = tw
  self._texH = th
  self._lastW = -1
  self._lastH = -1
  self._lastR = -1
  self._canvas = ctx:canvas({ width = tw, height = th })
  initGpu(self, ctx)
  ensureInstance(self)
  return true
end

local function update(self: Sphere3D)
  local src = self.face
  local path = self.viewModelProperty
  if type(path) ~= 'string' then
    path = ''
  end
  local props = self.properties
  if type(props) ~= 'string' then
    props = ''
  end
  if src ~= self._lastFace then
    self._inst = nil
    self._faceVm = nil
    self._didWatch = false
    self._lastFace = src
  end
  if path ~= self._lastPath or props ~= self._lastProps then
    self._didWatch = false
    self._lastPath = path
    self._lastProps = props
  end
  ensureInstance(self)
  local fw, fh = faceDims(self)
  self._faceW = fw
  self._faceH = fh
  self._radius = radiusOf(fw, fh)
end

local function advance(self: Sphere3D, seconds: number): boolean
  self._dt = seconds
  if type(self._tiltX) ~= 'number' then
    self._tiltX = 0
    self._tiltY = 0
    self._tgtX = 0
    self._tgtY = 0
  end
  self._tiltX = easeToward(self._tiltX, self._tgtX, seconds)
  self._tiltY = easeToward(self._tiltY, self._tgtY, seconds)
  ensureInstance(self)
  local inst = self._inst
  if inst then
    inst:advance(seconds)
  end
  return true
end

local function draw(self: Sphere3D, renderer: Renderer)
  ensureInstance(self)
  local fw, fh = faceDims(self)
  ensureGpuSize(self, fw, fh)
  renderFace(self)
  local gc = self._gpu
  local pipe = self._pipe
  local ubo = self._ubo
  local vbo = self._vbo
  local depthTex = self._depthTex
  local gpuSamp = self._gpuSamp
  if not (gc and pipe and ubo and vbo and depthTex and gpuSamp) then
    return
  end

  local r = self._radius
  if type(r) ~= 'number' or r < 8 then
    r = radiusOf(fw, fh)
    self._radius = r
  end
  local vdata = self._vdata
  if buffer.len(vdata) < VBYTES then
    vdata = buffer.create(VBYTES)
    self._vdata = vdata
    vbo = GPUBuffer.new({ size = VBYTES, usage = 'vertex' })
    self._vbo = vbo
  end
  if
    math.abs(r - self._lastR) > 0.01
    or math.abs(fw - self._lastW) > 0.01
    or math.abs(fh - self._lastH) > 0.01
  then
    self._vcount = buildSphere(vdata, r)
    vbo:write(vdata)
    self._lastR = r
    self._lastW = fw
    self._lastH = fh
  end

  local tiltX = self._tiltX
  local tiltY = self._tiltY
  if type(tiltX) ~= 'number' then
    tiltX = 0
  end
  if type(tiltY) ~= 'number' then
    tiltY = 0
  end
  local model = Mat4.fromRotationY(math.rad(self.rotY + tiltY))
    * Mat4.fromRotationX(math.rad(self.rotX + tiltX))
  local gpuHw = self._gpuPx * 0.5
  local proj = Mat4.ortho(-gpuHw, gpuHw, -gpuHw, gpuHw, -400, 400)
  local mvp = proj * model
  if buffer.len(self._ubuf) < UBO_SIZE then
    self._ubuf = buffer.create(UBO_SIZE)
    ubo = GPUBuffer.new({ size = UBO_SIZE, usage = 'uniform' })
    self._ubo = ubo
  end
  mvp:writeToBuffer(self._ubuf, 0)
  model:writeToBuffer(self._ubuf, 64)
  local ec = { 0.165, 0.094, 0.38, 1 }
  if self.edgeColor ~= nil then
    ec = Color.toFloat(self.edgeColor)
  end
  buffer.writef32(self._ubuf, 128, ec[1])
  buffer.writef32(self._ubuf, 132, ec[2])
  buffer.writef32(self._ubuf, 136, ec[3])
  buffer.writef32(self._ubuf, 140, ec[4])
  buffer.writef32(self._ubuf, 144, math.rad(num(self.lightAngle, 90)))
  buffer.writef32(self._ubuf, 148, num(self.lightIntensity, 25) / 100)
  buffer.writef32(self._ubuf, 152, num(self.glossIntensity, 40) / 100)
  buffer.writef32(self._ubuf, 156, num(self.glossSharpness, 40) / 100)
  buffer.writef32(self._ubuf, 160, 0.55)
  buffer.writef32(self._ubuf, 164, num(self.ambient, 42) / 100)
  buffer.writef32(self._ubuf, 168, 1)
  buffer.writef32(self._ubuf, 172, 0)
  local lc = { 1, 0.973, 0.902, 1 }
  if self.lightColor ~= nil then
    lc = Color.toFloat(self.lightColor)
  end
  buffer.writef32(self._ubuf, 176, lc[1])
  buffer.writef32(self._ubuf, 180, lc[2])
  buffer.writef32(self._ubuf, 184, lc[3])
  buffer.writef32(self._ubuf, 188, lc[4])
  buffer.writef32(self._ubuf, 192, num(self.foilIntensity, 40) / 100)
  buffer.writef32(self._ubuf, 196, num(self.foilStripes, 3))
  buffer.writef32(self._ubuf, 200, num(self.foilShift, 60) / 100)
  buffer.writef32(self._ubuf, 204, math.rad(num(self.foilAngle, 45)))
  ubo:write(self._ubuf)

  local faceView = self._dummyView
  local canvas = self._canvas
  if canvas and canvas.image then
    faceView = canvas.image:view()
  end
  if not faceView then
    return
  end

  local bg = GPUBindGroup.new({
    layout = pipe:getBindGroupLayout(0),
    ubos = { { slot = 0, buffer = ubo } },
    textures = { { slot = 1, view = faceView } },
    samplers = { { slot = 2, sampler = gpuSamp } },
  })

  local msaaView = self._msaaView
  local depthView = self._depthView
  if not depthView then
    return
  end
  local colorAttach
  if msaaView then
    colorAttach = {
      view = msaaView,
      resolveTarget = gc:colorView(),
      loadOp = 'clear',
      storeOp = 'discard',
      clearColor = { 0, 0, 0, 0 },
    }
  else
    colorAttach = {
      loadOp = 'clear',
      storeOp = 'store',
      clearColor = { 0, 0, 0, 0 },
    }
  end

  local passDesc: { [string]: any } = {
    color = { colorAttach },
    depthStencil = {
      view = depthView,
      depthLoadOp = 'clear',
      depthStoreOp = 'discard',
      depthClearValue = 1,
    },
  }
  local pass = gc:beginRenderPass(passDesc :: any)
  pass:setPipeline(pipe)
  pass:setVertexBuffer(0, vbo)
  pass:setBindGroup(0, bg)
  pass:draw(self._vcount)
  pass:finish()

  local s = 1
  if type(self.scale) == 'number' then
    s = math.max(0.01, self.scale)
  end
  renderer:save()
  renderer:transform(Mat2D.withScale(s, s))
  drawSphereShadow(self, renderer, r)
  renderer:save()
  renderer:transform(Mat2D.withTranslation(-gpuHw, -gpuHw))
  renderer:drawImage(gc.image, self._imgSamp, 'srcOver', 1)
  renderer:restore()
  renderer:restore()
end

return function(): Node<Sphere3D>
  return {
    rotX = 0,
    rotY = 0,
    scale = 1,
    maxTilt = 18,
    tiltArea = 180,
    edgeColor = Color.rgb(42, 24, 97),
    face = late(),
    viewModelProperty = 'propertyOfPurpleman',
    properties = 'idle,lookDown,twitch',
    shadowColor = Color.rgb(20, 12, 40),
    shadowOpacity = 45,
    shadowOffsetX = 0,
    shadowOffsetY = 18,
    shadowSoftness = 28,
    lightAngle = 90,
    lightIntensity = 25,
    glossIntensity = 40,
    glossSharpness = 40,
    lightColor = Color.rgb(255, 248, 230),
    ambient = 42,
    foilIntensity = 40,
    foilStripes = 3,
    foilShift = 60,
    foilAngle = 45,
    _canvas = nil,
    _gpu = nil,
    _msaaColor = nil,
    _msaaView = nil,
    _depthTex = nil,
    _depthView = nil,
    _pipe = nil,
    _ubo = nil,
    _ubuf = buffer.create(UBO_SIZE),
    _vbo = nil,
    _vdata = buffer.create(VBYTES),
    _gpuSamp = nil,
    _imgSamp = ImageSampler('clamp', 'clamp', 'bilinear'),
    _dummyView = nil,
    _inst = nil,
    _faceVm = nil,
    _lastFace = nil,
    _lastPath = '',
    _lastProps = '',
    _didWatch = false,
    _dt = 0,
    _lastR = -1,
    _lastW = -1,
    _lastH = -1,
    _faceW = DEFAULT_W,
    _faceH = DEFAULT_H,
    _radius = radiusOf(DEFAULT_W, DEFAULT_H),
    _gpuPx = gpuPxFor(radiusOf(DEFAULT_W, DEFAULT_H)),
    _texW = DEFAULT_W * TEX_SCALE,
    _texH = DEFAULT_H * TEX_SCALE,
    _vcount = 0,
    _samples = 1,
    _ctx = nil,
    _hover = false,
    _tiltX = 0,
    _tiltY = 0,
    _tgtX = 0,
    _tgtY = 0,
    _shadowPath = Path.new(),
    _shadowPathB = Path.new(),
    _shadowFlip = false,
    _shadowPaint = Paint.with({
      style = 'fill',
      color = Color.rgb(20, 12, 40),
      feather = 28,
    }),
    init = init,
    update = update,
    advance = advance,
    draw = draw,
    pointerMove = pointerMove,
    pointerDown = pointerDown,
    pointerExit = pointerExit,
  }
end
