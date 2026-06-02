-- Gojo Energy Orbs System (Red, Blue, Purple)
-- Interactive draggable orbs that combine on collision

local VIEWPORT_WIDTH = 450
local VIEWPORT_HEIGHT = 600
local ORB_RADIUS = 30
local COLLISION_DISTANCE = 60 -- Distance for orbs to merge
local EXPLOSION_DURATION = 0.5
local PURPLE_ORB_SIZE_MULTIPLIER = 5

-- Orb colors (hardcoded as ARGB: 0xAARRGGBB)
local BLUE_ORB_COLOR = 0xFF00D9FF -- Cyan/Electric Blue
local RED_ORB_COLOR = 0xFFFF3D00 -- Orange-Red
local PURPLE_ORB_COLOR = 0xFFDD00FF -- Magenta/Purple

type Particle = {
  x: number,
  y: number,
  vx: number,
  vy: number,
  angle: number,
  vAngle: number,
  distance: number,
  opacity: number,
  life: number,
  maxLife: number,
}

type LightningBolt = {
  points: { Vector },
  opacity: number,
  life: number,
  maxLife: number,
  thickness: number,
}

type Orb = {
  x: number,
  y: number,
  active: boolean,
  dragging: boolean,
  particles: { Particle },
  rotation: number,
  pulsePhase: number,
}

type EnergyOrbSystem = {
  -- Trigger inputs
  blueOrbTrigger: Input<Trigger>,
  redOrbTrigger: Input<Trigger>,
  purpleOrbExplodeTrigger: Input<Trigger>,

  -- Position inputs
  blueOrbX: Input<number>,
  blueOrbY: Input<number>,
  redOrbX: Input<number>,
  redOrbY: Input<number>,

  -- Outputs
  purpleOrbActive: Output<boolean>,

  -- Internal state
  blueOrb: Orb?,
  redOrb: Orb?,
  purpleOrb: Orb?,
  exploding: boolean,
  explosionTime: number,
  explosionParticles: { Particle },
  lightningBolts: { LightningBolt },
  explosionCenterX: number,
  explosionCenterY: number,
  isMassiveExplosion: boolean,
  whiteOutTime: number,
  whiteOutDuration: number,
  whiteOutDelay: number,
  time: number,
  dragStartX: number,
  dragStartY: number,
  context: Context?,
}

-- Utility functions
local function clamp(value: number, min: number, max: number): number
  return math.max(min, math.min(max, value))
end

local function distance(x1: number, y1: number, x2: number, y2: number): number
  local dx = x2 - x1
  local dy = y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end

local function randomRange(min: number, max: number): number
  return min + math.random() * (max - min)
end

-- Helper function to add a circle to a path
local function addCircleToPath(path: Path, center: Vector, radius: number)
  local c = 0.5519150244935105707435627 -- Bezier approximation constant for circles
  local cx, cy = center.x, center.y

  path:moveTo(Vector.xy(cx + radius, cy))
  path:cubicTo(
    Vector.xy(cx + radius, cy + radius * c),
    Vector.xy(cx + radius * c, cy + radius),
    Vector.xy(cx, cy + radius)
  )
  path:cubicTo(
    Vector.xy(cx - radius * c, cy + radius),
    Vector.xy(cx - radius, cy + radius * c),
    Vector.xy(cx - radius, cy)
  )
  path:cubicTo(
    Vector.xy(cx - radius, cy - radius * c),
    Vector.xy(cx - radius * c, cy - radius),
    Vector.xy(cx, cy - radius)
  )
  path:cubicTo(
    Vector.xy(cx + radius * c, cy - radius),
    Vector.xy(cx + radius, cy - radius * c),
    Vector.xy(cx + radius, cy)
  )
  path:close()
end

-- Create a new orb
local function createOrb(x: number, y: number): Orb
  return {
    x = x,
    y = y,
    active = true,
    dragging = false,
    particles = {},
    rotation = 0,
    pulsePhase = 0,
  }
