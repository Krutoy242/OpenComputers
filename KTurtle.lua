-- ********************************************************************************** --
-- **                                                                              ** --
-- **   Krutoy Turtle Wrapper                                                      ** --
-- **   ----------------------------------------------------                       ** --
-- **                                                                              ** --
-- **   Wrap standart turtle functions but monitoring position and orientation     ** --
-- **   To get turtle pos and orient use Turtle.pos and Turtle.orient              ** --
-- **                                                                              ** --
-- **   ----------------------------------------------------                       ** --
-- **   Most of code was used from "OreQuarry" from AustinKK                       ** --
-- **                                                                              ** --
-- ********************************************************************************** --

-- Enumeration to store names for the 6 directions
local way = { FORWARD=0, RIGHT=1, BACK=2, LEFT=3, UP=4, DOWN=5 }
local lastMoveNeededDig
local maximumGravelStackSupported = 26

-- Global Turtle variable
Turtle = {}
Turtle.__index = Turtle

-- Variables to store the current location and orientation of the turtle. x is right, left, z is up, down and
-- y is forward, back with relation to the starting orientation. 
Turtle.orient = way.FORWARD

Turtle.pos = vector.new() -- Start Pos is 0,0,0

local surround = {
[way.FORWARD] = vector.new( 0, 1, 0),
[way.RIGHT]   = vector.new( 1, 0, 0),
[way.BACK]    = vector.new( 0,-1, 0),
[way.LEFT]    = vector.new(-1, 0, 0),
[way.UP]      = vector.new( 0, 0, 1),
[way.DOWN]    = vector.new( 0, 0,-1)
}


-- ********************************************************************************** --
-- Sets the turtle to a specific orientation, irrespective of its current orientation
-- ********************************************************************************** --
function Turtle.setOrient(newOrient)

  -- Already turned
  if (Turtle.orient == newOrient) then return true end


  -- Wrong parameters - we cant turn up or down
  if newOrient < 0 or newOrient > way.LEFT then
    error("Invalid newOrient in Turtle.setOrient function")
    return false
  end
  
  local turn = Turtle.orient - newOrient
  local turnFnc
  
  if turn==1 or turn==-3 then
    turnFnc = turtle.turnLeft
  else
    turnFnc = turtle.turnRight
  end
  
  turn = math.abs(turn)
  if(turn==3) then turn=1 end

  Turtle.orient = newOrient
  

  for i=1, turn do
    turnFnc()
  end
  
  return true
end

--===========================================================
-- Dig, depending on direction
--===========================================================
function Turtle.dig(direction)
  direction = direction or way.FORWARD -- Optional param
  
  if(direction ~= way.DOWN and direction ~= way.UP and direction ~= way.FORWARD) then
    error('Wrong params in Turtle.dig()')
    return false
  end
  
  local digFnc = {[way.FORWARD]=turtle.dig, [way.DOWN]=turtle.digDown, [way.UP]=turtle.digUp}
  
  return digFnc[direction]()
end
 
-- ********************************************************************************** --
-- Generic function to move the Turtle (pushing through any gravel or other
-- things such as mobs that might get in the way).
--
-- The only thing that should stop the turtle moving is bedrock. Where this is
-- found, the function will return after 15 seconds returning false
-- ********************************************************************************** --
function Turtle.move(moveFn, detectFn, digFn, attackFn, compareFn, suckFn, maxDigCount, newX, newY, newZ)
 
  local moveSuccess = false
 

  -- Flag to determine whether digging has been tried yet. If it has
  -- then pause briefly before digging again to allow sand or gravel to drop
  local digCount = 0
 
  if (lastMoveNeededDig == false) then
    -- Didn't need to dig last time the turtle moved, so try moving first
  
    moveSuccess = moveFn()
 
    if (moveSuccess == true) then
      Turtle.pos.x = newX
      Turtle.pos.y = newY
      Turtle.pos.z = newZ
    end
  else 
    -- Try to dig (without doing a detect as it is quicker)
    local digSuccess = digFn()
    if (digSuccess == true) then
      digCount = 1
    end
 
    moveSuccess = moveFn()
 
    if (moveSuccess == true) then
      lastMoveNeededDig = digSuccess
      Turtle.pos.x = newX
      Turtle.pos.y = newY
      Turtle.pos.z = newZ
    end
 
  end
 
  -- Loop until we've successfully moved
  if (moveSuccess == false) then
    while ((moveSuccess == false) and (digCount < maxDigCount)) do
 
        -- If there is a block in front, dig it
      if (detectFn() == true) then
     
        -- If we've already tried digging, then pause before digging again to let
        -- any sand or gravel drop, otherwise check for a chest before digging
        if(digCount ~= 0) then
          sleep(0.1)
        end
 
        digFn()
        digCount = digCount + 1
      else
       -- Am being stopped from moving by a mob, attack it
       attackFn()
      end
      
      -- Try the move again
      moveSuccess = moveFn()
 
      if (moveSuccess == true) then
        Turtle.pos.x = newX
        Turtle.pos.y = newY
        Turtle.pos.z = newZ
      end
    end
 
    if (digCount == 0) then
      lastMoveNeededDig = false
    else
      lastMoveNeededDig = true
    end
  end
 
  -- Return the move success
  return moveSuccess
