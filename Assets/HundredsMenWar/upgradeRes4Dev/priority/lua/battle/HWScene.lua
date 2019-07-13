HWScene = {}
local IDLGridTileSide = require("battle.IDLGridTileSide")
require("battle.IDLBuildingSize")
HWScene.gridTileSidePorc = IDLGridTileSide
HWScene.offset4Tile = Vector3.up * 0.35
HWScene.offset4Building = Vector3.up * 0.4
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
    local rows = 15
    local cols = 50
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

    CLThingsPool.borrowObjAsyn(
        "FourWayArrow",
        function(name, obj, orgs)
            obj.transform.parent = transform
        end
    )

    IDLBuildingSize.init()
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

---@public grid中index位置在的size个格子是都是空闲的
function HWScene.isSizeInFreeCell(index, size, canOnLand, canOnWater)
    local list = HWScene.grid:getOwnGrids(index, size)
    local count = list.Count
    local cellIndex = 0
    local haveland = false
    local havewater = false
    for i = 0, count - 1 do
        cellIndex = NumEx.getIntPart(list[i])
        if (not grid:IsInBounds(cellIndex)) then
            return false
        end
        if (gridState4Building[cellIndex] == true) then
            return false
        end
        if (not canOnLand) and gridState4Tile[cellIndex] == true then
            return false
        end
        if (not canOnWater) and (gridState4Tile[cellIndex] ~= true) then
            return false
        end
        if haveland or gridState4Tile[cellIndex] == true then
            haveland = true
        end
        if havewater or (gridState4Tile[cellIndex] ~= true) then
            havewater = true
        end
    end
    if haveland and havewater then
        return false
    end
    return true
end

---@public 选中状态
function HWScene.setSelected(unit, selected)
    if unit == nil then
        return
    end

    local cell = unit
    local isTile = cell.isTile
    if (selected) then
        SFourWayArrow.show(unit.csSelf, cell.size) --设置箭头
        SFourWayArrow.setMatToon()
        if isTile then
            HWScene.refreshGridState(cell.gridIndex, cell.size, false, gridState4Tile)
        else
            HWScene.refreshGridState(cell.gridIndex, cell.size, false, gridState4Building)
        end
    else
        -- //TODO:释放技能范围的圈
        HWScene.setOtherUnitsColiderState(nil, true)
        SFourWayArrow.hide()
        IDLBuildingSize.hide()

        local grid = HWScene.getGrid()
        local index = grid:GetCellIndex(unit.transform.position)
        local placeGround, placeSea
        if isTile then
            placeGround = false
            placeSea = true
        else
            placeGround = cell.attr.PlaceGround
            placeSea = cell.attr.PlaceSea
        end

        if (HWScene.isSizeInFreeCell(index, cell.size, placeGround, placeSea)) then
            cell.gridIndex = index

            if isTile then
                HWScene.refreshGridState(cell.gridIndex, cell.size, true, gridState4Tile)
            else
                HWScene.refreshGridState(cell.gridIndex, cell.size, true, gridState4Building)
            end
        else
            local pos = Vector3.zero
            if (cell.size % 2 == 0) then
                pos = grid:GetCellPosition(cell.gridIndex)
            else
                pos = grid:GetCellCenter(cell.gridIndex)
            end
            if unit.isTile then
                pos = pos + HWScene.offset4Tile
            else
                local posOffset
                posOffset = HWScene.offset4Building
                pos = pos + posOffset
            end
            unit.transform.position = pos
            if unit.shadow then
                unit.shadow.position = pos + Vector3.up * 0.01
            end

            if unit ~= HWScene.newBuildUnit then
                if isTile then
                    HWScene.refreshGridState(cell.gridIndex, cell.size, true, gridState4Tile)
                else
                    HWScene.refreshGridState(cell.gridIndex, cell.size, true, gridState4Building)
                end
            end
        end

        IDLCameraMgr.setPostProcessingProfile("normal")
        if isTile then
            NGUITools.SetLayer(unit.gameObject, LayerMask.NameToLayer("Tile"))
        else
            NGUITools.SetLayer(unit.body.gameObject, LayerMask.NameToLayer("Building"))
        end
        IDLBuildingSize.setLayer("Default")
    end
end

