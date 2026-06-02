-- Oxygen (O2 particles rising up)
-- o2 0 = fewer, 100 = more. Blue/pink dots.
-- explosionTrigger: when fired, particles burst randomly from the spawn line for 3s, then back to normal rising.

local MAX_O2 = 50
local BOUNDS_W = 200
local BOUNDS_H = 400
local EXPLOSION_DURATION = 3
local EXPLOSION_BURST_MIN = 60
local EXPLOSION_BURST_MAX = 180

type O2Particle = {
  x: number,
  y: number,
  vx: number,
  vy: number,
  size: number,
  opacity: number,
  color: number, -- 0 blue, 1 pink
  artboardInstance: Artboard<nil>?,
}

export type Oxygen = {
  o2: Input<number>,
  explosionTrigger: Input<Trigger>,
  o2Molecule: Input<Artboard<nil>>,      -- artboard for blue O2 particles
  o2MoleculePink: Input<Artboard<nil>>,  -- artboard for pink O2 particles
  o2Particles: { O2Particle },
  spawnAccumulator: number,
  boundsW: number,
  boundsH: number,
  time: number,
  explosionEndTime: number,
  hasMoleculeArtboard: boolean,
  hasPinkMoleculeArtboard: boolean,
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

local function getO2SpawnRate(o2Norm: number): number
  if o2Norm <= 0 then return 0 end
  return 3 + o2Norm * 60
end

local function isArtboardValid(artboard: Artboard<nil>): boolean
  local ok = pcall(function()
    local _ = artboard.width
  end)
  return ok
end

local function isExploding(self: Oxygen): boolean
  return self.explosionEndTime > 0 and self.time < self.explosionEndTime
end

-- Spawn O2: normal = from bottom rising; explosion = from center line with random burst
local function spawnO2(self: Oxygen, exploding: boolean): O2Particle
  local x = randomRange(self.boundsW * 0.2, self.boundsW * 0.8)
  local y = self.boundsH + randomRange(0, 30)
  local vx: number
  local vy: number
  if exploding then
    vx = randomRange(-EXPLOSION_BURST_MAX, EXPLOSION_BURST_MAX)
    vy = randomRange(-EXPLOSION_BURST_MAX, EXPLOSION_BURST_MAX)
  else
    vx = 0
    vy = -randomRange(25, 85)
  end
  local color = math.random() < 0.5 and 0 or 1
  local artboardInstance: Artboard<nil>? = nil
  if color == 0 and self.hasMoleculeArtboard then
    artboardInstance = self.o2Molecule:instance()
  elseif color == 1 and self.hasPinkMoleculeArtboard then
    artboardInstance = self.o2MoleculePink:instance()
  end
  return {
    x = x,
    y = y,
    vx = vx,
    vy = vy,
    size = randomRange(1.2, 2.6),
    opacity = randomRange(0.4, 0.9),
    color = color,
    artboardInstance = artboardInstance,
  }
end

-- Update O2: move by vx, vy; remove if off-screen
local function updateO2(p: O2Particle, dt: number, boundsW: number, boundsH: number): boolean
  p.x = p.x + p.vx * dt
  p.y = p.y + p.vy * dt
  if p.artboardInstance then
    p.artboardInstance:advance(dt)
  end
  if p.y < -p.size - 20 then
    return false
  end
  if p.y > boundsH + p.size + 20 then
    return false
  end
  if p.x < -p.size - 20 or p.x > boundsW + p.size + 20 then
    return false
  end
  return true
end

-- Trigger: start explosion (burst all particles from center line for 3s)
local function onExplosionTrigger(self: Oxygen)
  self.explosionEndTime = self.time + EXPLOSION_DURATION
  for _, p in ipairs(self.o2Particles) do
    p.vx = randomRange(-EXPLOSION_BURST_MAX, EXPLOSION_BURST_MAX)
    p.vy = randomRange(-EXPLOSION_BURST_MAX, EXPLOSION_BURST_MAX)
  end
end

local function addCircle(path: Path, r: number)
  local n = 10
  for i = 0, n - 1 do
    local a = (i / n) * 2 * math.pi
    local x = r * math.cos(a)
    local y = r * math.sin(a)
    if i == 0 then
      path:moveTo(Vector.xy(x, y))
    else
      path:lineTo(Vector.xy(x, y))
    end
  end
  path:close()
end

local function init(self: Oxygen, context: Context): boolean
  self.o2Particles = {}
  self.spawnAccumulator = 0
  self.boundsW = BOUNDS_W
  self.boundsH = BOUNDS_H
  self.time = 0
  self.explosionEndTime = 0
  self.hasMoleculeArtboard = isArtboardValid(self.o2Molecule)
  self.hasPinkMoleculeArtboard = isArtboardValid(self.o2MoleculePink)
  return true
end

local function advance(self: Oxygen, dt: number): boolean
  local cappedDt = math.min(dt, 0.05)
  self.time = self.time + cappedDt
  local o2Norm = norm(self.o2)
  local exploding = isExploding(self)

  -- When explosion just ended, reset all particles to rising
  if self.explosionEndTime > 0 and self.time >= self.explosionEndTime then
    self.explosionEndTime = 0
    for _, p in ipairs(self.o2Particles) do
      p.vx = 0
      p.vy = -randomRange(25, 85)
    end
  end

  local alive: { O2Particle } = {}
  for _, p in ipairs(self.o2Particles) do
    if updateO2(p, cappedDt, self.boundsW, self.boundsH) then
      table.insert(alive, p)
    end
  end
  self.o2Particles = alive

  local rate = getO2SpawnRate(o2Norm)
  self.spawnAccumulator = self.spawnAccumulator + rate * cappedDt
  local toSpawn = math.floor(self.spawnAccumulator)
  self.spawnAccumulator = self.spawnAccumulator - toSpawn
  toSpawn = math.min(toSpawn, MAX_O2 - #self.o2Particles, 15)
  for _ = 1, toSpawn do
    table.insert(self.o2Particles, spawnO2(self, exploding))
  end

  return true
end

local function draw(self: Oxygen, renderer: Renderer)
  local margin = 60
  for _, p in ipairs(self.o2Particles) do
    if p.y > -margin and p.y < self.boundsH + margin
       and p.x > -margin and p.x < self.boundsW + margin then
      if p.artboardInstance then
        renderer:save()
        local scale = p.size / 2
        renderer:transform(Mat2D.withTranslation(p.x, p.y))
        renderer:transform(Mat2D.withScale(scale, scale))
        p.artboardInstance:draw(renderer)
        renderer:restore()
      else
        local path = Path.new()
        addCircle(path, p.size)
        local r = p.color == 0 and 0x4A or 0xE0
        local g = p.color == 0 and 0x90 or 0x70
        local b = p.color == 0 and 0xF0 or 0xA0
        local alpha = clamp(math.floor(p.opacity * 255), 0, 255)
        local color = bit32.bor(
          bit32.lshift(alpha, 24),
          bit32.lshift(r, 16),
          bit32.lshift(g, 8),
          b
        )
        local paint = Paint.with({ style = "fill", color = color })
        renderer:save()
        renderer:transform(Mat2D.withTranslation(p.x, p.y))
        renderer:drawPath(path, paint)
        renderer:restore()
      end
    end
  end
end

return function(): Node<Oxygen>
  return {
    o2 = 50,
    explosionTrigger = onExplosionTrigger,
    o2Molecule = late(),
    o2MoleculePink = late(),
    o2Particles = {},
    spawnAccumulator = 0,
    boundsW = BOUNDS_W,
    boundsH = BOUNDS_H,
    time = 0,
    explosionEndTime = 0,
    hasMoleculeArtboard = false,
    hasPinkMoleculeArtboard = false,
    init = init,
    advance = advance,
    draw = draw,
  }
end
