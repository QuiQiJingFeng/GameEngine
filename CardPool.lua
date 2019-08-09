local CardDefine = require("CardDefine")
local Card = require("Card")
local CardPool = class("CardPool")

function CardPool:ctor()
	self._pool = {}
	local index = 1
	for value,_ in pairs(CardDefine.CardType) do
		if value <= 40 then
			for i=1,4 do
				local card = Card.new(index,value)
				table.insert(self._pool,card)
				index = index + 1
			end
		else
			index = index + 1
		end
	end
end

return CardPool