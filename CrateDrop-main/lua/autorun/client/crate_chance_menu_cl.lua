if (CLIENT) then
    local textBox -- Define textBox variable outside the scope

    net.Receive("OpenNPCMenu", function()
        local npcClasses = net.ReadTable()  

        local frame = vgui.Create("DFrame")
        frame:SetSize(500, 400)
        frame:SetTitle("NPC Menu")
        frame:Center()
        frame:MakePopup()

        local tabPanel = vgui.Create("DPropertySheet", frame)
        tabPanel:Dock(FILL)

        -- Default Drop Chance Tab
        
        local defaultDropChancePanel = vgui.Create("DPanel")
        defaultDropChancePanel:SetVisible(true)
        tabPanel:AddSheet("Default Drop Chance", defaultDropChancePanel, nil, false, false, "Manage default drop chances.")

        local npcList = vgui.Create("DListView", defaultDropChancePanel)
        npcList:Dock(LEFT)
        npcList:SetWidth(200)
        npcList:SetMultiSelect(false)
        npcList:AddColumn("NPC Name")

        for _, npcData in pairs(npcClasses) do
            npcList:AddLine(npcData.name)
        end

        local setButton = vgui.Create("DButton", defaultDropChancePanel)
        setButton:Dock(BOTTOM)
        setButton:DockMargin(10, 10, 10, 10)
        setButton:SetText("Set")

        textBox = vgui.Create("DTextEntry", defaultDropChancePanel)
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

        -- Respawning NPCs Tab

        local respawningNPCPanel = vgui.Create("DPanel")
        respawningNPCPanel:SetVisible(true)
        tabPanel:AddSheet("Respawning NPCs", respawningNPCPanel, nil, false, false, "Manage respawning NPCs.")

        local npcDataTable = {} -- Table to store NPC data

        -- NPC List
        local npcListRespawn = vgui.Create("DListView", respawningNPCPanel)
        npcListRespawn:Dock(FILL)
        npcListRespawn:SetMultiSelect(false)
        local IDColumn = npcListRespawn:AddColumn("ID")
        IDColumn:SetWidth(1)
        npcListRespawn:AddColumn("NPC Class")
        npcListRespawn:AddColumn("Crate Chance")
        npcListRespawn:AddColumn("Time Interval")
        npcListRespawn:AddColumn("Position")

        -- Load NPC Data from File
        local function LoadNPCData()
            npcListRespawn:Clear()
            npcDataTable = {}
        
            if file.Exists("npc_data.txt", "DATA") then
                local data = file.Read("npc_data.txt", "DATA")
                if data then
                    npcDataTable = util.JSONToTable(data)
                    for _, npcData in ipairs(npcDataTable) do
                        local xPos = npcData.xPos or 0
                        local yPos = npcData.yPos or 0
                        local zPos = npcData.zPos or 0
        
                        if isnumber(xPos) and isnumber(yPos) and isnumber(zPos) then
                            local positionString = string.format('%.f, %.f, %.f', xPos, yPos, zPos)
                            npcListRespawn:AddLine(npcData.uniqueID, npcData.npcClass, npcData.crateChance, npcData.timeInterval, positionString)
                        else
                            print("Invalid position values found in NPC data.")
                        end
                    end
                end
            end
        end
        
        -- Function to get NPC data by ID
        local function GetNPCDataByID(uniqueID)
            for _, npcData in ipairs(npcDataTable) do
                if npcData.uniqueID == uniqueID then
                    return npcData
                end
            end
            return nil
        end

        -- Save NPC Data to File
        local function SaveNPCData()
            local data = util.TableToJSON(npcDataTable)
            file.Write("npc_data.txt", data)
        end

        -- Add New Row Button
        local addButton = vgui.Create("DButton", respawningNPCPanel)
        addButton:Dock(BOTTOM)
        addButton:DockMargin(10, 10, 10, 10)
        addButton:SetText("Add New Row")

        -- Remove Row Button
        local removeButton = vgui.Create("DButton", respawningNPCPanel)
        removeButton:Dock(BOTTOM)
        removeButton:DockMargin(10, 0, 10, 10)
        removeButton:SetText("Remove Row")
        removeButton:SetEnabled(true)

        -- Edit Row Button
        local editButton = vgui.Create("DButton", respawningNPCPanel)
        editButton:Dock(BOTTOM)
        editButton:DockMargin(10, 0, 10, 10)
        editButton:SetText("Edit Row")
        editButton:SetEnabled(true)

        -- Add New Row
        addButton.DoClick = function()
            local uniqueID = 1
            if #npcDataTable > 0 then
                uniqueID = npcDataTable[#npcDataTable].uniqueID + 1
            end

            local frame = vgui.Create("DFrame")
            frame:SetSize(350, 500)
            frame:SetTitle("Add New Row")
            frame:Center()
            frame:MakePopup()

            local npcClassSearch = vgui.Create("DTextEntry", frame)
            npcClassSearch:Dock(TOP)
            npcClassSearch:DockMargin(10, 10, 10, 5)
            npcClassSearch:SetUpdateOnType(true)
            npcClassSearch:SetTall(25)
            npcClassSearch:SetPlaceholderText("Search NPC Class")

            local npcClassList = vgui.Create("DListView", frame)
            npcClassList:Dock(FILL)
            npcClassList:SetMultiSelect(false)
            npcClassList:AddColumn("NPC Class")

            -- Function to populate the NPC Class List
            local function populateNPCClassList()
                npcClassList:Clear()

                for _, npcData in pairs(npcClasses) do
                    if string.find(string.lower(npcData.class), string.lower(npcClassSearch:GetText()), 1, true) then
                        npcClassList:AddLine(npcData.class)
                    end
                end
            end

            -- Populate NPC Class List
            populateNPCClassList()

            -- Filter NPC Class List based on search input
            npcClassSearch.OnValueChange = function(self)
                populateNPCClassList()
            end

            local crateChanceTextEntry = vgui.Create("DTextEntry", frame)
            crateChanceTextEntry:Dock(TOP)
            crateChanceTextEntry:DockMargin(10, 0, 10, 5)
            crateChanceTextEntry:SetPlaceholderText("Crate Chance")

            local timeIntervalTextEntry = vgui.Create("DTextEntry", frame)
            timeIntervalTextEntry:Dock(TOP)
            timeIntervalTextEntry:DockMargin(10, 0, 10, 5)
            timeIntervalTextEntry:SetPlaceholderText("Time Interval")

            local playerPos = LocalPlayer():GetPos()
            tempXPos = math.Round(playerPos.x)
            tempYPos = math.Round(playerPos.y)
            tempZPos = math.Round(playerPos.z)

            local xPosTextEntry = vgui.Create("DTextEntry", frame)
            xPosTextEntry:Dock(TOP)
            xPosTextEntry:DockMargin(10, 0, 10, 5)
            xPosTextEntry:SetText(tostring(tempXPos))

            local yPosTextEntry = vgui.Create("DTextEntry", frame)
            yPosTextEntry:Dock(TOP)
            yPosTextEntry:DockMargin(10, 0, 10, 5)
            yPosTextEntry:SetText(tostring(tempYPos))

            local zPosTextEntry = vgui.Create("DTextEntry", frame)
            zPosTextEntry:Dock(TOP)
            zPosTextEntry:DockMargin(10, 0, 10, 5)
            zPosTextEntry:SetText(tostring(tempZPos))

            local addButtonFrame = vgui.Create("DButton", frame)
            addButtonFrame:Dock(BOTTOM)
            addButtonFrame:DockMargin(10, 10, 10, 10)
            addButtonFrame:SetText("Add")

            -- Add New Row
            addButtonFrame.DoClick = function()
                if npcClassList:GetSelected()[1] == nil then return end
                local npcClass = npcClassList:GetSelected()[1]:GetValue(1)
                local crateChance = crateChanceTextEntry:GetText()
                local timeInterval = timeIntervalTextEntry:GetText()
                local xPos = tonumber(xPosTextEntry:GetText()) or 0
                local yPos = tonumber(yPosTextEntry:GetText()) or 0
                local zPos = tonumber(zPosTextEntry:GetText()) or 0

                -- Check if any position component is empty and use player's current position if it is
                if xPos == 0 and yPos == 0 and zPos == 0 then
                    local playerPos = LocalPlayer():GetPos()
                    xPos = math.Round(playerPos.x)
                    yPos = math.Round(playerPos.y)
                    zPos = math.Round(playerPos.z)
                end
                if timeInterval == nil or timeInterval == "" then
                    timeInterval = 600
                end

                if crateChance == nil or crateChance == "" then
                    crateChance = npcCrateChances[npcClass]
                end

                frame:Close()

                local positionString = string.format('%.f, %.f, %.f', xPos, yPos, zPos)
                local line = npcListRespawn:AddLine(uniqueID, npcClass, crateChance, timeInterval, positionString)
                table.insert(npcDataTable, { uniqueID = uniqueID, npcClass = npcClass, crateChance = crateChance, timeInterval = timeInterval, xPos = xPos, yPos = yPos, zPos = zPos })

                npcListRespawn:SelectItem(line)
                removeButton:SetEnabled(true)
                editButton:SetEnabled(true)
                SaveNPCData()
            end
        end

        local function LoadCrateChances()
            if not file.Exists("crate_chances.txt", "DATA") then
                return {}
            end
    
            local contents = file.Read("crate_chances.txt", "DATA")
            return util.JSONToTable(contents) or {}
        end

        
        npcCrateChances = LoadCrateChances()

        -- Remove Row
        removeButton.DoClick = function()
            local selectedLine = npcListRespawn:GetSelectedLine()
            if selectedLine then
                npcListRespawn:RemoveLine(selectedLine)
                table.remove(npcDataTable, selectedLine)

                if npcListRespawn:GetLine(selectedLine) then
                    npcListRespawn:SelectItem(npcListRespawn:GetLine(selectedLine))
                end

                SaveNPCData()
            end
        end

        -- Edit Selected Row
        editButton.DoClick = function()
            local selectedLine = npcListRespawn:GetSelectedLine()
            if not selectedLine then return end

            local uniqueID = npcListRespawn:GetLine(selectedLine):GetValue(1)
            local npcData = GetNPCDataByID(uniqueID)
            if not npcData then return end

            local frame = vgui.Create("DFrame")
            frame:SetSize(350, 500)
            frame:SetTitle("Edit Row")
            frame:Center()
            frame:MakePopup()

            local npcClassSearch = vgui.Create("DTextEntry", frame)
            npcClassSearch:Dock(TOP)
            npcClassSearch:DockMargin(10, 10, 10, 5)
            npcClassSearch:SetUpdateOnType(true)
            npcClassSearch:SetTall(25)
            npcClassSearch:SetPlaceholderText("Search NPC Class")

            local npcClassList = vgui.Create("DListView", frame)
            npcClassList:Dock(FILL)
            npcClassList:SetMultiSelect(false)
            npcClassList:AddColumn("NPC Class")

            -- Function to populate the NPC Class List
            local function populateNPCClassList()
                npcClassList:Clear()

                for _, npcData in pairs(npcClasses) do
                    if string.find(string.lower(npcData.class), string.lower(npcClassSearch:GetText()), 1, true) then
                        npcClassList:AddLine(npcData.class)
                    end
                end
            end

            -- Populate NPC Class List
            populateNPCClassList()

            -- Filter NPC Class List based on search input
            npcClassSearch.OnValueChange = function(self)
                populateNPCClassList()
            end

            local crateChanceTextEntry = vgui.Create("DTextEntry", frame)
            crateChanceTextEntry:Dock(TOP)
            crateChanceTextEntry:DockMargin(10, 0, 10, 5)
            crateChanceTextEntry:SetPlaceholderText("Crate Chance")
            crateChanceTextEntry:SetText(npcData.crateChance)

            local timeIntervalTextEntry = vgui.Create("DTextEntry", frame)
            timeIntervalTextEntry:Dock(TOP)
            timeIntervalTextEntry:DockMargin(10, 0, 10, 5)
            timeIntervalTextEntry:SetPlaceholderText("Time Interval")
            timeIntervalTextEntry:SetText(npcData.timeInterval)

            local xPosTextEntry = vgui.Create("DTextEntry", frame)
            xPosTextEntry:Dock(TOP)
            xPosTextEntry:DockMargin(10, 0, 10, 5)
            xPosTextEntry:SetText(tostring(npcData.xPos))
            xPosTextEntry:SetPlaceholderText("X Position")

            local yPosTextEntry = vgui.Create("DTextEntry", frame)
            yPosTextEntry:Dock(TOP)
            yPosTextEntry:DockMargin(10, 0, 10, 5)
            yPosTextEntry:SetText(tostring(npcData.yPos))
            yPosTextEntry:SetPlaceholderText("Y Position")

            local zPosTextEntry = vgui.Create("DTextEntry", frame)
            zPosTextEntry:Dock(TOP)
            zPosTextEntry:DockMargin(10, 0, 10, 5)
            zPosTextEntry:SetText(tostring(npcData.zPos))
            zPosTextEntry:SetPlaceholderText("Z Position")

            local saveButton = vgui.Create("DButton", frame)
            saveButton:Dock(BOTTOM)
            saveButton:DockMargin(10, 10, 10, 10)
            saveButton:SetText("Save")

            -- Save Edited Row
            saveButton.DoClick = function()
                local npcClass = npcClassList:GetSelected()[1]:GetValue(1)
                local crateChance = crateChanceTextEntry:GetText()
                local timeInterval = timeIntervalTextEntry:GetText()
                local xPos = tonumber(xPosTextEntry:GetText()) or 0
                local yPos = tonumber(yPosTextEntry:GetText()) or 0
                local zPos = tonumber(zPosTextEntry:GetText()) or 0

                -- Check if any position component is empty and use the existing position if it is
                if xPos == 0 and yPos == 0 and zPos == 0 then
                    xPos = npcData.xPos
                    yPos = npcData.yPos
                    zPos = npcData.zPos
                end

                local selectedLine = npcListRespawn:GetSelectedLine()
                if selectedLine then
                    npcListRespawn:RemoveLine(selectedLine)
                    table.remove(npcDataTable, selectedLine)

                    if npcListRespawn:GetLine(selectedLine) then
                        npcListRespawn:SelectItem(npcListRespawn:GetLine(selectedLine))
                    end

                    SaveNPCData()
                end

                frame:Close()

                local positionString = string.format('%.f, %.f, %.f', xPos, yPos, zPos)
                local line = npcListRespawn:AddLine(uniqueID, npcClass, crateChance, timeInterval, positionString)
                table.insert(npcDataTable, { uniqueID = uniqueID, npcClass = npcClass, crateChance = crateChance, timeInterval = timeInterval, xPos = xPos, yPos = yPos, zPos = zPos })

                SaveNPCData()

                
            end
        end
        LoadNPCData()
    end)

    net.Receive("SetNPCCrateChance", function()
        local crateChance = net.ReadInt(32)
        if textBox then -- Check if textBox is valid before accessing it
            textBox:SetText(tostring(crateChance))
        end
    end)
end