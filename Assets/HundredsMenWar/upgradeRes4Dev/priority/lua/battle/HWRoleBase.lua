---@class HWRoleBase
HWRoleBase = class("HWRoleBase")

---@type MyUnit
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
    ---@type Coolape.MyTween
    self.tween = csSelf:GetComponent("MyTween")
    ---@type Coolape.CLSeeker
    self.seeker = csSelf:GetComponent("CLSeeker")
    self.seeker:init(
        self:wrapFunction4CS(self.onFinishSeekCallback),
        self:wrapFunction4CS(self.onMovingCallback),
        self:wrapFunction4CS(self.onArrivedCallback)
    )
    ---@type Coolape.CLRoleAvata
    self.avata = csSelf:GetComponent("CLRoleAvata")
    ---@type AnimationInstancing.AnimationInstancing
    self.aniInstancing = csSelf:GetComponent("AnimationInstancing")
    ---@type CLEjector
    self.ejector = getCC(transform, "node/ejector", "CLEjector")
    ---@type Coolape.CLRoleAction
    self.action = csSelf.mbody:GetComponent("CLRoleAction")
end

-- 初始化，只会调用一次
function HWRoleBase:init(csObj, id, lev, isOffense, other)
    self:_init(csObj)
    self.seeker.mAStarPathSearch = CLAStarPathSearch.current

    self.isRole = true
    self.transform = transform
    self.isOffense = isOffense
    self.id = id
    self.lev = lev
    csSelf:initRandomFactor()
    self:goAround()
end

-- 换装
function HWRoleBase:dress(...)
    if (self.avata == nil) then
        --print("The csSelf.avata is null!!");
        return
    end
    local index = self.isOffense and "1" or "2"
    SetActive(csSelf.mbody.gameObject, false)
    --SetActive(csSelf.shadow.gameObject, false)
    self.avata:switch2xx(
        "body",
        index,
        function()
        end
    )
end

-- 动作
function HWRoleBase:setAction(...)
    local paras = {...}
    local len = #(paras)
    if (len == 0) then
        print("The action name is none, must send to")
        return
    end

    local actionName = paras[1]

    if (csSelf == nil or (csSelf.isDead and actionName ~= "dead")) then
        return
    end

    local callback = nil
    if (len == 1) then
        if (actionName == "idel" or actionName == "idel2" or actionName == "run" or actionName == "walk") then
            -- 这些都是loop的动作
            callback = nil
        else
            callback = ActCBtoList(100, self.wrapFunction4CS(self.onCompleteAction))
        end
    elseif (len == 2) then
        callback = paras[2]
    end

    if self.aniInstancing then
        self.aniInstancing:PlayAnimation(actionName, callback)
    else
        self.action:setAction(getAction(actionName), callback)
    end
end

function HWRoleBase:playIdel()
    self:setAction("idel")
end

-- 完成一组动作的回调
function HWRoleBase:onCompleteAction(act)
    if self.aniInstancing then
        if act.currAction == "idel" or act.currAction == "idel2" or act.currAction == "walk" or act.currAction == "run" then
            return
        end
        if ("dead" ~= act.currAction and "down" ~= act.currAction) then
            self:setAction("idel")
        --_cell.playIdel()
        end
        if ("attack" == act.currAction) then
            -- if(csSelf.state == RoleState.attack) then
            --   csSelf:cancelFixedInvoke4Lua(_cell._doAttack);
            --   _cell.doAttack();
            -- end
            self:setAction("idel")
        elseif ("happy" == act.currAction) then
            --_cell.setAction("idel");
            self:playIdel()
        elseif ("down" == act.currAction) then
            self:setAction("up")
        elseif ("up" == act.currAction) then
            -- self:formation()
            self:playIdel()
        elseif ("dead" == act.currAction) then
            --             _cell.IamDead();
            if self.aniInstancing then
                self.aniInstancing:Stop()
            end
        end
    else
        local curActVal = act.currActionValue
        if
            (getAction("idel") == curActVal or getAction("idel2") == curActVal or getAction("run") == curActVal or
                getAction("walk") == curActVal)
         then
            return
        end

        if (getAction("dead") ~= curActVal and getAction("down") ~= curActVal) then
            --_cell.setAction("idel");
            self:playIdel()
        end
        if (getAction("attack") == curActVal) then
            -- if(csSelf.state == RoleState.attack) then
            --   csSelf:cancelFixedInvoke4Lua(_cell._doAttack);
            --   _cell.doAttack();
            -- end
            self:setAction("idel")
        elseif (getAction("happy") == curActVal) then
            --_cell.setAction("idel");
            self:playIdel()
        elseif (getAction("down") == curActVal) then
            self:setAction("up")
        elseif (getAction("up") == curActVal) then
            self:formation()
        elseif (getAction("dead") == curActVal) then
        --             _cell.IamDead();
        end
    end
end

function HWRoleBase:onFinishSeekCallback(pathList, canReach)
  self:setAction("run")
end
function HWRoleBase:onMovingCallback()
end
function HWRoleBase:onArrivedCallback()
  self:goAround()
end

function HWRoleBase:goAround()
    local toPos = HWScene.randomGridCellPos()
    self.seeker:seek(toPos)
end
--------------------------------------------
return HWRoleBase
