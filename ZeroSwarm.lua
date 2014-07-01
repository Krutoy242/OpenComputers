
-- —тандартный "типо-класс"
swarm = {}
swarm.__index = swarm
local modemOpened = false
local MASTERMESSAGE = 'I AM YOUR MASTER. OBEY!'
local masterId
local slaves


local function openModem()
  if modemOpened then return true end
   
  for n,sSide in ipairs( rs.getSides() ) do
    if rednet.isOpen( sSide ) then
      modemOpened = true
      return true
    end
  end
  for n,sSide in ipairs( rs.getSides() ) do
    if peripheral.getType( sSide )=='modem' then
      rednet.open(sSide)
      modemOpened = true
      return true
    end
  end
  return false
end

------------------------------
-- ‘ункции, вызываемые снаружи
------------------------------

-- ¬ызываетс€ по стандарту на всех запущенных черепашках
-- ∆дет броадкаста от ведущей черепашки и по получению сигнала посылает
-- в реднет ведущему рассто€ние до себ€ и свои параметры вроде имени.
-- ‘ункци€ возвращает рассто€ние до себ€, которое по сути €вл€етс€ ее
-- номером в р€ду черепашек.
function swarm.searchOwner()
  openModem()
  
  local event, senderId, message, distance
  while true do
    event, senderId, message, distance = os.pullEvent("rednet_message")
    if message==MASTERMESSAGE then
      -- We gained first message from master.
      -- Send back a distance
      sleep(distance/10)
      masterId = senderId
      rednet.send(senderId, distance)
    end
  end
  
  return distance
end


-- ¬ызываетс€ из ведомой.
-- Ёта функци€ будет запускатьс€ после того как черепашка определила себ€
-- как ведомую. ƒалее она будет вызыватьс€ снова дл€ получени€ новых команд,
-- если они необходимы.
-- ‘ункци€ возвращает полученную команду ввиде строки
function swarm.waitOrders()

  local senderId, message
  while senderId ~= masterId do
    senderId, message = rednet.receive()
  end
  
  return message
end


-- ¬ызываетс€ из ведущей. ѕосылает бродкаст и ждет ответов.
-- Ќаходит всех черепашек, сто€щих р€дом с вызывающей этот метод черепашкой.
-- waitingResponceTime - указывает как долго ждать ответа от ведомых
-- ¬озвращает количество найденых ведомых черепах
function swarm.findSlaves(waitingResponceTime)
  local received={}
  rednet.broadcast(MASTERMESSAGE)
  local senderId, message = rednet.reseive(waitingResponceTime)
  while senderId do
    if(type(tonumber(message)) == 'number') then
      table.insert(received, {id=senderId, dist=tonumber(message)})
      senderId, message = rednet.reseive(waitingResponceTime)
    end
  end
  table.sort(received,function(s1,s2) return s1.dist < s2.dist end)
  
  slaves = {}
  local k=1
  for _,v in pairs(received) do
    if(v.dist == k) then 
      k = k+1
      table.insert(slaves, v)
    else
      break
    end
  end
  
  return k-1
end


-- ¬ызываетс€ из ведущей. ѕередает на ведомую черепашку сообщение
-- turtleNumber - номер черепашки по счету, начина€ с "1"
-- taskString   - €вл€етс€ строкой, которую нужно передать
function swarm.transmitTask(turtleNumber, taskString)
  rednet.send(slaves[turtleNumber].id, taskString)
  return true
end

-- ¬ызываетс€ из ведомых после получени€ задани€ на строительство, если
-- черепашка не может начать работу. Ёто может произойти, например,
-- если черепашке не хватает топлива дл€ выполнени€ задани€.
-- Ёто необходимо, что бы вс€ группа не начинала работу, если кака€ то
-- черепашка не может этого сделать.
function swarm.transmitError(errorString)
  rednet.send(masterId, errorString)
  return true
end