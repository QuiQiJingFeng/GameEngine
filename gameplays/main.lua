local CommandCenter = require("commands.CommandCenter")

local function main(gameType)
	local commonCommands = require("gameplays.GAME_TYPE_COMMON.config")
	local gameCommands = require("gameplays."..gameType.."config")
	CommandCenter.registCommands(commonCommands)
	CommandCenter.registCommands(gameCommands)

end