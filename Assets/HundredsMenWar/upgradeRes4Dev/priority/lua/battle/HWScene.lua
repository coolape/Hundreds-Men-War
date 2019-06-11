HWScene = {}

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

    IDWorldMap.onLoadOcena()
end

function HWScene.init(data, callback, progressCB)
    HWScene._init()
end

return HWScene