end

-- Spawn particles for orb effect
local function spawnOrbParticles(orb: Orb, count: number)
  for i = 1, count do
    local angle = randomRange(0, math.pi * 2)
    local dist = randomRange(ORB_RADIUS * 0.5, ORB_RADIUS * 1.2)

    table.insert(orb.particles, {
      x = orb.x + math.cos(angle) * dist,
      y = orb.y + math.sin(angle) * dist,
      vx = math.cos(angle) * randomRange(10, 30),
      vy = math.sin(angle) * randomRange(10, 30),
      angle = angle,
      vAngle = randomRange(-2, 2),
      distance = dist,
      opacity = 1,
      life = 0,
      maxLife = randomRange(0.5, 1.5),
    })
  end
end

-- Create a lightning bolt from origin to a random direction
local function createLightningBolt(
  originX: number,
  originY: number,
  angle: number,
  length: number
): LightningBolt
  local points: { Vector } = {}
  local segments = math.floor(randomRange(5, 10))
  local segmentLength = length / segments

  local currentX = originX
  local currentY = originY
  table.insert(points, Vector.xy(currentX, currentY))

  for i = 1, segments do
    -- Add some randomness to the angle
    local jitter = randomRange(-0.5, 0.5)
    local segAngle = angle + jitter

    currentX = currentX + math.cos(segAngle) * segmentLength
    currentY = currentY + math.sin(segAngle) * segmentLength

    -- Add perpendicular offset for jagged look
    local perpAngle = segAngle + math.pi / 2
    local offset = randomRange(-15, 15)
    currentX = currentX + math.cos(perpAngle) * offset
    currentY = currentY + math.sin(perpAngle) * offset

    table.insert(points, Vector.xy(currentX, currentY))
  end

  return {
    points = points,
    opacity = 1,
    life = 0,
    maxLife = randomRange(0.15, 0.35),
    thickness = randomRange(2, 4),
  }
end

-- Spawn explosion particles
local function createExplosion(self: EnergyOrbSystem, x: number, y: number)
  self.exploding = true
  self.explosionTime = 0
  self.explosionParticles = {}
  self.lightningBolts = {}
  self.explosionCenterX = x
  self.explosionCenterY = y
  self.isMassiveExplosion = false

  -- Create radial explosion particles
  for i = 1, 60 do
    local angle = (i / 60) * math.pi * 2
    local speed = randomRange(100, 300)

    table.insert(self.explosionParticles, {
      x = x,
      y = y,
      vx = math.cos(angle) * speed,
      vy = math.sin(angle) * speed,
      angle = angle,
      vAngle = randomRange(-5, 5),
      distance = 0,
      opacity = 1,
      life = 0,
      maxLife = randomRange(0.3, 0.6),
    })
  end

  -- Create lightning bolts radiating from explosion center
  for i = 1, 12 do
    local angle = (i / 12) * math.pi * 2 + randomRange(-0.2, 0.2)
    local length = randomRange(80, 150)
    table.insert(self.lightningBolts, createLightningBolt(x, y, angle, length))
  end

  -- Create purple orb at collision point
  local purpleOrb = createOrb(x, y)
  self.purpleOrb = purpleOrb
  spawnOrbParticles(purpleOrb, 40)
end

