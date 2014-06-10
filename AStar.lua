-- ********************************************************************************** --
-- **                                                                              ** --
-- **   A-Star algorithm for 3d dimensional volume                                 ** --
-- **                                                                              ** --
-- **   http://en.wikipedia.org/wiki/A*_search_algorithm                           ** --
-- **   ----------------------------------------------------                       ** --
-- **                                                                              ** --
-- **   Developed to use in program "KrutoyTurtle"                                 ** --
-- **     http://pastebin.com/YxWNp5bZ                                             ** --
-- **                                                                              ** --
-- ********************************************************************************** --

local abs   = math.abs
local pairs = pairs
local floor = math.floor
local time  = os.time

-- Heuristic estimate. Notice that moving by Z axis is easyest
local function heuristic_cost_estimate(p1,p2)
  return abs(p1.x-p2.x) + abs(p1.y-p2.y)*0.999 + abs(p1.z-p2.z)*0.998
end

-- ********************************************************************************** --
-- **                         Utils                                                ** --
-- ********************************************************************************** --

local function CopyArray(source, destination)
  local index
  for k,v in pairs(source) do
      destination[k] = v
  end
end

local function New3dArray(w,h,d, value)
  local arr = {}
  
  for z=0,d-1 do
    arr[z] = {}
    for y=0,h-1 do
      arr[z][y] = {}
      if value ~= nil then
        for x=0,w-1 do
          arr[z][y][x] = value
        end
      end
    end
  end
  
  arr.size = {d,h,w}
  arr.GetLength = function(self, dimension) return self.size[dimension+1] end
  
  return arr
end

local chtime=time()
local function checktime()
  if not chtime then chtime=time() end
  local ntime=time()
  if ntime-chtime>0.05 then
    sleep(0)
    chtime=ntimr
  elseif ntime-chtime<0 then
    sleep(0)
    chtime=ntime
  end
end

-- ********************************************************************************** --
-- **                            BreadCrumb                                        ** --
-- ********************************************************************************** --

BreadCrumb = {}
BreadCrumb.__index = BreadCrumb

function BreadCrumb.new(x,y,z, parent)
  local self = setmetatable({}, BreadCrumb)
  self.pos = vector.new(x,y,z)
  self.next = parent
  self.cost = math.huge
  self.onClosedList = false
  self.onOpenList = false
  return self
end

function BreadCrumb:Equals(breadcrumb)
    return breadcrumb.pos.x == self.pos.x and breadcrumb.pos.y == self.pos.y and breadcrumb.pos.z == self.pos.z
end

function BreadCrumb:GetHashCode()
    return self.pos.GetHashCode()
end

function BreadCrumb:CompareTo(other)
  if self.cost>other.cost then 
    return 1 
  elseif self.cost<other.cost then 
    return -1 
  else 
    return 0 
  end
end

-- ********************************************************************************** --
-- **                           MinHeap                                            ** --
-- ********************************************************************************** --
MinHeap = {}
MinHeap.__index = MinHeap


function MinHeap.new(_capacity)
  local self = setmetatable({}, MinHeap)
  self.count = 0
  self.capacity = _capacity
  self.array = {}
  self.temp  = nil
  self.mheap = nil
  self.tempArray = nil
  return self
end 

function MinHeap:DoubleArray()
  self.capacity = bit.blshift(self.capacity, 1)
  self.tempArray = {}
  CopyArray(self.array, self.tempArray)
  self.array = self.tempArray
end

function MinHeap:Add(item)
  self.count = self.count+1
  if self.count > self.capacity then
      self:DoubleArray()
  end
  self.array[self.count - 1] = item
  local pos = self.count - 1

  local parentPosition = floor((pos - 1)/2)

  while pos > 0 and self.array[parentPosition]:CompareTo(self.array[pos]) > 0 do
      self.temp = self.array[pos]
      self.array[pos] = self.array[parentPosition]
      self.array[parentPosition] = self.temp
      pos = parentPosition
      parentPosition = floor((pos - 1)/2)
  end
end   
  
function MinHeap:ExtractFirst()
  if self.count == 0 then
      error("Heap is empty")
  end
  self.temp = self.array[0]
  self.array[0] = self.array[self.count - 1]
  self.count = self.count - 1
  self:MinHeapify(0)
  return self.temp
end

function MinHeap:MinHeapify(pos)
  while true do
    local left = pos*2 + 1
    local right = left + 1
    local minPosition

    if left < self.count and self.array[left]:CompareTo(self.array[pos]) < 0 then
        minPosition = left
    else
        minPosition = pos
    end

    if right < self.count and self.array[right]:CompareTo(self.array[minPosition]) < 0 then
        minPosition = right
    end

    if minPosition ~= pos then
        self.mheap = self.array[pos]
        self.array[pos] = self.array[minPosition]
        self.array[minPosition] = self.mheap
        pos = minPosition
    else
        return
    end

  end
