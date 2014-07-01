-- ********************************************************************************** --
-- **                                                                              ** --
-- **   Krutoy Turtle   (debug version)                                            ** --
-- **   ----------------------------------------------------                       ** --
-- **                                                                              ** --
-- **   To start program, write in turte:                                          ** --
-- **                                                                              ** --
-- **    For stable version:                                                       ** --
-- **   pastebin get YxWNp5bZ KrutoyTurtle                                         ** --
-- **                                                                              ** --
-- **    For developing version                                                    ** --
-- **   pastebin get GHUv2MCR KrutoyTurtle                                         ** --
-- **                                                                              ** --
-- **   ----------------------------------------------------                       ** --
-- **   Thanks for this peoples, i use theirs code:                                ** --
-- **    - AustinKK (OreQuarry Turtle)                                             ** --
-- **    - NitrogenFingers (NPaintPro)                                             ** --
-- **                                                                              ** --
-- ********************************************************************************** --


------------------------------------------------------
-- Fun                                              --
------------------------------------------------------

--[[

    ____
\  /o o \  /
 \|  ~   |/
   \____/


 ,+---+
+---+'| z=9999
|^_^| +
+---+' y=9999
 x=9999

]]

------------------------------------------------------
-- Filling function variables                       --
------------------------------------------------------

-- Main patterns, using in fill() function
--  Numbers tell what the count block will be placed
--  Exists: fillPattern[name][z][y][x]
--  [space]: here will no block
--  0: remove block here
fillPattern = {
  ['Plain'] =
  { {'1'} },
  ['BoxGrid'] =
   {{'3222';
     '2111';
     '2111';
     '2111';},
    {'2111';
     '1   ';
     '1   ';
     '1   ';},
    {'2111';
     '1   ';
     '1   ';
     '1   ';},
    {'2111';
     '1   ';
     '1   ';
     '1   ';}}
}


fillingFlags = {
  'sides',          -- Making boxes without corners
  'corners',        -- Making frames
  'mirror',         -- Pattern texture will mirrored
  'mirror -1',      -- Each mirrored pattern indexes will shif by one block
  'mirror -1x',
  'mirror -1y',
  'mirror -1z',
  'y->',            -- Build first x-z blocks, then go to next y layer
  'x++', 'x--',     -- Shift next coord. Userful for stairs
  'y++', 'y--',
  'z++', 'z--',
  'clear',          -- Replaces all pattern indexes to -1
  'clearAllSkipped',-- Replaces all 0 to -1
  'skipClearing',   -- Replaces all -1 to 0
  'tunnel', 'tube'  -- tunnel without caps on start end end
}


------------------------------------------------------
-- Other variables                                  --
------------------------------------------------------

--A list of hexidecimal conversions from numbers to hex digits
local hexnums = { [10] = "a", [11] = "b", [12] = "c", [13] = "d", [14] = "e" , [15] = "f" }

-- Enumeration to store the the different types of message that can be written
messageLevel = { DEBUG=0, INFO=1, WARNING=2, ERROR=3, FATAL=4 }

-- Enumeration to store names for the 6 directions
local way = { FORWARD=0, RIGHT=1, BACK=2, LEFT=3, UP=4, DOWN=5 }


local maximumGravelStackSupported = 25 -- The number of stacked gravel or sand blocks supported
local turtleId -- For rednet
local isWirelessTurtle
local logFileName = "KrutoyTurtle.log"
 

-- ********************************************************************************** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                Utilities                                     ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- ********************************************************************************** --

