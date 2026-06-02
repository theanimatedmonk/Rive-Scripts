--[[
  HelmetHMI: each time `swapGun` fires, cycles the Artboard property `aim`:
  rifle-aim → automatic-aim → pistol-aim → rocket-launcher-aim → rifle-aim

  IMPORTANT — View Model wiring:
  Node scripts often get `context:viewModel() == nil` (or not HelmetHMI) if the script sits on a
  layer/node that has no View Model. Fix: select the script in the Hierarchy, open Property Group,
  and bind the `helmet` input to your HelmetHMI instance (e.g. Main → same VM that owns `aim`).
]]

local EXPECTED_VM_NAME = "HelmetHMI"

local AIM_CYCLE = {
  "rifle-aim",
  "automatic-aim",
  "pistol-aim",
  "rocket-launcher-aim",
}

export type HelmetAimCycle = {
  -- Bind in Property Group to the HelmetHMI view model instance that has `aim` + `swapGun`.
  helmet: Input<Data.HelmetHMI>,
  aimEnum: any?,
  aimIndex: number,
}

local function syncIndexFromCurrent(aimEnum: any): number
  local v = aimEnum.value
  local asString = tostring(v)
  if type(v) == "string" then
    asString = v
  end
  for i, name in ipairs(AIM_CYCLE) do
    if name == asString then
      return i - 1
    end
  end
  return 0
end

local function applyNextAim(self: HelmetAimCycle)
  if not self.aimEnum then
    return
  end
  self.aimIndex = (self.aimIndex + 1) % #AIM_CYCLE
  self.aimEnum.value = AIM_CYCLE[self.aimIndex + 1]
end

local function resolveVm(self: HelmetAimCycle, context: Context): any?
  local bound = self.helmet
  if bound then
    return bound
  end
  return context:viewModel()
end

function init(self: HelmetAimCycle, context: Context): boolean
  self.aimEnum = nil
  self.aimIndex = 0

  local vm = resolveVm(self, context)
  if not vm then
    print("HelmetAimCycle: no View Model — bind script input 'helmet' to HelmetHMI in Property Group.")
    return false
  end

  local vmName = vm.name
  if vmName and vmName ~= EXPECTED_VM_NAME then
    print("HelmetAimCycle: bound View Model is '" .. tostring(vmName) .. "', expected '" .. EXPECTED_VM_NAME .. "'.")
  end

  local aim = vm:getEnum("aim")
  if not aim then
    print("HelmetAimCycle: getEnum('aim') is nil — wrong VM instance or `aim` is not an enum/artboard picker here.")
    return false
  end

  self.aimEnum = aim
  self.aimIndex = syncIndexFromCurrent(aim)

  local swapGun = vm:getTrigger("swapGun")
  if not swapGun then
    print("HelmetAimCycle: getTrigger('swapGun') returned nil")
    return false
  end

  swapGun:addListener(function()
    applyNextAim(self)
  end)

  return true
end

return function(): Node<HelmetAimCycle>
  return {
    helmet = late(),
    aimEnum = nil,
    aimIndex = 0,
    init = init,
  }
end
