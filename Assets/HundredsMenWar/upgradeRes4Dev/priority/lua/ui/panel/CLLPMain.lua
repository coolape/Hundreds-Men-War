-- 主界面
do
    local pName = nil;
    local panel = nil;
    local transform = nil;
    local gameObject = nil;
    local LabelGold = nil;
    local LabelGems = nil;
    local LabelPower = nil;
    local LabelLvl = nil;
    local LabelName = nil;

    PanelMain = {}
    function PanelMain.init (go)
        pName = go.name;
        panel = go:GetComponent('CLPanelBase');
        transform = panel.transform;
        gameObject = panel.gameObject;

        LabelGold = getChild(transform, "TopLeft", "ResInfo", "LabelGold");
        LabelGold = LabelGold:GetComponent("UILabel");
        LabelGems = getChild(transform, "TopLeft", "ResInfo", "GemsInfo", "LabelGems");
        LabelGems = LabelGems:GetComponent("UILabel");
        LabelPower = getChild(transform, "TopLeft", "PowerInfo", "LabelPower");
        LabelPower = LabelPower:GetComponent("UILabel");
        LabelLvl = getChild(transform, "TopLeft", "UserInfo", "LabelLvl");
        LabelLvl = LabelLvl:GetComponent("UILabel");
        LabelName = getChild(transform, "TopLeft", "UserInfo", "LabelName");
        LabelName = LabelName:GetComponent("UILabel");
    end

    function PanelMain.setData (pars)
    end

    function PanelMain.show ()
        if (CLLData.player ~= nil and
        string.find(CLLData.player.pname, "pl") ~= nil) then
            CLPanelManager.getPanelAsy ("PanelSetName", PanelMain.onLoadPanelSetName);
        end
    end

    function PanelMain.onLoadPanelSetName (p)
        CLPanelManager.showTopPanel(p, true, true);
    end

    function PanelMain.hide ()
    end

    function PanelMain.refresh ()
        if (CLLData.player ~= nil) then
            LabelGold.text = NumEx.bio2Int(CLLData.player.gold);
            LabelGems.text = NumEx.bio2Int(CLLData.player.gems);
            LabelPower.text = joinStr( bio2Int(CLLData.player.powercur), "/", bio2Int(CLLData.player.powermax));
            LabelLvl.text = NumEx.bio2Int(CLLData.player.lvl);
            LabelName.text = CLLData.player.pname;
        end
    end

    function PanelMain.procNetwork (cmd, succ, msg, pars)
        if (succ == 0) then
            if (cmd == "lastLoginSv") then
                Net.self.gateTcp:stop(); -- 关掉网关连接
            end
        end
    end

    function PanelMain.OnClickMail ( ... )
    end

    function PanelMain.OnClickMonster()
        local p = CLPanelManager.getPanel ("PanelMonsterTeam");
        CLPanelManager.showTopPanel(p, true, false);
    end

    function PanelMain.OnClickChat ( ... )
    end
    function PanelMain.OnClickGifs ( ... )
    end
    return PanelMain;
end
