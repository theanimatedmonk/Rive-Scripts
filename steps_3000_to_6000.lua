-- Node script: drives the View Model number "steps" from 3000 to 6000 over 1 second
-- when the View Model trigger "btn" is fired.
-- View Model must have: number "steps", trigger "btn".

type StepsRamp = {
  stepsRef: any?,
  elapsed: number,
  duration: number,
  from: number,
  to: number,
  rampActive: boolean,
}

local function onBtnTriggered(self: StepsRamp)
  self.elapsed = 0
  self.rampActive = true
end

function init(self: StepsRamp, context: Context): boolean
  self.elapsed = 0
  self.duration = 1
  self.from = 3000
  self.to = 6000
  self.rampActive = false
  local vm = context:viewModel()
  if vm then
    self.stepsRef = vm:getNumber("steps")
    if self.stepsRef then
      self.stepsRef.value = self.from
    end
    local btnTrigger = vm:getTrigger("btn")
    if btnTrigger then
      btnTrigger:addListener(function()
        onBtnTriggered(self)
      end)
    end
  end
  return true
end

function advance(self: StepsRamp, dt: number): boolean
  if not self.stepsRef or not self.rampActive then return true end
  self.elapsed = self.elapsed + dt
  local t = math.min(1, self.elapsed / self.duration)
  self.stepsRef.value = self.from + (self.to - self.from) * t
  if self.elapsed >= self.duration then
    self.rampActive = false
  end
  return true
end

return function(): Node<StepsRamp>
  return {
    stepsRef = nil,
    elapsed = 0,
    duration = 1,
    from = 3000,
    to = 6000,
    rampActive = false,
    init = init,
    advance = advance,
  }
end
