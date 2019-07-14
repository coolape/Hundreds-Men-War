---@class HWRoleBase
HWRoleBase = class("HWRoleBase")

---@type Coolape.CLUnit
local csSelf = nil
local transform = nil

function HWRoleBase:_init(csObj)
    if self.isInited then
        return
    end
    self.isInited = true
    csSelf = csObj
    transform = csObj.transform
    self.csSelf = csSelf
    self.transform = transform
    self.tween = csSelf:GetComponent("MyTween")
    self.seeker = csSelf:GetComponent("CLSeeker")
    self.avata = csSelf:GetComponent("CLRoleAvata")
    self.aniIns = csSelf:GetComponent("AnimationInstancing")
    self.ejector = getCC(transform, "node/ejector", "CLEjector")
end

-- 初始化，只会调用一次
function HWRoleBase:init(csObj, id, lev, isOffense, other)
    self:_init(csObj)
    self.transform = transform
    self.isOffense = isOffense
    self.id = id
    self.lev = lev
end

--------------------------------------------
return HWRoleBase
