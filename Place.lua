local Place = class("Place")

function Place:ctor()
	self._operateCards = {}  --吃碰杠、补花等特殊操作
	self._outCards = {}      --已经出的牌
	self._handCards = {}     --手牌  哈希表 id -> card
	self._curScore = 0       --当前局积分
	self._totalScore = 0     --总积分
	self._lastCard = nil     --最后一张摸到的牌
end

function Place:addHandCard(card)
	self._lastCard = card
	self._handCards[card:getId()] = card
end

function Place:removeHandCardBy(id)
	self._handCards[id] = nil
end

function Place:removeHandCardByValue(value,num)
	for id,card in pairs(self._handCards) do
		if card:getCardValue() == value then
			self._handCards[id] = nil
			num = num - 1
		end

		if num <= 0 then
			break
		end
	end
end

function Place:addOutCard(card)
	table.insert(self._outCards,card)
end

function Place:removeOutCard(id)
	local find = false
	for index,card in ipairs(self._outCards) do
		if card:getId() == id then
			table.remove(self._outCards,index)
			find = true
			break
		end
	end
	assert(find)
end


return Place