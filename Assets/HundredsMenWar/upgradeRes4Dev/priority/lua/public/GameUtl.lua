require("battle.IDLBuilding")
GameUtl = {}

---@public 切换场景
function GameUtl.chgScene(data, callback)
    data = data or {}
    data.__finishCallback__ = callback
    getPanelAsy("PanelSceneManager", onLoadedPanel, data)
end

function GameUtl.newBuildingLua(attr)
    if bio2number(attr.ID) == 1 or bio2number(attr.ID) == 2 then
        return IDLBuilding.new()
    end
end

return GameUtl