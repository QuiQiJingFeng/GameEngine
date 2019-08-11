local skynet = require "skynet"
local log = require "skynet.log"
require "skynet.manager"
local cjson = require "cjson"
local Room = require "Room"
local pbc = require "protobuf"
local Constants = require("Constants")
local RESULT = Constants.RESULT
local CMD = {}

local data = {}

function CMD.CreateRoomREQ(content)
    local response = {result = RESULT.SUCCESS}
    data.room = Room.new(content.settings, content.roomId)
    --是否需要在创建的时候即加入房间
    if content.isJoinRoom then
        local roleId   = content.roleId
        local roleName = content.roleName
        local headUrl  = content.headUrl
        local fd       = content.fd

        result = data.room:joinRoom(roleId, roleName, headUrl, fd)
        if result == RESULT.SUCCESS then
            data.room:noticeRoomPlayerInfo()
        end
        response.result = result
    end
    response.roomId = content.roomId
    return response
end

function CMD.JoinRoomREQ(content)
    local response = {result = RESULT.SUCCESS}
    local roleId   = content.roleId
    local roleName = content.roleName
    local headUrl  = content.headUrl
    local fd       = content.fd
    result = data.room:joinRoom(roleId, roleName, headUrl, fd)
    if result == RESULT.SUCCESS then
        data.room:noticeRoomPlayerInfo()
    end
    response.result = result
    return response
end

function CMD.Disconnect(content)
    local roleId = content.roleId
    data.room:setDisconnectRoleId(roleId)
end

function CMD.SelectSeatREQ(content)
    local position = content.position
    local roleId   = content.roleId
    data.room:selectSeat(roleId,position)    
end

function CMD.LeaveRoomREQ(content)
    local roleId = content.roleId
    data.room:leaveRoom(roleId)
end

function CMD.force_distroy(room_id)
    room:distroy(constant.DISTORY_TYPE.FORCE_DISTORY)
end

function CMD.distroy_room(content)
    local user_id = content.user_id
    local room_id = content.room_id
    local owner_id = room.owner_id
    local type = content.type
    --在游戏当中
    if room.game and room.cur_round >= 1 then
        type = constant.DISTORY_TYPE.ALL_AGREE
    else
        --如果不在游戏当中,房主可以直接解散房间
        if user_id == owner_id then
            type = constant.DISTORY_TYPE.OWNER_DISTROY
        else
            type = constant.DISTORY_TYPE.ALL_AGREE
        end
    end

    --如果是房主解散房间
    if type == constant.DISTORY_TYPE.OWNER_DISTROY then
        if room.state ~= constant.ROOM_STATE.GAME_PREPARE or user_id ~= owner_id then
            return "no_permission_distroy"
        else
            room:distroy(constant.DISTORY_TYPE.OWNER_DISTROY)
            return "success"
        end
    end
    --如果是申请解散房间
    if type ==  constant.DISTORY_TYPE.ALL_AGREE then
        room.can_distroy = true
        local players = room.player_list
        room.confirm_map = room.confirm_map or {}
        local confirm_map = room.confirm_map
        for i,obj in ipairs(players) do
            confirm_map[obj.user_id] = false
        end
        confirm_map[user_id] = true
        
        for i,player in ipairs(players) do
            local distroy_time = math.ceil(skynet.time() + constant["AUTO_CONFIRM"])
            room.distroy_time = distroy_time
            local data = {}
            for user_id,v in pairs(confirm_map) do
                if v then
                    local info = room:getPlayerByUserId(user_id)
                    table.insert(data,info.user_id)
                end
            end
            
            player:send({notice_other_distroy_room={distroy_time = distroy_time,confirm_map=data}})
        end

        --2分钟 如果玩家仍然没有同意,则自动同意
        skynet.timeout(constant["AUTO_CONFIRM"]*100,function() 
                if room.state == ROOM_STATE.ROOM_DISTROY then
                    print("这个房间已经被解散了 ",room.room_id)
                    --如果这个房间已经被解散了
                    return 
                end
                local can_distroy = room.can_distroy
                if not can_distroy then
                    print("这个房间已经被人拒绝解散了")
                    --如果这个房间已经被人拒绝解散了
                    return 
                end
                --遍历所有没有同意的玩家,让他同意
                local confirm_map = room.confirm_map
                for user_id,confirm in pairs(confirm_map) do
                    if not confirm then
                        CMD.confirm_distroy_room({user_id=user_id,room_id=room_id,confirm=true})
                    end
                end
            end)
        return "success"
    end
    return "paramater_error"
end

function CMD.confirm_distroy_room(content)
    local user_id = content.user_id
    local room_id = content.room_id
    local confirm = content.confirm
    local can_distroy = room.can_distroy
    if not can_distroy then
        --非法的请求
        return "no_support_command"
    end
    local players = room.player_list
    if confirm then
        local confirm_map = room.confirm_map
        confirm_map[user_id] = true
        --当前玩家的数量
        local player_num = 0
        for i,player in ipairs(players) do
            player_num = player_num + 1
        end
        local num = 0
        for k,v in pairs(confirm_map) do
            if v then
                num = num + 1
            end
        end

        --如果所有人都点了确定
        if num == player_num then
            room.can_distroy = nil
            room.distroy_time = nil
            room.confirm_map = {}
            room:distroy(constant.DISTORY_TYPE.ALL_AGREE)
        else
            local data = {}
            for user_id,v in pairs(confirm_map) do
                if v then
                    local info = room:getPlayerByUserId(user_id)
                    table.insert(data,info.user_id)
                end
            end

            room:broadcastAllPlayers("notice_other_distroy_room",{distroy_time = room.distroy_time,confirm_map=data})
        end
    else
        local s_player = room:getPlayerByUserId(user_id)

        --如果有人不同意,则通知其他人 谁不同意
        local players = room.player_list
        for i,player in ipairs(players) do
            player:send({notice_other_refuse={user_id=s_player.user_id,user_pos=s_player.user_pos}})
        end
        room.confirm_map = {}
        room.can_distroy = nil
    end

    return "success"
end
 

function CMD.request(req_name,req_content)
    local func = CMD[req_name]
    if not func then
        if room.game then
            local func2 = room.game[req_name]
            if func2 then
                print("REQ->",req_name,cjson.encode(req_content))
                return func2(room.game,req_content)
            end
        end
        return "no_support_command"
    end

    return func(req_content)
end


local function checkExpireRoom()
    local now = skynet.time()
    if room.expire_time and room.expire_time < now then
        room:distroy(constant.DISTORY_TYPE.EXPIRE_TIME)
    else
        --每隔1分钟检查一下失效的房间
        skynet.timeout(60 * 100, checkExpireRoom)   
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
        local f = assert(CMD[cmd])
        skynet.ret(skynet.pack(f(subcmd, ...)))
    end)

    pbc.register_file(skynet.getenv("protobuf"))

    checkExpireRoom()

    skynet.register ".room"
end)
