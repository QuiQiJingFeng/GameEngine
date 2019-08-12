local Constants = {}

Constants.RESULT = {
	SUCCESS    = 0X0001,
	EMPTY_ROOM = 0x0002, --房间已满
	POSITION_HAS_PLAYER = 0X0003,  --该位置上已经有人了
} 

Constants.PLAY_TYPE = {
    COMMAND_START        = 1,   --牌局开始
     
}

return Constants