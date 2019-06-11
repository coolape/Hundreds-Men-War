GameUtl = {}

---@public 切换场景
function GameUtl.chgScene(data, callback)
    data = data or {}
    data.__finishCallback__ = callback
    getPanelAsy("PanelSceneManager", onLoadedPanel, data)
end

return GameUtl