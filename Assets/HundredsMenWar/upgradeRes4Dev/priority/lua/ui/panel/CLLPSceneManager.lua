-- xx界面
CLLPSceneManager = {}
require("battle.HWBattle")

---@type UnityEngine.Transform
local lookAtTarget = MyCfg.self.lookAtTarget
---@type CLUIDrag4World
local dragSetting = CLUIDrag4World.self
---@type IDLCameraMgr
local smoothFollow = IDLCameraMgr.smoothFollow

local csSelf = nil
local transform = nil
local mData
local progressBar

-- 初始化，只会调用一次
function CLLPSceneManager.init(csObj)
    csSelf = csObj
    transform = csObj.transform
    progressBar = getCC(transform, "Progress Bar", "UIProgressBar")
end

-- 设置数据
function CLLPSceneManager.setData(paras)
    mData = paras
end

-- 显示，在c#中。show为调用refresh，show和refresh的区别在于，当页面已经显示了的情况，当页面再次出现在最上层时，只会调用refresh
function CLLPSceneManager.show()
    progressBar.value = 0
    if mData.mode == GameMode.battle then
        CLLPSceneManager.gotoBattle()
    end
end

-- 刷新
function CLLPSceneManager.refresh()
end

-- 关闭页面
function CLLPSceneManager.hide()
end

-- 网络请求的回调；cmd：指命，succ：成功失败，msg：消息；paras：服务器下行数据
function CLLPSceneManager.procNetwork(cmd, succ, msg, paras)
    --[[
        if(succ == 1) then
          if(cmd == "xxx") then
            -- TODO:
          end
        end
        --]]
end

-- 处理ui上的事件，例如点击等
function CLLPSceneManager.uiEventDelegate(go)
    local goName = go.name
    --[[
        if(goName == "xxx") then
          --TODO:
        end
        --]]
end

-- 当按了返回键时，关闭自己（返值为true时关闭）
function CLLPSceneManager.hideSelfOnKeyBack()
    return false
end

function CLLPSceneManager.gotoBattle()
    Time.fixedDeltaTime = 0.02
    -- Turn off v-sync
    QualitySettings.vSyncCount = 0
    Application.targetFrameRate = 60

    if dragSetting then
        dragSetting.isLimitCheckStrict = false
        dragSetting.canMove = true
        dragSetting.canRotation = true
        dragSetting.canScale = true
        dragSetting.scaleMini = 7
        dragSetting.scaleMax = 20
        dragSetting.scaleHeightMini = 10
        dragSetting.scaleHeightMax = 100
        dragSetting.viewRadius = 65
        dragSetting.dragMovement = Vector3.one
         -- * 0.4
        dragSetting.scaleSpeed = 1
    end

    smoothFollow.distance = 5
    smoothFollow.height = 10
    lookAtTarget.transform.localPosition = Vector3(15, 0, -15)
    HWBattle.init(mData, CLLPSceneManager.onLoadBattle, CLLPSceneManager.onProgress)
end

function CLLPSceneManager.onLoadBattle()
    getPanelAsy("PanelBattle", onLoadedPanel)
end

function CLLPSceneManager.onProgress(totalAssets, currCount)
    SetActive(progressBar.gameObject, true)
    progressBar.value = currCount / totalAssets
end
--------------------------------------------
return CLLPSceneManager
