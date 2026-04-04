--------------MADE BY Radioaktiivinen
--------------Should be configurable with some crappy configuration tool of roblox >_>
local seat=script.Parent
local data=seat.Configuration
local owner=nil
local running=false
local x=0
local y=0

seat.ChildAdded:connect(
function(w)
if w.className=="Weld" and w.Name=="SeatWeld" then
local char=w.Part1.Parent
local player=game.Players:FindFirstChild(char.Name)
if player~=nil then
owner=player
seat.ChildRemoved:connect(
function(w2)
if w2==w then
owner=nil
end
end
)
seat.BodyVelocity.maxForce=Vector3.new(1,1,1)*data.MaxForce.Value
seat.BodyGyro.maxTorque=Vector3.new(1,1,1)*50000
local spd=0
local gui=seat.ScreenGui:clone()
gui.Parent=player.PlayerGui
gui.Frame.Faster.MouseButton1Click:connect(
function()
spd=math.min(spd+data.MaxSpeed.Value/20,data.MaxSpeed.Value)
gui.Frame.Speed.Text=math.floor(spd)
end
)
gui.Frame.Slower.MouseButton1Click:connect(
function()
spd=math.max(spd-data.MaxSpeed.Value/20,0)
gui.Frame.Speed.Text=math.floor(spd)
end
)
while owner==player do
seat.BodyVelocity.velocity=seat.CFrame.lookVector*spd
wait()
end
gui:remove()
seat.BodyVelocity.velocity=Vector3.new(0,0,0)
seat.BodyVelocity.maxForce=Vector3.new(0,0,0)
seat.BodyGyro.maxTorque=Vector3.new(0,0,0)
end
end
end
)

seat.Changed:connect(
function()
if not running then
local cur=seat.Steer
local cur2=seat.Throttle
running=true
while (cur~=0 or cur2~=0) do
y=y-seat.Steer*data.TurnSpeed.Value
x=x-seat.Throttle*data.TurnSpeed.Value
seat.BodyGyro.cframe=CFrame.new(0,0,0)*CFrame.Angles(0,math.rad(y),0)*CFrame.Angles(math.rad(x),0,0)
wait()
end
running=false
end
end
)