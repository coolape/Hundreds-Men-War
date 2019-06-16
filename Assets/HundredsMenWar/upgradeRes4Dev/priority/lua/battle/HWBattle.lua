require("battle.HWScene")
HWBattle = {}
local csSelf
local transform
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
    HWScene.init(data, callback, progressCB)
end

return HWBattle
