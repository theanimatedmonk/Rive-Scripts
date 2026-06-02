--[[
  Endless Runner Game Script

  Inputs: CharacterArtboard, Obstacle1/2/3Artboard, PauseToggle, JumpTrigger, StartGameTrigger
]]

local WORLD_W: number = 1000
local WORLD_H: number = 500
local GROUND_Y: number = 400
local CHARACTER_X: number = 200
local OBSTACLE_SPEED: number = 280
local SPAWN_INTERVAL: number = 2.2
local JUMP_VELOCITY: number = -560
local GRAVITY: number = 1200
local OBSTACLE_SPAWN_X: number = 1050
local COLLISION_PADDING: number = 8

type Obstacle = {
  x: number,
  y: number,
  width: number,
  height: number,
  instance: Artboard?,
}

type GameState = "Idle" | "Running" | "Paused" | "GameOver"

export type DinoGame = {
  -- Trigger inputs
  StartGameTrigger: Input<Trigger>,
  JumpTrigger: Input<Trigger>,

  -- Boolean input
  PauseToggle: Input<boolean>,

  -- Artboard inputs
  CharacterArtboard: Input<Artboard>,
  Obstacle1Artboard: Input<Artboard>,
  Obstacle2Artboard: Input<Artboard>,
  Obstacle3Artboard: Input<Artboard>,

  -- Internal state
  gameState: GameState,
  characterY: number,
  characterVy: number,
  characterInstance: Artboard?,
  characterWidth: number,
  characterHeight: number,
  currentObstacle: Obstacle?,
  spawnTimer: number,
}

-- Safely get artboard dimensions
local function getArtboardSize(artboard: Artboard): (number, number)
  local w: number = artboard.width
  local h: number = artboard.height
  if w <= 0 then
    w = 60
  end
  if h <= 0 then
    h = 60
  end
  return w, h
end

-- AABB overlap
local function boxesOverlap(
  ax: number, ay: number, aw: number, ah: number,
  bx: number, by: number, bw: number, bh: number
): boolean
  return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- Create a character instance from the artboard input
local function createCharacterInstance(self: DinoGame)
  local ok, inst = pcall(function()
    return self.CharacterArtboard:instance()
  end)
  if ok and inst then
    self.characterInstance = inst
    local w: number, h: number = getArtboardSize(self.CharacterArtboard)
    self.characterWidth = w
    self.characterHeight = h
  else
    self.characterInstance = nil
    self.characterWidth = 50
    self.characterHeight = 60
  end
end