---@public 扩建地块
function HWScene.showExtendTile(data)
    GameUtl.hidePopupMenus()
    SFourWayArrow.hide()
    if HWScene.selectedUnit == nil then
        return
    end
    if HWScene.ExtendTile == nil then
        CLUIOtherObjPool.borrowObjAsyn(
            "ExtendTile",
            function(name, go, orgs)
                if orgs ~= HWScene.selectedUnit then
                    CLUIOtherObjPool.returnObj(go)
                    SetActive(go, false)
                    return
                end
                HWScene.ExtendTile = go:GetComponent("CLCellLua")
                HWScene.ExtendTile.transform.parent = transform
                HWScene.ExtendTile.transform.localScale = Vector3.one
                HWScene.ExtendTile.transform.localEulerAngles = Vector3.zero
                HWScene.ExtendTile.transform.position = HWScene.selectedUnit.transform.position
                --SetActive(go, true)
                IDLGridTileSide.clean()
                HWScene.ExtendTile:init(HWScene.selectedUnit, nil)
            end,
            HWScene.selectedUnit
        )
    else
        --SetActive(IDMainCity.ExtendTile.gameObject, true)
        IDLGridTileSide.clean()
        HWScene.ExtendTile:init(HWScene.selectedUnit, nil)
    end
end

---@public 能否放在一个地块
---@param ...、 可以是index或x、y
function HWScene.canPlaceTile(...)
    local param = {...}
    local index
    if #param > 1 then
        local x = param[1]
        local y = param[2]
        index = grid:GetCellIndex(x, y)
    else
        index = param[1]
    end
    return HWScene.isSizeInFreeCell(index, 2, false, true)
end

---@param tile IDLTile
function HWScene.onClickTile(tile)
    printe("HWScene.onClickTile==" .. tile.gridIndex)
    if (HWScene.selectedUnit == tile) then
        return
    end

    if HWScene.ExtendTile then
        SetActive(HWScene.ExtendTile.gameObject, false)
    end
    -- 处理之前的选中
    if (HWScene.selectedUnit ~= nil) then
        HWScene.setSelected(HWScene.selectedUnit, false)
    end

    -- 判断能否操作
    if tile then
        local cell = tile
        local index = cell.gridIndex
        local isOK = HWScene.isSizeInFreeCell(index, cell.size, true, false)
        if not isOK then
            CLAlert.add(LGet("CannotProcTile"), Color.yellow, 1)
            local newPos = grid:GetCellPosition(index)
            newPos = newPos + IDMainCity.offset4Tile
            IDLBuildingSize.show(cell.size, Color.red, newPos)
            IDLBuildingSize.setLayer("Top")
            InvokeEx.invoke(IDLBuildingSize.hide, 0.15)
            HWScene.selectedUnit = nil
            HWScene.showhhideBuildingProc(nil)
            return
        else
            cell.jump()
        end
    end

    -- 设置为当前选中
    HWScene.selectedUnit = tile
    if (HWScene.selectedUnit ~= nil) then
        HWScene.setSelected(tile, true)
    end

    HWScene.showhhideBuildingProc(tile)
end

function HWScene.onClickOcean()
    if HWScene.ExtendTile then
        SetActive(HWScene.ExtendTile.gameObject, false)
    end

    if (HWScene.selectedUnit ~= nil) then
        HWScene.setSelected(HWScene.selectedUnit, false)

        if (HWScene.newBuildUnit == HWScene.selectedUnit) then
            -- 说明是新建
            CLThingsPool.returnObj(HWScene.selectedUnit.csSelf.gameObject)
            HWScene.selectedUnit:clean()
            SetActive(HWScene.selectedUnit.csSelf.gameObject, false)
            HWScene.newBuildUnit = nil
        end
        GameUtl.hidePopupMenus()
        HWScene.selectedUnit = nil
    end

    IDLGridTileSide.show()
end

function HWScene.showhhideBuildingProc(unit)
    --//TODO:
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
    HWScene.refreshGridState(index, bio2number(attr.Size), true, gridState4Building)
end

function HWScene.onReleaseTile(tile, hadMoved)
    if HWScene.newBuildUnit == tile then
    elseif HWScene.selectedUnit == tile then
        -- IDLGridTileSide.refreshAndShow(nil, nil, true)
        if hadMoved then
            -- 通知服务器
            local blua = tile
            ---@type IDDBTile
            local d = blua.mData
            local gidx = blua.gridIndex

            -- 刷新a星网格
            local oldIndex = bio2number(d.pos)
            CLAStarPathSearch.current:scanRange(oldIndex, 2)
            -- 新位置
            CLAStarPathSearch.current:scanRange(tile.transform.position, 2)

            -- net:send(NetProtoIsland.send.moveTile(bio2number(d.idx), gidx))
        end
    end
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
