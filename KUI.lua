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
  local styleStr = borderStylesStr[borderStyle]
  for i = 1, #styleStr do
    borderStyles[k]:insert(styleStr:sub(i,i))
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
  local textLinesCount = select(2, text:gsub('\n', '\n'))
  
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
  for l in text:gmatch('\n') do
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
  term.write(styleArr[3]..repeatChar(styleArr[6], w-2)..styleArr[4])
  
  -- Vertical lines
  for i=0,w-3 do
    term.setCursorPos(x, y+i+1)
    term.write(styleArr[7])
    term.setCursorPos(x+w-1, y+i+1)
    term.write(styleArr[8])
  end

end

-- Draw panel with text
function KUI.drawTextPanel(text, x,y, w,h, borderStyle, align)
  KUI.drawPanel(x,y, w,h, borderStyle)
  
  KUI.drawText(text, x+2,y+1, w-4,h-2, align)
end


function KUI.add(obj)
  -- Add additional info
  obj.center = {x=obj.x+obj.w/2, y=obj.y+obj.h/2} 
  obj.tabId  = #KUI.items
  obj.isSelected = false
  
  KUI.items:insert(obj)
end

function KUI.setWindow(window)
  KUI.items = {}
  for _,obj in pairs(window) do
    KUI.add(obj)
  end
  KUI.selectedObj = KUI.items[1]
  KUI.draw()
end

function KUI.draw()
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
    if KUI.selectedObj == obj and obj.type == 'button' then
      KUI.drawPanel(obj.x,obj.y, obj.w,obj.h, 'selectedBtn')
    end
    
  end
end

function KUI.navigate()
  while true do
    local e, p1 = os.pullEvent('key')
    if     p1 == 200 then --UP

    elseif p1 == 208 then --DOWN
      
    elseif p1 == 203 then --LEFT
      
    elseif p1 == 205 then --RIGHT
      
    elseif p1 == 15  then --TAB
      for k,obj in pairs(KUI.items) do
        if KUI.selectedObj == obj then
          if KUI.items[k+1] ~= nil then
            KUI.selectedObj = KUI.items[k+1]
          else
            KUI.selectedObj = KUI.items[1]
          end
        end
      end
      KUI.draw()
    elseif p1 == 28  then --ENTER
      if KUI.selectedObj ~= nil then
        return KUI.selectedObj.id, KUI.selectedObj
      end
    end
  end
  
end

-- ********************************************************************************** --
-- **                                   Menu                                       ** --
-- ********************************************************************************** --

function KUI.drawMenu(menuTable, cursor, offset)
  local xlim, ylim = term.getSize()
  --if xlim < 3 or (ylim < 3 and #menuTable > 2) then
  --  return nil, "Not enough space to draw menu!"
  --end
  term.clear()
  offset = offset or 1
  term.setCursorPos(3, 1)
  if offset > 1 then
    term.write("/\\")
  else
    term.write(string.sub(menuTable[1], 1, xlim - 2))
  end
  for i=1, math.min(ylim - 2,#menuTable - 1) do
    term.setCursorPos(3, i + 1)
    term.write(string.sub(menuTable[offset + i], 1, xlim - 2))
  end
  if #menuTable >= ylim then
    term.setCursorPos(3, ylim)
    if #menuTable > offset + ylim - 1 then
      term.write("\\/")
    else
      term.write(string.sub(menuTable[#menuTable], 1, xlim - 2))
    end
  end
  term.setCursorPos(1, cursor - offset + 1)
  term.write(">")
end


function KUI.menuSelect(menuTable)
  local cursor, offset = 1, 1
  drawMenu(menuTable, cursor, offset)
  while true do
    local e, p1, p2, p3 = os.pullEvent()
    if e == "key" then
      --up
      if p1 == 200 then
        if cursor - offset + 1 > 2 or (cursor > 1 and offset ==  1) then
          term.setCursorPos(1, cursor - offset + 1)
          term.write(" ")
          cursor = cursor - 1
          term.setCursorPos(1, cursor - offset + 1)
          term.write(">")
        elseif cursor - offset + 1 == 2 and offset > 1 then
          offset = offset - 1
          cursor = cursor - 1
          drawMenu(menuTable, cursor, offset)
        end
      --down
      elseif p1 == 208 then
        _, ylim = term.getSize()
        if cursor < #menuTable and (cursor - offset + 1 < ylim - 1 or #menuTable <= ylim or (cursor == #menuTable - 1 and cursor - offset + 1 == ylim - 1)) then
          term.setCursorPos(1, cursor - offset + 1)
          term.write(" ")
          cursor = cursor + 1
          term.setCursorPos(1, cursor - offset + 1)
          term.write(">")
        elseif cursor < #menuTable and cursor - offset + 1 == ylim - 1 then
          offset = offset + 1
          cursor = cursor + 1
          drawMenu(menuTable, cursor, offset)
        end
      elseif p1 == 28 then
        return cursor
      end
    elseif e == "window_resize" then
      drawMenu(menuTable, cursor, offset)
    end
  end
end
