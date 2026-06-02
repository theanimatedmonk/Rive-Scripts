-- Lightning Particle System
-- A scalable lightning effect with configurable intensity, frequency, and flash duration

local MAX_LIGHTNING_BOLTS = 50
local VIEWPORT_WIDTH = 600
local VIEWPORT_HEIGHT = 300
local MIN_FLASH_DURATION = 0.05 -- Minimum flash duration in seconds
local MAX_FLASH_DURATION = 0.3 -- Maximum flash duration in seconds

-- Lightning color palette (bright whites/blues)
local COLORS = {
  0xFFFFFFFF, -- Pure white
  0xFFE6F2FF, -- Light blue-white
  0xFFCCE5FF, -- Medium blue-white
  0xFFB3D9FF, -- Bright blue
  0xFF99CCFF, -- Electric blue
}

type LightningBranch = {
  points: { Vector },
  thickness: number,
  opacity: number,
}

type LightningBolt = {
  startX: number,
  startY: number,
  endX: number,
  endY: number,
  branches: { LightningBranch },
  mainBranch: LightningBranch,
  age: number,
  maxAge: number,
  opacity: number,
  color: number,
  flashIntensity: number,
}

type LightningSystem = {
  lightningIntensity: Input<number>,
  lightningFrequency: Input<number>, -- Strikes per second
  lightningFlashDuration: Input<number>, -- Base flash duration multiplier
  lightningParticle: Input<Artboard<nil>>,
  bolts: { LightningBolt },
  spawnAccumulator: number,
  nextSpawnTime: number,
  context: Context?,
  hasParticleArtboard: boolean,
  time: number,
}

-- Utility: Clamp value between min and max
local function clamp(value: number, min: number, max: number): number
  if value < min then
    return min
  end
  if value > max then
    return max
  end
  return value
end

-- Utility: Linear interpolation
local function lerp(a: number, b: number, t: number): number
  return a + (b - a) * t
end

-- Utility: Simple pseudo-random using math.random
local function randomRange(min: number, max: number): number
  return min + math.random() * (max - min)
end

-- Generate jagged lightning path from start to end
local function generateLightningPath(
  startX: number,
  startY: number,
  endX: number,
  endY: number,
  segments: number,
  jitterAmount: number
): { Vector }
  local points: { Vector } = {}
  local dx = endX - startX
  local dy = endY - startY
  
  table.insert(points, Vector.xy(startX, startY))
  
  for i = 1, segments - 1 do
    local t = i / segments
    local baseX = startX + dx * t
    local baseY = startY + dy * t
    
    -- Add perpendicular jitter for jagged effect
    local perpX = -dy / math.sqrt(dx * dx + dy * dy)
    local perpY = dx / math.sqrt(dx * dx + dy * dy)
    
    local jitter = randomRange(-jitterAmount, jitterAmount)
    local jitterX = baseX + perpX * jitter
    local jitterY = baseY + perpY * jitter
    
    -- Add some forward/backward jitter too
    local forwardJitter = randomRange(-jitterAmount * 0.3, jitterAmount * 0.3)
    jitterX = jitterX + (dx / segments) * forwardJitter
    jitterY = jitterY + (dy / segments) * forwardJitter
    
    table.insert(points, Vector.xy(jitterX, jitterY))
  end
  
  table.insert(points, Vector.xy(endX, endY))
  return points
end

