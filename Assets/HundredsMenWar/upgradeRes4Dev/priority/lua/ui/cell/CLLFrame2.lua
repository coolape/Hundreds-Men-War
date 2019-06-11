-- 通用ui框1
---@class BGFrame2Param init时传入参数
---@field title string 标题
---@field closeCallback function 关闭回调
---@field panel CLPanelLua 所在的Panel
---@field hideClose boolean true时隐藏关闭按钮
---@field hideTitle boolean true时隐藏标题

local _cell = {}
local csSelf = nil
local transform = nil
local mData = nil
local uiobjs = {}

-- 初始化，只调用一次
function _cell.init(csObj)
    csSelf = csObj
    transform = csSelf.transform
    uiobjs.BtnClose = getChild(transform, "ButtonClose").gameObject
    uiobjs.LabelTitle = getCC(transform, "LabelTitle", "UILabel")
end

-- 显示，
-- 注意，c#侧不会在调用show时，调用refresh
function _cell.show(go, data)
    mData = data
    if mData.hideClose then
        SetActive(uiobjs.BtnClose, false)
    else
        SetActive(uiobjs.BtnClose, true)
    end
    if mData.hideTitle then
        SetActive(uiobjs.LabelTitle.gameObject, false)
    else
        uiobjs.LabelTitle.text = mData.title
        SetActive(uiobjs.LabelTitle.gameObject, true)
    end
end

function _cell.uiEventDelegate(go)
    local goName = go.name
    if goName == "ButtonClose" then
        if mData.closeCallback then
            Utl.doCallback(mData.closeCallback)
        else
            hideTopPanel(mData.panel)
        end
    end
end

-- 取得数据
function _cell.getData()
    return mData
end

--------------------------------------------
return _cell
