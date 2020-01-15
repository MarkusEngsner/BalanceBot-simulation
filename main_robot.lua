require "pid_class"
X = 1
Y = 2
Z = 3
ACCELEROMETER_ANGLE_OFFSET = math.pi / 2
SAVED_ERRORS = 10 -- size of error array used for calculating D term

function speedChange_callback(ui,id,newVal)
    new_setpoint = newVal / 100 * max_angle
    pid:setSetpoint(new_setpoint)
    --speed=minMaxSpeed[1]+(minMaxSpeed[2]-minMaxSpeed[1])*newVal/100
end

function sysCall_init()
    -- This is executed exactly once, the first time this script is executed
    robBase=sim.getObjectAssociatedWithScript(sim.handle_self) -- this is bubbleRob's handle
    leftMotor=sim.getObjectHandle("motor_left") -- Handle of the left motor
    rightMotor=sim.getObjectHandle("motor_right") -- Handle of the right motor
    minMaxSpeed={50*math.pi/180,300*math.pi/180} -- Min and max speeds for each motor
    backUntilTime=-1 -- Tells whether bubbleRob is in forward or backward mode
    -- Create the custom UI:
        xml = '<ui title="'..sim.getObjectName(robBase)..' speed" closeable="false" resizeable="false" activate="false">'..[[
        <hslider minimum="-100" maximum="100" onchange="speedChange_callback" id="1"/>
        <label text="" style="* {margin-left: 300px;}"/>
        </ui>
        ]]
    ui=simUI.create(xml)
    --ui=simGetUIHandle('MainUI_UI')
    speed=(minMaxSpeed[1]+minMaxSpeed[2])*0.5
    simUI.setSliderValue(ui,1,100*(speed-minMaxSpeed[1])/(minMaxSpeed[2]-minMaxSpeed[1]))
    graphHandle=simGetObjectHandle("acc_graph")
    acc_z = 0
    counter = 0
    angle_gyro = 0


    curr_time = 0
    prev_time = sim.getSimulationTime()


    last_errors = {}
    for i=0, SAVED_ERRORS do
        -- a[i] = 0
    end

    pid = ControlSystem:new{}
    print(pid.kI)
    pid.kP = 1
    pid.kI = .5
    pid.kD = 0.5
    pid.set_point = 0.0
    max_angle = math.rad(20)
end

function moveErrorTerms(new_error)
    for i=0, SAVED_ERRORS - 1 do
        last_errors[i + 1] = last_errors[i]
    end
    last_errors[0] = new_error

end


function getSensorData(stringSignalName)
    data = simGetStringSignal(stringSignalName)
    if (data) then
        return sim.unpackFloatTable(data)
    else
        return {0, 0, 0}
    end
end

function isNan(x)
    return x ~= x
end

function calculateDeriviate(error_array, averaged_values)
    sum = 0
    for i=0,averaged_values do
        sum = sum + error_array[i]
    end
    new_error = sum / averaged_values
    sum = 0
    for i=SAVED_ERRORS-averaged_values,SAVED_ERRORS do
        sum = sum + error_array[i]
    end
    old_error = sum / averaged_values
    -- timestep has to be considered somehow - store time vals?
    return 0
end

function sysCall_actuation()
    set_point = 0
    acceleration = getSensorData("accelerometerData")
    gyroData = getSensorData("gyroscopeData")
    simSetGraphUserData(graphHandle, "accelX", acceleration[1])
    simSetGraphUserData(graphHandle, "accelY", acceleration[2])
    simSetGraphUserData(graphHandle, "accelZ", acceleration[3])
    angle_accelerometer = math.atan(acceleration[Z] / -acceleration[Y]) 


    curr_time = sim.getSimulationTime()
    dt = curr_time - prev_time -- Time increase in ms
    angle_gyro = angle_gyro + (gyroData[X] * dt / 1)


    max_speed = -10000

    --angle = angle_gyro * 0.75 + angle_accelerometer * 0.25
    angle = angle_gyro

    pid:setPV(angle, dt)
    y = pid:getControlVariable()
    speed = y * max_speed

    -- error_term = set_point - angle
    -- moveErrorTerms(error_term)
    -- D = calculateDeriviate(saved_errors)
    -- add D term: save ten last values, avg 3 last and 3 third, then compare difference
    -- add I term
    -- speed = math.min(error_term / 1 * max_speed)
    if (counter == 0) then
        print("Gyro: "..angle_gyro)
        print("Acce: "..angle_accelerometer)
        print("Angle: "..angle)
        --print("Error:"..error_term)
        print("Speed: "..speed)
        print("")
        counter = 200
    end
    counter = counter - 1
    if (not isNan(speed)) then
        sim.setJointTargetVelocity(rightMotor, speed)
        sim.setJointTargetVelocity(leftMotor, speed)
    end

    prev_time = curr_time
end

function sysCall_cleanup()
	simUI.destroy(ui)
end

