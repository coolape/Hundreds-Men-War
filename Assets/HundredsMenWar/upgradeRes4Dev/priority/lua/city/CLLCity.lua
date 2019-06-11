-- 主城
do
    CLLCity = {}
    CLLCity.csSelf = nil;
    local csSelf = nil;
    local transform = nil;

    -- 初始化，只会调用一次
    function CLLCity.init()
        CLLCity._init()

    end

    function CLLCity._init()
        if CLLCity.csSelf ~= nil then
            return;
        end
        local go = GameObject("CityRoot")
        CLLCity.csSelf = go:AddComponent(CLBaseLua)
        CLLCity.csSelf.luaTable = CLLCity;
        csSelf = CLLCity.csSelf;
        transform = go.transform;
        transform.parent = MyMain.self.transform;
        transform.localScale = Vector3.one;
        transform.localPosition = Vector3.zero;
    end


    --------------------------------------------
    return CLLCity;
end
