-- Hanging vines with configurable palette and wind sway.
-- Draws within a 412x600 area.

local CANVAS_W = 412
local CANVAS_H = 600
local STRAND_COUNT = 36
local SEGMENTS_PER_STRAND = 16

type LeafDef = {
  t: number,
  side: number,
  size: number,
  angleJitter: number,
  colorIndex: number,
}

type StrandDef = {
  x: number,
  yStart: number,
  length: number,
  thickness: number,
  phase: number,
  swayBias: number,
  leaves: { LeafDef },
}

export type Vines = {
  -- Exposed inputs
  windSpeed: Input<number>, -- 1..10
  stemColor: Input<Color>,
  leafColor1: Input<Color>,
  leafColor2: Input<Color>,
  leafColor3: Input<Color>,
  leafColor4: Input<Color>,

  -- Internal state
  time: number,
  strands: { StrandDef },
  palette: { Color },
}

local function clamp(v: number, minV: number, maxV: number): number
  if v < minV then
    return minV
  end
  if v > maxV then
    return maxV
  end
  return v
end

local function randomRange(minV: number, maxV: number): number
  return minV + math.random() * (maxV - minV)
end

local function speedNorm(self: Vines): number
  local s = clamp(self.windSpeed or 1, 1, 10)
  return (s - 1) / 9
end

local function updatePalette(self: Vines)
  self.palette = {
    self.leafColor1 or Color.rgb(74, 133, 45),
    self.leafColor2 or Color.rgb(92, 151, 56),
    self.leafColor3 or Color.rgb(113, 168, 67),
    self.leafColor4 or Color.rgb(56, 112, 37),
  }
end

local function stemOffsetX(self: Vines, strand: StrandDef, t: number): number
  local sn = speedNorm(self)
  local amp = 2 + sn * 18
  local freq = 0.35 + sn * 1.65

  local slow = math.sin(self.time * freq + strand.phase) * amp * (0.15 + 0.85 * t)
  local ripple = math.sin(self.time * (freq * 2.2) + strand.phase * 1.7 + t * 5.5) * amp * 0.22
  local gust = math.sin(self.time * (0.2 + sn * 0.5) + strand.phase * 0.5) * amp * 0.35 * t * t

  return (slow + ripple + gust) * strand.swayBias
end

local function stemPoint(self: Vines, strand: StrandDef, t: number): (number, number)
  local y = strand.yStart + strand.length * t
  local x = strand.x + stemOffsetX(self, strand, t)
  return x, y
end

local function drawLeaf(renderer: Renderer, size: number, color: Color)
  local path = Path.new()
  -- Curvier ivy-like leaf silhouette with a soft tip and rounded lobes.
  path:moveTo(Vector.xy(0, -size * 1.05))
  path:cubicTo(
    Vector.xy(size * 0.7, -size * 0.85),
    Vector.xy(size * 0.92, -size * 0.1),
    Vector.xy(size * 0.48, size * 0.28)
  )
  path:cubicTo(
    Vector.xy(size * 0.42, size * 0.85),
    Vector.xy(size * 0.16, size * 1.05),
    Vector.xy(0, size * 1.1)
  )
  path:cubicTo(
    Vector.xy(-size * 0.16, size * 1.05),
    Vector.xy(-size * 0.42, size * 0.85),
    Vector.xy(-size * 0.48, size * 0.28)
  )
  path:cubicTo(
    Vector.xy(-size * 0.92, -size * 0.1),
    Vector.xy(-size * 0.7, -size * 0.85),
    Vector.xy(0, -size * 1.05)
  )
  path:close()
  renderer:drawPath(path, Paint.with({ style = "fill", color = color }))
end

