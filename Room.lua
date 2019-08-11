local RoomSetting = require("gameplays.RoomSetting")
local GamePlayCode = RoomSetting.GamePlayCode
local GamePlayName = RoomSetting.GamePlayName
local Place = require("Place")
local Constants = require("Constants")
local RESULT = Constants.RESULT
local pbc = require "protobuf"
local Room = class("Room")

function Room:ctor(settings,roomId)
	self._settings = settings
	self._settingNameMap = self:convertToGameNameMap(settings)

	self._roomId = roomId
	self._places = {}  --玩家的位置
end

function Room:getRoomId()
	return self._roomId
end

function Room:setDisconnectRoleId(roleId)
	local hasPlace = nil
	for _,place in ipairs(self._places) do
		if place.roleId == roleId then
			hasPlace = true
			place:setConnected(false)
			break
		end
	end
	assert(hasPlace)
end

function Room:leaveRoom(roleId)
	for idx,place in ipairs(self._places) do
		if roleId == place:getRoleId then
			table.remove(self._places,idx)
			break
		end
	end
	self:NoticeRoomInfoSYN()
end

function Room:selectSeat(roleId,position)
	local positions = {}
	for pos=1,#self:getPlayerNum() do
		positions[pos] = true
	end
	local unUsedPosition = {}
	local selectPlace = nil
	for _,place in ipairs(self._places) do
		local pos = place:getPosition()
		unUsedPosition[pos] = nil
		if not place:getRoleId() == roleId then
			selectPlace = place
		end
	end
	if not unUsedPosition[position] then
		return RESULT.POSITION_HAS_PLAYER
	end
	unUsedPosition[position] = nil
	if table.nums(unUsedPosition) <= 0 then
		--FYD 开局
	end
	selectPlace:setPosition(position)
	return RESULT.SUCCESS
end

function Room:joinRoom(roleId,roleName,headUrl,fd)
	local num = self:getPlayerNum()
	if num <= #self._places then
		return RESULT.EMPTY_ROOM
	end
	local oldPlace = nil
	for _,place in ipairs(self._places) do
		if place.roleId == roleId then
			oldPlace = place
			break
		end
	end
	if not oldPlace then
		local place = Place.new()
		place:setRoleId(roleId)
		place:setRoleName(roleName)
		place:setHeadUrl(headUrl)
		place:setFd(fd)
		place:setConnected(true)
		table.insert(self._places,place)
	else
		oldPlace:setRoleName(roleName)
		oldPlace:setHeadUrl(headUrl)
		oldPlace:setFd(fd)
		oldPlace:setConnected(true)
	end

	return RESULT.SUCCESS
end

function Room:noticeRoomPlayerInfo()
	local response = {}
	response.roomId = self._roomId
	response.places = {}
	for _,place in ipairs(self._places) do
		local data = {}
		data.roleId = place:getRoleId()
		data.roleName = place:getRoleName()
		data.position = place:getPosition()
		data.headUrl = place:getHeadUrl()
		table.insert(response.places,data)
	end
    local messageSyn = {NoticeRoomInfoSYN = response}
	-- 转换为protobuf编码
    local success, data, err = pcall(pbc.encode, "S2C", messageSyn)
    if not success or err then
        print("encode protobuf error",cjson.encode(messageSyn))
        return
    end

    for _,place in ipairs(self._places) do
    	local fd = place:getFd()
	    socket.write(fd, string.pack(">s2", crypt.base64encode(data)))
    end
end

function Room:_filterSettingName(filter)
	local settingNames = table.keys(self._settingNameMap)
	for _,name in ipairs(self.settingNames) do
		if string.find(name,filter) then
			return name
		end
	end
	assert(false)
end

--获取房间人数
function Room:getPlayerNum()
	local key = self:_filterSettingName("PLAYER_")
	return RoomSetting.CONVERT_PLAYER_NUM[key]
end

--获取游戏的类型
function Room:getGameType()
	return self:_filterSettingName("GAME_TYPE_")
end

--获取付费类型
function Room:getPayType()
	return self:_filterSettingName("PAY_BY_")
end

--获取当前的局数
function Room:getRoundCount()
	local key = self:_filterSettingName("ROOM_COUNT_")
	local config = RoomSetting.CONVERT_ROUND_NUM[key]
	if not config.isCircle then
		return config.num
	end
	--如果是圈数,则转换成局数
	local playerNum = self:getPlayerNum()
	return config.num * playerNum
end

--检测某个规则是否存在
function Room:hasSettingName(settingName)
	return self._settingNameMap[settingName]
end

--将规则码转换为规则名称
function Room:convertToGameNameMap(settings)
	local settingNameMap = {}
	for _,setting in ipairs(settings) do
		settingNameMap[GamePlayName[setting]] = true
	end
	return settingNameMap
end

return Room