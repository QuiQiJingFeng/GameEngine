local RoomSetting = require("gameplays.RoomSetting")
local GamePlayCode = RoomSetting.GamePlayCode
local GamePlayName = RoomSetting.GamePlayName
local GameBase = class("GameBase")

function GameBase:ctor(settings)
	self._settings = settings
	self._settingNameMap = self:convertToGameNameMap(settings)
end

function GameBase:_filterSettingName(filter)
	local settingNames = table.keys(self._settingNameMap)
	for _,name in ipairs(self.settingNames) do
		if string.find(name,filter) then
			return name
		end
	end
	assert(false)
end

--获取房间人数
function GameBase:getPlayerNum()
	return self:_filterSettingName("PLAYER_")
end

--获取游戏的类型
function GameBase:getGameType()
	return self:_filterSettingName("GAME_TYPE_")
end

--获取付费类型
function GameBase:getPayType()
	return self:_filterSettingName("PAY_BY_")
end

--检测某个规则是否存在
function GameBase:hasSettingName(settingName)
	return self._settingNameMap[settingName]
end

--将规则码转换为规则名称
function GameBase:convertToGameNameMap(settings)
	local settingNameMap = {}
	for _,setting in ipairs(settings) do
		settingNameMap[GamePlayName[setting]] = true
	end
	return settingNameMap
end

return GameBase