-- Leaf cluster 2: same setup as leaf-cluster, different position and orientation.
-- Inputs: flowerDensity, leafDensity 0–5; scale 1–5; windSpeed 0–5; FlowerArtboard, LeafArtboard.

local CANVAS_W = 412
local CANVAS_H = 600
local CLUSTER_CX = 105
local CLUSTER_CY = 260
local CLUSTER_RX = 95
local CLUSTER_RY = 110
local CLUSTER_ROTATION = 0.62
local MAX_LEAVES = 320
local MIN_VISIBLE = 10
local MAX_VISIBLE = 320
local WIND_CULL_MARGIN = 80

type Leaf = {
  x: number,
  y: number,
  size: number,
  shapeIndex: number,
  rotation: number,
  artboardType: number,
  windPhase: number,
  driftBias: number,
}

export type LeafCluster2 = {
  flowerDensity: Input<number>,
  leafDensity: Input<number>,
  scale: Input<number>,
  windSpeed: Input<number>,
  FlowerArtboard: Input<Artboard>,
  LeafArtboard: Input<Artboard>,
  time: number,
  leaves: { Leaf },
  flowerInstance: Artboard?,
  leafInstance: Artboard?,
  flowerArtboardW: number,
  flowerArtboardH: number,
  leafArtboardW: number,
  leafArtboardH: number,
}

local function clamp(v: number, lo: number, hi: number): number
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function lerp(a: number, b: number, t: number): number
  return a + (b - a) * t
end

local function randomRange(lo: number, hi: number): number
  return lo + math.random() * (hi - lo)
end

local function densityNorm05(self: LeafCluster2, input: string): number
  local v = (input == "flower" and self.flowerDensity or self.leafDensity) or 0
  return clamp(v, 0, 5) / 5
end

local function scaleNorm(self: LeafCluster2): number
  return clamp(self.scale or 3, 1, 5) / 5
end

local function windNorm(self: LeafCluster2): number
  return clamp(self.windSpeed or 0, 0, 5) / 5
end

local function getArtboardSize(artboard: Artboard): (number, number)
  local w = artboard.width
  local h = artboard.height
  if w <= 0 then w = 20 end
  if h <= 0 then h = 20 end
  return w, h
end

local function ensureLeafInstance(self: LeafCluster2): boolean
  if not self.LeafArtboard then return false end
  if self.leafInstance then return true end
  local ok, inst = pcall(function()
    return self.LeafArtboard:instance()
  end)
  if ok and inst then
    self.leafInstance = inst
    local w, h = getArtboardSize(self.LeafArtboard)
    self.leafArtboardW = w
    self.leafArtboardH = h
    return true
  end
  return false
end

local function ensureFlowerInstance(self: LeafCluster2): boolean
  if not self.FlowerArtboard then return false end
  if self.flowerInstance then return true end
  local ok, inst = pcall(function()
    return self.FlowerArtboard:instance()
  end)
  if ok and inst then
    self.flowerInstance = inst
    local w, h = getArtboardSize(self.FlowerArtboard)
    self.flowerArtboardW = w
    self.flowerArtboardH = h
    return true
  end
  return false
end

local function leafPath1(size: number): Path
  local p = Path.new()
  local s = size
  p:moveTo(Vector.xy(0, -s * 1.05))
  p:cubicTo(Vector.xy(s * 0.7, -s * 0.85), Vector.xy(s * 0.92, -s * 0.1), Vector.xy(s * 0.48, s * 0.28))
  p:cubicTo(Vector.xy(s * 0.42, s * 0.85), Vector.xy(s * 0.16, s * 1.05), Vector.xy(0, s * 1.1))
  p:cubicTo(Vector.xy(-s * 0.16, s * 1.05), Vector.xy(-s * 0.42, s * 0.85), Vector.xy(-s * 0.48, s * 0.28))
  p:cubicTo(Vector.xy(-s * 0.92, -s * 0.1), Vector.xy(-s * 0.7, -s * 0.85), Vector.xy(0, -s * 1.05))
  p:close()
  return p
end

local function leafPath2(size: number): Path
  local p = Path.new()
  local s = size
  p:moveTo(Vector.xy(0, -s))
  p:cubicTo(Vector.xy(s * 0.9, -s * 0.3), Vector.xy(s * 0.85, s * 0.7), Vector.xy(0, s))
  p:cubicTo(Vector.xy(-s * 0.85, s * 0.7), Vector.xy(-s * 0.9, -s * 0.3), Vector.xy(0, -s))
  p:close()
  return p
end

local function leafPath3(size: number): Path
  local p = Path.new()
  local s = size
  p:moveTo(Vector.xy(0, -s * 1.2))
  p:cubicTo(Vector.xy(s * 0.5, 0), Vector.xy(s * 0.35, s * 1.0), Vector.xy(0, s * 1.15))
  p:cubicTo(Vector.xy(-s * 0.35, s * 1.0), Vector.xy(-s * 0.5, 0), Vector.xy(0, -s * 1.2))
  p:close()
  return p
end

local function drawLeafPath(renderer: Renderer, path: Path, color: Color)
  renderer:drawPath(path, Paint.with({ style = "fill", color = color }))
end

