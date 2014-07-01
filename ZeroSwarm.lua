
-- ����������� "����-�����"
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
-- �������, ���������� �������
------------------------------

-- ���������� �� ��������� �� ���� ���������� ����������
-- ���� ���������� �� ������� ��������� � �� ��������� ������� ��������
-- � ������ �������� ���������� �� ���� � ���� ��������� ����� �����.
-- ������� ���������� ���������� �� ����, ������� �� ���� �������� ��
-- ������� � ���� ���������.
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


-- ���������� �� �������.
-- ��� ������� ����� ����������� ����� ���� ��� ��������� ���������� ����
-- ��� �������. ����� ��� ����� ���������� ����� ��� ��������� ����� ������,
-- ���� ��� ����������.
-- ������� ���������� ���������� ������� ����� ������
function swarm.waitOrders()

  local senderId, message
  while senderId ~= masterId do
    senderId, message = rednet.receive()
  end
  
  return message
end


-- ���������� �� �������. �������� �������� � ���� �������.
-- ������� ���� ���������, ������� ����� � ���������� ���� ����� ����������.
-- waitingResponceTime - ��������� ��� ����� ����� ������ �� �������
-- ���������� ���������� �������� ������� �������
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


-- ���������� �� �������. �������� �� ������� ��������� ���������
-- turtleNumber - ����� ��������� �� �����, ������� � "1"
-- taskString   - �������� �������, ������� ����� ��������
function swarm.transmitTask(turtleNumber, taskString)
  rednet.send(slaves[turtleNumber].id, taskString)
  return true
end

-- ���������� �� ������� ����� ��������� ������� �� �������������, ����
-- ��������� �� ����� ������ ������. ��� ����� ���������, ��������,
-- ���� ��������� �� ������� ������� ��� ���������� �������.
-- ��� ����������, ��� �� ��� ������ �� �������� ������, ���� ����� ��
-- ��������� �� ����� ����� �������.
function swarm.transmitError(errorString)
  rednet.send(masterId, errorString)
  return true
end