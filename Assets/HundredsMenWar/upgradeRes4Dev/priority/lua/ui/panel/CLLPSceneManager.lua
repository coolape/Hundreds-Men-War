-- xx界面
do
    CLLPSceneManager = {}

    local csSelf = nil;
    local transform = nil;
    local mData;
    local progressBar

    -- 初始化，只会调用一次
    function CLLPSceneManager.init(csObj)
        csSelf = csObj;
        transform = csObj.transform;
        progressBar = getCC(transform, "Progress Bar", "UIProgressBar")
    end

    -- 设置数据
    function CLLPSceneManager.setData(paras)
        mData = paras;
    end

    -- 显示，在c#中。show为调用refresh，show和refresh的区别在于，当页面已经显示了的情况，当页面再次出现在最上层时，只会调用refresh
    function CLLPSceneManager.show()
        progressBar.value = 0;
        if mData.mode == GameMode.city then
            CLLPSceneManager.gotoCity()
        end
    end

    -- 刷新
    function CLLPSceneManager.refresh()
    end

    -- 关闭页面
    function CLLPSceneManager.hide()
    end

    -- 网络请求的回调；cmd：指命，succ：成功失败，msg：消息；paras：服务器下行数据
    function CLLPSceneManager.procNetwork (cmd, succ, msg, paras)
        --[[
        if(succ == 1) then
          if(cmd == "xxx") then
            -- TODO:
          end
        end
        --]]
    end

    -- 处理ui上的事件，例如点击等
    function CLLPSceneManager.uiEventDelegate( go )
        local goName = go.name;
        --[[
        if(goName == "xxx") then
          --TODO:
        end
        --]]
    end

    -- 当按了返回键时，关闭自己（返值为true时关闭）
    function CLLPSceneManager.hideSelfOnKeyBack( )
        return false;
    end


    function CLLPSceneManager.gotoCity()
        CLLCity.init();
    end
    --------------------------------------------
    return CLLPSceneManager;
end
