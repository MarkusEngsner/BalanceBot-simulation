ControlSystem = { kP = 1, kI = 1, kD = 1, set_point = 0, process_variable = 0,
                  P = 0, I = 0, D = 0, error_val = 0, last_error = 0, time = 1
}

function ControlSystem:calculateErrorValue()
    self.last_error = self.error_val
    self.error_val = self.set_point - self.process_variable
end

function ControlSystem:setSetpoint(new_setpoint)
    -- todo: adjust all variables if setpoint changes
    self.set_point = new_setpoint
end

function ControlSystem:calculateProportional()
    self.P = error_val
end

function ControlSystem:calculateIntegral()
    if (self.last_error < 0 and self.error_val > 0) or
    (self.last_error > 0 and self.error_val < 0) then
        self.I = 0
    end
    self.I = self.I + self.error_val
end

function ControlSystem:calculateDeriviate()
    self.D = (self.error_val - self.last_error) / self.time
end

function ControlSystem:setPV(measurement, timing_interval)
    -- sets latest ProcessValue
    -- measurement: number, the latest measured value
    -- timing_interval: time since last measurement
    self.process_variable = measurement
    self.time = timing_interval
    -- add into latest ten values
end

function ControlSystem:getControlVariable()
    -- returns the weighted output u(t)
    self:calculateErrorValue()
    self:calculateProportional()
    self:calculateIntegral()
    self:calculateDeriviate()
    y = self.P * self.kP + self.I * self.kI + self.D * self.kD
    return y
end

function ControlSystem:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--controller = ControlSystem:new{}
-- print(controller.kI)
