--[[
  FluidParticles — 400×80 drifting particles (1×1, 2×2, 3×3, …).

  Wiring in Rive:
  1. Create a Node script from this asset and place it on your artboard (400×80 region).
  2. Property Group:
     - pace (0–10): movement speed
     - density (0–10): particle count (sparse → dense)
     - particle1–particle4: artboards used for dots (optional; falls back to drawn circles)
  3. Bind pace / density to View Model numbers or tune in the inspector.
]]

local VIEWPORT_W = 400
local VIEWPORT_H = 80
local MAX_PARTICLES = 90

local SIZE_OPTIONS = { 1, 1, 2, 2, 3, 3 }

local FALLBACK_COLOR = 0xB3FFFFFF -- soft white, ~70% opacity

type FluidParticle = {
  x: number,
  y: number,
  vx: number,
  vy: number,
  size: number,
  phase: number,
  driftRate: number,
  opacity: number,
  artboardInstance: Artboard<nil>?,
}

export type FluidParticles = {
  pace: Input<number>,
  density: Input<number>,
  particle1: Input<Artboard<nil>>,
  particle2: Input<Artboard<nil>>,
  particle3: Input<Artboard<nil>>,
  particle4: Input<Artboard<nil>>,
  particles: { FluidParticle },
  targetCount: number,
  time: number,
  hasParticleArtboard1: boolean,
  hasParticleArtboard2: boolean,
  hasParticleArtboard3: boolean,
  hasParticleArtboard4: boolean,
  circlePath: Path?,
  circlePaint: Paint?,
}

local function clamp(value: number, minVal: number, maxVal: number): number
  if value < minVal then
    return minVal
  end
  if value > maxVal then
    return maxVal
  end
  return value
end

local function randomRange(min: number, max: number): number
  return min + math.random() * (max - min)
end

local function readInput(value: number?, fallback: number): number
  if value == nil then
    return fallback
  end
  return value
end

local function targetCountFromDensity(density: number): number
  local d = clamp(density, 0, 10) / 10
  if d <= 0 then
    return 0
  end
  return math.max(1, math.floor(d * MAX_PARTICLES))
end

local function paceNorm(pace: number): number
  return clamp(pace, 0, 10) / 10
end

local function maxSpeed(pace: number): number
  local n = paceNorm(pace)
  return 2 + n * 38
end

local function flowStrength(pace: number): number
  local n = paceNorm(pace)
  return 3 + n * 50
end

