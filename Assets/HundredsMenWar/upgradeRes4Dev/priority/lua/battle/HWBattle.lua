require("battle.HWScene")
HWBattle = {}
local csSelf
local transform

HWBattle.offenseObjs = {} -- 进攻方
HWBattle.defenseObjs = {} -- 防守方

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
end

function HWBattle.init(data, callback, progressCB)
    HWBattle._init()
    HWBattle.callback = callback
    HWScene.init(data, HWBattle.onFinishLoadScene, progressCB)
end

function HWBattle.onFinishLoadScene()
    -- 加载建筑
    HWBattle.loadBuildings()
    CLAStarPathSearch.current:scan()
    if HWBattle.callback then
        HWBattle.callback()
    end
end

function HWBattle.loadBuildings()
    CLThingsPool.borrowObjAsyn("Buildings.1", HWBattle.onLoadBuilding, {id = 1, isOffense = true, pos = 240})
    CLThingsPool.borrowObjAsyn("Buildings.2", HWBattle.onLoadBuilding, {id = 2, isOffense = true, pos = 240})
    CLThingsPool.borrowObjAsyn("Buildings.1", HWBattle.onLoadBuilding, {id = 1, isOffense = false, pos = 120})
    CLThingsPool.borrowObjAsyn("Buildings.2", HWBattle.onLoadBuilding, {id = 2, isOffense = false, pos = 240})
end

function HWBattle.onLoadBuilding(name, obj, param)
    local isOffense = param.isOffense
    local index = param.pos
    local id = param.id
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
        else
            HWBattle.defenseObjs[unit.instanceID] = buildingLua
        end
    end
end

function HWBattle.onClickSomeObj(unit, pos)
    if unit.isTile then
        HWScene.onClickTile(unit)
    else

    end
end

function HWBattle.clean()
    HWScene.clean()
end

return HWBattle
