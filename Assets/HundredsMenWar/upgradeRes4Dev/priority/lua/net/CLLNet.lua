--- 网络下行数据调度器
do
    require("bio.BioUtl")
    require("net.NetProtoUsermgrClient")
    CLLNet = {}

    local strLen = string.len;
    local strSub = string.sub;
    local strPack = string.pack
    local maxPackSize = 1 * 1024 - 1;
    local subPackSize = 1 * 1024 - 1 - 50;
    local csSelf;
    local __maxLen = 1024 * 1024;

    function CLLNet.init()
        csSelf = Net.self;
    end

    local httpPostBio = function(url, postData, callback)
        WWWEx.postBytes(Utl.urlAddTimes(url),
            postData,
            CLAssetType.bytes,
            callback,
            CLLNet.httpError,nil, true)
    end

    local baseUrlUsermgr = "http://127.0.0.1:8801/usermgr/postbio"
    function CLLNet.httpPostUsermgr( data)
        local postData = BioUtl.writeObject(data)
        httpPostBio(baseUrlUsermgr, postData, CLLNet.onResponsedUsermgr)
    end

    function CLLNet.onResponsedUsermgr(content, orgs)
        local map = nil
        if content then
            map = BioUtl.readObject(content)
        end
        if map then
            local dispatchInfor = NetProtoUsermgr.dispatch[map[0]]
            if dispatchInfor then
                local data = dispatchInfor.onReceive(map);
                CLLNet.dispatch(data)
            end
        end
    end

    function CLLNet.httpError(content, orgs)
        --CLLNet.dispatchHttp(map)
    end

    --============================================================
    -- 组包
    function CLLNet.packMsg(data, tcp)
        local bytes = BioUtl.writeObject(data)
        if bytes == nil or tcp == nil or tcp.socket == nil then
            return nil;
        end
        local len = strLen(bytes)
        if len > maxPackSize then
            -- 处理分包
            local packList = ArrayList()
            local subPackgeCount = math.floor(len / subPackSize)
            local left = len % subPackSize
            local count = 0;
            if left > 0 then
                count = subPackgeCount + 1
            end
            for i = 1, subPackgeCount do
                local subPackg = {}
                table.insert(subPackg, count);
                table.insert(subPackg, i);
                table.insert(subPackg, strSub(bytes, ((i - 1) * subPackSize) + 1, i * subPackSize));
                local package = strPack(">s2", BioUtl.writeObject(subPackg))
                tcp.socket:SendAsync(package);
            end
            if left > 0 then
                local subPackg = {}
                table.insert(subPackg, count);
                table.insert(subPackg, count);
                table.insert(subPackg, strSub(bytes, len - left + 1, len));
                local package = strPack(">s2", BioUtl.writeObject(subPackg))
                tcp.socket:SendAsync(package);
            end
        else
            local package = strPack(">s2", bytes)
            tcp.socket:SendAsync(package);
        end
    end

    local function isArray(t)
        if t == nil then
            return false;
        end
        local ret = true;
        if type(t) == "table" then
            local i = 0
            for _ in pairs(t) do
                i = i + 1
                if t[i] == nil then
                    return false
                end
            end
        else
            ret = false;
        end
        return ret;
    end

    -- 完整的接口都是table，当有分包的时候会收到list。list[1]=共有几个分包，list[2]＝第几个分包，list[3]＝ 内容
    local function isSubPackage(m)
        if m[0] then
            --判断有没有cmd
            return false
        end
        if isArray(m) then
            return true;
        end
        return false
    end

    local currPack = {};
    local function unPackSubMsg(m)
        -- 是分包
        local len = m[1]
        local index = m[2]
        table.insert(currPack, index, m[3])
        if (#currPack == len) then
            -- 说明分包已经取完整
            local map = BioUtl.readObject(table.concat(currPack, ""))
            currPack = nil;
            currPack = {}
            return map;
        end
        return nil;
    end

    -- 解包
    function CLLNet.unpackMsg(socket, buffer)
        local ret = nil;
        local oldPos = buffer.Position;
        local tatalLen = buffer.Length;
        local needLen = buffer:ReadByte() * 256 + buffer:ReadByte();
        if (needLen <= 0 and needLen > __maxLen) then
            --// 网络Number据错误。断isOpen网络
            socket:close();
            return nil;
        end
        local usedLen = buffer.Position;
        if (usedLen + needLen <= tatalLen) then
            local lessBuff = Utl.read4MemoryStream(buffer, 0, needLen);
            ret = BioUtl.readObject(lessBuff);
        else
            --说明长度不够
            buffer.Position = oldPos;
        end

        if ret and isSubPackage(ret) then
            return unPackSubMsg(ret)
        else
            return ret;
        end
    end
    --============================================================

    function CLLNet.dispatchGame(map)
        if (map == nil) then
            return
        end
        if type(map) == "string" then
            if map == "connectCallback" then
                CLPanelManager.topPanel:procNetwork("connectCallback", 1, "connectCallback", nil);
            elseif map == "outofNetConnect" then
                CLPanelManager.topPanel:procNetwork("outofNetConnect", -9999, "outofNetConnect", nil);
            end
        else
            local dispatchInfor = NetProto.dispatch[map[0]]
            if dispatchInfor then
                local data = dispatchInfor.onReceive(map);
                CLLNet.dispatch(data)
            end
        end
    end

    function CLLNet.dispatch(map)
        local cmd = map.cmd; -- 接口名
        local retInfor = map.retInfor;
        -- 解密bio
        retInfor.code = BioUtl.bio2int(retInfor.code);
        local succ = retInfor.code;
        local msg = retInfor.msg;
        if (succ ~= 1) then
            retInfor.msg = Localization.Get("Error_" .. succ);
            CLAlert.add(msg, Color.red, 1);
        else
            -- success
            CLLNet.cacheData(cmd, map);
        end

        -- 通知所有显示的页面
        local panels4Retain = CLPanelManager.panels4Retain
        if (panels4Retain ~= nil and panels4Retain.Length > 0) then
            for i = 0, panels4Retain.Length - 1 do
                panels4Retain[i]:procNetwork(cmd, succ, msg, map);
            end
        else
            if (CLPanelManager.topPanel ~= nil) then
                CLPanelManager.topPanel:procNetwork(cmd, succ, msg, map);
            end
        end
    end

    function CLLNet.cacheData(cmd, data)
        if (cmd == "getMapData") then
            if (data ~= nil and data.list ~= nil) then
                CLLData.onGetMapData(data.list);
            end
        elseif (cmd == "getMapDataOneScreen") then
            if (data ~= nil) then
                CLLData.onGetOneMapPageData(data);
            end
        end
    end

    -- 显示网关公告
    function CLLNet.showGateNotice(paras)
        local data = paras[1];
        if (data ~= nil and data.list ~= nil) then
            local count = data.list.Count;
            local msg = "";
            local notice = nil;
            for i = 1, count do
                notice = data.list[i];
                msg = msg .. notice.title .. "\n" .. notice.cont .. "\n";
            end
            if (msg ~= "") then
                CLUIUtl.showConfirm(msg, nil);
            end
        end
    end

    return CLLNet;
end

