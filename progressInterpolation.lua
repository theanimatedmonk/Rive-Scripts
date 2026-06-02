--[[
  InterpolatedProgress — drives the CatAndTorch View Model number "progress" from
  `from` to `to` over `duration` seconds when `startAnimation` fires.

  Defaults: from = 0, to = 100, duration = 3 (0 → 100 in 3s).

  Wiring in Rive:
  1. Add this script to your CatAndTorch artboard as a Node.
  2. Property Group: bind `catAndTorch` to your CatAndTorch view model instance
     (or rely on context:viewModel() if the node already has that VM).
  3. Set from / to / duration as needed; fire `startAnimation` to run the ramp.
  4. Bind anything that should follow progress to the VM's `progress` property.
]]

local EXPECTED_VM_NAME = "CatAndTorch"
local DEFAULT_FROM = 0
local DEFAULT_TO = 100
local DEFAULT_DURATION = 3

export type InterpolatedProgress = {
  catAndTorch: Input<Data.CatAndTorch>,
  from: Input<number>,
  to: Input<number>,
  duration: Input<number>,
  startAnimation: Input<Trigger>,

  progressRef: any?,
  elapsed: number,
  animating: boolean,
  animFrom: number,
  animTo: number,
  animDuration: number,
}

local function readNumber(input: Input<number>?, fallback: number): number
  if input == nil then
    return fallback
  end
  return input
end

local function resolveVm(self: InterpolatedProgress, context: Context): any?
  if self.catAndTorch then
    return self.catAndTorch
  end
  return context:viewModel()
end

local function onStartAnimation(self: InterpolatedProgress)
  if not self.progressRef then
    return
  end

  self.animFrom = readNumber(self.from, DEFAULT_FROM)
  self.animTo = readNumber(self.to, DEFAULT_TO)
  self.animDuration = readNumber(self.duration, DEFAULT_DURATION)

  if self.animDuration <= 0 then
    self.progressRef.value = self.animTo
    self.animating = false
    self.elapsed = 0
    return
  end

  self.elapsed = 0
  self.animating = true
  self.progressRef.value = self.animFrom
end

local function init(self: InterpolatedProgress, context: Context): boolean
  self.progressRef = nil
  self.elapsed = 0
  self.animating = false
  self.animFrom = DEFAULT_FROM
  self.animTo = DEFAULT_TO
  self.animDuration = DEFAULT_DURATION

  local vm = resolveVm(self, context)
  if not vm then
    print("InterpolatedProgress: no View Model — bind 'catAndTorch' to CatAndTorch in Property Group.")
    return false
  end

  local vmName = vm.name
  if vmName and vmName ~= EXPECTED_VM_NAME then
    print(
      "InterpolatedProgress: bound View Model is '"
        .. tostring(vmName)
        .. "', expected '"
        .. EXPECTED_VM_NAME
        .. "'."
    )
  end

  local progress = vm:getNumber("progress")
  if not progress then
    print("InterpolatedProgress: getNumber('progress') returned nil — add a number property named progress.")
    return false
  end

  self.progressRef = progress
  self.progressRef.value = readNumber(self.from, DEFAULT_FROM)
  return true
end

local function advance(self: InterpolatedProgress, dt: number): boolean
  if not self.progressRef or not self.animating then
    return true
  end

  self.elapsed = self.elapsed + dt
  local t = math.min(1, self.elapsed / self.animDuration)
  self.progressRef.value = self.animFrom + (self.animTo - self.animFrom) * t

  if self.elapsed >= self.animDuration then
    self.progressRef.value = self.animTo
    self.animating = false
  end

  return true
end

return function(): Node<InterpolatedProgress>
  return {
    catAndTorch = late(),
    from = DEFAULT_FROM,
    to = DEFAULT_TO,
    duration = DEFAULT_DURATION,
    startAnimation = onStartAnimation,
    progressRef = nil,
    elapsed = 0,
    animating = false,
    animFrom = DEFAULT_FROM,
    animTo = DEFAULT_TO,
    animDuration = DEFAULT_DURATION,
    init = init,
    advance = advance,
  }
end
