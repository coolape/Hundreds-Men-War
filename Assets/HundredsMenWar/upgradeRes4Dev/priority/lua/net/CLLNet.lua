﻿--- 网络下行数据调度器
require("bio.BioUtl")
require("net.NetProtoUsermgrClient")
require("net.NetPtMonstersClient")
CLLNet = {}
local protoClient = NetPtMonsters

local strLen = string.len
local strSub = string.sub
local strPack = string.pack
--local strbyte = string.byte
--local maxPackSize = 64 * 1024 - 1
--local subPackSize = 64 * 1024 - 1 - 50
---@type Coolape.Net
local csSelf = Net.self
--local __maxLen = 1024 * 1024
local timeOutSec = 30 -- 超时秒
local NetSuccess = NetSuccess
local __httpBaseUrl = PStr.b():a("http://"):a(Net.self.gateHost):a(":"):a(tostring(Net.self.gatePort)):e()
local baseUrlUsermgr = joinStr(__httpBaseUrl, "/usermgr/postbio")

function CLLNet.refreshBaseUrl(host)
    __httpBaseUrl = PStr.b():a("http://"):a(host):a(":"):a(tostring(Net.self.gatePort)):e()
    baseUrlUsermgr = joinStr(__httpBaseUrl, "/usermgr/postbio")
end

--function CLLNet.init()
--    csSelf = Net.self
--end

local httpPostBio = function(url, postData, callback, orgs)
    WWWEx.postBytes(Utl.urlAddTimes(url), postData, CLAssetType.bytes, callback, CLLNet.httpError, orgs, true)
end

function CLLNet.httpPostUsermgr(data, callback)
    local postData = BioUtl.writeObject(data)
    httpPostBio(baseUrlUsermgr, postData, CLLNet.onResponsedUsermgr, {callback = callback, data = data})
end

function CLLNet.onResponsedUsermgr(content, orgs)
    local callback = orgs.callback
    local map = nil
    if content then
        map = BioUtl.readObject(content)
    end
    if map then
        local cmd = map[0]
        local dispatchInfor = NetProtoUsermgr.dispatch[cmd]
        if dispatchInfor then
            local data = dispatchInfor.onReceive(map)
            if callback then
                callback(data)
            else
                CLLNet.dispatch(data)
            end
        end
    end
end

function CLLNet.httpError(content, orgs)
    local callback = orgs.callback
    local data = orgs.data
    local map = {}
    local ret = {}
    local cmd = data[0]
    ret.code = number2bio(2)
    ret.msg = "http error"
    map.retInfor = ret
    map.cmd = cmd
    if callback then
        callback(map, data)
    else
        CLLNet.dispatch(map)
    end
end

--============================================================

function CLLNet.dispatchGame(map)
    if (map == nil) then
        return
    end
    if type(map) == "string" then
        if map == "connectCallback" then
            CLPanelManager.topPanel:procNetwork("connectCallback", 1, "connectCallback", nil)
            --csSelf:invoke4Lua(CLLNet.heart, nil, timeOutSec, true);
            InvokeEx.invoke(CLLNet.heart, timeOutSec)
        elseif map == "outofNetConnect" then
            --csSelf:cancelInvoke4Lua(CLLNet.heart)
            InvokeEx.cancelInvoke(CLLNet.heart)
            CLPanelManager.topPanel:procNetwork("outofNetConnect", -9999, "outofNetConnect", nil)

            -- 处理断线处理
            if GameMode.none ~= MyCfg.mode then
                local ok, result = pcall(procOffLine)
                if not ok then
                    printe(result)
                end
            end
        end
    else
        local dispatchInfor = protoClient.dispatch[map[0]]
        if dispatchInfor then
            local data = dispatchInfor.onReceive(map)
            CLLNet.dispatch(data)
        end
    end
end

function CLLNet.dispatch(map)
    local cmd = map.cmd -- 接口名
    if protoClient and cmd == protoClient.cmds.heart then
        -- 心跳不处理
        return
    end
    local retInfor = map.retInfor
    -- 解密bio
    retInfor.code = BioUtl.bio2int(retInfor.code)
    local succ = retInfor.code
    local msg = retInfor.msg

    if MyCfg.self.isEditMode then
        print(joinStr("cmd=", cmd, "==succ==", succ, "==msg==", msg))
    end

    if (succ ~= NetSuccess) then
        retInfor.msg = Localization.Get(joinStr("Error_", succ))
        CLAlert.add(retInfor.msg, Color.red, 1)
        hideHotWheel()
    else
        -- success
        CLLNet.cacheData(cmd, map)
    end

    -- 通知所有显示的页面
    local panels4Retain = CLPanelManager.panels4Retain
    if (panels4Retain ~= nil and panels4Retain.Length > 0) then
        for i = 0, panels4Retain.Length - 1 do
            panels4Retain[i]:procNetwork(cmd, succ, msg, map)
        end
    else
        if (CLPanelManager.topPanel ~= nil) then
            CLPanelManager.topPanel:procNetwork(cmd, succ, msg, map)
        end
    end
end

--数据缓存的function
local cacheDataFuncs = {
    [protoClient.cmds.sendNetCfg] = function(netData)
        ---@type NetPtMonsters.RC_sendNetCfg
        local data = netData
        -- 初始化时间
        local systime = bio2number(data.systime)
        DateEx.init(systime)
        ---@type CLLNetSerialize
        local netSerialize = csSelf.luaTable
        if netSerialize then
            netSerialize.setCfg(data.netCfg)
        end
    end,
    [protoClient.cmds.login] = function(netData)
        ---@type NetPtMonsters.RC_login
        local data = netData
        protoClient.__sessionID = bio2number(data.session)
        -- 初始化时间
        local systime = bio2number(data.systime)
        DateEx.init(systime)
        --//TODO:
        --[[
        ---@type protoClient.ST_player
        local player = data.player
        local p = IDDBPlayer.new(player)
        IDDBPlayer.myself = p
        ---@type protoClient.ST_city
        local city = data.city
        local curCity = IDDBCity.new(city)
        curCity:initDockyardShips()
        IDDBCity.curCity = curCity
        --]]
    end
}

function CLLNet.cacheData(cmd, netData)
    if protoClient == nil then
        return
    end
    local func = cacheDataFuncs[cmd]
    if func then
        func(netData)
    end
end

-- 心跳
function CLLNet.heart()
    net:send(protoClient.send.heart())
    InvokeEx.invoke(CLLNet.heart, timeOutSec)
    --csSelf:invoke4Lua(CLLNet.heart, nil, timeOutSec, true)
end

function CLLNet.cancelHeart()
    --csSelf:cancelInvoke4Lua(CLLNet.heart)
    InvokeEx.cancelInvoke(CLLNet.heart)
end

return CLLNet
