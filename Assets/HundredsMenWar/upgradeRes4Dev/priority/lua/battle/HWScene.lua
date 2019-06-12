HWScene = {}
HWScene.offset4Tile = Vector3.zero
local grid
local lookAtTarget = MyCfg.self.lookAtTarget

-- 重新加载海
function IDWorldMap.onLoadOcena(name, obj, orgs)
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
    if IDWorldMap.isFinishInit then
        return
    end
    IDWorldMap.isFinishInit = true
    HWScene.gameObject = GameObject("Scene")
    HWScene.transform = HWScene.gameObject.transform

    local go = GameObject("grid")
    go.transform.parent = HWScene.transform
    HWScene.grid = go:AddComponent(typeof(CLGrid))
    HWScene.grid.gridLineHight = HWScene.offset4Tile.y
    grid = HWScene.grid.grid

    HWScene.onLoadOcena()
end

function HWScene.init(data, callback, progressCB)
    HWScene._init()
end


function HWScene.clean()
    
end

return HWScene
