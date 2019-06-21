HWScene = {}
local IDLGridTileSide = require("battle.IDLGridTileSide")
HWScene.gridTileSidePorc = IDLGridTileSide
HWScene.offset4Tile = Vector3.up * 0.3
HWScene.offset4Building = Vector3.up * 0.3
HWScene.selectedUnit = nil
local transform
local grid
local lookAtTarget = MyCfg.self.lookAtTarget
local drag4World = CLUIDrag4World.self
local progressCallback
local gridState4Tile = {}
local gridState4Building = {}
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
    local rows = 20
    local cols = 40
    HWScene.grid.numRows = rows
    HWScene.grid.numCols = cols
    HWScene.grid.numGroundRows = rows
    HWScene.grid.numGroundCols = cols
    HWScene.grid.cellSize = 1
    HWScene.grid.transform.localPosition = Vector3(-rows / 2, 0, -cols / 2)
    HWScene.grid.showGrid = false
    HWScene.grid.showGridRange = true
    HWScene.grid:init()
    HWScene.grid:showRect()

    CLAStarPathSearch.current.numRows = rows
    CLAStarPathSearch.current.numCols = cols
    CLAStarPathSearch.current.cellSize = 1
    CLAStarPathSearch.current:init(Vector3(-rows / 2, 0, -cols / 2))

    local uvWave = HWScene.gameObject:AddComponent(typeof(CS.Wave))
    IDLGridTileSide.init(grid, uvWave)

    -- 加载水
    CLThingsPool.borrowObjAsyn("OceanLow", HWScene.onLoadOcena)
end

function HWScene.init(data, callback, progressCB)
    progressCallback = progressCB
    HWScene._init()
    HWScene.callback = callback
    HWScene.loadTiles(HWScene.onFinishLoadTiles)
    -- 屏幕拖动代理
    drag4World.onDragMoveDelegate = HWScene.onDragMove
    drag4World.onDragScaleDelegate = HWScene.onScaleGround
end

function HWScene.onFinishLoadTiles()
    if HWScene.callback then
        HWScene.callback()
    end
end

---@public 加载地块
function HWScene.loadTiles(cb)
    local list = {}
    local x, y
    for i = 0, grid.NumberOfCells - 1 do
        x = grid:GetX(i)
        y = grid:GetY(i)
        if
            ((x > 2 and x < HWScene.grid.numCols / 2 - 4) or
                (x > HWScene.grid.numCols / 2 + 4 and x < HWScene.grid.numCols - 2)) and
                y > 2 and
                y < HWScene.grid.numRows - 2
         then
            if x % 2 == 0 and y % 2 == 0 then
                table.insert(list, {pos = number2bio(i)})
            end
        end
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
    local index = bio2number(d.pos)
    obj.transform.parent = transform
    obj.transform.localScale = Vector3.one
    obj.transform.position = grid:GetCellPosition(index) + HWScene.offset4Tile
    SetActive(obj, true)
    local index2 = grid:GetCellIndex(obj.transform.position)
    HWScene.refreshGridState(index2, 2, true, gridState4Tile)

    local tile = obj:GetComponent("CLCellLua")
    tile:init(d, nil)
    tiles[bio2number(d.pos)] = tile.luaTable

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

function HWScene.getState4Tile()
    return gridState4Tile
end
function HWScene.getTiles()
    return tiles
end

function HWScene.getGrid()
    return grid
end
function HWScene.onClickTile(tile)
end

function HWScene.onClickOcean()
end

function HWScene.setOtherUnitsColiderState(target, activeCollider)
    for k, v in pairs(tiles) do
        if v ~= target then
            v.setCollider(activeCollider)
        end
    end
end

function HWScene.placeBuilding(building, id, index)
    local attr = DBCfg.getBuildingByID(id)
    local size = bio2Int(attr.Size)
    local posOffset = HWScene.offset4Building

    if (size % 2 == 0) then
        building.transform.position = grid:GetCellPosition(index) + posOffset
    else
        building.transform.position = grid:GetCellCenter(index) + posOffset
    end
    IDMainCity.refreshGridState(index, bio2number(attr.Size), true, gridState4Building)
end

function HWScene.clean()
    HWScene.onClickOcean()

    for k, v in pairs(tiles) do
        v.csSelf:clean()
        CLThingsPool.returnObj(v.gameObject)
        SetActive(v.gameObject, false)
    end
    tiles = {}
    IDLGridTileSide.clean()

    gridState4Tile = {}
    gridState4Building = {}
end

return HWScene