-- Create massive explosion (2x viewport) for purple orb
local function createMassiveExplosion(self: EnergyOrbSystem, x: number, y: number)
  self.exploding = true
  self.explosionTime = 0
  self.explosionParticles = {}
  self.lightningBolts = {}
  self.explosionCenterX = x
  self.explosionCenterY = y
  self.isMassiveExplosion = true
  self.whiteOutTime = 0
  self.whiteOutDuration = 2.0 -- 2 seconds white-out
  self.whiteOutDelay = EXPLOSION_DURATION + 0.05 -- Delay: explosion duration + 50ms

  -- Create many more radial explosion particles (scaled for 2x viewport)
  -- Calculate max viewport dimension for scaling
  local maxViewportDim = math.max(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
  local minSpeed = maxViewportDim * 0.3
  local maxSpeed = maxViewportDim * 0.8
  
  for i = 1, 200 do
    local angle = (i / 200) * math.pi * 2
    local speed = randomRange(minSpeed, maxSpeed) -- Scaled to 2x viewport

    table.insert(self.explosionParticles, {
      x = x,
      y = y,
      vx = math.cos(angle) * speed,
      vy = math.sin(angle) * speed,
      angle = angle,
      vAngle = randomRange(-10, 10),
      distance = 0,
      opacity = 1,
      life = 0,
      maxLife = randomRange(0.5, 1.0), -- Longer lifetime
    })
  end

  -- Create many more lightning bolts with longer lengths (2x viewport scale)
  local minBoltLength = maxViewportDim * 0.4
  local maxBoltLength = maxViewportDim * 0.8
  
  for i = 1, 24 do
    local angle = (i / 24) * math.pi * 2 + randomRange(-0.3, 0.3)
    local length = randomRange(minBoltLength, maxBoltLength) -- 2x viewport scale
    table.insert(self.lightningBolts, createLightningBolt(x, y, angle, length))
  end

  -- Remove purple orb when it explodes
  self.purpleOrb = nil
end

-- Check collision between orbs
local function checkCollision(self: EnergyOrbSystem)
  if
    self.blueOrb
    and self.blueOrb.active
    and self.redOrb
    and self.redOrb.active
  then
    local dist =
      distance(self.blueOrb.x, self.blueOrb.y, self.redOrb.x, self.redOrb.y)

    if dist < COLLISION_DISTANCE then
      -- Calculate collision point (midpoint)
      local collisionX = (self.blueOrb.x + self.redOrb.x) / 2
      local collisionY = (self.blueOrb.y + self.redOrb.y) / 2

      -- Immediately remove orbs and clear their particles
      self.blueOrb = nil
      self.redOrb = nil

      -- Create explosion and purple orb
      createExplosion(self, collisionX, collisionY)
    end
  end
end

-- Update orb particles
local function updateOrbParticles(orb: Orb, dt: number)
  local aliveParticles = {}

  for _, p in ipairs(orb.particles) do
    p.life = p.life + dt

    if p.life < p.maxLife then
      -- Rotate around orb
      p.angle = p.angle + p.vAngle * dt

      -- Spiral outward slightly
      p.distance = p.distance + dt * 10

      -- Update position
      p.x = orb.x + math.cos(p.angle) * p.distance
      p.y = orb.y + math.sin(p.angle) * p.distance

      -- Fade out
      p.opacity = 1 - (p.life / p.maxLife)

      table.insert(aliveParticles, p)
    end
  end

  orb.particles = aliveParticles

  -- Spawn new particles continuously
  if #orb.particles < 30 then
    spawnOrbParticles(orb, 2)
  end
end

-- Draw an orb with glow and particles
local function drawOrb(
  renderer: Renderer,
  orb: Orb,
  color: number,
  time: number,
  isPurple: boolean
)
  local radius = isPurple and ORB_RADIUS * PURPLE_ORB_SIZE_MULTIPLIER
    or ORB_RADIUS

  -- Extract RGB from ARGB color (0xAARRGGBB)
  local r = bit32.band(bit32.rshift(color, 16), 0xFF)
  local g = bit32.band(bit32.rshift(color, 8), 0xFF)
  local b = bit32.band(color, 0xFF)

  -- Draw outer glow (multiple layers)
  for i = 3, 1, -1 do
    local glowRadius = radius * (1 + i * 0.3)
    local glowAlpha = math.floor(30 / i)
    local glowColor = bit32.bor(
      bit32.lshift(glowAlpha, 24),
      bit32.lshift(r, 16),
      bit32.lshift(g, 8),
      b
    )

    local glowPath = Path.new()
    addCircleToPath(glowPath, Vector.xy(orb.x, orb.y), glowRadius)

    local glowPaint = Paint.with({
      style = 'fill',
      color = glowColor,
    })
    renderer:drawPath(glowPath, glowPaint)
  end

  -- Draw rotating rings (3 rings)
  for ringIndex = 1, 3 do
    local ringRadius = radius * (0.6 + ringIndex * 0.15)
    local ringRotation = orb.rotation + (ringIndex * math.pi / 3)

    for i = 1, 8 do
      local angle = (i / 8) * math.pi * 2 + ringRotation
      local x1 = orb.x + math.cos(angle) * ringRadius
      local y1 = orb.y + math.sin(angle) * ringRadius
      local x2 = orb.x + math.cos(angle + 0.2) * ringRadius
      local y2 = orb.y + math.sin(angle + 0.2) * ringRadius

      local ringPath = Path.new()
      ringPath:moveTo(Vector.xy(x1, y1))
      ringPath:lineTo(Vector.xy(x2, y2))

      local ringAlpha = 200
      local ringColor = bit32.bor(
        bit32.lshift(ringAlpha, 24),
        bit32.lshift(r, 16),
        bit32.lshift(g, 8),
        b
      )

      local ringPaint = Paint.with({
        style = 'stroke',
        thickness = 2,
        color = ringColor,
        cap = 'round',
      })
      renderer:drawPath(ringPath, ringPaint)
    end
  end

  -- Draw particles (energy wisps)
  for _, p in ipairs(orb.particles) do
    if p.opacity > 0.01 then
      local particlePath = Path.new()

      -- Draw as line/streak
      local angle = math.atan2(p.vy, p.vx)
      local length = 8
      local x2 = p.x - math.cos(angle) * length
      local y2 = p.y - math.sin(angle) * length

      particlePath:moveTo(Vector.xy(x2, y2))
      particlePath:lineTo(Vector.xy(p.x, p.y))

      local alpha = math.floor(p.opacity * 180)
      local particleColor = bit32.bor(
        bit32.lshift(alpha, 24),
        bit32.lshift(r, 16),
        bit32.lshift(g, 8),
        b
      )

      local particlePaint = Paint.with({
        style = 'stroke',
        thickness = 1.5,
        color = particleColor,
        cap = 'round',
      })
      renderer:drawPath(particlePath, particlePaint)
    end
  end

  -- Draw core with pulsing effect
  local pulse = 1 + math.sin(orb.pulsePhase) * 0.2
  local coreRadius = radius * 0.3 * pulse

  -- Bright white core
  local corePath = Path.new()
  addCircleToPath(corePath, Vector.xy(orb.x, orb.y), coreRadius)

  local corePaint = Paint.with({
    style = 'fill',
    color = 0xFFFFFFFF, -- White
  })
  renderer:drawPath(corePath, corePaint)

  -- Colored middle layer
  local midPath = Path.new()
  addCircleToPath(midPath, Vector.xy(orb.x, orb.y), coreRadius * 1.5)

  local midColor = bit32.bor(
    bit32.lshift(0xFF, 24),
    bit32.lshift(r, 16),
    bit32.lshift(g, 8),
    b
  )

  local midPaint = Paint.with({
    style = 'fill',
    color = midColor,
  })
  renderer:drawPath(midPath, midPaint)

  -- Purple orb gets energy spikes
  if isPurple then
    for i = 1, 12 do
      local spikeAngle = (i / 12) * math.pi * 2 + time * 3
      local spikeLength = radius * (1.2 + math.sin(time * 5 + i) * 0.3)

      local x1 = orb.x + math.cos(spikeAngle) * radius * 0.8
      local y1 = orb.y + math.sin(spikeAngle) * radius * 0.8
      local x2 = orb.x + math.cos(spikeAngle) * spikeLength
      local y2 = orb.y + math.sin(spikeAngle) * spikeLength

      local spikePath = Path.new()
      spikePath:moveTo(Vector.xy(x1, y1))
      spikePath:lineTo(Vector.xy(x2, y2))

      local spikePaint = Paint.with({
        style = 'stroke',
        thickness = 2,
        color = midColor,
        cap = 'round',
      })
      renderer:drawPath(spikePath, spikePaint)
    end
  end
end

-- Draw explosion effect
local function drawExplosion(self: EnergyOrbSystem, renderer: Renderer)
  local r = bit32.band(bit32.rshift(PURPLE_ORB_COLOR, 16), 0xFF)
  local g = bit32.band(bit32.rshift(PURPLE_ORB_COLOR, 8), 0xFF)
  local b = bit32.band(PURPLE_ORB_COLOR, 0xFF)

  -- Draw lightning bolts first (behind particles)
  for _, bolt in ipairs(self.lightningBolts) do
    if bolt.opacity > 0.01 and #bolt.points >= 2 then
      -- Draw glow layer (thicker, more transparent)
      local glowPath = Path.new()
      glowPath:moveTo(bolt.points[1])
      for i = 2, #bolt.points do
        glowPath:lineTo(bolt.points[i])
      end

      local glowAlpha = math.floor(bolt.opacity * 100)
      local glowColor = bit32.bor(
        bit32.lshift(glowAlpha, 24),
        bit32.lshift(r, 16),
        bit32.lshift(g, 8),
        b
      )

      local glowPaint = Paint.with({
        style = 'stroke',
        thickness = bolt.thickness * 3,
        color = glowColor,
        cap = 'round',
        join = 'round',
      })
      renderer:drawPath(glowPath, glowPaint)

      -- Draw core layer (bright white/purple)
      local corePath = Path.new()
      corePath:moveTo(bolt.points[1])
      for i = 2, #bolt.points do
        corePath:lineTo(bolt.points[i])
      end

      local coreAlpha = math.floor(bolt.opacity * 255)
      -- Mix white with purple for bright lightning
      local coreColor = bit32.bor(
        bit32.lshift(coreAlpha, 24),
        bit32.lshift(math.min(255, r + 100), 16),
        bit32.lshift(math.min(255, g + 100), 8),
        math.min(255, b + 100)
      )

      local corePaint = Paint.with({
        style = 'stroke',
        thickness = bolt.thickness,
        color = coreColor,
        cap = 'round',
        join = 'round',
      })
      renderer:drawPath(corePath, corePaint)
    end
  end

  -- Draw explosion particles
  for _, p in ipairs(self.explosionParticles) do
    if p.opacity > 0.01 then
      local path = Path.new()

      local angle = math.atan2(p.vy, p.vx)
      local length = 15
      local x2 = p.x - math.cos(angle) * length
      local y2 = p.y - math.sin(angle) * length

      path:moveTo(Vector.xy(x2, y2))
      path:lineTo(Vector.xy(p.x, p.y))

      local alpha = math.floor(p.opacity * 255)
      local color = bit32.bor(
        bit32.lshift(alpha, 24),
        bit32.lshift(r, 16),
        bit32.lshift(g, 8),
        b
      )

      local paint = Paint.with({
        style = 'stroke',
        thickness = 2,
        color = color,
        cap = 'round',
      })
      renderer:drawPath(path, paint)
    end
  end

  -- Draw bright flash at center during early explosion
  if self.explosionTime < 0.15 then
    local flashOpacity = 1 - (self.explosionTime / 0.15)
    local flashRadius
    if self.isMassiveExplosion then
      -- 2x viewport scale: much larger flash
      local maxViewportDim = math.max(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
      local baseFlashRadius = maxViewportDim * 0.8
      local flashGrowth = maxViewportDim * 1.2
      flashRadius = baseFlashRadius + self.explosionTime * flashGrowth
    else
      flashRadius = 50 + self.explosionTime * 200
    end

    local flashPath = Path.new()
    addCircleToPath(
      flashPath,
      Vector.xy(self.explosionCenterX, self.explosionCenterY),
      flashRadius
    )

    local flashAlpha = math.floor(flashOpacity * 150)
    local flashColor = bit32.bor(
      bit32.lshift(flashAlpha, 24),
      0xFFFFFF -- White flash
    )

    local flashPaint = Paint.with({
      style = 'fill',
      color = flashColor,
    })
    renderer:drawPath(flashPath, flashPaint)
  end
end

-- Initialize
local function init(self: EnergyOrbSystem, context: Context): boolean
  self.context = context
  self.time = 0
  self.blueOrb = nil
  self.redOrb = nil
  self.purpleOrb = nil
  self.exploding = false
  self.explosionTime = 0
  self.explosionParticles = {}
  self.lightningBolts = {}
  self.explosionCenterX = 0
  self.explosionCenterY = 0
  self.isMassiveExplosion = false
  self.whiteOutTime = 0
  self.whiteOutDuration = 0
  self.whiteOutDelay = 0
  self.dragStartX = 0
  self.dragStartY = 0
  return true
end

-- Advance simulation
local function advance(self: EnergyOrbSystem, dt: number): boolean
  local cappedDt = math.min(dt, 0.05)
  self.time = self.time + cappedDt

  -- Update blue orb
  if self.blueOrb and self.blueOrb.active then
    self.blueOrb.rotation = self.blueOrb.rotation + cappedDt * 2
    self.blueOrb.pulsePhase = self.blueOrb.pulsePhase + cappedDt * 5
    updateOrbParticles(self.blueOrb, cappedDt)
  end

  -- Update red orb
  if self.redOrb and self.redOrb.active then
    self.redOrb.rotation = self.redOrb.rotation - cappedDt * 2.2
    self.redOrb.pulsePhase = self.redOrb.pulsePhase + cappedDt * 5
    updateOrbParticles(self.redOrb, cappedDt)
  end

  -- Update purple orb
  if self.purpleOrb and self.purpleOrb.active then
    self.purpleOrb.rotation = self.purpleOrb.rotation + cappedDt * 3
    self.purpleOrb.pulsePhase = self.purpleOrb.pulsePhase + cappedDt * 7
    updateOrbParticles(self.purpleOrb, cappedDt)
  end

  -- Update explosion
  if self.exploding then
    self.explosionTime = self.explosionTime + cappedDt

    -- Update particles
    local aliveParticles: { Particle } = {}
    for _, p in ipairs(self.explosionParticles) do
      p.life = p.life + cappedDt

      if p.life < p.maxLife then
        p.x = p.x + p.vx * cappedDt
        p.y = p.y + p.vy * cappedDt
        p.opacity = 1 - (p.life / p.maxLife)
        table.insert(aliveParticles, p)
      end
    end
    self.explosionParticles = aliveParticles

    -- Update lightning bolts
    local aliveBolts: { LightningBolt } = {}
    for _, bolt in ipairs(self.lightningBolts) do
      bolt.life = bolt.life + cappedDt

      if bolt.life < bolt.maxLife then
        bolt.opacity = 1 - (bolt.life / bolt.maxLife)
        table.insert(aliveBolts, bolt)
      end
    end
    self.lightningBolts = aliveBolts

    -- Spawn new lightning bolts during explosion
    if self.explosionTime < 0.3 and self.purpleOrb and math.random() < 0.3 then
      local angle = randomRange(0, math.pi * 2)
      local length = randomRange(60, 120)
      table.insert(
        self.lightningBolts,
        createLightningBolt(self.purpleOrb.x, self.purpleOrb.y, angle, length)
      )
    end

    if self.explosionTime > EXPLOSION_DURATION then
      self.exploding = false
    end
  end

  -- Update white-out effect with delay
  if self.whiteOutDelay > 0 then
    self.whiteOutDelay = self.whiteOutDelay - cappedDt
    if self.whiteOutDelay <= 0 then
      -- Delay complete, start white-out
      self.whiteOutTime = 0
      self.whiteOutDelay = 0
    end
  elseif self.whiteOutDuration > 0 then
    -- White-out is active
    self.whiteOutTime = self.whiteOutTime + cappedDt
    if self.whiteOutTime >= self.whiteOutDuration then
      self.whiteOutTime = 0
      self.whiteOutDuration = 0
    end
  end

  -- Check collision
  checkCollision(self)

  -- Update output
  self.purpleOrbActive = self.purpleOrb ~= nil and self.purpleOrb.active

  return true
end

-- Pointer down handler
local function pointerDown(self: EnergyOrbSystem, event: PointerEvent)
  local x = event.position.x
  local y = event.position.y
  local hitOrb = false

  -- Check blue orb
  if self.blueOrb and self.blueOrb.active then
    local dist = distance(x, y, self.blueOrb.x, self.blueOrb.y)
    if dist < ORB_RADIUS * 1.5 then
      self.blueOrb.dragging = true
      self.dragStartX = x
      self.dragStartY = y
      hitOrb = true
    end
  end

  -- Check red orb
  if self.redOrb and self.redOrb.active then
    local dist = distance(x, y, self.redOrb.x, self.redOrb.y)
    if dist < ORB_RADIUS * 1.5 then
      self.redOrb.dragging = true
      self.dragStartX = x
      self.dragStartY = y
      hitOrb = true
    end
  end

  -- Check purple orb
  if self.purpleOrb and self.purpleOrb.active then
    local dist = distance(x, y, self.purpleOrb.x, self.purpleOrb.y)
    if dist < ORB_RADIUS * PURPLE_ORB_SIZE_MULTIPLIER * 1.5 then
      self.purpleOrb.dragging = true
      self.dragStartX = x
      self.dragStartY = y
      hitOrb = true
    end
  end

  -- Mark event as hit if we're dragging an orb
  if hitOrb then
    event:hit()
  end
end

-- Pointer move handler
local function pointerMove(self: EnergyOrbSystem, event: PointerEvent)
  local x = event.position.x
  local y = event.position.y
  local isDragging = false

  if self.blueOrb and self.blueOrb.dragging then
    self.blueOrb.x = clamp(x, ORB_RADIUS, VIEWPORT_WIDTH - ORB_RADIUS)
    self.blueOrb.y = clamp(y, ORB_RADIUS, VIEWPORT_HEIGHT - ORB_RADIUS)
    isDragging = true
  end

  if self.redOrb and self.redOrb.dragging then
    self.redOrb.x = clamp(x, ORB_RADIUS, VIEWPORT_WIDTH - ORB_RADIUS)
    self.redOrb.y = clamp(y, ORB_RADIUS, VIEWPORT_HEIGHT - ORB_RADIUS)
    isDragging = true
  end

  if self.purpleOrb and self.purpleOrb.dragging then
    self.purpleOrb.x = clamp(x, ORB_RADIUS, VIEWPORT_WIDTH - ORB_RADIUS)
    self.purpleOrb.y = clamp(y, ORB_RADIUS, VIEWPORT_HEIGHT - ORB_RADIUS)
    isDragging = true
  end

  if isDragging then
    event:hit()
  end
end

-- Pointer up handler
local function pointerUp(self: EnergyOrbSystem, event: PointerEvent)
  if self.blueOrb then
    self.blueOrb.dragging = false
  end
  if self.redOrb then
    self.redOrb.dragging = false
  end
  if self.purpleOrb then
    self.purpleOrb.dragging = false
  end
end

-- Draw
local function draw(self: EnergyOrbSystem, renderer: Renderer)
  -- Draw explosion first (behind orbs)
  if self.exploding then
    drawExplosion(self, renderer)
  end

  -- Draw blue orb
  if self.blueOrb and self.blueOrb.active then
    drawOrb(renderer, self.blueOrb, BLUE_ORB_COLOR, self.time, false)
  end

  -- Draw red orb
  if self.redOrb and self.redOrb.active then
    drawOrb(renderer, self.redOrb, RED_ORB_COLOR, self.time, false)
  end

  -- Draw purple orb
  if self.purpleOrb and self.purpleOrb.active then
    drawOrb(renderer, self.purpleOrb, PURPLE_ORB_COLOR, self.time, true)
  end

  -- Draw white-out effect (full viewport white overlay)
  -- Only draw if delay has passed and white-out is active
  if self.whiteOutDelay <= 0 and self.whiteOutDuration > 0 and self.whiteOutTime > 0 then
    local progress = self.whiteOutTime / self.whiteOutDuration
    
    -- Fade in quickly (first 0.1s), hold, then fade out (last 0.3s)
    local opacity = 1.0
    if progress < 0.05 then
      -- Fade in
      opacity = progress / 0.05
    elseif progress > 0.85 then
      -- Fade out
      opacity = 1.0 - ((progress - 0.85) / 0.15)
    end
    
    local whitePath = Path.new()
    whitePath:moveTo(Vector.xy(0, 0))
    whitePath:lineTo(Vector.xy(VIEWPORT_WIDTH, 0))
    whitePath:lineTo(Vector.xy(VIEWPORT_WIDTH, VIEWPORT_HEIGHT))
    whitePath:lineTo(Vector.xy(0, VIEWPORT_HEIGHT))
    whitePath:close()
    
    local alpha = math.floor(opacity * 255)
    local whiteColor = bit32.bor(
      bit32.lshift(alpha, 24),
      0xFFFFFF -- White
    )
    
    local whitePaint = Paint.with({
      style = 'fill',
      color = whiteColor,
    })
    renderer:drawPath(whitePath, whitePaint)
  end
end

-- Trigger handler for blue orb
local function onBlueOrbTrigger(self: EnergyOrbSystem)
  if not self.blueOrb or not self.blueOrb.active then
    local blueOrb = createOrb(self.blueOrbX, self.blueOrbY)
    self.blueOrb = blueOrb
    spawnOrbParticles(blueOrb, 30)
  end
end

-- Trigger handler for red orb
local function onRedOrbTrigger(self: EnergyOrbSystem)
  if not self.redOrb or not self.redOrb.active then
    local redOrb = createOrb(self.redOrbX, self.redOrbY)
    self.redOrb = redOrb
    spawnOrbParticles(redOrb, 30)
  end
end

-- Trigger handler for purple orb explosion
local function onPurpleOrbExplodeTrigger(self: EnergyOrbSystem)
  if self.purpleOrb and self.purpleOrb.active then
    createMassiveExplosion(self, self.purpleOrb.x, self.purpleOrb.y)
  end
end

-- Export Node factory
return function(): Node<EnergyOrbSystem>
  return {
    -- Trigger inputs (assigned handler functions)
    blueOrbTrigger = onBlueOrbTrigger,
    redOrbTrigger = onRedOrbTrigger,
    purpleOrbExplodeTrigger = onPurpleOrbExplodeTrigger,

    -- Position inputs
    blueOrbX = 150,
    blueOrbY = VIEWPORT_HEIGHT / 2,
    redOrbX = 300,
    redOrbY = VIEWPORT_HEIGHT / 2,

    -- Output
    purpleOrbActive = false,

    -- Internal state
    blueOrb = nil,
    redOrb = nil,
    purpleOrb = nil,
    exploding = false,
    explosionTime = 0,
    explosionParticles = {},
    lightningBolts = {},
    explosionCenterX = 0,
    explosionCenterY = 0,
    isMassiveExplosion = false,
    whiteOutTime = 0,
    whiteOutDuration = 0,
    whiteOutDelay = 0,
    time = 0,
    dragStartX = 0,
    dragStartY = 0,
    context = nil,

    -- Callbacks
    init = init,
    advance = advance,
    draw = draw,
    pointerDown = pointerDown,
    pointerMove = pointerMove,
    pointerUp = pointerUp,
  }
end