local function buildLeaves(self: LeafCluster2)
  self.leaves = {}
  for _ = 1, MAX_LEAVES do
    local u = math.random()
    local v = math.random()
    local r = math.sqrt(v) * (0.4 + 0.6 * math.random())
    local angle = u * 2 * math.pi
    local x = CLUSTER_CX + math.cos(angle) * CLUSTER_RX * r + randomRange(-18, 18)
    local y = CLUSTER_CY + math.sin(angle) * CLUSTER_RY * r + randomRange(-18, 18)
    local size = randomRange(4, 18)
    local shapeIndex = math.floor(randomRange(1, 3.99))
    local rotation = randomRange(0, 2 * math.pi)
    local artboardType = (math.random() < 0.5) and 1 or 2
    table.insert(self.leaves, {
      x = x,
      y = y,
      size = size,
      shapeIndex = shapeIndex,
      rotation = rotation,
      artboardType = artboardType,
      windPhase = randomRange(0, 2 * math.pi),
      driftBias = randomRange(0.5, 1.5),
    })
  end
end

function init(self: LeafCluster2, context: Context): boolean
  self.time = 0
  buildLeaves(self)
  return true
end

function advance(self: LeafCluster2, dt: number): boolean
  local cap = math.min(dt, 0.05)
  self.time = self.time + cap
  if self.leafInstance then self.leafInstance:advance(cap) end
  if self.flowerInstance then self.flowerInstance:advance(cap) end
  return true
end

function draw(self: LeafCluster2, renderer: Renderer)
  local useLeafArt = ensureLeafInstance(self)
  local useFlowerArt = ensureFlowerInstance(self)
  local flowerDn = densityNorm05(self, "flower")
  local leafDn = densityNorm05(self, "leaf")
  local wn = windNorm(self)
  local scaleMult = 0.55 + 0.65 * scaleNorm(self)
  local color = Color.rgb(72, 130, 52)
  local totalFlowers, totalLeaves = 0, 0
  for _, leaf in ipairs(self.leaves) do
    if leaf.artboardType == 2 then totalFlowers = totalFlowers + 1 else totalLeaves = totalLeaves + 1 end
  end
  local flowerVisibleCount = math.floor(lerp(0, totalFlowers, flowerDn))
  local leafVisibleCount = math.floor(lerp(0, totalLeaves, leafDn))
  local flowersDrawn, leavesDrawn = 0, 0
  local refLeaf, refFlower = 20.0, 20.0
  if useLeafArt and (self.leafArtboardW > 0 or self.leafArtboardH > 0) then refLeaf = math.max(self.leafArtboardW, self.leafArtboardH) end
  if useFlowerArt and (self.flowerArtboardW > 0 or self.flowerArtboardH > 0) then refFlower = math.max(self.flowerArtboardW, self.flowerArtboardH) end

  for _, leaf in ipairs(self.leaves) do
    local isFlower = (leaf.artboardType == 2)
    local shouldDraw = false
    if isFlower and flowerDn > 0 and flowersDrawn < flowerVisibleCount then shouldDraw = true; flowersDrawn = flowersDrawn + 1
    elseif not isFlower and leafDn > 0 and leavesDrawn < leafVisibleCount then shouldDraw = true; leavesDrawn = leavesDrawn + 1
    end
    if not shouldDraw then
    else
      local swayX = wn * 14 * math.sin(self.time * 1.8 + leaf.windPhase) * leaf.driftBias
      local swayY = wn * 5 * math.sin(self.time * 1.2 + leaf.windPhase * 0.7)
      local driftX = wn * 45 * self.time * 0.08 * leaf.driftBias
      local drawX = leaf.x + swayX + driftX
      local drawY = leaf.y + swayY
      if drawX < -WIND_CULL_MARGIN or drawX > CANVAS_W + WIND_CULL_MARGIN or drawY < -WIND_CULL_MARGIN or drawY > CANVAS_H + WIND_CULL_MARGIN then
      else
      local size = leaf.size * scaleMult
      local useArt, inst, tw, th, refSize = false, nil, 0, 0, 20.0
      if isFlower then
        if useFlowerArt and self.flowerInstance then useArt = true; inst = self.flowerInstance; tw, th = self.flowerArtboardW, self.flowerArtboardH; refSize = refFlower end
      else
        if useLeafArt and self.leafInstance then useArt = true; inst = self.leafInstance; tw, th = self.leafArtboardW, self.leafArtboardH; refSize = refLeaf end
      end
      renderer:save()
      renderer:transform(Mat2D.withTranslation(drawX, drawY))
      renderer:transform(Mat2D.withRotation(leaf.rotation + CLUSTER_ROTATION + wn * 0.15 * math.sin(self.time + leaf.windPhase)))
      renderer:transform(Mat2D.withScale(size / refSize, size / refSize))
      if useArt and inst then
        renderer:transform(Mat2D.withTranslation(-tw * 0.5, -th * 0.5))
        inst:draw(renderer)
      else
        local path = (leaf.shapeIndex == 1 and leafPath1(size)) or (leaf.shapeIndex == 2 and leafPath2(size)) or leafPath3(size)
        drawLeafPath(renderer, path, color)
      end
      renderer:restore()
      end
    end
  end
end

return function(): Node<LeafCluster2>
  return {
    flowerDensity = 3,
    leafDensity = 3,
    scale = 3,
    windSpeed = 0,
    FlowerArtboard = late(),
    LeafArtboard = late(),
    time = 0,
    leaves = {},
    flowerInstance = nil,
    leafInstance = nil,
    flowerArtboardW = 0,
    flowerArtboardH = 0,
    leafArtboardW = 0,
    leafArtboardH = 0,
    init = init,
    advance = advance,
    draw = draw,
  }
end
