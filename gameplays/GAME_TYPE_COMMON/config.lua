local Constants = require("Constants")
local PLAY_TYPE = Constants.PLAY_TYPE

local commanCommands = {
	--牌局开始
	[PLAY_TYPE.COMMAND_START] = require("gameplays.GAME_TYPE_COMMON.CommandStart.lua"),
}

return commanCommands