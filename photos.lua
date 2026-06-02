-- Photos (Photon particles falling down)
-- Light 0 = fewer, 100 = more. Optional artboard per photon. Bounds 388x160.

local MAX_PHOTONS = 400
local BOUNDS_W = 388
local BOUNDS_H = 160

type Photon = {
  x: number,
  y: number,
  vy: number,
  length: number,
  opacity: number,
  artboardInstance: Artboard<nil>?,
}

export type Photos = {
  light: Input<number>,
  lightPhotonParticle: Input<Artboard<nil>>,
  photons: { Photon },
  spawnAccumulator: number,
  boundsW: number,
  boundsH: number,
  hasPhotonArtboard: boolean,
}

local function clamp(value: number, minVal: number, maxVal: number): number
  if value < minVal then return minVal end
  if value > maxVal then return maxVal end
  return value
end

local function norm(v: number): number
  if v == nil then return 0.5 end
  if v <= 0 then return 0 end
  if v >= 100 then return 1 end
  return v / 100
end

local function randomRange(min: number, max: number): number
  return min + math.random() * (max - min)
end

local function getPhotonSpawnRate(lightNorm: number): number
  if lightNorm <= 0 then return 0 end
  return 5 + lightNorm * 95
end

local function isArtboardValid(artboard: Artboard<nil>): boolean
  local ok = pcall(function()
    local _ = artboard.width
  end)
  return ok
end

local function spawnPhoton(self: Photos): Photon
  local artboardInstance: Artboard<nil>? = nil
  if self.hasPhotonArtboard then
    artboardInstance = self.lightPhotonParticle:instance()
  end
  return {
    x = randomRange(0, self.boundsW),
    y = randomRange(-40, 0),
    vy = randomRange(60, 180),
    length = randomRange(10, 28),
    opacity = randomRange(0.5, 0.95),
    artboardInstance = artboardInstance,
  }
end

local function updatePhoton(ph: Photon, dt: number, boundsH: number): boolean
  ph.y = ph.y + ph.vy * dt
  if ph.artboardInstance then
    ph.artboardInstance:advance(dt)
  end
  if ph.y > boundsH + ph.length + 20 then
    return false
  end
  return true
end

local function init(self: Photos, context: Context): boolean
  self.photons = {}
  self.spawnAccumulator = 0
  self.boundsW = BOUNDS_W
  self.boundsH = BOUNDS_H
  self.hasPhotonArtboard = isArtboardValid(self.lightPhotonParticle)
  return true
end

local function advance(self: Photos, dt: number): boolean
  local cappedDt = math.min(dt, 0.05)
  local lightNorm = norm(self.light)

  local alive: { Photon } = {}
  for _, ph in ipairs(self.photons) do
    if updatePhoton(ph, cappedDt, self.boundsH) then
      table.insert(alive, ph)
    end
  end
  self.photons = alive

  local rate = getPhotonSpawnRate(lightNorm)
  self.spawnAccumulator = self.spawnAccumulator + rate * cappedDt
  local toSpawn = math.floor(self.spawnAccumulator)
  self.spawnAccumulator = self.spawnAccumulator - toSpawn
  toSpawn = math.min(toSpawn, MAX_PHOTONS - #self.photons, 25)
  for _ = 1, toSpawn do
    table.insert(self.photons, spawnPhoton(self))
  end

  return true
end

local function draw(self: Photos, renderer: Renderer)
  for _, ph in ipairs(self.photons) do
    if ph.y + ph.length > 0 and ph.y < self.boundsH + 20 then
      if ph.artboardInstance then
        renderer:save()
        renderer:transform(Mat2D.withTranslation(ph.x, ph.y))
        ph.artboardInstance:draw(renderer)
        renderer:restore()
      else
        local path = Path.new()
        path:moveTo(Vector.xy(ph.x, ph.y))
        path:lineTo(Vector.xy(ph.x, ph.y + ph.length))
        local alpha = clamp(math.floor(ph.opacity * 255), 0, 255)
        local paint = Paint.with({
          style = "stroke",
          thickness = 1.2,
          color = bit32.bor(bit32.lshift(alpha, 24), 0xFFFFFF),
          cap = "round",
        })
        renderer:drawPath(path, paint)
      end
    end
  end
end

return function(): Node<Photos>
  return {
    light = 50,
    lightPhotonParticle = late(),
    photons = {},
    spawnAccumulator = 0,
    boundsW = BOUNDS_W,
    boundsH = BOUNDS_H,
    hasPhotonArtboard = false,
    init = init,
    advance = advance,
    draw = draw,
  }
end
