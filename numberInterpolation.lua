--[[
  NumberInterpolation — interpolates a View Model number property from `from` to `to`
  over `duration` seconds when `startAnimation` fires.

  Wiring in Rive:
  1. Add this script as a Node on your artboard.
  2. Property Group: bind `viewModel` to your view model instance.
     Change `Input<Data.CatAndTorch>` below if your view model type differs.
  3. Set `property` to the number property name on that VM.
  4. Set from / to / duration; fire `startAnimation` to run the ramp.
]]

local DEFAULT_FROM = 0
local DEFAULT_TO = 100
local DEFAULT_DURATION = 1
local DEFAULT_PROPERTY = "progress"

export type NumberInterpolation = {
  viewModel: Input<Data.CatAndTorch>,
  property: Input<string>,
  from: Input<number>,
  to: Input<number>,
  duration: Input<number>,
  startAnimation: Input<Trigger>,

  propertyRef: any?,
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

local function readPropertyName(input: Input<string>?): string
  if input == nil or input == "" then
    return DEFAULT_PROPERTY
  end
  return input
end

local function resolveVm(self: NumberInterpolation, context: Context): any?
  if self.viewModel then
    return self.viewModel
  end
  return context:viewModel()
end

local function resolvePropertyRef(self: NumberInterpolation, vm: any): any?
  local name = readPropertyName(self.property)

  if self.viewModel then
    local direct = self.viewModel[name]
    if direct then
      return direct
    end
  end

  return vm:getNumber(name)
end

local function onStartAnimation(self: NumberInterpolation)
  if not self.propertyRef then
    return
  end

  self.animFrom = readNumber(self.from, DEFAULT_FROM)
  self.animTo = readNumber(self.to, DEFAULT_TO)
  self.animDuration = readNumber(self.duration, DEFAULT_DURATION)

  if self.animDuration <= 0 then
    self.propertyRef.value = self.animTo
    self.animating = false
    self.elapsed = 0
    return
  end

  self.elapsed = 0
  self.animating = true
  self.propertyRef.value = self.animFrom
end

local function init(self: NumberInterpolation, context: Context): boolean
  self.propertyRef = nil
  self.elapsed = 0
  self.animating = false
  self.animFrom = DEFAULT_FROM
  self.animTo = DEFAULT_TO
  self.animDuration = DEFAULT_DURATION

  local vm = resolveVm(self, context)
  if not vm then
    print("NumberInterpolation: no View Model — bind 'viewModel' in Property Group.")
    return false
  end

  local propertyName = readPropertyName(self.property)
  local propertyRef = resolvePropertyRef(self, vm)
  if not propertyRef then
    print(
      "NumberInterpolation: could not find number property '"
        .. propertyName
        .. "' on the bound view model."
    )
    return false
  end

  self.propertyRef = propertyRef
  self.propertyRef.value = readNumber(self.from, DEFAULT_FROM)
  return true
end

local function advance(self: NumberInterpolation, dt: number): boolean
  if not self.propertyRef or not self.animating then
    return true
  end

  self.elapsed = self.elapsed + dt
  local t = math.min(1, self.elapsed / self.animDuration)
  self.propertyRef.value = self.animFrom + (self.animTo - self.animFrom) * t

  if self.elapsed >= self.animDuration then
    self.propertyRef.value = self.animTo
    self.animating = false
  end

  return true
end

return function(): Node<NumberInterpolation>
  return {
    viewModel = late(),
    property = DEFAULT_PROPERTY,
    from = DEFAULT_FROM,
    to = DEFAULT_TO,
    duration = DEFAULT_DURATION,
    startAnimation = onStartAnimation,
    propertyRef = nil,
    elapsed = 0,
    animating = false,
    animFrom = DEFAULT_FROM,
    animTo = DEFAULT_TO,
    animDuration = DEFAULT_DURATION,
    init = init,
    advance = advance,
  }
end
