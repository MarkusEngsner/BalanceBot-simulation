X = 1
Y = 2
Z = 3

function speedChange_callback(ui,id,newVal)
    speed=minMaxSpeed[1]+(minMaxSpeed[2]-minMaxSpeed[1])*newVal/100
end

function sysCall_init()
    -- This is executed exactly once, the first time this script is executed
    print('in init...')
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
end

function y_angle(acceleration)
    local angle = math.atan(acceleration[Z] / acceleration[Y])
    return angle
end

function sysCall_actuation()
    data = simGetStringSignal("accelerometerData")
    if (data) then
        acceleration = sim.unpackFloatTable(data)
    end
    if (acceleration) then
        acc_z = acceleration[3]
        simSetGraphUserData(graphHandle, "accelX", acceleration[1])
        simSetGraphUserData(graphHandle, "accelY", acceleration[2])
        simSetGraphUserData(graphHandle, "accelZ", acceleration[3])
        angle_y = y_angle(acceleration)
        --simSetUIButtonLabel(ui, 3, string.format("Angle_Y: %.4f", angle_y))
    end
    counter = counter + 1
    if (counter == 100) then
        print(acc_z)
        counter = 0
    end

    max_acc = 10
    max_speed = 500
    speed = acc_z / max_acc * max_speed
    if (acc_z > 0) then
        sim.setJointTargetVelocity(leftMotor, -speed)
        sim.setJointTargetVelocity(rightMotor, -speed)
    else
        sim.setJointTargetVelocity(leftMotor, speed)
        sim.setJointTargetVelocity(rightMotor, speed)
    end


end

function sysCall_cleanup()
	simUI.destroy(ui)
end