local function generateStrands(self: Vines)
  self.strands = {}

  for i = 1, STRAND_COUNT do
    local baseX = ((i - 0.5) / STRAND_COUNT) * CANVAS_W + randomRange(-6, 6)
    local yStart = randomRange(-30, 10)
    local len = randomRange(140, 320)
    local thickness = randomRange(1.4, 3.0)
    local phase = randomRange(0, 2 * math.pi)
    local swayBias = randomRange(0.8, 1.2)
    local leaves: { LeafDef } = {}
    local tCursor = randomRange(0.04, 0.08)

    -- Dense at top; spacing gradually increases toward bottom.
    while tCursor < 0.98 do
      local t = clamp(tCursor + randomRange(-0.015, 0.015), 0.04, 0.98)
      local side = (math.random() < 0.5) and -1 or 1
      local sizeScale = 1.0 - t * 0.55 -- bigger near top, smaller downwards
      local size = randomRange(5.2, 9.8) * sizeScale
      local angleJitter = randomRange(-0.35, 0.35)
      local colorIndex = math.floor(randomRange(1, 4.99))
      table.insert(leaves, {
        t = t,
        side = side,
        size = size,
        angleJitter = angleJitter,
        colorIndex = colorIndex,
      })

      local step = randomRange(0.026, 0.05) + t * randomRange(0.055, 0.08)
      tCursor = tCursor + step
    end

    table.insert(self.strands, {
      x = baseX,
      yStart = yStart,
      length = len,
      thickness = thickness,
      phase = phase,
      swayBias = swayBias,
      leaves = leaves,
    })
  end
end

function init(self: Vines, context: Context): boolean
  self.time = 0
  updatePalette(self)
  generateStrands(self)
  return true
end

function advance(self: Vines, dt: number): boolean
  self.time = self.time + math.min(dt, 0.05)
  updatePalette(self)
  return true
end

function update(self: Vines)
  updatePalette(self)
end

function draw(self: Vines, renderer: Renderer)
  local stemColor = self.stemColor or Color.rgb(66, 118, 42)

  for _, strand in ipairs(self.strands) do
    -- Draw stem
    local stem = Path.new()
    for s = 0, SEGMENTS_PER_STRAND do
      local t = s / SEGMENTS_PER_STRAND
      local x, y = stemPoint(self, strand, t)
      if s == 0 then
        stem:moveTo(Vector.xy(x, y))
      else
        stem:lineTo(Vector.xy(x, y))
      end
    end

    renderer:drawPath(
      stem,
      Paint.with({
        style = "stroke",
        thickness = strand.thickness,
        cap = "round",
        join = "round",
        color = stemColor,
      })
    )

    -- Draw leaves along the stem
    for _, leaf in ipairs(strand.leaves) do
      local px, py = stemPoint(self, strand, leaf.t)
      local nx, ny = stemPoint(self, strand, clamp(leaf.t + 0.015, 0, 1))
      local tangent = math.atan2(ny - py, nx - px)
      local normal = tangent + math.pi * 0.5

      local offset = 3.5 + leaf.size * 0.45
      local lx = px + math.cos(normal) * offset * leaf.side
      local ly = py + math.sin(normal) * offset * leaf.side

      local leafAngle = normal + leaf.side * 0.8 + leaf.angleJitter
      local leafColor = self.palette[leaf.colorIndex] or self.palette[1]

      if ly > -16 and ly < CANVAS_H + 16 and lx > -16 and lx < CANVAS_W + 16 then
        renderer:save()
        renderer:transform(Mat2D.withTranslation(lx, ly))
        renderer:transform(Mat2D.withRotation(leafAngle))
        drawLeaf(renderer, leaf.size, leafColor)
        renderer:restore()
      end
    end
  end
end

return function(): Node<Vines>
  return {
    -- Exposed controls
    windSpeed = 2,
    stemColor = Color.rgb(66, 118, 42),
    leafColor1 = Color.rgb(74, 133, 45),
    leafColor2 = Color.rgb(92, 151, 56),
    leafColor3 = Color.rgb(113, 168, 67),
    leafColor4 = Color.rgb(56, 112, 37),

    -- Internal state
    time = 0,
    strands = {},
    palette = {},

    init = init,
    advance = advance,
    update = update,
    draw = draw,
  }
end