--===========================================================
-- Make keys from values
--===========================================================
local function makeSet (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

--===========================================================
-- Clear screen and set cursor to start
--===========================================================
local function clear()
   term.clear()
   term.setCursorPos (1,1)
end


--===========================================================
-- Waiting untill user press key
--===========================================================
local function pressAnyKey()
  local event, param1 = os.pullEvent ("key")
end

--===========================================================
-- Writes requestText and wait while user press number key
--===========================================================
local function readNumberParametr(requestText, from, to)
  while true do
     clear()
     print (requestText)
     local event, param1 = os.pullEvent ("char") -- limit os.pullEvent to the char event
     local result = tonumber(param1)
     if type(result) == 'number' and result >= from and result <= to then
         return result
     end
  end
end

--===========================================================
-- 
--===========================================================
local function readTable(separator)
  local resultStr = read()
  if resultStr ~= '' then
    local result = {}
    local i=1
    for v in string.gmatch(resultStr, separator) do
      result[i] = v
      i = i+1
    end
    return result
  end
  return nil
end

--===========================================================
-- Writes requestText and wait while user type
-- several words or numbers
--===========================================================
local function readTableRequest(requestText, canBeSkipped, separator)
  local resultStr = ''
 
  while true do
    clear()
    print(requestText)
    resultStr = read()
    if resultStr == '' and canBeSkipped == true then
      return nil
    elseif resultStr ~= '' then
      local result = {}
      local i=1
      for v in string.gmatch(resultStr, separator) do
        result[i] = v
        i = i+1
      end
      return result
    end
  end
end

--===========================================================
-- Writes requestText and wait while user type
-- several numbers
--===========================================================
local function readTableOfNumbers(requestText, canBeSkipped, numbersCount, separator)
  local resultStr = ''
  local result = {}
  for i=1,numbersCount do result[i]=0 end
 
 
  while true do
    local returnedResult = readTableRequest(requestText, canBeSkipped, separator)
   
    if not returnedResult and canBeSkipped == true then
      return result
    elseif(returnedResult)then
      local isAllNumbers = true
      for i=1,numbersCount do
        if(type(tonumber(returnedResult[i])) == "number") then
          result[i] = tonumber(returnedResult[i])
        else
          print(returnedResult[i]..' is not number!')
          sleep(1)
          isAllNumbers=false
        end
      end
     
      if isAllNumbers == true then
        return result
      end
    end
  end
end

--===========================================================
-- Writes requestText and wait while user type
-- several numbers
--===========================================================
local function readNumbersInput(cursorX, cursorY, canBeSkipped, numbersCount, separator)
  local result = {}
  for i=1,numbersCount do result[i]=0 end
  

  while true do
    term.setCursorPos(cursorX, cursorY)
    term.clearLine()
    local returnedResult = readTable(separator)
   
    if not returnedResult and canBeSkipped == true then
      return result
    elseif(returnedResult)then
      local isAllNumbers = true
      for i=1,numbersCount do
        if(type(tonumber(returnedResult[i])) == "number") then
          result[i] = tonumber(returnedResult[i])
        else
          term.write(returnedResult[i]..' is not number!')
          sleep(1)
          isAllNumbers=false
        end
      end
     
      if isAllNumbers == true then
        return result
      end
    end
  end
end

--===========================================================
-- Writes an output message
-- Also, working with rednet
--===========================================================
local function writeMessage(message, msgLevel)
  print(message)

  -- If this turtle has a modem, then write the message to red net
  if (isWirelessTurtle == true) then
    if (turtleId == nil) then
      rednet.broadcast(message)
    else
      -- Broadcast the message (prefixed with the turtle's id)
      rednet.broadcast("[".. turtleId.."] "..message)
      end
    end
 
    if (logFileName ~= nil) then
      -- Open file, write message and close file (flush doesn't seem to work!)
    local outputFile
    if (fs.exists(logFileName) == true) then
      outputFile = io.open(logFileName, "a")
    else
      outputFile = io.open(logFileName, "w")
    end
 
    outputFile:write(message)
    outputFile:write("\n")
    outputFile:close()
  end
end


--===========================================================
-- Reads the next number from a given file
--===========================================================
local function readNumber(inputFile)

  local returnVal
  local nextLine = inputFile.readLine()
  if (nextLine ~= nil) then
    returnVal = tonumber(nextLine)
  end

  return returnVal
end

--===========================================================
-- Reads the next number from a given file
--===========================================================
local function getChar(str, pos)
  return string.sub(str, pos, pos)
end


--===========================================================
-- Converts a hex digit into a colour value
-- Params: hex:?string = the hex digit to be converted
-- Returns:string A colour value corresponding to the hex, or nil if the character is invalid
--===========================================================
local function getColourOf(hex)
  local value = tonumber(hex, 16)
  if not value then return nil end
  value = math.pow(2,value)
  return value
end


--===========================================================
-- Converts a colour parameter into a single-digit hex coordinate for the colour
-- Params: colour:int = The colour to be converted
-- Returns:string A string conversion of the colour
--===========================================================
local function getHexOf(colour)
  if not colour or not tonumber(colour) then
    return " "
  end
  local value = math.log(colour)/math.log(2)
  if value > 9 then
    value = hexnums[value]
  end
  return value
end


--===========================================================
-- Params: path:string = The path in which the file is located
-- Returns:nil
--===========================================================
local function loadNFA(path)
  if fs.exists(path) == false then
    return nil
  end
  
  local frames = { }
  frames[1] = { }
  
  local file = io.open(path, "r" )
  local sLine = file:read()
  local z = 1
  local y = 1
  while sLine do
    if sLine == "~" then
      z = z + 1
      frames[z] = { }
      y = 1
    else
      if not frames[z][y] then frames[z][y]='' end
      for i=1,#sLine do
        frames[z][y] = frames[z][y] .. string.sub(sLine,i,i)
      end
      y = y+1
    end
    sLine = file:read()
  end
  file:close()
  
  return frames
end

--===========================================================
-- Just leave numbers in pattern, if in blacklist is 0
--===========================================================
local function selectPatternByBlacklist(pattern, blacklist)
  local resultPattern = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  for i=1, 16 do
      if(blacklist[i] == 0) then resultPattern[i] = pattern[i] end
  end
  return resultPattern
end

--===========================================================
-- Searching if wee have needed item in inventory
--===========================================================
local function findInSlotsArrayByPattern(arr, n, blacklist)
  blacklist = blacklist or {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  
  -- Set indexes to 0 if blacklist here is 1
  local filteredArr = selectPatternByBlacklist(arr, blacklist)

  for i=1, 16 do
    if(filteredArr[i] == n) and (turtle.getItemCount(i) > 0) then
      return i
    end
  end
  return 0
end


-- ********************************************************************************** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                PROGRAMS                                      ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- ********************************************************************************** --


-- ********************************************************************************** --
-- Go to the storage and suck needed blocks. Storage must be defined
-- ********************************************************************************** --
function reloadForFilling(slotsPattern, blacklistPattern)
  
  local reloadedPattern = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  
  -- Default blacklist. No thrash to drop
  if(blacklistPattern==nil) then blacklistPattern = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} end
  
  -- First, unload blacklisted slotls
  -- This is blocks that we dont using for building
  for i=1, 16 do
    if( blacklistPattern[i] > 0) then
      Turtle.goTo(0,0,0)
      Turtle.setOrient(way.LEFT)
      
      turtle.select(i)
      turtle.drop()
    end
  end
  
  -- Then move to storages and take blocks
  for i=1, 16 do
    local itemSpace = turtle.getItemSpace(i)
    if( itemSpace > 0  and (slotsPattern[i] > 0)) then
      Turtle.goTo((slotsPattern[i]-1)*2, 0, 0)
      Turtle.setOrient(way.BACK)
      turtle.select(i)
      if( turtle.suck(itemSpace) ) then
        -- Yes, we sucked something. Lets write it in pattern
        reloadedPattern[i] = 1
      end
    end
  end
  
  return reloadedPattern
end


-- ********************************************************************************** --
-- Get slot pattern.
-- Returning array(16) that represent indexes in slots
-- ********************************************************************************** --
function getSlotsPattern()
  local ptattern = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- Standart pattern. All slots empty
  local lastUnemptySlot = 0
  local lastEnum = 1
  
  for i=1, 16 do
    turtle.select(i)
    if( turtle.getItemCount(i) > 0) then
      if (lastUnemptySlot == 0) then
        lastUnemptySlot = i
      elseif (i>1) and (turtle.compareTo(lastUnemptySlot) == false) then
        lastEnum = lastEnum + 1
        lastUnemptySlot = i
      end
      
      ptattern[i] = lastEnum
    end
  end
  return ptattern
end


-- ********************************************************************************** --
-- Fill territory by blocks pattern
-- 
-- ********************************************************************************** --
function fill(sizeX, sizeY, sizeZ, patternId, pos, isGoBackAfterFill, fillFlags)

  -- ==============================
  -- Variables
  -- ==============================
  if not pos then pos = vector.new() end -- Default position: zero
  
  if not patternId then patternId = 'plain' end -- Default pattern index - plain fill
  if not isGoBackAfterFill then isGoBackAfterFill = true end -- Default returning - yes, go back

  -- There we will storage what slots was deplited, out of building blocks
  -- 0: slot in use, have blocks.
  -- 1: slot deplited, haven't blocks or have thrash
  local blacklistPattern = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  
  local totalVolume = sizeX*sizeY*sizeZ -- Total volume of blocks
  local vol = {{{}}} -- 3d array of whole volume filling territory
 
  -- Statistics
  local totalBlocksToPlace    = 0  -- Total count of blocks that must be placed
  local totalBlocksCountArray = {} -- Blocks count by indexes
  local totalFuelNeeded       = 0


  -- ==============================
  -- Preparing
  -- ==============================
  
  -- Preparing world for path finding
  local wrldSize = vector.new(sizeX+pos.x, sizeY+pos.y, sizeZ+pos.z)
  local localWorld = World.new(wrldSize.x, wrldSize.y, wrldSize.z)
  
  -- Block all cells in outside of filling volume
  for z = 0, wrldSize.z-1 do
    for y = 0, wrldSize.y-1 do
      for x = 0, wrldSize.x-1 do
        -- Prevent the starting square from being blocked
        if not((z==0 and y==0) or (x==0 and z==0) or
           (x>=pos.x and y>=pos.y and z>=pos.z))then -- FIXME: Fix condition to right
          localWorld.blocked[z][y][x] = true
        end
      end
    end
  end
    
    
  -- Pattern sizes per axis
  local ptSzX, ptSzY, ptSzZ = 0,0,0
  
  -- Get sizes of pattern
  local zCount = #fillPattern[patternId]
  ptSzZ = zCount
  for z=1, zCount do
    local yCount = #fillPattern[patternId][z]
    if ptSzY < yCount then ptSzY = yCount end
    for y=1, yCount do
      local xCount = #fillPattern[patternId][z][y]
      if ptSzX < xCount then ptSzX = xCount end
    end
  end
  
  -- Write new pattern
  local parsedPattern = {}
  for z=1, ptSzZ do
    parsedPattern[z] = {}
    for y=1, ptSzY do
      parsedPattern[z][y] = {}
      for x=1, ptSzX do
        parsedPattern[z][y][x] = tonumber(getChar(fillPattern[patternId][z][y], x))
      end
    end
  end

 
 
  
  -- We must make a large
  -- array of all blocks in volume
  for O=0, totalVolume-1 do
    local u, v, w
    u = math.floor(O/(sizeX*sizeY)) -- z
    v = math.floor(O/sizeX) % sizeY -- y
    w = math.floor(O%sizeX)         -- x
   

    -- Pattern picker must think we are on this 'imagined' or 'fabled' positions
    local fabled_u, fabled_v, fabled_w = u,v,w
    if(fillFlags['mirror -1'] or fillFlags['mirror -1z']) then
      fabled_u = u + math.floor( (u+ptSzZ-1) / (ptSzZ*2-1) )
    end
    if(fillFlags['mirror -1'] or fillFlags['mirror -1y']) then
      fabled_v = v + math.floor( (v+ptSzY-1) / (ptSzY*2-1) )
    end
    if(fillFlags['mirror -1'] or fillFlags['mirror -1x']) then
      fabled_w = w + math.floor( (w+ptSzX-1) / (ptSzX*2-1) )
    end

    -- Compute pattern array indexes. Place on pattern that we want to take
    local ptX, ptY, ptZ = fabled_w%ptSzX, fabled_v%ptSzY, fabled_u%ptSzZ
    
    -- Flag "mirror" must mirrored all coordinates on even step
    if(fillFlags['mirror'] or fillFlags['mirror -1'] or fillFlags['mirror -1x'] or
       fillFlags['mirror -1y'] or fillFlags['mirror -1z']) then
      if (math.floor(fabled_w/ptSzX) % 2) == 1 then ptX = ptSzX-ptX-1 end
      if (math.floor(fabled_v/ptSzY) % 2) == 1 then ptY = ptSzY-ptY-1 end
      if (math.floor(fabled_u/ptSzZ) % 2) == 1 then ptZ = ptSzZ-ptZ-1 end
    end


    -- Get block index from pattern, demands on position of turtle
    local blockIndex = parsedPattern[ptZ+1][ptY+1][ptX+1]
   
    -- When we use 'sides' or 'corners' flags, we avoid all blocks inside volume
    if fillFlags['sides'] or fillFlags['corners'] then
      if(u>0 and u<sizeZ-1) and (v>0 and v<sizeY-1) and (w>0 and w<sizeX-1) then
        blockIndex = 0
      end
    end
    
    -- If only 'sides' flag enabled, clear all corners
    if fillFlags['sides'] and not fillFlags['corners'] then
      if not(((u>0 and u<sizeZ-1) and (v>0 and v<sizeY-1)) or
             ((u>0 and u<sizeZ-1) and (w>0 and w<sizeX-1)) or
             ((w>0 and w<sizeX-1) and (v>0 and v<sizeY-1))) then
        blockIndex = 0
      end
    end
    
    -- If only 'corners', clear all sides
    if fillFlags['corners'] and not fillFlags['sides'] then
      if not(((u==0 or u==sizeZ-1) and (v==0 or v==sizeY-1)) or
             ((u==0 or u==sizeZ-1) and (w==0 or w==sizeX-1)) or
             ((w==0 or w==sizeX-1) and (v==0 or v==sizeY-1))) then
        blockIndex = 0
      end
    end
    if fillFlags['tunnel'] and (w==0 or w==sizeX-1) and (u>0 and u<sizeZ-1) and (v>0 and v<sizeY-1) then
      blockIndex = 0
    end
    if fillFlags['tube'] and (u==0 or u==sizeZ-1) and (w>0 and w<sizeX-1) and (v>0 and v<sizeY-1) then
      blockIndex = 0
    end
    if fillFlags['clearAllSkipped'] then if blockIndex== nil then blockIndex = 0 end end
    if fillFlags['skipClearing']    then if blockIndex==   0 then blockIndex = nil end end
    
    -- Clear all blocks, ignoring any pattern
    if fillFlags['clear'] then blockIndex = 0 end
  
  
    -- Add tables if they are not defined
    if not vol[u]       then vol[u]       = {} end
    if not vol[u][v]    then vol[u][v]    = {} end
    if not vol[u][v][w] then vol[u][v][w] = {} end
    
    -- Put block index in volume array
    vol[u][v][w] = blockIndex
    
    -- Statistics
    if blockIndex ~= nil and blockIndex ~= 0 then
    
      -- Create key for new type
      if not totalBlocksCountArray[blockIndex] then totalBlocksCountArray[blockIndex] = 0 end
    
      -- Increment counters
      if(blockIndex>0)then
        totalBlocksToPlace = totalBlocksToPlace + 1
        totalBlocksCountArray[blockIndex] = totalBlocksCountArray[blockIndex] + 1
      end
    end
  end
  
  -- More statistics
  totalFuelNeeded = sizeX*sizeY*(2 + math.floor(sizeZ/3))
  
  
  
  -- ==============================
  -- Info screen
  -- ==============================
  
  clear()
  print('---------INFO---------:\n'..
  'Minimum fuel needed:   '..totalFuelNeeded)
  
  -- Print how much we need of blocks by each type
  for k,v in pairs(totalBlocksCountArray) do
    local stacks   = math.floor(v/64)
    local modStacks= v%64
    print(' #'..k..': '..((stacks>0) and stacks..'x64' or '')..
      ((stacks>0 and modStacks>0) and ' + ' or '')..
      ((modStacks>0) and modStacks or '') )
  end
  print('Press ENTER')
  
  -- Wait while user press key
  read()
  
  
  
  -- ==============================
  -- Functions
  -- ==============================
  
  -- Compute slots pattern. Pattern shows what block index in whitch slot
  local slotsPattern = getSlotsPattern() 
  local startPos = vector.new(Turtle.pos.x, Turtle.pos.y, Turtle.pos.z)

  
  -- Function same as GoTo, but consider position of building and incremental shifting
  local fillGoToFnc = function(x,y,z)
    -- Shift next coord with flags
    -- Userful for stairs and diagonals
    local shift = vector.new()
    if y then shift.x = y*(fillFlags['x++'] and 1 or (fillFlags['x--'] and -1 or 0)) end
    if x then shift.y = x*(fillFlags['y++'] and 1 or (fillFlags['y--'] and -1 or 0)) end
    if y then shift.z = y*(fillFlags['z++'] and 1 or (fillFlags['z--'] and -1 or 0)) end
    
    local changeVec = pos + shift    
    
    -- nil means we dont need change current position
    if not x then x = Turtle.pos.x-changeVec.x end
    if not y then y = Turtle.pos.y-changeVec.y end
    if not z then z = Turtle.pos.z-changeVec.z end

    local targetPos = vector.new(x,y,z) + changeVec
    Turtle.goTo(targetPos)
  end


  -- If we handle some unsolutionabled error, we can hope only on user.
  -- Going to start and waiting until he fix all
  local backToStartFnc = function(msg)
    writeMessage(msg, messageLevel.ERROR)
    
    Turtle.pathTo(localWorld, 0,0,0)
    Turtle.setOrient(way.FORWARD)
    
    pressAnyKey()
  end
  
  -- Go to start and try reload while accomplished
  local reloadFnc = function(blockIndex)
  
    local isReloaded = false
    
    while isReloaded==false do
      Turtle.pathTo(localWorld, 0, 0, 0)
      local reloadedPattern = reloadForFilling(slotsPattern, blacklistPattern)
     
      -- If some slots was not reloaded, leave them in blacklist
      for i=1, 16 do
        if(reloadedPattern[i] > 0) then
          blacklistPattern[i] = 0
        end
      end
      
      -- Check if we reloaded needed blockIndex
      if findInSlotsArrayByPattern(slotsPattern, blockIndex, blacklistPattern) == 0 then
        backToStartFnc('Error: Reloading failed. Please make storage and press any key')
      else
        isReloaded = true
      end
    end
  end
  

  -- The main function of placing blocks with parameters
  local fillFnc = function(x,y,z,direct,orient, blockIndex)
  
    -- Error text only for fatals, where program cant do nothing
    local fillError
    
    repeat -- Repeat until no fillErrors
      fillError = nil
      
      if( blockIndex ~= nil) then  
        if blockIndex > 0 then
          local slotWithNeededItem = findInSlotsArrayByPattern(slotsPattern, blockIndex, blacklistPattern)
          if(slotWithNeededItem ~= 0) then
            fillGoToFnc(x,y,z)
            if(orient)then Turtle.setOrient(orient) end -- Can be nil - orientation don't matter
            
            -- We have block and can put it on place
            local placeSucces = Turtle.place(slotWithNeededItem, direct)
            
            -- Block this cell in world, make it unable to go throught
            if(placeSucces == true)then
              local blockPos = Turtle.getRelativeCoord(direct)
              localWorld.blocked[blockPos.z][blockPos.y][blockPos.x] = true
            end
           
            -- If slot was emptyed, we must note, that now there will be thrash
            -- Each next time when turtle dig, empty slot will filling
            if(turtle.getItemCount(slotWithNeededItem) == 0) then
              blacklistPattern[slotWithNeededItem] = 1
              
              -- Check again if we have another slot with item
              if( findInSlotsArrayByPattern(slotsPattern, blockIndex, blacklistPattern) == 0)then
                -- No avaliable blocks to build!
                -- Save coords, reload and return
                local stopPosX,stopPosY,stopPosZ = Turtle.pos.x, Turtle.pos.y, Turtle.pos.z
                
                reloadFnc(blockIndex)
                
                -- Go back to work
                Turtle.pathTo(localWorld, stopPosX,stopPosY,stopPosZ)
              end
            end
          else
            -- Fatal fillError. We are probably reloaded, but still havent blocks to place
            -- This can happend only with bug in code
            fillError = 'Fatal fillError: No blocks to place on {'..x..','..y..','..z..'}\nI dont know what went wrong.'
            backToStartFnc(fillError)
          end
        else -- blockIndexToPlace == 0
          fillGoToFnc(x,y,z)
          if(orient)then Turtle.setOrient(orient) end -- Can be nil - orientation don't matter
          
          -- Remove block here and do nothing
          Turtle.dig(direct)
        end
      else -- blockIndexToPlace == nil
        
      end
    until not fillError
    
    return nil
  end -- fillFnc()


  -- ==============================
  -- Iterators
  -- ==============================
  
  
  -- move to start position
  fillGoToFnc(0, 0, ((sizeZ>1) and 1 or 0))
  
  -- y-> is printing method, when we fill from us to forward
  if     fillFlags['y->'] then
    for _y=0, sizeY-1 do
      for _z=0, sizeZ-1 do
        for _x=0, sizeX-1 do
          local x,y,z = _x,_y,_z
          if(z%2==1) then x = sizeX-x-1 end -- Ping-pong
          
          fillFnc(x,y,z+1, way.DOWN, nil, vol[z][y][x])
        end
      end
    end
    
  -- Printer working as usual building programs
  elseif fillFlags['printer'] then
    for _z=0, sizeZ-1 do
      for _y=0, sizeY-1 do
        for _x=0, sizeX-1 do
          local x,y,z = _x,_y,_z
          if(z%2==1) then y = sizeY-y-1; x = sizeX-x-1 end -- Ping-pong
          if(y%2==1) then x = sizeX-x-1 end                -- Ping-pong
          
          fillFnc(x,y,z+1, way.DOWN, nil, vol[z][y][x])
        end
      end
    end
    
  -- And most awesome and fast filling method
  -- It filling 3 blocks per move
  else
    local zStepsCount    = math.ceil(sizeZ/3)-1 -- Count of levels, where robot moves horisontally
    local lastZStepIsCap = (sizeZ%3 == 1) -- The top level of volume is last level where turtle moves hor-ly
    local zLastStepLevel = zStepsCount*3+(lastZStepIsCap and 0 or 1) -- Z level where turtle will move last
    
    for _z=0, zStepsCount do
      for _y=0, sizeY-1 do
        for _x=0, sizeX-1 do
          local x,y = _x,_y
          x = sizeX - x - 1 -- Revert X coordinates. Filling will be from right to left
          
          local z = _z*3+1
          local currZStepIsLast = (_z==zStepsCount)
          if currZStepIsLast then z = zLastStepLevel end -- Cap of volume
          
          -- Ping-pong
          local currZIsEven = (_z%2==0)
          local horisontDirect = way.BACK -- Specific orientation, when we move to next Y pos
          local horisontShift  = -1       -- Y direction, when we move to next Y pos
          if not currZIsEven then
            y = sizeY - y - 1
            horisontDirect = way.FORWARD
            horisontShift = 1
          end          
          
          local escapeShaftHere = (x==0 and y==0)
          local hereWeWillGoUp = ((x==0 and ((_z%2==0 and y==sizeY-1) or (_z%2==1 and y==0))) and _z < zStepsCount)
          

          -- Fill down
          if z>0 and not (lastZStepIsCap and currZStepIsLast) and not escapeShaftHere then
            fillFnc(x,y,z, way.DOWN, nil, vol[z-1][y][x])
          end
          
          -- Fill forward
          if x < sizeX-1 then
            fillFnc(x,y,z, way.FORWARD, way.RIGHT, vol[z][y][x+1])
          end
          
          -- Fill back previous line when we starting new x line
          if not currZStepIsLast or (not currZIsEven and currZStepIsLast) then
            if x==0 and ((currZIsEven and y>0) or ((not currZIsEven) and y<sizeY-1)) and
             not (x==0 and y==1 and currZIsEven) then
              fillFnc(x,y,z, way.FORWARD, horisontDirect, vol[z][y+horisontShift][x])
            end
          end
          
          -- Fill UP
          if z<sizeZ-1 and not hereWeWillGoUp and (not escapeShaftHere or currZStepIsLast) then
            fillFnc(x,y,z, way.UP, nil, vol[z+1][y][x])
          end
          
          -- Go forward if we finished the line
          if x==0 and ((_z%2==0 and y<sizeY-1) or (_z%2==1 and y>0)) then
            Turtle.goTo(Turtle.pos.x, Turtle.pos.y-horisontShift, Turtle.pos.z)
          end
          
          -- Move up and fill bocks down, if we advance to next Z level
          if hereWeWillGoUp then
            local nextZLevel = (_z+1)*3 + 1
            if lastZStepIsCap and (_z+1==zStepsCount) then nextZLevel = nextZLevel-1 end -- Cap of volume
            if(escapeShaftHere)then
              fillGoToFnc(nil, nil, nextZLevel)
            else
              for zAdvance=z+1, nextZLevel do
                fillGoToFnc(x,y,zAdvance)
                fillFnc(x,y,zAdvance, way.DOWN, nil, vol[zAdvance-1][y][x])
              end
            end
          end
          
        end
      end
    end
    
    -- We use our shaft to go back to x=0, y=0
    if not (zStepsCount%2==1) then
      for y=sizeY-2, 0, -1 do
        fillFnc(0, y, zLastStepLevel, way.FORWARD, way.FORWARD, vol[zLastStepLevel][y+1][0])
      end
    end
    
    -- And then go down to z 0
    for z=zLastStepLevel-1, 0, -1 do
      fillFnc(0, 0, z, way.UP, nil, vol[z+1][0][0])
    end
    fillGoToFnc(0,0,0)
    
    -- And last block
    fillFnc(0, -1, 0, way.FORWARD, way.FORWARD, vol[0][0][0])
  end
  
  
  -- ==============================
  -- Finishing
  -- ==============================
  
  -- Now we finished filling territory. Just go home
  if isGoBackAfterFill == true then
    Turtle.goTo(startPos.x, startPos.y, startPos.z)
    Turtle.setOrient(way.FORWARD)
  end
  
  return true
end

-- ********************************************************************************** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                            Startup functions                                 ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- **                                                                              ** --
-- ********************************************************************************** --
local args = { ... }

startupMode = {
  'Fill', 'Lake drying'
}


function main()

  -- ## Test function ##
  -- add to patterns all .nfa files
  local allFiles = fs.list('')
  local only_nfa = {}
  for k,v in pairs(allFiles) do
    if(string.sub(v,#v-3,#v) == '.nfa')then
      fillPattern[v] = loadNFA(v)
    end
  end
  
  -- ## Test function ##
  -- Detect whether this is a wireless turtle, and if so, open the modem
  local peripheralConnected = peripheral.getType("right")
  if (peripheralConnected == "modem") then
    isWirelessTurtle = true
    turtleId = os.getComputerLabel()
    rednet.open("right")
  end


   
  -- Get screen params
  local scrW, scrH = term.getSize()
  
  -- ==============================
  -- Main menu
  -- ==============================
  local mainMenuWindow = {} 
  table.insert(mainMenuWindow,{ id='welcomeLabel', type='textPanel', text='KRUTOY TURTLE',
      x=3,y=1, w=scrW-6,h=3, borderStyle='standart', align='center'})
  
  local maiMenuBths = { {id='menuBtn_fill', text='FILL'},
                        {id='menuBtn_lake', text='Refuel from Lake'} }
  
  local k=0
  for _,v in pairs(maiMenuBths) do
    table.insert(mainMenuWindow,{ id=v.id, type='button', text=v.text,
        x=5,y=4+k*2, w=scrW-10,h=3, borderStyle='none', align='center'})
    k = k + 1
  end
  table.insert(mainMenuWindow,{ id='menuBtn_exit', type='button', text='EXIT',
      x=scrW/2-3,y=scrH-2, w=4,h=1, borderStyle='none', align='center'})

         
  -- ==============================
  -- Fill options
  -- ==============================
  local nextBtn = { id='btn_next', type='button',   text='Next>>',
      x=scrW-10,y=scrH-1,w=10,h=1, borderStyle='none', align='center'}
  
  local fillOptionsWindow = {} 
  table.insert(fillOptionsWindow,{ id='optionsLabel', type='textPanel', text='Fill options',
      x=0,y=0, w=scrW+2,h=3, borderStyle='standart', align='center'})
      
  table.insert(fillOptionsWindow,{ id='btn_pattern', type='button', text='Pattern: ""',
      x=1,y=4, w=scrW,h=3, borderStyle='none', align='left'})
  table.insert(fillOptionsWindow,{ id='btn_size', type='button',    text='   Size: 0 0 0',
      x=1,y=6, w=scrW,h=3, borderStyle='none', align='left'})
  table.insert(fillOptionsWindow,{ id='btn_flags', type='button',   text='  Flags: _',
      x=1,y=8,w=scrW,h=3, borderStyle='none', align='left'})
  table.insert(fillOptionsWindow,nextBtn)
  
  -- ==============================
  -- Patterns
  -- ==============================
  local patternsWindow = {}
  table.insert(patternsWindow,{ id='patternsLabel', type='textPanel', text='Select pattern',
      x=0,y=0, w=scrW,h=3, borderStyle='standart', align='center'})
  
  
  
  while true do
    KUI.setWindow(mainMenuWindow, 'menuBtn_fill')
    local idPressed = KUI.navigate()
    
    if idPressed == 'menuBtn_lake' then
      
      -- Check is we have bucket
      while turtle.getItemCount(1) == 0 do
          KUI.setWindow({{ id='noBuketLabel', type='textPanel', text='Place buket in\nfirst slot',
              x=8,y=scrH/2-3, w=scrW-16,h=6, borderStyle='standart', align='center'}})
          sleep(1)
      end
      
      -- Offer user to input size
      KUI.setWindow({{ id='lakeLabel', type='textPanel',
        text='Specify size by x y z (z is deph)\n, separate with spaces, and press ENTER:',
        x=0,y=0, w=scrW+2,h=4, borderStyle='standart', align='center'}})
      local result = readNumbersInput(3, 6, false, 3, "%S+")
      local sizeX,sizeY,sizeZ = result[1],result[2] ,result[3]
      
      
      turtle.select(1)
      turtle.refuel()
      local startPos = vector.new(Turtle.pos.x,Turtle.pos.y,Turtle.pos.z)
      for z=0,sizeZ-1 do
        for x=0,sizeX-1 do
          for y=0,sizeY-1 do
            if(x%2==1) then y = sizeY - y - 1 end -- Ping-pong
            Turtle.goTo(x,y+1,-z)
            turtle.placeDown()
            turtle.refuel()
            
            clear()
            print('Fuel level: '..turtle.getFuelLevel())
          end
        end
      end
      Turtle.goTo(nil, nil, startPos.z)
      Turtle.goTo(startPos)
      Turtle.setOrient(way.FORWARD)
    end
    
    
    if idPressed == 'menuBtn_fill' then
    
      local sizeX,sizeY,sizeZ 
      local pattern = nil
      local pos = vector.new(0,1,0) -- Trutle build start is block forward of it
      local fillFlags = {}
      
      local optionId, sender
      while optionId ~= 'btn_next' or not pattern or not sizeX or not sizeY or not sizeZ do
        KUI.setWindow(fillOptionsWindow)
        optionId, sender = KUI.navigate()
        
        if     optionId == 'btn_pattern' then
          local n = 1
          local currLine = ''
          for k,v in pairs(fillPattern) do
            currLine = currLine..' '..n..' - '..k..'\n'
            n = n+1
          end
          local result = readNumberParametr(currLine, 1, n)
          n = 1
          for k,v in pairs(fillPattern) do
            if(n == result) then
              pattern = k
              break
            end
            n = n+1
          end
          sender.text = 'Pattern: '..pattern
        elseif optionId == 'btn_size' then
          -- TODO: Fix clearing line with text "size"
          local result = readNumbersInput(sender.x+9, sender.y, false, 3, "%S+")
          sizeX,sizeY,sizeZ = result[1],result[2],result[3]
          sender.text = '   Size: '..sizeX..' '..sizeY..' '..sizeZ
        elseif optionId == 'btn_flags' then
          KUI.setWindow({{ id='flags_label', type='textPanel',
            text='Add flags if need, separate with commas, and press ENTER',
            x=0,y=0, w=scrW,h=4, borderStyle='standart', align='center'}})
          term.setCursorPos(3,6)
          local result = readTable("%S+")
          if(result) then fillFlags = makeSet(result) end
        end
      end
      
      
      if IDE then
        sizeX,sizeY,sizeZ, pattern, pos, fillFlags = 5, 5, 9,'BoxGrid', pos, {}
      end
      
      
      ---------------------------------------
      fill(sizeX,sizeY,sizeZ, pattern, pos, true, fillFlags)
    end
  end
end