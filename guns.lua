--[[
  Circular gun wheel: rifle / automatic / pistol / grenadeLauncher artboards; Swap cycles focus (1→2→3→4→1).
  Focus gun: full scale + total ammo (7-seg style) left of artboard, cyan bar, magazine bullets below.
  Per gun: totalAmmo, magazineBullets (chips per mag / UI count), bulletsPerRow (grid wrap).
  BulletArtboard: one component artboard; reused for each magazine chip (scaled into each cell).
  Other guns: 0.5× scale only (no extra dimming).
  GunFire: removes one chip from current mag; reloads when mag empty if reserve left; at 0 reserve, ignores.
]]

-- Layout (tune to your host artboard). Focus gun is at 9 o'clock on the wheel.
local CIRCLE_CX = 700
local CIRCLE_CY = 300
local CIRCLE_R = 100
local SWAP_DURATION = 0.88 -- longer + quintic easing = smoother orbit
local INACTIVE_GUN_SCALE = 0.5

local FOCUS_ANGLE = math.pi -- left (9 o'clock), y-down coords
local SLOT_ANGLES = { math.pi, -math.pi / 2, 0, math.pi / 2 } -- left, top, right, bottom

-- Magazine chips: compact, tucked close under the selected gun.
local BULLET_W = 6
local BULLET_H = 16
local BULLET_GAP = 3
local ROW_GAP = 4
local GAP_BELOW_ARTBOARD = 10
-- Horizontal space between ammo digits (right edge) and the cyan bar.
local AMMO_GAP_FROM_CYAN_BAR = 28

local COLOR_CYAN = Color.rgb(0, 220, 255)
local COLOR_WHITE = Color.rgb(255, 255, 255)

type GunInstances = {
  inst: Artboard?,
  w: number,
  h: number,
}

type GunAmmoState = {
  remainingTotal: number,
  displayCount: number,
}

export type GunWheel = {
  rifle: Input<Artboard>,
  automatic: Input<Artboard>,
  pistol: Input<Artboard>,
  grenadeLauncher: Input<Artboard>,
  BulletArtboard: Input<Artboard>,
  Swap: Input<Trigger>,
  GunFire: Input<Trigger>,

  rifleTotalAmmo: Input<number>,
  rifleMagazineBullets: Input<number>,
  rifleBulletsPerRow: Input<number>,
  automaticTotalAmmo: Input<number>,
  automaticMagazineBullets: Input<number>,
  automaticBulletsPerRow: Input<number>,
  pistolTotalAmmo: Input<number>,
  pistolMagazineBullets: Input<number>,
  pistolBulletsPerRow: Input<number>,
  grenadeLauncherTotalAmmo: Input<number>,
  grenadeLauncherMagazineBullets: Input<number>,
  grenadeLauncherBulletsPerRow: Input<number>,

  settledActive: number, -- 0..3
  swapT: number,
  swapping: boolean,
  fromActive: number,
  toActive: number,

  guns: { GunInstances },
  ammo: { GunAmmoState },
  bulletInstance: Artboard?,
  bulletArtboardW: number,
  bulletArtboardH: number,
}

local function clamp(v: number, lo: number, hi: number): number
  if v < lo then
    return lo
  end
  if v > hi then
    return hi
  end
  return v
end

-- Quintic smoothstep (0→1): gentler accel/decel than cubic smoothstep.
local function easeSwap(t: number): number
  t = clamp(t, 0, 1)
  return t * t * t * (t * (t * 6 - 15) + 10)
end

local function getArtboardSize(artboard: Artboard): (number, number)
  local w = artboard.width
  local h = artboard.height
  if w <= 0 then
    w = 120
  end
  if h <= 0 then
    h = 120
  end
  return w, h
end

local function slotIndexForGun(gunIdx0: number, active0: number): number
  return (gunIdx0 - active0) % 4
end

local function angleForSlot(slot: number): number
  return SLOT_ANGLES[slot + 1]
end

local function angleDiff(a: number, b: number): number
  local d = math.abs(a - b) % (2 * math.pi)
  if d > math.pi then
    d = 2 * math.pi - d
  end
  return d
end

local function lerpAngle(a0: number, a1: number, t: number): number
  local d = a1 - a0
  while d > math.pi do
    d = d - 2 * math.pi
  end
  while d < -math.pi do
    d = d + 2 * math.pi
  end
  return a0 + d * t
end

local function gunAngle(self: GunWheel, gunIdx0: number, t: number): number
  if not self.swapping then
    local s = slotIndexForGun(gunIdx0, self.settledActive)
    return angleForSlot(s)
  end
  local fromS = slotIndexForGun(gunIdx0, self.fromActive)
  local toS = slotIndexForGun(gunIdx0, self.toActive)
  local a0 = angleForSlot(fromS)
  local a1 = angleForSlot(toS)
  return lerpAngle(a0, a1, t)
end

local function gunTotalAmmo(self: GunWheel, i: number): number
  local t = {
    self.rifleTotalAmmo,
    self.automaticTotalAmmo,
    self.pistolTotalAmmo,
    self.grenadeLauncherTotalAmmo,
  }
  local v = t[i]
  if v == nil then return 0 end
  return math.max(0, v)
end

local function gunMagazineBullets(self: GunWheel, i: number): number
  local t = {
    self.rifleMagazineBullets,
    self.automaticMagazineBullets,
    self.pistolMagazineBullets,
    self.grenadeLauncherMagazineBullets,
  }
  local v = t[i]
  if v == nil then return 1 end
  return math.max(1, math.floor(v))
end

local function gunBulletsPerRow(self: GunWheel, i: number): number
  local t = {
    self.rifleBulletsPerRow,
    self.automaticBulletsPerRow,
    self.pistolBulletsPerRow,
    self.grenadeLauncherBulletsPerRow,
  }
  local v = t[i]
  if v == nil then return 15 end
  return math.max(1, math.floor(v))
end

local function ensureGunInstance(
  self: GunWheel,
  i: number,
  src: Artboard?
): boolean
  if not self.guns[i] then
    self.guns[i] = { inst = nil, w = 120, h = 120 }
  end
  local g = self.guns[i]
  if not src then
    g.inst = nil
    return false
  end
  if g.inst then
    return true
  end
  local ok, inst = pcall(function()
    return src:instance()
  end)
  if ok and inst then
    local w, h = getArtboardSize(src)
    g.inst = inst
    g.w = w
    g.h = h
    return true
  end
  g.inst = nil
  return false
end

local function ensureAllGunInstances(self: GunWheel)
  local sources = {
    self.rifle,
    self.automatic,
    self.pistol,
    self.grenadeLauncher,
  }
  for i = 1, 4 do
    ensureGunInstance(self, i, sources[i])
  end
end

local function ensureBulletInstance(self: GunWheel): boolean
  local src = self.BulletArtboard
  if not src then
    self.bulletInstance = nil
    return false
  end
  if self.bulletInstance then
    return true
  end
  local ok, inst = pcall(function()
    return src:instance()
  end)
  if ok and inst then
    self.bulletInstance = inst
    local w, h = getArtboardSize(src)
    self.bulletArtboardW = w
    self.bulletArtboardH = h
    return true
  end
  self.bulletInstance = nil
  return false
end

-- 7-segment style digits (coarse); draws digit centered at (cx, cy)
local SEG_T = 3.5
local SEG_W = 16
local SEG_H = 22

local function segH(
  renderer: Renderer,
  cx: number,
  cy: number,
  w: number,
  paint: any
)
  local p = Path.new()
  p:moveTo(Vector.xy(cx - w / 2, cy - SEG_T / 2))
  p:lineTo(Vector.xy(cx + w / 2, cy - SEG_T / 2))
  p:lineTo(Vector.xy(cx + w / 2, cy + SEG_T / 2))
  p:lineTo(Vector.xy(cx - w / 2, cy + SEG_T / 2))
  p:close()
  renderer:drawPath(p, paint)
end

local function segV(
  renderer: Renderer,
  cx: number,
  cy: number,
  h: number,
  paint: any
)
  local p = Path.new()
  p:moveTo(Vector.xy(cx - SEG_T / 2, cy - h / 2))
  p:lineTo(Vector.xy(cx + SEG_T / 2, cy - h / 2))
  p:lineTo(Vector.xy(cx + SEG_T / 2, cy + h / 2))
  p:lineTo(Vector.xy(cx - SEG_T / 2, cy + h / 2))
  p:close()
  renderer:drawPath(p, paint)
end

-- segments: top, tl, tr, mid, bl, br, bot -> indices 1..7
local DIGIT_SEGS: { { number } } = {
  { 1, 2, 3, 5, 6, 7 }, -- 0
  { 3, 6 }, -- 1
  { 1, 3, 4, 5, 7 }, -- 2
  { 1, 3, 4, 6, 7 }, -- 3
  { 2, 3, 4, 6 }, -- 4
  { 1, 2, 4, 6, 7 }, -- 5
  { 1, 2, 4, 5, 6, 7 }, -- 6
  { 1, 3, 6 }, -- 7
  { 1, 2, 3, 4, 5, 6, 7 }, -- 8
  { 1, 2, 3, 4, 6, 7 }, -- 9
}

local function drawDigit(
  renderer: Renderer,
  digit: number,
  cx: number,
  cy: number,
  paint: any
)
  if digit < 0 or digit > 9 then
    return
  end
  local segs = DIGIT_SEGS[digit + 1]
  local halfH = SEG_H / 2 - SEG_T
  local halfW = SEG_W / 2 - SEG_T * 0.6
  local present = { false, false, false, false, false, false, false }
  for _, s in ipairs(segs) do
    present[s] = true
  end
  if present[1] then
    segH(renderer, cx, cy - halfH, SEG_W, paint)
  end
  if present[7] then
    segH(renderer, cx, cy + halfH, SEG_W, paint)
  end
  if present[4] then
    segH(renderer, cx, cy, SEG_W - 2, paint)
  end
  if present[2] then
    segV(renderer, cx - halfW, cy - halfH / 2, halfH + SEG_T, paint)
  end
  if present[3] then
    segV(renderer, cx + halfW, cy - halfH / 2, halfH + SEG_T, paint)
  end
  if present[5] then
    segV(renderer, cx - halfW, cy + halfH / 2, halfH + SEG_T, paint)
  end
  if present[6] then
    segV(renderer, cx + halfW, cy + halfH / 2, halfH + SEG_T, paint)
  end
end

local function drawNumber(
  renderer: Renderer,
  value: number,
  rightX: number,
  cy: number,
  paint: any
)
  local s = tostring(math.floor(value + 0.5))
  local digitSpacing = SEG_W + 6
  local z = string.byte('0', 1)
  for i = 1, #s do
    local ch = string.byte(s, i) - z
    local dcx = rightX - (#s - i) * digitSpacing
    drawDigit(renderer, ch, dcx, cy, paint)
  end
end

-- Vertical capsule = ellipse outline (reliable fill vs. hand-built stadium paths).
local function drawBulletChip(
  renderer: Renderer,
  cx: number,
  cy: number,
  paint: any
)
  local rx = BULLET_W / 2
  local ry = BULLET_H / 2
  local p = Path.new()
  local n = 16
  for i = 0, n - 1 do
    local t = (i / n) * 2 * math.pi
    local x = cx + rx * math.cos(t)
    local y = cy + ry * math.sin(t)
    if i == 0 then
      p:moveTo(Vector.xy(x, y))
    else
      p:lineTo(Vector.xy(x, y))
    end
  end
  p:close()
  renderer:drawPath(p, paint)
end

local function drawBulletGrid(
  self: GunWheel,
  renderer: Renderer,
  leftX: number,
  topY: number,
  count: number,
  maxPerRow: number
)
  if count <= 0 then
    return
  end
  local useArt = ensureBulletInstance(self)
  local tw = self.bulletArtboardW > 0 and self.bulletArtboardW or 1
  local th = self.bulletArtboardH > 0 and self.bulletArtboardH or 1
  local col = 0
  local row = 0
  for _ = 1, count do
    local cx = leftX + col * (BULLET_W + BULLET_GAP) + BULLET_W / 2
    local cy = topY + row * (BULLET_H + ROW_GAP) + BULLET_H / 2
    if useArt and self.bulletInstance then
      local scale = math.min(BULLET_W / tw, BULLET_H / th)
      renderer:save()
      renderer:transform(Mat2D.withTranslation(cx, cy))
      renderer:transform(Mat2D.withScale(scale, scale))
      renderer:transform(Mat2D.withTranslation(-tw / 2, -th / 2))
      self.bulletInstance:draw(renderer)
      renderer:restore()
    else
      drawBulletChip(
        renderer,
        cx,
        cy,
        Paint.with({ style = 'fill', color = COLOR_WHITE })
      )
    end
    col = col + 1
    if col >= maxPerRow then
      col = 0
      row = row + 1
    end
  end
end

local function onSwap(self: GunWheel)
  if self.swapping then
    return
  end
  self.fromActive = self.settledActive
  self.toActive = (self.settledActive + 1) % 4
  self.swapT = 0
  self.swapping = true
end

local function resetAmmoState(self: GunWheel)
  self.ammo = {}
  for i = 1, 4 do
    local magCap = gunMagazineBullets(self, i)
    local tot = gunTotalAmmo(self, i)
    self.ammo[i] = {
      remainingTotal = tot,
      displayCount = math.min(magCap, tot),
    }
  end
end

-- Fires one round from the gun currently selected (settledActive), not mid-swap ghost focus.
local function onGunFire(self: GunWheel)
  local idx = self.settledActive + 1
  local a = self.ammo[idx]
  local magCap = gunMagazineBullets(self, idx)
  if not a or a.remainingTotal <= 0 then
    return
  end
  if a.displayCount <= 0 and a.remainingTotal > 0 then
    a.displayCount = math.min(magCap, a.remainingTotal)
  end
  a.remainingTotal = a.remainingTotal - 1
  if a.displayCount > 0 then
    a.displayCount = a.displayCount - 1
  end
  if a.displayCount == 0 and a.remainingTotal > 0 then
    a.displayCount = math.min(magCap, a.remainingTotal)
  end
end

function init(self: GunWheel, context: Context): boolean
  self.settledActive = 0
  self.swapT = 0
  self.swapping = false
  self.fromActive = 0
  self.toActive = 0
  self.guns = {}
  resetAmmoState(self)
  ensureAllGunInstances(self)
  self.bulletInstance = nil
  self.bulletArtboardW = 0
  self.bulletArtboardH = 0
  ensureBulletInstance(self)
  return true
end

function advance(self: GunWheel, dt: number): boolean
  local cap = math.min(dt, 0.05)

  if self.swapping then
    self.swapT = self.swapT + cap / SWAP_DURATION
    if self.swapT >= 1 then
      self.swapT = 1
      self.settledActive = self.toActive
      self.swapping = false
      self.swapT = 0
    end
  end

  for i = 1, 4 do
    local g = self.guns[i]
    if g and g.inst then
      g.inst:advance(cap)
    end
  end
  if self.bulletInstance then
    self.bulletInstance:advance(cap)
  end
  return true
end

function draw(self: GunWheel, renderer: Renderer)
  ensureAllGunInstances(self)

  local t = self.swapping and easeSwap(self.swapT) or 0

  -- Focus = closest to FOCUS_ANGLE among guns that actually have an instance (so UI always matches a visible artboard).
  local bestG = 1
  local bestD = 1e9
  for g = 1, 4 do
    local gi = self.guns[g]
    if gi and gi.inst then
      local ang = gunAngle(self, g - 1, t)
      local d = angleDiff(ang, FOCUS_ANGLE)
      if d < bestD then
        bestD = d
        bestG = g
      end
    end
  end

  -- draw guns: inactive first, focus last
  local order = { 1, 2, 3, 4 }
  table.sort(order, function(a, b)
    local fa = (a == bestG) and 1 or 0
    local fb = (b == bestG) and 1 or 0
    return fa < fb
  end)

  local bulletsLeftX: number? = nil
  local bulletsTopY: number? = nil
  local bulletsCount = 0
  local bulletsMaxPerRow = 15

  for _, g in ipairs(order) do
    local gi = self.guns[g]
    if gi and gi.inst then
      local ang = gunAngle(self, g - 1, t)
      local px = CIRCLE_CX + math.cos(ang) * CIRCLE_R
      local py = CIRCLE_CY + math.sin(ang) * CIRCLE_R
      local w, h = gi.w, gi.h
      local gunScale = (g == bestG) and 1.0 or INACTIVE_GUN_SCALE

      renderer:save()
      renderer:transform(Mat2D.withTranslation(px, py))
      renderer:transform(Mat2D.withScale(gunScale, gunScale))
      renderer:transform(Mat2D.withTranslation(-w / 2, -h / 2))
      gi.inst:draw(renderer)
      renderer:restore()

      if g == bestG then
        local am = self.ammo[g]
        local remaining = am and am.remainingTotal or gunTotalAmmo(self, g)
        local chips = am and am.displayCount or gunMagazineBullets(self, g)
        bulletsMaxPerRow = gunBulletsPerRow(self, g)
        local sepX = px - w / 2 - 10
        local numRight = sepX - AMMO_GAP_FROM_CYAN_BAR
        local numCy = py
        drawNumber(
          renderer,
          remaining,
          numRight,
          numCy,
          Paint.with({ style = 'fill', color = COLOR_WHITE })
        )

        local bar = Path.new()
        bar:moveTo(Vector.xy(sepX, py - h / 2 - 4))
        bar:lineTo(Vector.xy(sepX, py + h / 2 + 4))
        renderer:drawPath(
          bar,
          Paint.with({
            style = 'stroke',
            thickness = 2,
            color = COLOR_CYAN,
            cap = 'round',
          })
        )

        -- Bullets drawn in a final pass so they are not covered by other artboards.
        bulletsLeftX = px - w / 2
        bulletsTopY = py + h / 2 + GAP_BELOW_ARTBOARD
        bulletsCount = chips
      end
    end
  end

  if bulletsLeftX and bulletsTopY and bulletsCount > 0 then
    drawBulletGrid(
      self,
      renderer,
      bulletsLeftX,
      bulletsTopY,
      bulletsCount,
      bulletsMaxPerRow
    )
  end
end

return function(): Node<GunWheel>
  return {
    rifle = late(),
    automatic = late(),
    pistol = late(),
    grenadeLauncher = late(),
    BulletArtboard = late(),
    Swap = onSwap,
    GunFire = onGunFire,

    rifleTotalAmmo = 300,
    rifleMagazineBullets = 30,
    rifleBulletsPerRow = 15,
    automaticTotalAmmo = 100,
    automaticMagazineBullets = 20,
    automaticBulletsPerRow = 15,
    pistolTotalAmmo = 100,
    pistolMagazineBullets = 10,
    pistolBulletsPerRow = 15,
    grenadeLauncherTotalAmmo = 150,
    grenadeLauncherMagazineBullets = 15,
    grenadeLauncherBulletsPerRow = 15,

    settledActive = 0,
    swapT = 0,
    swapping = false,
    fromActive = 0,
    toActive = 0,
    guns = {},
    ammo = {},
    bulletInstance = nil,
    bulletArtboardW = 0,
    bulletArtboardH = 0,

    init = init,
    advance = advance,
    draw = draw,
  }
end
