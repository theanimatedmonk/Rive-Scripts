-- SandDust node: drives SandDustShader (WGSL in the Shaders panel).
-- Overlay of drifting sand / dust motes. Drop on an artboard over a gradient.
-- Width / height size the GPU canvas (defaults match the dither artboard).

local UBO_SIZE = 80
local DEFAULT_W = 1220
local DEFAULT_H = 567

type SandDust = {
  width: Input<number>,
  height: Input<number>,
  density: Input<number>,
  grainSize: Input<number>,
  softness: Input<number>,
  opacity: Input<number>,
  speed: Input<number>,
  windAngle: Input<number>,
  turbulence: Input<number>,
  falloff: Input<number>,
  sparkle: Input<number>,
  haze: Input<number>,
  seed: Input<number>,
  dustColor: Input<Color>,
  highlightColor: Input<Color>,
  _gpu: GPUCanvas?,
  _pipe: GPUPipeline?,
  _ubo: GPUBuffer?,
  _ubuf: buffer,
  _imgSamp: ImageSampler,
  _ctx: Context?,
  _t: number,
  _gpuW: number,
  _gpuH: number,
}

local function dim(v: any, fallback: number): number
  local n = num(v, fallback)
  if n <= 0 then
    return fallback
  end
  return n
end

local function initGpu(self: SandDust, ctx: Context): boolean
  local sh = ctx:shader('SandDustShader')
  if not sh then
    print('[SandDust] SandDustShader missing')
    return false
  end

  local w = math.max(8, math.floor(dim(self.width, DEFAULT_W) + 0.5))
  local h = math.max(8, math.floor(dim(self.height, DEFAULT_H) + 0.5))
  local gc = ctx:gpuCanvas({ width = w, height = h })
  local fmt = gc.format

  local pipe = GPUPipeline.new({
    vertex = sh,
    fragment = sh,
    vertexLayout = {},
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
    cullMode = 'none',
    sampleCount = 1,
  })

  self._gpu = gc
  self._pipe = pipe
  self._ubo = GPUBuffer.new({ size = UBO_SIZE, usage = 'uniform' })
  self._ubuf = buffer.create(UBO_SIZE)
  self._gpuW = w
  self._gpuH = h
  return true
end

local function ensureSize(self: SandDust)
  local gc = self._gpu
  if not gc then
    return
  end
  local w = math.max(8, math.floor(dim(self.width, DEFAULT_W) + 0.5))
  local h = math.max(8, math.floor(dim(self.height, DEFAULT_H) + 0.5))
  if w == self._gpuW and h == self._gpuH and gc.width == w then
    return
  end
  gc:resize(w, h)
  self._gpuW = w
  self._gpuH = h
end

local function init(self: SandDust, ctx: Context): boolean
  self._ctx = ctx
  self._t = 0
  self._imgSamp = ImageSampler('clamp', 'clamp', 'bilinear')
  initGpu(self, ctx)
  return true
end

local function update(self: SandDust) end

local function advance(self: SandDust, seconds: number): boolean
  self._t += seconds
  return true
end

local function draw(self: SandDust, renderer: Renderer)
  ensureSize(self)
  local gc = self._gpu
  local pipe = self._pipe
  local ubo = self._ubo
  if not (gc and pipe and ubo) then
    return
  end
  if buffer.len(self._ubuf) < UBO_SIZE then
    self._ubuf = buffer.create(UBO_SIZE)
    ubo = GPUBuffer.new({ size = UBO_SIZE, usage = 'uniform' })
    self._ubo = ubo
  end

  local w = self._gpuW
  local h = self._gpuH
  local buf = self._ubuf
  buffer.writef32(buf, 0, self._t)
  buffer.writef32(buf, 4, num(self.seed, 1))
  buffer.writef32(buf, 8, num(self.density, 45) / 100)
  buffer.writef32(buf, 12, num(self.grainSize, 35) / 100)
  buffer.writef32(buf, 16, math.rad(num(self.windAngle, 18)))
  buffer.writef32(buf, 20, num(self.speed, 22) / 100)
  buffer.writef32(buf, 24, num(self.turbulence, 40) / 100)
  buffer.writef32(buf, 28, w / math.max(h, 1))
  buffer.writef32(buf, 32, num(self.opacity, 55) / 100)
  buffer.writef32(buf, 36, num(self.softness, 50) / 100)
  buffer.writef32(buf, 40, num(self.falloff, 70) / 100)
  buffer.writef32(buf, 44, num(self.sparkle, 28) / 100)
  local dc = { 0.91, 0.82, 0.68, 1 }
  if self.dustColor ~= nil then
    dc = Color.toFloat(self.dustColor)
  end
  buffer.writef32(buf, 48, dc[1])
  buffer.writef32(buf, 52, dc[2])
  buffer.writef32(buf, 56, dc[3])
  buffer.writef32(buf, 60, 1)
  local hc = { 1, 0.96, 0.88, 1 }
  if self.highlightColor ~= nil then
    hc = Color.toFloat(self.highlightColor)
  end
  buffer.writef32(buf, 64, hc[1])
  buffer.writef32(buf, 68, hc[2])
  buffer.writef32(buf, 72, hc[3])
  buffer.writef32(buf, 76, num(self.haze, 35) / 100)
  ubo:write(buf)

  local bg = GPUBindGroup.new({
    layout = pipe:getBindGroupLayout(0),
    ubos = { { slot = 0, buffer = ubo } },
  })

  local pass = gc:beginRenderPass({
    color = {
      {
        loadOp = 'clear',
        storeOp = 'store',
        clearColor = { 0, 0, 0, 0 },
      },
    },
  } :: any)
  pass:setPipeline(pipe)
  pass:setBindGroup(0, bg)
  pass:draw(3)
  pass:finish()

  renderer:save()
  renderer:transform(Mat2D.withTranslation(-w * 0.5, -h * 0.5))
  renderer:drawImage(gc.image, self._imgSamp, 'srcOver', 1)
  renderer:restore()
end

return function(): Node<SandDust>
  return {
    width = DEFAULT_W,
    height = DEFAULT_H,
    density = 45,
    grainSize = 35,
    softness = 50,
    opacity = 55,
    speed = 22,
    windAngle = 18,
    turbulence = 40,
    falloff = 70,
    sparkle = 28,
    haze = 35,
    seed = 1,
    dustColor = Color.rgb(232, 209, 173),
    highlightColor = Color.rgb(255, 245, 224),
    _gpu = nil,
    _pipe = nil,
    _ubo = nil,
    _ubuf = buffer.create(UBO_SIZE),
    _imgSamp = ImageSampler('clamp', 'clamp', 'bilinear'),
    _ctx = nil,
    _t = 0,
    _gpuW = DEFAULT_W,
    _gpuH = DEFAULT_H,
    init = init,
    update = update,
    advance = advance,
    draw = draw,
  }
end