end

-- ********************************************************************************** --
-- **                                  World                                       ** --
-- ********************************************************************************** --

World = {}
World.__index = World

function World.new(width, height, depth)
  local self = setmetatable({}, World)
  self.blocked = New3dArray(width, height, depth, nil)
  return self
end

function World:SizeZ () return self.blocked:GetLength(0) end
function World:SizeY () return self.blocked:GetLength(1) end
function World:SizeX () return self.blocked:GetLength(2) end

-- Checks if a pos is free or marked (and legal)
-- return true if the pos is free
function World:PositionIsFree(x,y,z)
    return x >= 0 and x < self:SizeX () and
           y >= 0 and y < self:SizeY   () and
           z >= 0 and z < self:SizeZ  () and
           self.blocked[z][y][x] == nil
end

-- ********************************************************************************** --
-- **                          Path Finder                                         ** --
-- ********************************************************************************** --

-- Neigtbours of current point
local surrounding = {
  vector.new( 1,0,0), vector.new(0, 1,0), vector.new(0,0, 1), 
  vector.new(-1,0,0), vector.new(0,-1,0), vector.new(0,0,-1)
}

-- Method that switfly finds the best path from p_start to end. Doesn't reverse outcome
-- The p_end breadcrump where each .next is a step back
function FindPathReversed(world, p_start, p_end)
  local openList = MinHeap.new(256)
  local brWorld  = New3dArray(world:SizeX(), world:SizeY(), world:SizeZ(), nil)
  local node
  local cost
  local diff
 
  local current= BreadCrumb.new(p_start.x,p_start.y,p_start.z)
  current.cost = 0

  local finish = BreadCrumb.new(p_end.x,p_end.y,p_end.z)
  brWorld[current.pos.z][current.pos.y][current.pos.x] = current
  openList:Add(current)

  while openList.count > 0 do
    --Find best item and switch it to the 'closedList'
    current = openList:ExtractFirst()
    current.onClosedList = true

    --Find neighbours
    for k,v in pairs(surrounding) do
      local tmpX,tmpY,tmpZ = current.pos.x + v.x, current.pos.y + v.y, current.pos.z + v.z
      if world:PositionIsFree(tmpX,tmpY,tmpZ) then
        --Check if we've already examined a neighbour, if not create a new node for it.
        if brWorld[tmpZ][tmpY][tmpX] == nil then
          node = BreadCrumb.new(tmpX,tmpY,tmpZ)
          brWorld[tmpZ][tmpY][tmpX] = node
        else
          node = brWorld[tmpZ][tmpY][tmpX]
        end
        
        --If the node is not on the 'closedList' check it's new score, keep the best
        if node.onClosedList == false then
        
          diff = 0
          if current.pos.x ~= node.pos.x then diff = diff+1 end
          if current.pos.y ~= node.pos.y then diff = diff+1 end
          if current.pos.z ~= node.pos.z then diff = diff+1 end
          
          cost = current.cost + diff + heuristic_cost_estimate(node.pos,p_end)

          if cost < node.cost then
            node.cost = cost
            node.next = current
          end

          --If the node wasn't on the openList yet, add it 
          if node.onOpenList == false then
            --Check to see if we're done
            if node:Equals(finish) == true then
              node.next = current
              return node
            end
            node.onOpenList = true
            openList:Add(node)
          end         
        end
      end
    end
    
    checktime() -- Check yelding time for computerCraft
  end
  
  return nil --no path found
end

-- Method that switfly finds the best path from p_start to end.
-- The starting breadcrumb traversable via .next to the end or nil if there is no path
function AStarFindPath(world, p_start, p_end)
    -- note we just flip p_start and end here so you don't have to.            
    return FindPathReversed(world, p_end, p_start)
end

-- ********************************************************************************** --
-- **                              Usage                                           ** --
-- ********************************************************************************** --

--[[--

-- Create new world as 3d array, filled by nil's. sizes by X,Y,Z
local world = World.new(10,10,10)  

-- Block a cell, make it impassable. Indexes from [0]
-- Indexes is [z][y][x]
world.blocked[0][3][9] = true

local p_start = vector.new()      -- Start point.
local p_end   = vector.new(7,8,9) -- End point

-- Main path find function
-- Return the first bread crumb of path
local crumb = AStarFindPath(world, p_start, p_end)

if crumb == nil then
  print('Path not found')
else
  print('Start: ' .. crumb.pos.x..","..crumb.pos.y..","..crumb.pos.z)
  
  -- BreadCrumbs is connected list. To get next point in path use crumb.next
  while crumb.next ~= nil do
    crumb = crumb.next
    print('Route: '.. crumb.pos.x..","..crumb.pos.y..","..crumb.pos.z)
  end
  
  print('Finish: ' .. crumb.pos.x..","..crumb.pos.y..","..crumb.pos.z)
end

--]]--