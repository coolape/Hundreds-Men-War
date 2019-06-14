HWScene = {}
require("battle.IDLGridTileSide")

HWScene.offset4Tile = Vector3.zero
local transform
local grid
local lookAtTarget = MyCfg.self.lookAtTarget
local drag4World = CLUIDrag4World.self
local progressCallback
local gridState4Tile = {}
local tiles = {}

-- 重新加载海
function HWScene.onLoadOcena(name, obj, orgs)
    HWScene.ocean = obj:GetComponent("MirrorReflection")
    HWScene.oceanTransform = HWScene.ocean.transform
    HWScene.oceanTransform.parent = HWScene.transform
    --IDWorldMap.oceanTransform.localPosition = IDMainCity.offset4Ocean
    HWScene.oceanTransform.localScale = Vector3.one
    ---@type Coolape.CLBaseLua
    local oceanlua = HWScene.ocean:GetComponent("CLBaseLua")
    if oceanlua.luaTable == nil then
        oceanlua:setLua()
        oceanlua.luaTable.init(oceanlua)
    end
    -- 先为false
    HWScene.ocean.enableMirrorReflection = false
    HWScene.oceanTransform.position = lookAtTarget.position
    SetActive(obj, true)
end

function HWScene._init()
    if HWScene.isFinishInit then
        return
    end
    HWScene.isFinishInit = true
    HWScene.gameObject = GameObject("Scene")
    HWScene.transform = HWScene.gameObject.transform
    transform = HWScene.transform
    HWScene.transform.position = Vector3.zero

    local go = GameObject("grid")
    go.transform.parent = HWScene.transform
    HWScene.grid = go:AddComponent(typeof(CLGrid))
    HWScene.grid.gridLineHight = HWScene.offset4Tile.y
    grid = HWScene.grid.grid

    HWScene.grid.numRows = 5
    HWScene.grid.numCols = 15
    HWScene.grid.numGroundRows = 5
    HWScene.grid.numGroundCols = 15
    HWScene.grid.cellSize = 2
    HWScene.grid.transform.localPosition = Vector3(-5 * 2 / 2, 0, -15 * 2 / 2)
    HWScene.grid.showGrid = false
    HWScene.grid.showGridRange = true
    HWScene.grid:showRect()
    HWScene.grid:init()

    -- 加载水
    CLThingsPool.borrowObjAsyn("OceanLow", HWScene.onLoadOcena)
end

function HWScene.init(data, callback, progressCB)
    progressCallback = progressCB
    HWScene._init()
    HWScene.loadTiles(callback)
    -- 屏幕拖动代理
    drag4World.onDragMoveDelegate = HWScene.onDragMove
    drag4World.onDragScaleDelegate = HWScene.onScaleGround
end

---@public 加载地块
function HWScene.loadTiles(cb)
    local list = {}
    for i = 0, grid.NumberOfCells - 1 do
        table.insert(list, {pos = i})
    end
    HWScene.totalTile = #list
    if HWScene.totalTile == 0 then
        if cb then
            cb()
        end
    else
        HWScene.doLoadTile({1, list, cb})
    end
end

function HWScene.doLoadTile(orgs)
    CLThingsPool.borrowObjAsyn("Tiles.Tile_1", HWScene.onLoadTile, orgs)
end

---@param obj UnityEngine.GameObject
---@param d IDDBTile
function HWScene.onLoadTile(name, obj, orgs)
    local i = orgs[1]
    local list = orgs[2]
    local cb = orgs[3]
    local d = list[i]
    local index = d.pos
    obj.transform.parent = transform
    obj.transform.localScale = Vector3.one
    obj.transform.position = grid:GetCellPosition(index) + HWScene.offset4Tile
    SetActive(obj, true)
    local index2 = grid:GetCellIndex(obj.transform.position)
    HWScene.refreshGridState(index2, 1, true, gridState4Tile)

    local tile = obj:GetComponent("CLCellLua")
    tile:init(d, nil)
    tiles[bio2number(d.idx)] = tile.luaTable

    Utl.doCallback(progressCallback, HWScene.totalTile, i)
    if i == #list then
        IDLGridTileSide.refreshAndShow(cb, progressCallback, false)
    else
        InvokeEx.invokeByUpdate(HWScene.doLoadTile, {i + 1, list, cb}, 0.01)
    end
end

---@public 刷新网格的状态
function HWScene.refreshGridState(center, size, val, gridstate)
    --gridstate = gridstate or gridState4Building
    local list = HWScene.grid:getOwnGrids(center, size)
    local count = list.Count
    for i = 0, count - 1 do
        gridstate[NumEx.getIntPart(list[i])] = val
    end
end

function HWScene.onClickOcean()
end

function HWScene.clean()
    HWScene.onClickOcean()

    for k, v in pairs(tiles) do
        v.csSelf:clean()
        CLThingsPool.returnObj(v.gameObject)
        SetActive(v.gameObject, false)
    end
    tiles = {}
end

return HWScene
