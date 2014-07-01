-- ********************************************************************************** --
-- **                                                                              ** --
-- ********************************************************************************** --

KUI = {}
KUI.__index = KUI

local sub = string.sub

local borderStylesStr = {
  ['selectedBtn']= '/\\/\\  ||',
  ['standart']   = '++++--||',
  ['none']       = '        ',
  ['inlineBtn']  = '[]][    '
}
-- Transform string to array
local borderStyles = {}
for k,v in pairs(borderStylesStr) do
  borderStyles[k] = {}
  local styleStr = v
  for i = 1, #styleStr do
    borderStyles[k][i] = (styleStr:sub(i,i))
  end
end


local alignTypes = {'left', 'right', 'center'}

KUI.items = {} -- Array of UI elements
KUI.selectedObj = nil -- Currently selected item



-- Repeat char many as need times to make string
local function repeatChar(char, count)
  local returnString = ''
  for _=0, count-1 do
    returnString = returnString..char
  end
  return returnString
end


function KUI.drawText(text, x,y, w,h, align)
  align = align or 'center'
  
  -- String params
  local textLinesCount = 1 + select(2, text:gsub('\n', '\n'))
  
  -- Top spaces
  local vertSpace = (h-textLinesCount)/2
  local clearLine = repeatChar(' ', w)
  for _=1, math.floor(vertSpace) do
    term.setCursorPos(x, y)
    term.write(clearLine)
  end
  
  -- Bottom spaces
  for _=1, math.ceil (vertSpace) do
    term.setCursorPos(x, y+h-1)
    term.write(clearLine)
  end  
  
  -- Write lines 
  local currLine = 0
  for l in text:gmatch('.+') do
    local margin = {0,0} -- Spaces from left and right
    local horisSpace = (w - #l)
    
    -- Align styles
    if    (align == 'left') then
      margin = {0, horisSpace}
    elseif(align == 'right')then
      margin = {horisSpace, 0}
    elseif(align == 'center')then
      margin = {math.floor(horisSpace/2), math.ceil(horisSpace/2)}
    end
    
    term.setCursorPos(x, y+currLine)
    term.write( repeatChar(' ',margin[1])..l..repeatChar(' ',margin[2]))
    currLine = currLine+1
  end
end

-- Draw simple panel with borders
function KUI.drawPanel(x,y, w,h, borderStyle)
  borderStyle = borderStyle or 'standart'
  local styleArr = borderStyles[borderStyle]
  
  -- Horisontal lines
  term.setCursorPos(x, y)
  term.write(styleArr[1]..repeatChar(styleArr[5], w-2)..styleArr[2])
  term.setCursorPos(x, y+h-1)
  term.write(styleArr[4]..repeatChar(styleArr[6], w-2)..styleArr[3])
  
  -- Vertical lines
  for i=0,h-3 do
    term.setCursorPos(x, y+i+1)
    term.write(styleArr[7])
    term.setCursorPos(x+w-1, y+i+1)
    term.write(styleArr[8])
  end

end

-- Draw panel with text
function KUI.drawTextPanel(text, x,y, w,h, borderStyle, align)
  KUI.drawPanel(x,y, w,h, borderStyle)
  
  KUI.drawText(text, x+2,y+1, w-2,h, align)
end

-- ********************************************************************************** --
-- Add gui element to current window
-- ********************************************************************************** --
function KUI.add(obj)

  -- Add additional info
  
  obj.center = {x=obj.x+obj.w/2, y=obj.y+obj.h/2}
  
  obj.nextTab = KUI.items[1] or obj
  if(#KUI.items >= 1) then 
  KUI.items[#KUI.items].nextTab = obj 
  end
  
  if obj.type == 'button' then
    obj.selectable = true
  end
  
  table.insert(KUI.items, obj)
end

-- ********************************************************************************** --
-- Set new window. Add all objects in list to screen
-- ********************************************************************************** --
function KUI.setWindow(window, selectedId)
  KUI.items = {}
  KUI.selectedObj = nil
  for _,obj in pairs(window) do
    KUI.add(obj)
    if obj.id == selectedId then KUI.selectedObj = obj end
  end
  KUI.selectedObj = KUI.selectedObj or KUI.items[1]
  KUI.draw()
end

-- ********************************************************************************** --
-- Draw all objects in list
-- ********************************************************************************** --
function KUI.draw()
  term.clear()
  for _,obj in pairs(KUI.items) do
    
    -- Switch type
    if     obj.type == 'panel' then
      KUI.drawPanel(obj.x,obj.y, obj.w,obj.h, obj.borderStyle)
    elseif obj.type == 'text' then
      KUI.drawText(obj.text, obj.x,obj.y, obj.w,obj.h, obj.align)
    elseif obj.type == 'textPanel' or obj.type == 'button' then
      KUI.drawTextPanel(obj.text, obj.x,obj.y, obj.w,obj.h, obj.borderStyle, obj.align)
    elseif obj.type == '' then
      
    elseif obj.type == '' then
      
    else
      
    end
    
    -- This object is selected and selectable
    if KUI.selectedObj == obj and obj.selectable == true then
      KUI.drawPanel(obj.x,obj.y, obj.w,obj.h, 'selectedBtn')
    end
    
  end
  sleep(0)
end

function KUI.navigate() 
  
  while true do
    local e, p1 = os.pullEvent('key')
    if     p1 == 200 then --UP

    elseif p1 == 208 then --DOWN
      
    elseif p1 == 203 then --LEFT
      
    elseif p1 == 205 then --RIGHT
      
    elseif p1 == 15  then --TAB
      local oldSelectedObj = KUI.selectedObj
      KUI.selectedObj = KUI.selectedObj.nextTab
      while KUI.selectedObj.selectable ~= true and oldSelectedObj ~= KUI.selectedObj do
        KUI.selectedObj = KUI.selectedObj.nextTab
      end
      KUI.draw()
    elseif p1 == 28  then --ENTER
      if KUI.selectedObj ~= nil then
        return KUI.selectedObj.id, KUI.selectedObj
      end
    end
  end
  
end