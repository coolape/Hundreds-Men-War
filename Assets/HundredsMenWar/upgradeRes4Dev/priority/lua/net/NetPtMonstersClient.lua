do
    ---@class NetPtMonsters
    NetPtMonsters = {}
    local table = table
    require("bio.BioUtl")

    NetPtMonsters.__sessionID = 0 -- 会话ID
    NetPtMonsters.dispatch = {}
    local __callbackInfor = {} -- 回调信息
    local __callTimes = 1
    ---@public 设计回调信息
    local setCallback = function (callback, orgs, ret)
       if callback then
           local callbackKey = os.time() + __callTimes
           __callTimes = __callTimes + 1
           __callbackInfor[callbackKey] = {callback, orgs}
           ret[3] = callbackKey
        end
    end
    ---@public 处理回调
    local doCallback = function(map, result)
        local callbackKey = map[3]
        if callbackKey then
            local cbinfor = __callbackInfor[callbackKey]
            if cbinfor then
                pcall(cbinfor[1], cbinfor[2], result)
            end
            __callbackInfor[callbackKey] = nil
        end
    end
    --==============================
    -- public toMap
    NetPtMonsters._toMap = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = stuctobj.toMap(v)
        end
        return ret
    end
    -- public toList
    NetPtMonsters._toList = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, stuctobj.toMap(v))
        end
        return ret
    end
    -- public parse
    NetPtMonsters._parseMap = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = stuctobj.parse(v)
        end
        return ret
    end
    -- public parse
    NetPtMonsters._parseList = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, stuctobj.parse(v))
        end
        return ret
    end
  --==================================
  --==================================
    ---@class NetPtMonsters.ST_retInfor 返回信息
    ---@field public msg string 返回消息
    ---@field public code number 返回值
    NetPtMonsters.ST_retInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[10] = m.msg  -- 返回消息 string
            r[11] = m.code  -- 返回值 int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.msg = m[10] --  string
            r.code = m[11] --  int
            return r;
        end,
    }
    ---@class NetPtMonsters.ST_player 用户信息
    ---@field public idx number 唯一标识 int
    ---@field public diam number 钻石 long
    ---@field public name string 名字
    ---@field public unionidx number 联盟id int
    ---@field public cityidx number 城池id int
    ---@field public lev number 等级 long
    ---@field public status number 状态 1：正常 int
    NetPtMonsters.ST_player = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] = m.idx  -- 唯一标识 int int
            r[13] = m.diam  -- 钻石 long int
            r[14] = m.name  -- 名字 string
            r[15] = m.unionidx  -- 联盟id int int
            r[16] = m.cityidx  -- 城池id int int
            r[17] = m.lev  -- 等级 long int
            r[18] = m.status  -- 状态 1：正常 int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.diam = m[13] --  int
            r.name = m[14] --  string
            r.unionidx = m[15] --  int
            r.cityidx = m[16] --  int
            r.lev = m[17] --  int
            r.status = m[18] --  int
            return r;
        end,
    }
    ---@class NetPtMonsters.ST_netCfg 网络协议解析配置
    ---@field public encryptType number 加密类别，1：只加密客户端，2：只加密服务器，3：前后端都加密，0及其它情况：不加密
    ---@field public checkTimeStamp useData 检测时间戳
    ---@field public secretKey string 密钥
    NetPtMonsters.ST_netCfg = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[19] = m.encryptType  -- 加密类别，1：只加密客户端，2：只加密服务器，3：前后端都加密，0及其它情况：不加密 int
            r[20] = m.checkTimeStamp  -- 检测时间戳 boolean
            r[21] = m.secretKey  -- 密钥 string
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.encryptType = m[19] --  int
            r.checkTimeStamp = m[20] --  boolean
            r.secretKey = m[21] --  string
            return r;
        end,
    }
    --==============================
    NetPtMonsters.send = {
    -- 登陆
    login = function(uidx, channel, deviceID, isEditMode, __callback, __orgs) -- __callback:接口回调, __orgs:回调参数
        local ret = {}
        ret[0] = 22
        ret[1] = NetPtMonsters.__sessionID
        ret[23] = uidx; -- 用户id
        ret[24] = channel; -- 渠道号
        ret[25] = deviceID; -- 机器码
        ret[26] = isEditMode; -- 编辑模式
        setCallback(__callback, __orgs, ret)
        return ret
    end,
    -- 心跳
    heart = function(__callback, __orgs) -- __callback:接口回调, __orgs:回调参数
        local ret = {}
        ret[0] = 30
        ret[1] = NetPtMonsters.__sessionID
        setCallback(__callback, __orgs, ret)
        return ret
    end,
    -- 网络协议配置
    sendNetCfg = function(__callback, __orgs) -- __callback:接口回调, __orgs:回调参数
        local ret = {}
        ret[0] = 31
        ret[1] = NetPtMonsters.__sessionID
        setCallback(__callback, __orgs, ret)
        return ret
    end,
    -- 玩家信息变化时推送
    onPlayerChg = function(__callback, __orgs) -- __callback:接口回调, __orgs:回调参数
        local ret = {}
        ret[0] = 33
        ret[1] = NetPtMonsters.__sessionID
        setCallback(__callback, __orgs, ret)
        return ret
    end,
    -- 登出
    logout = function(__callback, __orgs) -- __callback:接口回调, __orgs:回调参数
        local ret = {}
        ret[0] = 34
        ret[1] = NetPtMonsters.__sessionID
        setCallback(__callback, __orgs, ret)
        return ret
    end,
    }
    --==============================
    NetPtMonsters.recive = {
    ---@class NetPtMonsters.RC_login
    ---@field public retInfor NetPtMonsters.ST_retInfor 返回信息
    ---@field public player NetPtMonsters.ST_player 玩家信息
    ---@field public systime  系统时间 long
    ---@field public session  会话id
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.retInfor = NetPtMonsters.ST_retInfor.parse(map[2]) -- 返回信息
        ret.player = NetPtMonsters.ST_player.parse(map[27]) -- 玩家信息
        ret.systime = map[28]-- 系统时间 long
        ret.session = map[29]-- 会话id
        doCallback(map, ret)
        return ret
    end,
    ---@class NetPtMonsters.RC_heart
    heart = function(map)
        local ret = {}
        ret.cmd = "heart"
        doCallback(map, ret)
        return ret
    end,
    ---@class NetPtMonsters.RC_sendNetCfg
    ---@field public retInfor NetPtMonsters.ST_retInfor 返回信息
    ---@field public netCfg NetPtMonsters.ST_netCfg 网络协议解析配置
    ---@field public systime  系统时间 long
    sendNetCfg = function(map)
        local ret = {}
        ret.cmd = "sendNetCfg"
        ret.retInfor = NetPtMonsters.ST_retInfor.parse(map[2]) -- 返回信息
        ret.netCfg = NetPtMonsters.ST_netCfg.parse(map[32]) -- 网络协议解析配置
        ret.systime = map[28]-- 系统时间 long
        doCallback(map, ret)
        return ret
    end,
    ---@class NetPtMonsters.RC_onPlayerChg
    ---@field public retInfor NetPtMonsters.ST_retInfor 返回信息
    ---@field public player NetPtMonsters.ST_player 玩家信息
    onPlayerChg = function(map)
        local ret = {}
        ret.cmd = "onPlayerChg"
        ret.retInfor = NetPtMonsters.ST_retInfor.parse(map[2]) -- 返回信息
        ret.player = NetPtMonsters.ST_player.parse(map[27]) -- 玩家信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetPtMonsters.RC_logout
    ---@field public retInfor NetPtMonsters.ST_retInfor 返回信息
    logout = function(map)
        local ret = {}
        ret.cmd = "logout"
        ret.retInfor = NetPtMonsters.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    }
    --==============================
    NetPtMonsters.dispatch[22]={onReceive = NetPtMonsters.recive.login, send = NetPtMonsters.send.login}
    NetPtMonsters.dispatch[30]={onReceive = NetPtMonsters.recive.heart, send = NetPtMonsters.send.heart}
    NetPtMonsters.dispatch[31]={onReceive = NetPtMonsters.recive.sendNetCfg, send = NetPtMonsters.send.sendNetCfg}
    NetPtMonsters.dispatch[33]={onReceive = NetPtMonsters.recive.onPlayerChg, send = NetPtMonsters.send.onPlayerChg}
    NetPtMonsters.dispatch[34]={onReceive = NetPtMonsters.recive.logout, send = NetPtMonsters.send.logout}
    --==============================
    NetPtMonsters.cmds = {
        login = "login", -- 登陆,
        heart = "heart", -- 心跳,
        sendNetCfg = "sendNetCfg", -- 网络协议配置,
        onPlayerChg = "onPlayerChg", -- 玩家信息变化时推送,
        logout = "logout", -- 登出
    }
    --==============================
    return NetPtMonsters
end