end

-- ********************************************************************************** --
-- Get relativety position from direction of turtle
-- ********************************************************************************** --
function Turtle.getRelativeCoord(direct)

  local irrespectiveOrient -- New irrespective orientation to world
  
  if direct == way.UP or direct == way.DOWN then
    irrespectiveOrient = direct
  else
    irrespectiveOrient = (Turtle.orient + direct)%4
  end
  
  -- Return direction with displace
  return Turtle.pos + surround[irrespectiveOrient]
end


-- ********************************************************************************** --
-- Move the turtle forward one block (updating the turtle's position)
-- ********************************************************************************** --
function Turtle.forward()

  -- Determine the new co-ordinate that the turtle will be moving to
  local newX, newY
  
  -- Update the current co-ordinates
  if (Turtle.orient == way.FORWARD) then
    newY = Turtle.pos.y + 1
    newX = Turtle.pos.x
  elseif (Turtle.orient == way.LEFT) then
    newX = Turtle.pos.x - 1
    newY = Turtle.pos.y
  elseif (Turtle.orient == way.BACK) then
    newY = Turtle.pos.y - 1
    newX = Turtle.pos.x
  elseif (Turtle.orient == way.RIGHT) then
    newX = Turtle.pos.x + 1
    newY = Turtle.pos.y
  end
 
  local returnVal = Turtle.move(turtle.forward, turtle.detect, turtle.dig, turtle.attack, turtle.compare, turtle.suck, maximumGravelStackSupported, newX, newY, Turtle.pos.z)

 
  return returnVal
end

-- ********************************************************************************** --
-- Move the turtle up one block (updating the turtle's position)
-- ********************************************************************************** --
function Turtle.up()
  local  returnVal = Turtle.move(turtle.up, turtle.detectUp, turtle.digUp, turtle.attackUp, turtle.compareUp, turtle.suckUp, maximumGravelStackSupported, Turtle.pos.x, Turtle.pos.y, Turtle.pos.z + 1)
  return returnVal
end
 
-- ********************************************************************************** --
-- Move the turtle down one block (updating the turtle's position)
-- ********************************************************************************** --
function Turtle.down()
  local  returnVal = Turtle.move(turtle.down, turtle.detectDown, turtle.digDown, turtle.attackDown, turtle.compareDown, turtle.suckDown, 1, Turtle.pos.x, Turtle.pos.y, Turtle.pos.z - 1)
  return returnVal
end
 
-- ********************************************************************************** --
-- Move the turtle back one block (updating the turtle's position)
-- ********************************************************************************** --
function Turtle.back(doNotTurnBack)
 
  -- Assume that the turtle will move, and switch the co-ords back if it doesn't
  -- (do this so that we can write the co-ords to a file before moving)
  local newX, newY
 
  -- Update the current co-ordinates
  if (Turtle.orient == way.FORWARD) then
    newY = Turtle.pos.y - 1
    newX = Turtle.pos.x
  elseif (Turtle.orient == way.LEFT) then
    newX = Turtle.pos.x + 1
    newY = Turtle.pos.y
  elseif (Turtle.orient == way.BACK) then
    newY = Turtle.pos.y + 1
    newX = Turtle.pos.x
  elseif (Turtle.orient == way.RIGHT) then
    newX = Turtle.pos.x - 1
    newY = Turtle.pos.y
  end
 
  -- First try to move back using the standard function
  local returnVal = turtle.back()
 
  if (returnVal == false) then 
    turtle.turnRight()
    turtle.turnRight()
 
    -- Try to move by using the forward function (note, the orientation will be set as
    -- the same way as this function started because if the function stops, that is the
    -- way that we want to consider the turtle to be pointing)
    returnVal = Turtle.move(turtle.forward, turtle.detect, turtle.dig, turtle.attack, turtle.compare, turtle.suck, maximumGravelStackSupported, newX, newY, Turtle.pos.z)
 
    if doNotTurnBack ~= true then
      turtle.turnRight()
      turtle.turnRight()
    end
  else  
    Turtle.pos.x = newX
    Turtle.pos.y = newY
  end
   
  return returnVal
end

--===========================================================
-- Find path to coordinates, avoid block listed cells
-- Using A* algorithm http://pastebin.com/CHCB8nDz
--===========================================================
function Turtle.pathTo(world,_x,_y,_z)

  -- Get first crumb of path
  local crumb = AStarFindPath(world, Turtle.pos, vector.new(_x,_y,_z))
  
  if crumb then
    -- Run over all crumbs 
    while crumb.next ~= nil do
      crumb = crumb.next
      Turtle.goTo(crumb.pos)
    end
  else
    -- Path can be found. Move straight
    Turtle.goTo(_x,_y,_z)
  end
  
end

--===========================================================
-- Move turtle on needed position
-- Simple move by x, then y, then z 
-- args can be vector or three parameters x,y,z
--===========================================================
function Turtle.goTo(_x,_y,_z)
  local x,y,z
  
  -- Overload to working with vectors
  if type(_x) ~= 'number' and _x ~= nil then
    if _x.x and _x.y and _x.z then
      x,y,z = _x.x, _x.y, _x.z
    else
      error('Wrong Turtle.goTo() params')
    end
  else
    x,y,z = _x,_y,_z
  end

  -- If param undefined, leave it unchanged
  if not x then x=Turtle.pos.x end
  if not y then y=Turtle.pos.y end
  if not z then z=Turtle.pos.z end

  local targetVec = vector.new(x,y,z) - Turtle.pos
  

  -- X
  if (targetVec.x<0 and Turtle.orient==way.RIGHT)   or
     (targetVec.x>0 and Turtle.orient==way.LEFT)    then
     while Turtle.pos.x ~= x do
       Turtle.back(true)
     end
  end
  
  while (x<Turtle.pos.x) do
    Turtle.setOrient(way.LEFT)
    Turtle.forward()
  end
  while (x>Turtle.pos.x) do
    Turtle.setOrient(way.RIGHT)
    Turtle.forward()
  end
  
  
  -- Y
  if(targetVec.y<0 and Turtle.orient==way.FORWARD) or
    (targetVec.y>0 and Turtle.orient==way.BACK)    then
     while Turtle.pos.y ~= y do
       Turtle.back(true)
     end
  end
  
  while (y<Turtle.pos.y) do
    Turtle.setOrient(way.BACK)
    Turtle.forward()
  end
  while (y>Turtle.pos.y) do
    Turtle.setOrient(way.FORWARD)
    Turtle.forward()
  end
  
  
  -- Z
  while (z<Turtle.pos.z) do
    Turtle.down()
  end
  while (z>Turtle.pos.z) do
    Turtle.up()
  end
end

-- ********************************************************************************** --
-- Select non-empty slot
-- ********************************************************************************** --
function Turtle.selectNonEmptySlot()
  for i=1, 16 do
    if( turtle.getItemCount(i) > 0) then
      turtle.select(i)
      return true
    end
  end
  return false
end

-- ********************************************************************************** --
-- Place item in front of turtle. Check if item already placed.
-- ********************************************************************************** --
function Turtle.place(itemSlot, direction)
  
  local detectFnc, compareFnc, placeFnc, attackFnc =
        turtle.detect, turtle.compare, turtle.place,turtle.attack
  
  if( direction == way.UP ) then
    detectFnc, compareFnc, placeFnc, attackFnc =
    turtle.detectUp, turtle.compareUp, turtle.placeUp, turtle.attackUp
  elseif( direction == way.DOWN )then
    detectFnc, compareFnc, placeFnc, attackFnc =
    turtle.detectDown, turtle.compareDown, turtle.placeDown, turtle.attackDown
  end
  
  -- slotsPattern is array of 16 nubbers that represent
  -- what kind of blocks lying in what kind of
  if(itemSlot == nil) then
    Turtle.selectNonEmptySlot()
  else
    turtle.select(itemSlot)
  end
  
  local placeSucces = false
  local digCount = 0
  local maxDigCount = 20

  
  -- Check if there is already item  then try to place
  placeSucces = placeFnc()
  
  if((not placeSucces) and detectFnc()) then
    if(compareFnc()) then
      -- Item that we must set already here
      return true
    else
      -- There is something else. Dig/Attack and place item
      Turtle.dig(direction)
      digCount = digCount + 1
    end
  end
  
  -- Now try to place item until item will placed
  while ((placeSucces == false) and (digCount < maxDigCount)) do
    if (detectFnc()) then
      if(digCount > 0) then
        sleep(0.1)
      end
      Turtle.dig(direction)
      digCount = digCount + 1
    else
       -- Am being stopped from moving by a mob, attack it
       attackFnc()
    end
    -- Try the place again
    placeSucces = placeFnc()
  end
  
  return placeSucces
end