-- Spawn an obstacle from one of the available artboards
local function spawnObstacle(self: DinoGame): Obstacle?
  local sources: { Artboard } = {
    self.Obstacle1Artboard,
    self.Obstacle2Artboard,
    self.Obstacle3Artboard,
  }

  -- Filter to artboards that can be instanced
  local choices: { Artboard } = {}
  for _, src in sources do
    local ok, inst = pcall(function()
      return src:instance()
    end)
    if ok and inst then
      table.insert(choices, src)
    end
  end

  if #choices == 0 then
    return nil
  end

  local idx: number = math.floor(math.random() * #choices) + 1
  local art: Artboard = choices[idx]
  local inst: Artboard = art:instance()
  local w: number, h: number = getArtboardSize(art)
  return {
    x = OBSTACLE_SPAWN_X,
    y = GROUND_Y,
    width = w,
    height = h,
    instance = inst,
  }
end

local function startGame(self: DinoGame)
  self.gameState = "Running"
  self.characterY = GROUND_Y
  self.characterVy = 0
  self.currentObstacle = nil
  self.spawnTimer = 0
  createCharacterInstance(self)
end

local function onStartGameTrigger(self: DinoGame)
  if self.gameState == "Idle" or self.gameState == "GameOver" then
    startGame(self)
  end
end

local function onJumpTrigger(self: DinoGame)
  if self.gameState == "Running" and not self.PauseToggle then
    if self.characterVy == 0 and self.characterY >= GROUND_Y - 2 then
      self.characterVy = JUMP_VELOCITY
    end
  end
end

function init(self: DinoGame, context: Context): boolean
  self.gameState = "Idle"
  self.characterY = GROUND_Y
  self.characterVy = 0
  self.currentObstacle = nil
  self.spawnTimer = 0

  createCharacterInstance(self)

  return true
end

function advance(self: DinoGame, dt: number): boolean
  local cappedDt: number = math.min(dt, 0.05)
  local pauseOn: boolean = self.PauseToggle == true

  -- Pause toggle drives Running <-> Paused
  if self.gameState == "Running" and pauseOn then
    self.gameState = "Paused"
  elseif self.gameState == "Paused" and not pauseOn then
    self.gameState = "Running"
  end

  -- Early out for non-active states
  if self.gameState == "Paused"
    or self.gameState == "GameOver"
    or self.gameState == "Idle"
  then
    return true
  end

  -- Running state: physics
  self.characterVy = self.characterVy + GRAVITY * cappedDt
  self.characterY = self.characterY + self.characterVy * cappedDt
  if self.characterY >= GROUND_Y then
    self.characterY = GROUND_Y
    self.characterVy = 0
  end

  -- Advance character artboard
  if self.characterInstance then
    self.characterInstance:advance(cappedDt)
  end

  -- Obstacle movement
  if self.currentObstacle then
    local obs: Obstacle = self.currentObstacle
    obs.x = obs.x - OBSTACLE_SPEED * cappedDt

    if obs.instance then
      obs.instance:advance(cappedDt)
    end

    -- Off screen
    if obs.x + obs.width < 0 then
      self.currentObstacle = nil
    else
      -- Collision check
      local cx: number = CHARACTER_X - self.characterWidth / 2 + COLLISION_PADDING
      local cy: number = self.characterY - self.characterHeight + COLLISION_PADDING
      local cw: number = self.characterWidth - 2 * COLLISION_PADDING
      local ch: number = self.characterHeight - 2 * COLLISION_PADDING
      local ox: number = obs.x
      local oy: number = obs.y - obs.height

      if boxesOverlap(cx, cy, cw, ch, ox, oy, obs.width, obs.height) then
        self.gameState = "GameOver"
        self.currentObstacle = nil
        return true
      end
    end
  end

  -- Spawn timer
  if self.currentObstacle == nil then
    self.spawnTimer = self.spawnTimer + cappedDt
    if self.spawnTimer >= SPAWN_INTERVAL then
      self.spawnTimer = 0
      self.currentObstacle = spawnObstacle(self)
    end
  end

  return true
end

function draw(self: DinoGame, renderer: Renderer)
  -- Draw character
  local charY: number = self.characterY
  if self.characterInstance then
    local w: number = self.characterWidth
    local h: number = self.characterHeight
    renderer:save()
    renderer:transform(Mat2D.withTranslation(CHARACTER_X - w / 2, charY - h))
    self.characterInstance:draw(renderer)
    renderer:restore()
  else
    -- Fallback rectangle
    local path: Path = Path.new()
    path:moveTo(Vector.xy(CHARACTER_X - 25, charY))
    path:lineTo(Vector.xy(CHARACTER_X + 25, charY))
    path:lineTo(Vector.xy(CHARACTER_X + 25, charY - 60))
    path:lineTo(Vector.xy(CHARACTER_X - 25, charY - 60))
    path:close()
    renderer:drawPath(path, Paint.with({ style = "fill", color = Color.rgb(80, 180, 80) }))
  end

  -- Draw obstacle
  if self.currentObstacle then
    local obs: Obstacle = self.currentObstacle
    if obs.instance then
      renderer:save()
      renderer:transform(Mat2D.withTranslation(obs.x, obs.y - obs.height))
      obs.instance:draw(renderer)
      renderer:restore()
    else
      local path: Path = Path.new()
      path:moveTo(Vector.xy(obs.x, obs.y))
      path:lineTo(Vector.xy(obs.x + obs.width, obs.y))
      path:lineTo(Vector.xy(obs.x + obs.width, obs.y - obs.height))
      path:lineTo(Vector.xy(obs.x, obs.y - obs.height))
      path:close()
      renderer:drawPath(path, Paint.with({ style = "fill", color = Color.rgb(180, 80, 80) }))
    end
  end

  -- Game Over overlay
  if self.gameState == "GameOver" then
    local path: Path = Path.new()
    path:moveTo(Vector.xy(0, 0))
    path:lineTo(Vector.xy(WORLD_W, 0))
    path:lineTo(Vector.xy(WORLD_W, WORLD_H))
    path:lineTo(Vector.xy(0, WORLD_H))
    path:close()
    renderer:drawPath(path, Paint.with({ style = "fill", color = Color.rgba(0, 0, 0, 140) }))

    local gw: number = 280
    local gh: number = 50
    local gx: number = (WORLD_W - gw) / 2
    local gy: number = (WORLD_H - gh) / 2 - 25
    local gp: Path = Path.new()
    gp:moveTo(Vector.xy(gx, gy))
    gp:lineTo(Vector.xy(gx + gw, gy))
    gp:lineTo(Vector.xy(gx + gw, gy + gh))
    gp:lineTo(Vector.xy(gx, gy + gh))
    gp:close()
    renderer:drawPath(gp, Paint.with({ style = "fill", color = Color.rgb(200, 60, 60) }))
  end
end

return function(): Node<DinoGame>
  return {
    -- Trigger inputs
    StartGameTrigger = onStartGameTrigger,
    JumpTrigger = onJumpTrigger,

    -- Boolean input
    PauseToggle = false,

    -- Artboard inputs
    CharacterArtboard = late(),
    Obstacle1Artboard = late(),
    Obstacle2Artboard = late(),
    Obstacle3Artboard = late(),

    -- Internal state
    gameState = "Idle",
    characterY = GROUND_Y,
    characterVy = 0,
    characterInstance = nil,
    characterWidth = 50,
    characterHeight = 60,
    currentObstacle = nil,
    spawnTimer = 0,

    init = init,
    advance = advance,
    draw = draw,
  }
end
