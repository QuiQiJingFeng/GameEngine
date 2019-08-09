local Place = require("Place")
local Engine = class("Engine")

function Engine:ctor(placeNum,roundNum)
	self._places = {}
	for i=1,placeNum do
		local place = Place.new()
		table.insert(self._places,place)
	end
	--局数
	self._roundNum = roundNum
	--当前局数
	self._curRound = 0
	--牌池
	
end

return Engine