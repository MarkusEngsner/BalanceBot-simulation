X = 1
Y = 2
Z = 3
ACCELEROMETER_ANGLE_OFFSET = math.pi / 2

function speedChange_callback(ui,id,newVal)
    speed=minMaxSpeed[1]+(minMaxSpeed[2]-minMaxSpeed[1])*newVal/100
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
        <hslider minimum="0" maximum="100" onchange="speedChange_callback" id="1"/>
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

function isInf(x)
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
    error_term = set_point - angle
    speed = math.min(error_term / 1 * max_speed)
    if (counter == 0) then
        print("Gyro: "..angle_gyro)
        print("Acce: "..angle_accelerometer)
        print("Angle: "..angle)
        print("Error:"..error_term)
        print("Speed: "..speed)
        print("")
        counter = 200
    end
    counter = counter - 1
    if (not isNan(speed) and not isInf(speed)) then
        sim.setJointTargetVelocity(leftMotor, speed)
        sim.setJointTargetVelocity(rightMotor, speed)
    end


    prev_time = curr_time
end

function sysCall_cleanup()
	simUI.destroy(ui)
end

