require("battle.HWScene")
HWBattle = {}
local csSelf
local transform

HWBattle.offenseObjs = {} -- 进攻方
HWBattle.defenseObjs = {} -- 防守方
---@type IDLBuilding
HWBattle.offBase = nil --进攻方的主基地
---@type IDLBuilding
HWBattle.defBase = nil --敌方的主基地

function HWBattle._init()
    if HWBattle.csSelf ~= nil then
        return
    end
    local go = GameObject("battleRoot")
    HWBattle.csSelf = go:AddComponent(typeof(CLBaseLua))
    HWBattle.csSelf.luaTable = HWBattle
    csSelf = HWBattle.csSelf
    transform = go.transform
    transform.parent = MyMain.self.transform
    transform.localScale = Vector3.one
    transform.localPosition = Vector3.zero
    HWBattle.useInstancing = AnimationInstancingMgr.Instance.UseInstancing
end

function HWBattle.init(data, callback, progressCB)
    HWBattle._init()
    HWBattle.callback = callback
    HWScene.init(data, HWBattle.onFinishLoadScene, progressCB)
end

function HWBattle.onFinishLoadScene()
    -- 加载建筑
    local buildings = {
        {id = 1, isOffense = true, pos = 406},
        {id = 2, isOffense = true, pos = 414},
        {id = 1, isOffense = false, pos = 444},
        {id = 1, isOffense = false, pos = 444},
        {id = 2, isOffense = false, pos = 436}
    }
    HWBattle.loadBuildings(
        {
            list = buildings,
            i = 1,
            callback = function()
                CLAStarPathSearch.current:scan()
                if HWBattle.callback then
                    HWBattle.callback()
                end
            end
        }
    )
end

function HWBattle.loadBuildings(data)
    local list = data.list
    local i = data.i
    local id = list[i].id
    CLThingsPool.borrowObjAsyn("Buildings." .. id, HWBattle.onLoadBuilding, data)
end

function HWBattle.onLoadBuilding(name, obj, param)
    local list = param.list
    local i = param.i
    local data = list[i]
    local isOffense = data.isOffense
    local index = data.pos
    local id = data.id
    if obj then
        obj.transform.parent = transform
        obj.transform.localScale = Vector3.one
        HWScene.placeBuilding(obj, id, index)

        local attr = DBCfg.getBuildingByID(id)
        SetActive(obj, true)
        ---@type Coolape.CLUnit
        local unit = obj:GetComponent("MyUnit")
        ---@type IDLBuilding
        local buildingLua = nil
        if unit.luaTable == nil then
            buildingLua = GameUtl.newBuildingLua(attr)
            unit.luaTable = buildingLua
            unit:initGetLuaFunc()
        else
            buildingLua = unit.luaTable
        end

        buildingLua:init(unit, id, 0, 1, true, {index = index, serverData = {}})

        if isOffense then
            HWBattle.offenseObjs[unit.instanceID] = buildingLua
            if id == 1 then
                buildingLua.transform.localEulerAngles = Vector3(0, -90, 0)
                HWBattle.offBase = buildingLua
            end
        else
            HWBattle.defenseObjs[unit.instanceID] = buildingLua
            if id == 1 then
                buildingLua.transform.localEulerAngles = Vector3(0, 90, 0)
                HWBattle.defBase = buildingLua
            end
        end
        if i >= #list then
            -- finish
            if (param.callback) then
                param.callback()
            end
        else
            param.i = param.i + 1
            HWBattle.loadBuildings(param)
        end
    end
end

function HWBattle.newRole(id, isOffense)
    local roleName = ""
    if HWBattle.useInstancing then
        if isOffense then
            roleName = joinStr("role" .. id .. "_1_ins")
        else
            roleName = joinStr("role" .. id .. "_2_ins")
        end
    else
        roleName = joinStr("role" .. id)
    end
    CLRolePool.borrowObjAsyn(
        roleName,
        function(name, go, orgs)
            ---@type MyUnit
            local role = go
            role.transform.parent = transform
            role.transform.position = HWBattle.getRoleBornPos(isOffense)
            SetActive(role.gameObject, true)
            if role.luaTable == nil then
                role.luaTable = GameUtl.newRoleLua(id)
            end
            role.luaTable:init(role, id, 1, isOffense, nil)
            HWBattle.offenseObjs[role.instanceID] = role.luaTable
        end
    )
end

---@public 取得出生点
function HWBattle.getRoleBornPos(isOffense)
    if isOffense then
        return HWBattle.offBase.door.position
    else
        return HWBattle.defBase.door.position
    end
end

function HWBattle.onClickSomeObj(unit, pos)
    if unit.isTile then
        HWScene.onClickTile(unit)
    else
    end
end

function HWBattle.clean()
    for k, v in ipairs(HWBattle.offenseObjs) do
        v:clean()
        SetActive(v.gameObject, false)
        if v.isRole then
            CLRolePool.returnObj(v.csSelf)
        elseif v.isBuilding then
            CLThingsPool.returnObj(v.gameObject)
        end
    end
    HWBattle.defenseObjs = {}
    for k, v in ipairs(HWBattle.defenseObjs) do
        v:clean()
        SetActive(v.gameObject, false)
        if v.isRole then
            CLRolePool.returnObj(v.csSelf)
        elseif v.isBuilding then
            CLThingsPool.returnObj(v.gameObject)
        end
    end
    HWBattle.defenseObjs = {}

    HWScene.clean()
end

return HWBattle