-- Generate side branches for main lightning bolt
local function generateBranches(
  mainPoints: { Vector },
  branchCount: number,
  branchLength: number
): { LightningBranch }
  local branches: { LightningBranch } = {}
  
  for i = 1, branchCount do
    if #mainPoints < 2 then
      break
    end
    
    -- Pick a random point along the main path (not first or last)
    local branchStartIdx = math.floor(randomRange(2, #mainPoints - 1))
    local branchStart = mainPoints[branchStartIdx]
    
    -- Calculate direction from previous point
    local prevPoint = mainPoints[branchStartIdx - 1]
    local dirX = branchStart.x - prevPoint.x
    local dirY = branchStart.y - prevPoint.y
    local length = math.sqrt(dirX * dirX + dirY * dirY)
    
    if length > 0.01 then
      dirX = dirX / length
      dirY = dirY / length
      
      -- Perpendicular direction for branching
      local perpX = -dirY
      local perpY = dirX
      
      -- Random angle for branch
      local angle = randomRange(-math.pi / 3, math.pi / 3)
      local cosAngle = math.cos(angle)
      local sinAngle = math.sin(angle)
      
      local branchDirX = dirX * cosAngle - dirY * sinAngle
      local branchDirY = dirX * sinAngle + dirY * cosAngle
      
      -- Branch end point
      local branchLengthActual = randomRange(branchLength * 0.5, branchLength)
      local branchEndX = branchStart.x + branchDirX * branchLengthActual
      local branchEndY = branchStart.y + branchDirY * branchLengthActual
      
      -- Generate branch path
      local branchSegments = math.floor(randomRange(3, 6))
      local branchPoints = generateLightningPath(
        branchStart.x,
        branchStart.y,
        branchEndX,
        branchEndY,
        branchSegments,
        branchLengthActual * 0.2
      )
      
      table.insert(branches, {
        points = branchPoints,
        thickness = randomRange(1, 2.5),
        opacity = randomRange(0.6, 1.0),
      })
    end
  end
  
  return branches
end

-- Calculate spawn rate based on frequency (strikes per second)
local function getSpawnRate(frequency: number): number
  local normalized = clamp(frequency, 0.1, 10)
  return normalized -- Direct conversion: frequency = strikes per second
end

-- Spawn a new lightning bolt
local function spawnLightningBolt(self: LightningSystem): LightningBolt
  local intensity = clamp(self.lightningIntensity, 1, 10)
  local flashDuration = clamp(self.lightningFlashDuration, 0.5, 3)
  
  -- Random start position at top of viewport
  local startX = randomRange(0, VIEWPORT_WIDTH)
  local startY = randomRange(0, VIEWPORT_HEIGHT * 0.2) -- Top 20% of viewport
  
  -- Random end position (can be anywhere, but usually lower)
  local endX = randomRange(
    startX - VIEWPORT_WIDTH * 0.3,
    startX + VIEWPORT_WIDTH * 0.3
  )
  endX = clamp(endX, 0, VIEWPORT_WIDTH)
  
  local endY = randomRange(
    VIEWPORT_HEIGHT * 0.4,
    VIEWPORT_HEIGHT * 0.9
  )
  
  -- Number of segments based on bolt length
  local boltLength = math.sqrt(
    (endX - startX) * (endX - startX) + (endY - startY) * (endY - startY)
  )
  local segments = math.floor(boltLength / 15) + math.floor(randomRange(5, 12))
  segments = clamp(segments, 5, 20)
  
  -- Jitter amount scales with intensity
  local jitterAmount = 8 + (intensity / 10) * 12
  
  -- Generate main lightning path
  local mainPoints = generateLightningPath(
    startX,
    startY,
    endX,
    endY,
    segments,
    jitterAmount
  )
  
  -- Generate branches (more branches with higher intensity)
  local branchCount = math.floor(intensity / 2) + math.floor(randomRange(0, 2))
  branchCount = clamp(branchCount, 0, 5)
  local branchLength = boltLength * randomRange(0.15, 0.35)
  local branches = generateBranches(mainPoints, branchCount, branchLength)
  
  -- Flash duration based on intensity and multiplier
  local baseDuration = MIN_FLASH_DURATION + (MAX_FLASH_DURATION - MIN_FLASH_DURATION) * (1 - intensity / 10)
  local maxAge = baseDuration * flashDuration
  
  -- Select color from palette
  local colorIndex = math.floor(randomRange(1, #COLORS + 0.99))
  local color = COLORS[colorIndex]
  
  -- Flash intensity (brighter with higher intensity)
  local flashIntensity = 0.8 + (intensity / 10) * 0.2
  
  return {
    startX = startX,
    startY = startY,
    endX = endX,
    endY = endY,
    branches = branches,
    mainBranch = {
      points = mainPoints,
      thickness = 2 + (intensity / 10) * 3,
      opacity = 1.0,
    },
    age = 0,
    maxAge = maxAge,
    opacity = 1.0,
    color = color,
    flashIntensity = flashIntensity,
  }
end

-- Update a single lightning bolt
local function updateLightningBolt(
  bolt: LightningBolt,
  dt: number
): boolean
  bolt.age = bolt.age + dt
  
  -- Check expiration
  if bolt.age > bolt.maxAge then
    return false
  end
  
  -- Fade out quickly (most of the fade happens in the last 30% of lifetime)
  local fadeStart = bolt.maxAge * 0.7
  if bolt.age > fadeStart then
    local fadeProgress = (bolt.age - fadeStart) / (bolt.maxAge - fadeStart)
    bolt.opacity = lerp(1.0, 0.0, fadeProgress)
  else
    -- Flicker effect during main flash
    local flicker = 0.9 + math.sin(bolt.age * 50) * 0.1
    bolt.opacity = flicker
  end
  
  return true
end

-- Safely check if artboard is valid
local function isArtboardValid(artboard: Artboard<nil>): boolean
  local success = pcall(function()
    local _ = artboard.width
  end)
  return success
end

-- Initialize the lightning system
local function init(self: LightningSystem, context: Context): boolean
  self.context = context
  self.bolts = {}
  self.spawnAccumulator = 0
  self.nextSpawnTime = 0
  self.time = 0
  self.hasParticleArtboard = isArtboardValid(self.lightningParticle)
  return true
end

-- Advance the simulation
local function advance(self: LightningSystem, dt: number): boolean
  local frequency = clamp(self.lightningFrequency, 0.1, 10)
  
  -- Cap dt to prevent spiral of death
  local cappedDt = math.min(dt, 0.05)
  self.time = self.time + cappedDt
  
  -- Update existing bolts
  local aliveBolts: { LightningBolt } = {}
  for _, bolt in ipairs(self.bolts) do
    if updateLightningBolt(bolt, cappedDt) then
      table.insert(aliveBolts, bolt)
    end
  end
  self.bolts = aliveBolts
  
  -- Spawn new lightning bolts based on frequency
  local spawnRate = getSpawnRate(frequency)
  self.spawnAccumulator = self.spawnAccumulator + spawnRate * cappedDt
  
  -- Use time-based spawning for more natural distribution
  self.nextSpawnTime = self.nextSpawnTime - cappedDt
  
  if self.nextSpawnTime <= 0 then
    -- Calculate next spawn time (exponential distribution for natural randomness)
    local avgTimeBetweenStrikes = 1.0 / spawnRate
    self.nextSpawnTime = -math.log(math.random()) * avgTimeBetweenStrikes
    
    -- Spawn a bolt
    if #self.bolts < MAX_LIGHTNING_BOLTS then
      table.insert(self.bolts, spawnLightningBolt(self))
    end
  end
  
  -- Always return true to keep system running
  return true
end

-- Draw the lightning
local function draw(self: LightningSystem, renderer: Renderer)
  for _, bolt in ipairs(self.bolts) do
    if bolt.opacity > 0.01 then
      -- Extract RGB from color
      local baseColor = bolt.color
      local r = bit32.band(bit32.rshift(baseColor, 16), 0xFF)
      local g = bit32.band(bit32.rshift(baseColor, 8), 0xFF)
      local b = bit32.band(baseColor, 0xFF)
      
      -- Apply opacity and flash intensity
      local alpha = math.floor(bolt.opacity * bolt.flashIntensity * 255)
      alpha = clamp(alpha, 0, 255)
      
      -- Draw main branch with glow effect
      if #bolt.mainBranch.points >= 2 then
        -- Draw glow layer (thicker, more transparent)
        local glowPath = Path.new()
        glowPath:moveTo(bolt.mainBranch.points[1])
        for i = 2, #bolt.mainBranch.points do
          glowPath:lineTo(bolt.mainBranch.points[i])
        end
        
        local glowAlpha = math.floor(alpha * 0.4)
        local glowColor = bit32.bor(
          bit32.lshift(glowAlpha, 24),
          bit32.lshift(r, 16),
          bit32.lshift(g, 8),
          b
        )
        
        local glowPaint = Paint.with({
          style = 'stroke',
          thickness = bolt.mainBranch.thickness * 3,
          color = glowColor,
          cap = 'round',
          join = 'round',
        })
        renderer:drawPath(glowPath, glowPaint)
        
        -- Draw core branch (bright)
        local corePath = Path.new()
        corePath:moveTo(bolt.mainBranch.points[1])
        for i = 2, #bolt.mainBranch.points do
          corePath:lineTo(bolt.mainBranch.points[i])
        end
        
        -- Brighten the core (mix with white)
        local coreR = math.min(255, r + 100)
        local coreG = math.min(255, g + 100)
        local coreB = math.min(255, b + 100)
        
        local coreColor = bit32.bor(
          bit32.lshift(alpha, 24),
          bit32.lshift(coreR, 16),
          bit32.lshift(coreG, 8),
          coreB
        )
        
        local corePaint = Paint.with({
          style = 'stroke',
          thickness = bolt.mainBranch.thickness,
          color = coreColor,
          cap = 'round',
          join = 'round',
        })
        renderer:drawPath(corePath, corePaint)
      end
      
      -- Draw side branches
      for _, branch in ipairs(bolt.branches) do
        if #branch.points >= 2 then
          local branchPath = Path.new()
          branchPath:moveTo(branch.points[1])
          for i = 2, #branch.points do
            branchPath:lineTo(branch.points[i])
          end
          
          local branchAlpha = math.floor(alpha * branch.opacity)
          local branchColor = bit32.bor(
            bit32.lshift(branchAlpha, 24),
            bit32.lshift(r, 16),
            bit32.lshift(g, 8),
            b
          )
          
          local branchPaint = Paint.with({
            style = 'stroke',
            thickness = branch.thickness,
            color = branchColor,
            cap = 'round',
            join = 'round',
          })
          renderer:drawPath(branchPath, branchPaint)
        end
      end
    end
  end
end

-- Export the Node factory
return function(): Node<LightningSystem>
  return {
    -- Inputs with sensible defaults
    lightningIntensity = 5, -- 1-10: 1-2 light, 3-5 medium, 6-10 intense
    lightningFrequency = 1, -- Strikes per second: 0.1-10
    lightningFlashDuration = 1, -- Flash duration multiplier: 0.5-3
    lightningParticle = late(), -- Artboard to use as lightning particle (assign in editor)
    
    -- Internal state
    bolts = {},
    spawnAccumulator = 0,
    nextSpawnTime = 0,
    context = nil,
    hasParticleArtboard = false,
    time = 0,
    
    -- Callbacks
    init = init,
    advance = advance,
    draw = draw,
  }
end
