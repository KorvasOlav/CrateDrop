if ( CLIENT ) then
    
    net.Receive("OpenNPCMenu", function()
        local npcClasses = net.ReadTable()
    
        local frame = vgui.Create("DFrame")
        frame:SetSize(500, 400)
        frame:SetTitle("NPC Menu")
        frame:Center()
        frame:MakePopup()
    
        local npcList = vgui.Create("DListView", frame)
        npcList:Dock(LEFT)
        npcList:SetWidth(200)
        npcList:SetMultiSelect(false)
        npcList:AddColumn("NPC Name")
    
        for _, npcData in pairs(npcClasses) do
            npcList:AddLine(npcData.name)
        end

    
        local setButton = vgui.Create("DButton", frame)
        setButton:Dock(BOTTOM)
        setButton:DockMargin(10, 10, 10, 10)
        setButton:SetText("Set")
    
        textBox = vgui.Create("DTextEntry", frame)
        textBox:Dock(TOP)
        textBox:DockMargin(10, 10, 10, 10)
        textBox:SetNumeric(true)
        textBox:SetWide(200)
        textBox:SetVisible(true)
        textBox:SetEnabled(true)
    
        function npcList:OnRowSelected(_, row)
            local npcName = row:GetValue(1)
            local selectedNPCClass = nil
            for _, npcData in pairs(npcClasses) do
                if npcData.name == npcName then
                    selectedNPCClass = npcData.class
                    break
                end
            end

            if selectedNPCClass then
                net.Start("GetNPCCrateChance")
                net.WriteString(selectedNPCClass)
                net.SendToServer()
            end
        end

        setButton.DoClick = function()
            local newValue = tonumber(textBox:GetText()) or 0

            local selectedNPCClass = nil
            local npcName = npcList:GetSelectedLine()
            if npcName then
                npcName = npcList:GetLine(npcName):GetValue(1)
                for _, npcData in pairs(npcClasses) do
                    if npcData.name == npcName then
                        selectedNPCClass = npcData.class
                        break
                    end
                end
            end

            if selectedNPCClass then
                net.Start("SetNPCCrateChance")
                net.WriteString(selectedNPCClass)
                net.WriteInt(newValue, 32)
                net.SendToServer()
            end
        end
    end)

    net.Receive("SetNPCCrateChance", function()
        local crateChance = net.ReadInt(32)
        textBox:SetText(tostring(crateChance))
    end)
end