local function pickSize(): number
  local i = math.floor(randomRange(1, #SIZE_OPTIONS + 0.99))
  return SIZE_OPTIONS[i]
end

local function isArtboardValid(artboard: Artboard<nil>): boolean
  local ok = pcall(function()
    local _ = artboard.width
  end)
  return ok
end

local function addCircle(path: Path, radius: number)
  local segments = 12
  for i = 0, segments - 1 do
    local a = (i / segments) * 2 * math.pi
    local x = radius * math.cos(a)
    local y = radius * math.sin(a)
    if i == 0 then
      path:moveTo(Vector.xy(x, y))
    else
      path:lineTo(Vector.xy(x, y))
    end
  end
  path:close()
end

local function artboardScale(instance: Artboard<nil>, diameter: number): number
  local w = instance.width
  if w and w > 0 then
    return diameter / w
  end
  return diameter
end

local function refreshArtboardFlags(self: FluidParticles)
  self.hasParticleArtboard1 = isArtboardValid(self.particle1)
  self.hasParticleArtboard2 = isArtboardValid(self.particle2)
  self.hasParticleArtboard3 = isArtboardValid(self.particle3)
  self.hasParticleArtboard4 = isArtboardValid(self.particle4)
end

local function hasAnyParticleArtboard(self: FluidParticles): boolean
  return self.hasParticleArtboard1
    or self.hasParticleArtboard2
    or self.hasParticleArtboard3
    or self.hasParticleArtboard4
end

local function pickParticleArtboard(self: FluidParticles): Artboard<nil>?
  local choices: { Artboard<nil> } = {}
  if self.hasParticleArtboard1 then
    table.insert(choices, self.particle1)
  end
  if self.hasParticleArtboard2 then
    table.insert(choices, self.particle2)
  end
  if self.hasParticleArtboard3 then
    table.insert(choices, self.particle3)
  end
  if self.hasParticleArtboard4 then
    table.insert(choices, self.particle4)
  end
  if #choices == 0 then
    return nil
  end
  local i = math.floor(randomRange(1, #choices + 0.99))
  return choices[i]
end

local function spawnParticle(self: FluidParticles): FluidParticle
  local size = pickSize()
  local half = size * 0.5
  local artboardInstance: Artboard<nil>? = nil
  if hasAnyParticleArtboard(self) then
    local artboard = pickParticleArtboard(self)
    if artboard then
      artboardInstance = artboard:instance()
    end
  end

  return {
    x = randomRange(half, VIEWPORT_W - half),
    y = randomRange(half, VIEWPORT_H - half),
    vx = randomRange(-8, 8),
    vy = randomRange(-8, 8),
    size = size,
    phase = randomRange(0, math.pi * 2),
    driftRate = randomRange(0.6, 1.4),
    opacity = randomRange(0.35, 0.85),
    artboardInstance = artboardInstance,
  }
end

local function wrapParticle(p: FluidParticle)
  local half = p.size * 0.5
  if p.x < -half then
    p.x = VIEWPORT_W + half
  elseif p.x > VIEWPORT_W + half then
    p.x = -half
  end
  if p.y < -half then
    p.y = VIEWPORT_H + half
  elseif p.y > VIEWPORT_H + half then
    p.y = -half
  end
end

local function updateParticle(p: FluidParticle, dt: number, time: number, pace: number)
  local flow = flowStrength(pace)
  local cap = maxSpeed(pace)

  local ax = math.sin(time * 0.45 * p.driftRate + p.phase) * flow
  local ay = math.cos(time * 0.38 * p.driftRate + p.phase * 1.7) * flow * 0.85
  local ax2 = math.sin(time * 0.9 + p.phase * 2.1) * flow * 0.35
  local ay2 = math.cos(time * 0.75 + p.phase * 0.6) * flow * 0.35

  p.vx = p.vx + (ax + ax2) * dt
  p.vy = p.vy + (ay + ay2) * dt

  local damping = 1 - clamp(1.8 * dt, 0, 0.95)
  p.vx = p.vx * damping
  p.vy = p.vy * damping

  local speed = math.sqrt(p.vx * p.vx + p.vy * p.vy)
  if speed > cap and speed > 0 then
    p.vx = (p.vx / speed) * cap
    p.vy = (p.vy / speed) * cap
  end

  p.x = p.x + p.vx * dt
  p.y = p.y + p.vy * dt
  wrapParticle(p)
end

local function syncParticleCount(self: FluidParticles)
  local target = targetCountFromDensity(readInput(self.density, 5))
  self.targetCount = target

  while #self.particles > target do
    table.remove(self.particles)
  end

  while #self.particles < target do
    table.insert(self.particles, spawnParticle(self))
  end
end

local function init(self: FluidParticles, _context: Context): boolean
  self.particles = {}
  self.time = 0
  self.targetCount = 0
  refreshArtboardFlags(self)
  self.circlePath = Path.new()
  addCircle(self.circlePath, 1)
  self.circlePaint = Paint.with({
    style = "fill",
    color = FALLBACK_COLOR,
  })
  syncParticleCount(self)
  return true
end

local function update(self: FluidParticles)
  refreshArtboardFlags(self)
  syncParticleCount(self)
end

local function advance(self: FluidParticles, dt: number): boolean
  local cappedDt = math.min(dt, 0.05)
  self.time = self.time + cappedDt

  local pace = readInput(self.pace, 3)
  syncParticleCount(self)

  for _, p in ipairs(self.particles) do
    updateParticle(p, cappedDt, self.time, pace)
    if p.artboardInstance then
      p.artboardInstance:advance(cappedDt)
    end
  end

  return true
end

local function draw(self: FluidParticles, renderer: Renderer)
  local path = self.circlePath
  local basePaint = self.circlePaint
  if not path or not basePaint then
    return
  end

  for _, p in ipairs(self.particles) do
    if p.artboardInstance then
      renderer:save()
      local scale = artboardScale(p.artboardInstance, p.size)
      local transform = Mat2D.withTranslation(p.x, p.y)
      transform = transform * Mat2D.withScale(scale, scale)
      renderer:transform(transform)
      p.artboardInstance:draw(renderer)
      renderer:restore()
    else
      local alpha = clamp(math.floor(p.opacity * 255), 0, 255)
      local color = bit32.bor(
        bit32.lshift(alpha, 24),
        bit32.band(FALLBACK_COLOR, 0xFFFFFF)
      )
      local paint = basePaint:copy({ color = color })
      renderer:save()
      renderer:transform(Mat2D.withTranslation(p.x, p.y))
      renderer:transform(Mat2D.withScale(p.size, p.size))
      renderer:drawPath(path, paint)
      renderer:restore()
    end
  end
end

return function(): Node<FluidParticles>
  return {
    pace = 3,
    density = 5,
    particle1 = late(),
    particle2 = late(),
    particle3 = late(),
    particle4 = late(),
    particles = {},
    targetCount = 0,
    time = 0,
    hasParticleArtboard1 = false,
    hasParticleArtboard2 = false,
    hasParticleArtboard3 = false,
    hasParticleArtboard4 = false,
    circlePath = nil,
    circlePaint = nil,
    init = init,
    update = update,
    advance = advance,
    draw = draw,
  }
end
