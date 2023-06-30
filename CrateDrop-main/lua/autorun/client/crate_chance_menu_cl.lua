if (CLIENT) then
    local textBox -- Define textBox variable outside the scope

    net.Receive("OpenNPCMenu", function()

        local frame = vgui.Create("DFrame")
        frame:SetSize(700, 400)
        frame:SetTitle("NPC Menu")
        frame:Center()
        frame:MakePopup()



        -- REMOVE ONCE THE LIST IS POPULATED WITH WILTOS ITEMS --

        DropListValues = {
            { name = "Drop List 1", enabled = true },
            { name = "Drop List 2", enabled = false },
            { name = "Drop List 3", enabled = true },
        }

        local npcClasses = {}
        for npcClass, npcInfo in pairs(list.Get("NPC")) do
            table.insert(npcClasses, {
                class = npcClass,
                name = npcInfo.Name or npcClass,
                category = npcInfo.Category or "Unknown"
            })
        end

        local tabPanel = vgui.Create("DPropertySheet", frame)
        tabPanel:Dock(FILL)

        local dropGroupsData = {}
        local dropGroupsDataJSON = file.Read("drop_groups.txt", "DATA")
        if dropGroupsDataJSON then
            dropGroupsData = util.JSONToTable(dropGroupsDataJSON)
        end

        local function WriteDropGroupsDataToFile()
            local dropGroupsDataStr = util.TableToJSON(dropGroupsData, true)
            file.Write("drop_groups.txt", dropGroupsDataStr)
        end

        -- Default Drop Chance Tab
        
        local defaultDropChancePanel = vgui.Create("DPanel")
        defaultDropChancePanel:SetVisible(true)
        tabPanel:AddSheet("Default Drop Chance", defaultDropChancePanel, nil, false, false, "Manage default drop chances.")

        local npcList = vgui.Create("DListView", defaultDropChancePanel)
        npcList:Dock(LEFT)
        npcList:SetWidth(350)
        npcList:SetMultiSelect(false)
        npcList:AddColumn("NPC Name")

        for npcClass, npcInfo in pairs(list.Get("NPC")) do
            npcList:AddLine(npcClass)
        end

        local setButton = vgui.Create("DButton", defaultDropChancePanel)
        setButton:Dock(BOTTOM)
        setButton:DockMargin(10, 10, 10, 10)
        setButton:SetText("Set")

        dropChanceLabel = vgui.Create("DLabel", defaultDropChancePanel)
        dropChanceLabel:Dock(TOP)
        dropChanceLabel:DockMargin(10,0,10,0)
        dropChanceLabel:SetText("Default Drop Chance:")
        dropChanceLabel:SetColor(Color(0,0,0,255))

        textBox = vgui.Create("DTextEntry", defaultDropChancePanel)
        textBox:Dock(TOP)
        textBox:DockMargin(10, 3, 10, 10)
        textBox:SetNumeric(true)
        textBox:SetWide(200)
        textBox:SetVisible(true)
        textBox:SetEnabled(true)

        function npcList:OnRowSelected(_, row)
            local npcName = row:GetValue(1)
            local selectedNPCClass = nil
            for _, npcData in pairs(npcClasses) do
                if npcData.class == npcName then
                    selectedNPCClass = npcData.class
                    break
                end
            end

            if selectedNPCClass then
                net.Start("GetNPCCrateChance")
                net.WriteString(selectedNPCClass)
                net.SendToServer()
            end
            net.Receive("SetNPCCrateChance", function()
                readCrateChance = net.ReadInt(32)
                textBox:SetValue(readCrateChance)
            end)
        end

        setButton.DoClick = function()
            local newValue = tonumber(textBox:GetText()) or 0

            local selectedNPCClass = nil
            local npcName = npcList:GetSelectedLine()
            if npcName then
                npcName = npcList:GetLine(npcName):GetValue(1)
                for _, npcData in pairs(npcClasses) do
                    if npcData.class == npcName then
                        selectedNPCClass = npcData.class
                        break
                    end
                end
            end

            if selectedNPCClass then
                net.Start("SaveNPCCrateChance")
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
        npcListRespawn:AddColumn("XP Reward")
        npcListRespawn:AddColumn("Money Reward")
        npcListRespawn:AddColumn("Drop Group")
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
                            npcListRespawn:AddLine(npcData.uniqueID, npcData.npcClass, npcData.crateChance, npcData.timeInterval, npcData.xp, npcData.money, npcData.dropGroup, positionString)
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

            LoadNPCData()
        end

        LoadNPCData()

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

        local function GetLowestAvailableID()
            local usedIDs = {}
            for _, npcData in ipairs(npcDataTable) do
                usedIDs[npcData.uniqueID] = true
            end
        
            -- Find the lowest available ID
            local lowestID = 1
            while usedIDs[lowestID] do
                lowestID = lowestID + 1
            end
            return lowestID
        end

        -- Add New Row
        addButton.DoClick = function()
            local frame = vgui.Create("DFrame")
            frame:SetSize(350, 600)
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
            npcClassList:Dock(TOP)
            npcClassList:SetHeight(200)
            npcClassList:SetMultiSelect(false)
            npcClassList:AddColumn("NPC Class")
        
            -- Function to populate the NPC Class List
            local function populateNPCClassList()
                npcClassList:Clear()
        
                for npcClass, npcInfo in pairs(list.Get("NPC")) do
                    if string.find(string.lower(npcClass), string.lower(npcClassSearch:GetText()), 1, true) then
                        npcClassList:AddLine(npcClass)
                    end
                end
            end
        
            -- Populate NPC Class List
            populateNPCClassList()
        
            -- Filter NPC Class List based on search input
            npcClassSearch.OnValueChange = function(self)
                populateNPCClassList()
            end
        
            local crateChanceLabel = vgui.Create("DLabel", frame)
            crateChanceLabel:Dock(TOP)
            crateChanceLabel:DockMargin(10,0,10,0)
            crateChanceLabel:SetText("Crate Chance:")
        
            local crateChanceTextEntry = vgui.Create("DTextEntry", frame)
            crateChanceTextEntry:Dock(TOP)
            crateChanceTextEntry:DockMargin(10, 0, 10, 5)
            crateChanceTextEntry:SetPlaceholderText("Crate Chance")
        
            local timeIntervalLabel = vgui.Create("DLabel", frame)
            timeIntervalLabel:Dock(TOP)
            timeIntervalLabel:DockMargin(10,0,10,0)
            timeIntervalLabel:SetText("Respawn Interval:")
        
            local timeIntervalTextEntry = vgui.Create("DTextEntry", frame)
            timeIntervalTextEntry:Dock(TOP)
            timeIntervalTextEntry:DockMargin(10, 0, 10, 5)
            timeIntervalTextEntry:SetPlaceholderText("Time Interval")
        
            local xpLabel = vgui.Create("DLabel", frame)
            xpLabel:Dock(TOP)
            xpLabel:DockMargin(10, 0, 10, 0)
            xpLabel:SetText("XP:")
        
            local xpTextEntry = vgui.Create("DTextEntry", frame)
            xpTextEntry:Dock(TOP)
            xpTextEntry:DockMargin(10, 0, 10, 5)
            xpTextEntry:SetPlaceholderText("XP")
        
            local moneyLabel = vgui.Create("DLabel", frame)
            moneyLabel:Dock(TOP)
            moneyLabel:DockMargin(10, 0, 10, 0)
            moneyLabel:SetText("Money:")
        
            local moneyTextEntry = vgui.Create("DTextEntry", frame)
            moneyTextEntry:Dock(TOP)
            moneyTextEntry:DockMargin(10, 0, 10, 5)
            moneyTextEntry:SetPlaceholderText("Money")
        
            local playerPos = LocalPlayer():GetPos()
            tempXPos = math.Round(playerPos.x)
            tempYPos = math.Round(playerPos.y)
            tempZPos = math.Round(playerPos.z)
        
            local xPosLabel = vgui.Create("DLabel", frame)
            xPosLabel:Dock(TOP)
            xPosLabel:DockMargin(10, 0, 10, 0)
            xPosLabel:SetText("X Position:")
        
            local xPosTextEntry = vgui.Create("DTextEntry", frame)
            xPosTextEntry:Dock(TOP)
            xPosTextEntry:DockMargin(10, 0, 10, 5)
            xPosTextEntry:SetText(tostring(tempXPos))
        
            local yPosLabel = vgui.Create("DLabel", frame)
            yPosLabel:Dock(TOP)
            yPosLabel:DockMargin(10, 0, 10, 0)
            yPosLabel:SetText("Y Position:")
        
            local yPosTextEntry = vgui.Create("DTextEntry", frame)
            yPosTextEntry:Dock(TOP)
            yPosTextEntry:DockMargin(10, 0, 10, 5)
            yPosTextEntry:SetText(tostring(tempYPos))
        
            local zPosLabel = vgui.Create("DLabel", frame)
            zPosLabel:Dock(TOP)
            zPosLabel:DockMargin(10, 0, 10, 0)
            zPosLabel:SetText("Z Position:")
        
            local zPosTextEntry = vgui.Create("DTextEntry", frame)
            zPosTextEntry:Dock(TOP)
            zPosTextEntry:DockMargin(10, 0, 10, 5)
            zPosTextEntry:SetText(tostring(tempZPos))
        
            local setDropGroupButton = vgui.Create("DButton", frame)
            setDropGroupButton:Dock(TOP)
            setDropGroupButton:DockMargin(10, 10, 10, 10)
            setDropGroupButton:SetText("Set Drop Group")

            local DropGroupLabel = vgui.Create("DLabel", frame)
            DropGroupLabel:Dock(TOP)
            DropGroupLabel:DockMargin(10, 0, 10, 5)
            DropGroupLabel:SetText("Drop Group:")

            local addButtonFrame = vgui.Create("DButton", frame)
            addButtonFrame:Dock(TOP)
            addButtonFrame:DockMargin(10, 10, 10, 10)
            addButtonFrame:SetText("Add")

            local dropGroup = ""
        
            -- Event for setting the drop group
            setDropGroupButton.DoClick = function()
                -- Hide the original panel elements
                npcClassSearch:SetVisible(false)
                npcClassList:SetVisible(false)
                crateChanceTextEntry:SetVisible(false)
                timeIntervalTextEntry:SetVisible(false)
                xpTextEntry:SetVisible(false)
                moneyTextEntry:SetVisible(false)
                xPosTextEntry:SetVisible(false)
                yPosTextEntry:SetVisible(false)
                zPosTextEntry:SetVisible(false)
                addButtonFrame:SetVisible(false)
                setDropGroupButton:SetVisible(false)
                crateChanceLabel:SetVisible(false)
                timeIntervalLabel:SetVisible(false)
                xpLabel:SetVisible(false)
                moneyLabel:SetVisible(false)
                xPosLabel:SetVisible(false)
                yPosLabel:SetVisible(false)
                zPosLabel:SetVisible(false)
                DropGroupLabel:SetVisible(false)


                local dropGroupList = vgui.Create("DListView", frame)
                dropGroupList:Dock(FILL)
                dropGroupList:SetMultiSelect(false)
                dropGroupList:AddColumn("Drop Group Name")
            
                for _, dropGroupData in ipairs(dropGroupsData) do
                    dropGroupList:AddLine(dropGroupData.groupName)
                end
            
                -- Add Drop Group button
                local addDropGroupButton = vgui.Create("DButton", frame)
                addDropGroupButton:Dock(BOTTOM)
                addDropGroupButton:DockMargin(10, 10, 10, 1)
                addDropGroupButton:SetText("Add Drop Group")
            
                -- Select Drop Group button
                local selectDropGroupButton = vgui.Create("DButton", frame)
                selectDropGroupButton:Dock(BOTTOM)
                selectDropGroupButton:DockMargin(10, 1, 10, 10)
                selectDropGroupButton:SetText("Select Drop Group")
            
                addDropGroupButton.DoClick = function()
                    -- Hide the original panel elements
                    dropGroupList:SetVisible(false)
                    addDropGroupButton:SetVisible(false)
                    selectDropGroupButton:SetVisible(false)
                
                    -- Create a text box for drop group name
                    local dropGroupNameLabel = vgui.Create("DLabel", frame)
                    dropGroupNameLabel:Dock(TOP)
                    dropGroupNameLabel:DockMargin(10, 10, 10, 0)
                    dropGroupNameLabel:SetText("Drop Group Name:")
                
                    local dropGroupNameTextEntry = vgui.Create("DTextEntry", frame)
                    dropGroupNameTextEntry:Dock(TOP)
                    dropGroupNameTextEntry:DockMargin(10, 0, 10, 5)
                    dropGroupNameTextEntry:SetPlaceholderText("Enter drop group name")
                
                    -- Create a DListView for drop lists
                    local dropListLabel = vgui.Create("DLabel", frame)
                    dropListLabel:Dock(TOP)
                    dropListLabel:DockMargin(10, 10, 10, 0)
                    dropListLabel:SetText("Items:")
                
                    local dropListView = vgui.Create("DListView", frame)
                    dropListView:Dock(FILL)
                    dropListView:SetMultiSelect(false)
                    dropListView:SetHeight(440)
                    dropListView:AddColumn("Items")
                    dropListView:AddColumn("Enabled"):SetMaxWidth(50)
                
                
                    -- Populate drop list view with temporary values
                    for _, dropList in ipairs(DropListValues) do
                        local line = dropListView:AddLine(dropList.name, tostring(dropList.enabled))
                        line.DropList = dropList
                    end

                    function dropListView:DoDoubleClick(lineID, line)
                        if line and line.DropList then
                            -- Toggle the enabled value
                            line.DropList.enabled = not line.DropList.enabled
                            line:SetValue(2, tostring(line.DropList.enabled))
                    
                            -- Update the value in the temporary table
                            DropListValues[lineID].enabled = line.DropList.enabled
                        end
                    end

                    -- Function to handle adding a new drop group
                    local function addDropGroup()
                        local groupName = dropGroupNameTextEntry:GetText()
                        if groupName == "" or groupName == nil then return end
                
                        local dropValues = {}
                        for _, line in ipairs(dropListView:GetLines()) do
                            if groupName == "" or groupName == nil then return end
                            if groupName == line.DropList.name then return end
                            if line:GetColumnText(2) == "true" then
                                local dropList = line.DropList
                                local enabled = line:GetColumnText(2) == "true"
                                table.insert(dropValues, dropList.name)
                            end
                        end

                        local dropGroupData = {
                            groupName = groupName,
                            dropList = dropValues,
                            npcCount = 0
                        }
                        dropGroupList:AddLine(dropGroupData.groupName)
                        table.insert(dropGroupsData, dropGroupData)

                        WriteDropGroupsDataToFile()

                        
                        dropGroupNameLabel:Remove()
                        dropGroupNameTextEntry:Remove()
                        dropListLabel:Remove()
                        dropListView:Remove()
                        dropGroupList:SetVisible(true)
                        addDropGroupButton:SetVisible(true)
                        selectDropGroupButton:SetVisible(true)
                        return true
                    end
                
                    -- Add button to confirm adding the drop group
                    local confirmButton = vgui.Create("DButton", frame)
                    confirmButton:Dock(BOTTOM)
                    confirmButton:DockMargin(10, 10, 10, 10)
                    confirmButton:SetText("Add Drop Group")
                
                    confirmButton.DoClick = function()
                        if addDropGroup() then
                            confirmButton:Remove()
                        end
                    end 
                end

                selectDropGroupButton.DoClick = function()
                    local selectedLine = dropGroupList:GetSelectedLine()
                    if not selectedLine then return end
                
                    -- Retrieve the data associated with the selected line
                    local dropGroupName = dropGroupList:GetLine(selectedLine):GetValue(1)
                    dropGroup = dropGroupName

                    if not dropGroup then return end
                    
                    dropGroupList:Remove()
                    addDropGroupButton:Remove()
                    selectDropGroupButton:Remove()
                    selectDropGroupButton:Remove()
                    
                    npcClassSearch:SetVisible(true)
                    npcClassList:SetVisible(true)
                    crateChanceTextEntry:SetVisible(true)
                    timeIntervalTextEntry:SetVisible(true)
                    xpTextEntry:SetVisible(true)
                    moneyTextEntry:SetVisible(true)
                    xPosTextEntry:SetVisible(true)
                    yPosTextEntry:SetVisible(true)
                    zPosTextEntry:SetVisible(true)
                    addButtonFrame:SetVisible(true)
                    setDropGroupButton:SetVisible(true)
                    crateChanceLabel:SetVisible(true)
                    timeIntervalLabel:SetVisible(true)
                    xpLabel:SetVisible(true)
                    moneyLabel:SetVisible(true)
                    xPosLabel:SetVisible(true)
                    yPosLabel:SetVisible(true)
                    zPosLabel:SetVisible(true)
                    DropGroupLabel:SetVisible(true)

                    
                    DropGroupLabel:SetText("Drop Group: " .. dropGroup)

                end
            end
            
            

            -- Add New Row
            addButtonFrame.DoClick = function()
                if npcClassList:GetSelected()[1] == nil then return end

                local npcClass = npcClassList:GetSelected()[1]:GetValue(1)
                local crateChance = crateChanceTextEntry:GetText()
                local timeInterval = timeIntervalTextEntry:GetText()
                local xPos = tonumber(xPosTextEntry:GetText()) or 0
                local yPos = tonumber(yPosTextEntry:GetText()) or 0
                local zPos = tonumber(zPosTextEntry:GetText()) or 0
                local xp = tonumber(xpTextEntry:GetText()) or 0
                local money = tonumber(moneyTextEntry:GetText()) or 0
                local droupGroup = dropGroup

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

                uniqueID = GetLowestAvailableID()
                frame:Close()

                local positionString = string.format('%.f, %.f, %.f', xPos, yPos, zPos)
                local line = npcListRespawn:AddLine(uniqueID, npcClass, crateChance, timeInterval, xp, money, dropGroup, positionString)
                table.insert(npcDataTable, {
                    uniqueID = uniqueID,
                    npcClass = npcClass,
                    crateChance = crateChance,
                    timeInterval = timeInterval,
                    xPos = xPos,
                    yPos = yPos,
                    zPos = zPos,
                    xp = xp,
                    money = money,
                    dropGroup = droupGroup
                })

                npcListRespawn:SelectItem(line)
                removeButton:SetEnabled(true)
                editButton:SetEnabled(true)
                SaveNPCData()

                net.Start("NPCDataUpdate")
                net.WriteTable({ action = "add", data = npcDataTable[#npcDataTable] })
                net.SendToServer()
            end

            local frameScroll = vgui.Create("DScrollPanel", frame)
            frameScroll:Dock(FILL)

            frameScroll:AddItem(crateChanceLabel)
            frameScroll:AddItem(crateChanceTextEntry)
            frameScroll:AddItem(timeIntervalLabel)
            frameScroll:AddItem(timeIntervalTextEntry)
            frameScroll:AddItem(xpLabel)
            frameScroll:AddItem(xpTextEntry)
            frameScroll:AddItem(moneyLabel)
            frameScroll:AddItem(moneyTextEntry)
            frameScroll:AddItem(xPosLabel)
            frameScroll:AddItem(xPosTextEntry)
            frameScroll:AddItem(yPosLabel)
            frameScroll:AddItem(yPosTextEntry)
            frameScroll:AddItem(zPosLabel)
            frameScroll:AddItem(zPosTextEntry)
            frameScroll:AddItem(addButtonFrame)
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
                net.Start("NPCDataUpdate")
                net.WriteTable({ action = "remove", data = npcDataTable[selectedLine] })
                net.SendToServer()

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
            frame:SetSize(350, 600)
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
            npcClassList:Dock(TOP)
            npcClassList:SetHeight(200)
            npcClassList:SetMultiSelect(false)
            npcClassList:AddColumn("NPC Class")

            -- Function to populate the NPC Class List
            local function populateNPCClassList()
                npcClassList:Clear()

                for npcClass, npcInfo in pairs(list.Get("NPC")) do
                    if string.find(string.lower(npcClass), string.lower(npcClassSearch:GetText()), 1, true) then
                        npcClassList:AddLine(npcClass)
                    end
                end
            end

            -- Populate NPC Class List
            populateNPCClassList()

            -- Filter NPC Class List based on search input
            npcClassSearch.OnValueChange = function(self)
                populateNPCClassList()
            end

            -- Set the selected row in the NPC Class List
            for i, npcLine in ipairs(npcClassList:GetLines()) do
                local npcClass = npcLine:GetValue(1)
                if npcClass == npcData.npcClass then
                    npcClassList:SelectItem(npcLine)
                    break
                end
            end
            
            local DropGroupLabel = vgui.Create("DLabel", frame)
            DropGroupLabel:Dock(TOP)
            DropGroupLabel:DockMargin(10, 0, 10, 5)
            DropGroupLabel:SetText("Drop Group: " .. npcData.dropGroup or "")

            dropGroup = npcData.dropGroup

            local setDropGroupButton = vgui.Create("DButton", frame)
            setDropGroupButton:Dock(TOP)
            setDropGroupButton:DockMargin(10, 0, 10, 5)
            setDropGroupButton:SetText("Set Drop Group")

            local crateChanceLabel = vgui.Create("DLabel", frame)
            crateChanceLabel:Dock(TOP)
            crateChanceLabel:DockMargin(10,0,10,0)
            crateChanceLabel:SetText("Crate Chance:")

            local crateChanceTextEntry = vgui.Create("DTextEntry", frame)
            crateChanceTextEntry:Dock(TOP)
            crateChanceTextEntry:DockMargin(10, 0, 10, 5)
            crateChanceTextEntry:SetPlaceholderText("Crate Chance")
            crateChanceTextEntry:SetText(npcData.crateChance)

            local timeIntervalLabel = vgui.Create("DLabel", frame)
            timeIntervalLabel:Dock(TOP)
            timeIntervalLabel:DockMargin(10,0,10,0)
            timeIntervalLabel:SetText("Respawn Interval:")

            local timeIntervalTextEntry = vgui.Create("DTextEntry", frame)
            timeIntervalTextEntry:Dock(TOP)
            timeIntervalTextEntry:DockMargin(10, 0, 10, 5)
            timeIntervalTextEntry:SetPlaceholderText("Time Interval")
            timeIntervalTextEntry:SetText(npcData.timeInterval)

            local xpLabel = vgui.Create("DLabel", frame)
            xpLabel:Dock(TOP)
            xpLabel:DockMargin(10, 0, 10, 0)
            xpLabel:SetText("XP:")

            local xpTextEntry = vgui.Create("DTextEntry", frame)
            xpTextEntry:Dock(TOP)
            xpTextEntry:DockMargin(10, 0, 10, 5)
            xpTextEntry:SetPlaceholderText("XP")
            xpTextEntry:SetText(npcData.xp or 0)

            local moneyLabel = vgui.Create("DLabel", frame)
            moneyLabel:Dock(TOP)
            moneyLabel:DockMargin(10, 0, 10, 0)
            moneyLabel:SetText("Money:")

            local moneyTextEntry = vgui.Create("DTextEntry", frame)
            moneyTextEntry:Dock(TOP)
            moneyTextEntry:DockMargin(10, 0, 10, 5)
            moneyTextEntry:SetPlaceholderText("Money")
            moneyTextEntry:SetText(npcData.money or 0)

            local xPosLabel = vgui.Create("DLabel", frame)
            xPosLabel:Dock(TOP)
            xPosLabel:DockMargin(10, 0, 10, 0)
            xPosLabel:SetText("X Position:")

            local xPosTextEntry = vgui.Create("DTextEntry", frame)
            xPosTextEntry:Dock(TOP)
            xPosTextEntry:DockMargin(10, 0, 10, 5)
            xPosTextEntry:SetText(tostring(npcData.xPos))
            xPosTextEntry:SetPlaceholderText("X Position")

            local yPosLabel = vgui.Create("DLabel", frame)
            yPosLabel:Dock(TOP)
            yPosLabel:DockMargin(10, 0, 10, 0)
            yPosLabel:SetText("Y Position:")

            local yPosTextEntry = vgui.Create("DTextEntry", frame)
            yPosTextEntry:Dock(TOP)
            yPosTextEntry:DockMargin(10, 0, 10, 5)
            yPosTextEntry:SetText(tostring(npcData.yPos))
            yPosTextEntry:SetPlaceholderText("Y Position")

            local zPosLabel = vgui.Create("DLabel", frame)
            zPosLabel:Dock(TOP)
            zPosLabel:DockMargin(10, 0, 10, 0)
            zPosLabel:SetText("Z Position:")

            local zPosTextEntry = vgui.Create("DTextEntry", frame)
            zPosTextEntry:Dock(TOP)
            zPosTextEntry:DockMargin(10, 0, 10, 5)
            zPosTextEntry:SetText(tostring(npcData.zPos))
            zPosTextEntry:SetPlaceholderText("Z Position")

            local saveButton = vgui.Create("DButton", frame)
            saveButton:Dock(BOTTOM)
            saveButton:DockMargin(10, 10, 10, 10)
            saveButton:SetText("Save")
        
            -- Event for setting the drop group
            setDropGroupButton.DoClick = function()
                -- Hide the original panel elements
                npcClassSearch:SetVisible(false)
                npcClassList:SetVisible(false)
                crateChanceTextEntry:SetVisible(false)
                timeIntervalTextEntry:SetVisible(false)
                xpTextEntry:SetVisible(false)
                moneyTextEntry:SetVisible(false)
                xPosTextEntry:SetVisible(false)
                yPosTextEntry:SetVisible(false)
                zPosTextEntry:SetVisible(false)
                saveButton:SetVisible(false)
                setDropGroupButton:SetVisible(false)
                crateChanceLabel:SetVisible(false)
                timeIntervalLabel:SetVisible(false)
                xpLabel:SetVisible(false)
                moneyLabel:SetVisible(false)
                xPosLabel:SetVisible(false)
                yPosLabel:SetVisible(false)
                zPosLabel:SetVisible(false)
                DropGroupLabel:SetVisible(false)


                local dropGroupList = vgui.Create("DListView", frame)
                dropGroupList:Dock(FILL)
                dropGroupList:SetMultiSelect(false)
                dropGroupList:AddColumn("Drop Group Name")
            
                for _, dropGroupData in ipairs(dropGroupsData) do
                    dropGroupList:AddLine(dropGroupData.groupName)
                end
            
                -- Add Drop Group button
                local addDropGroupButton = vgui.Create("DButton", frame)
                addDropGroupButton:Dock(BOTTOM)
                addDropGroupButton:DockMargin(10, 10, 10, 1)
                addDropGroupButton:SetText("Add Drop Group")
            
                -- Select Drop Group button
                local selectDropGroupButton = vgui.Create("DButton", frame)
                selectDropGroupButton:Dock(BOTTOM)
                selectDropGroupButton:DockMargin(10, 1, 10, 10)
                selectDropGroupButton:SetText("Select Drop Group")
            
                addDropGroupButton.DoClick = function()
                    -- Hide the original panel elements
                    dropGroupList:SetVisible(false)
                    addDropGroupButton:SetVisible(false)
                    selectDropGroupButton:SetVisible(false)
                
                    -- Create a text box for drop group name
                    local dropGroupNameLabel = vgui.Create("DLabel", frame)
                    dropGroupNameLabel:Dock(TOP)
                    dropGroupNameLabel:DockMargin(10, 10, 10, 0)
                    dropGroupNameLabel:SetText("Drop Group Name:")
                
                    local dropGroupNameTextEntry = vgui.Create("DTextEntry", frame)
                    dropGroupNameTextEntry:Dock(TOP)
                    dropGroupNameTextEntry:DockMargin(10, 0, 10, 5)
                    dropGroupNameTextEntry:SetPlaceholderText("Enter drop group name")
                
                    -- Create a DListView for drop lists
                    local dropListLabel = vgui.Create("DLabel", frame)
                    dropListLabel:Dock(TOP)
                    dropListLabel:DockMargin(10, 10, 10, 0)
                    dropListLabel:SetText("Items:")
                
                    local dropListView = vgui.Create("DListView", frame)
                    dropListView:Dock(FILL)
                    dropListView:SetMultiSelect(false)
                    dropListView:SetHeight(440)
                    dropListView:AddColumn("Items")
                    dropListView:AddColumn("Enabled"):SetMaxWidth(50)
                
                
                    -- Populate drop list view with temporary values
                    for _, dropList in ipairs(DropListValues) do
                        local line = dropListView:AddLine(dropList.name, tostring(dropList.enabled))
                        line.DropList = dropList
                    end

                    function dropListView:DoDoubleClick(lineID, line)
                        if line and line.DropList then
                            -- Toggle the enabled value
                            line.DropList.enabled = not line.DropList.enabled
                            line:SetValue(2, tostring(line.DropList.enabled))
                    
                            -- Update the value in the temporary table
                            DropListValues[lineID].enabled = line.DropList.enabled
                        end
                    end

                    -- Function to handle adding a new drop group
                    local function addDropGroup()
                        local groupName = dropGroupNameTextEntry:GetText()
                        if groupName == "" or groupName == nil then return end
                
                        local dropValues = {}
                        for _, line in ipairs(dropListView:GetLines()) do
                            if groupName == "" or groupName == nil then return end
                            if groupName == line.DropList.name then return end
                            if line:GetColumnText(2) == "true" then
                                local dropList = line.DropList
                                local enabled = line:GetColumnText(2) == "true"
                                table.insert(dropValues, dropList.name)
                            end
                        end

                        local dropGroupData = {
                            groupName = groupName,
                            dropList = dropValues,
                            npcCount = 0
                        }
                        dropGroupList:AddLine(dropGroupData.groupName)
                        table.insert(dropGroupsData, dropGroupData)

                        WriteDropGroupsDataToFile()

                        
                        dropGroupNameLabel:Remove()
                        dropGroupNameTextEntry:Remove()
                        dropListLabel:Remove()
                        dropListView:Remove()
                        dropGroupList:SetVisible(true)
                        addDropGroupButton:SetVisible(true)
                        selectDropGroupButton:SetVisible(true)
                        return true
                    end
                
                    -- Add button to confirm adding the drop group
                    local confirmButton = vgui.Create("DButton", frame)
                    confirmButton:Dock(BOTTOM)
                    confirmButton:DockMargin(10, 10, 10, 10)
                    confirmButton:SetText("Add Drop Group")
                
                    confirmButton.DoClick = function()
                        if addDropGroup() then
                            confirmButton:Remove()
                        end
                    end 
                end

                selectDropGroupButton.DoClick = function()
                    local selectedLine = dropGroupList:GetSelectedLine()
                    if not selectedLine then return end
                
                    -- Retrieve the data associated with the selected line
                    local dropGroupName = dropGroupList:GetLine(selectedLine):GetValue(1)
                    dropGroup = dropGroupName

                    if not dropGroup then return end
                    
                    dropGroupList:Remove()
                    addDropGroupButton:Remove()
                    selectDropGroupButton:Remove()
                    selectDropGroupButton:Remove()
                    
                    npcClassSearch:SetVisible(true)
                    npcClassList:SetVisible(true)
                    crateChanceTextEntry:SetVisible(true)
                    timeIntervalTextEntry:SetVisible(true)
                    xpTextEntry:SetVisible(true)
                    moneyTextEntry:SetVisible(true)
                    xPosTextEntry:SetVisible(true)
                    yPosTextEntry:SetVisible(true)
                    zPosTextEntry:SetVisible(true)
                    saveButton:SetVisible(true)
                    setDropGroupButton:SetVisible(true)
                    crateChanceLabel:SetVisible(true)
                    timeIntervalLabel:SetVisible(true)
                    xpLabel:SetVisible(true)
                    moneyLabel:SetVisible(true)
                    xPosLabel:SetVisible(true)
                    yPosLabel:SetVisible(true)
                    zPosLabel:SetVisible(true)
                    DropGroupLabel:SetVisible(true)

                    
                    DropGroupLabel:SetText("Drop Group: " .. dropGroup)

                end
            end

            -- Save Edited Row
            saveButton.DoClick = function()
                local npcClass = npcClassList:GetSelected()[1]:GetValue(1)
                local crateChance = crateChanceTextEntry:GetText()
                local timeInterval = timeIntervalTextEntry:GetText()
                local xPos = tonumber(xPosTextEntry:GetText()) or 0
                local yPos = tonumber(yPosTextEntry:GetText()) or 0
                local zPos = tonumber(zPosTextEntry:GetText()) or 0
                local xp = tonumber(xpTextEntry:GetText()) or npcData.xp
                local money = tonumber(moneyTextEntry:GetText()) or npcData.money

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
                local line = npcListRespawn:AddLine(uniqueID, npcClass, crateChance, timeInterval, xp, money, dropGroup, positionString)
                table.insert(npcDataTable, { uniqueID = uniqueID, npcClass = npcClass, crateChance = crateChance, timeInterval = timeInterval, xPos = xPos, yPos = yPos, zPos = zPos, xp = xp, money = money, dropGroup = dropGroup })

                SaveNPCData()
                print(uniqueID)
                npcData.uniqueID = uniqueID
                npcData.npcClass = npcClass
                npcData.crateChance = crateChance
                npcData.timeInterval = timeInterval
                npcData.xPos = xPos
                npcData.yPos = yPos
                npcData.zPos = zPos
                npcData.money = money
                npcData.xp = xp
                npcData.dropGroup = dropGroup
                net.Start("NPCDataUpdate")
                net.WriteTable({ action = "edit", data = npcData })
                net.SendToServer()
            end
        end



        -- Item Group Tab

        local dropGroupsTab = vgui.Create("DPanel", tabPanel)
        dropGroupsTab.Paint = function(self, w, h)
            -- Panel appearance customization for DropGroups tab
            surface.SetDrawColor(255, 255, 255)
            surface.DrawRect(0, 0, w, h)
        end
        tabPanel:AddSheet("DropGroups", dropGroupsTab)

        -- Create the DListView
        local dropGroupsList = vgui.Create("DListView", dropGroupsTab)
        dropGroupsList:Dock(FILL)
        dropGroupsList:SetMultiSelect(false)
        dropGroupsList:AddColumn("Group Name"):SetMaxWidth(75)
        dropGroupsList:AddColumn("Drop List")
        dropGroupsList:AddColumn("NPC's"):SetMaxWidth(35)

        for _, dropGroup in ipairs(dropGroupsData) do
            local groupName = dropGroup.groupName
            local dropList = dropGroup.dropList
            local npcCount = dropGroup.npcCount
        
            if type(dropList) == "table" then
                dropList = table.concat(dropList, ", ")
            end
        
            local listItem = dropGroupsList:AddLine(groupName, dropList, npcCount)
            listItem.groupName = groupName
        end

        local editGroupButton = vgui.Create("DButton", dropGroupsTab)
        editGroupButton:Dock(BOTTOM)
        editGroupButton:DockMargin(10, 10, 10, 10)
        editGroupButton:SetText("Edit")
        editGroupButton.DoClick = function()
            local selectedLine = dropGroupsList:GetSelectedLine()
            if not selectedLine then return end
        
            -- Retrieve the data associated with the selected line
            local listItem = dropGroupsList:GetLine(selectedLine)
            local groupName = listItem:GetValue(1)
        
            local frame = vgui.Create("DFrame")
            frame:SetSize(350, 600)
            frame:SetTitle("Edit Drop Group")
            frame:Center()
            frame:MakePopup()
        
            -- Create a text box for drop group name
            local dropGroupNameLabel = vgui.Create("DLabel", frame)
            dropGroupNameLabel:Dock(TOP)
            dropGroupNameLabel:DockMargin(10, 10, 10, 0)
            dropGroupNameLabel:SetText("Drop Group Name:")
        
            local dropGroupNameTextEntry = vgui.Create("DTextEntry", frame)
            dropGroupNameTextEntry:Dock(TOP)
            dropGroupNameTextEntry:DockMargin(10, 0, 10, 5)
            dropGroupNameTextEntry:SetPlaceholderText("Enter drop group name")
            dropGroupNameTextEntry:SetText(groupName) -- Set the initial value to the existing group name
        
            -- Create a DListView for drop lists
            local dropListLabel = vgui.Create("DLabel", frame)
            dropListLabel:Dock(TOP)
            dropListLabel:DockMargin(10, 10, 10, 0)
            dropListLabel:SetText("Items:")
        
            local dropListView = vgui.Create("DListView", frame)
            dropListView:Dock(FILL)
            dropListView:SetMultiSelect(false)
            dropListView:SetHeight(440)
            dropListView:AddColumn("Items")
            dropListView:AddColumn("Enabled"):SetMaxWidth(50)
        
            -- Retrieve the existing drop group data
            local dropGroupData = dropGroupsData[selectedLine]
            local existingDropList = dropGroupData.dropList
        
            -- Populate drop list view with existing drop list values
            for _, dropList in ipairs(DropListValues) do
                local enabled = table.HasValue(existingDropList, dropList.name)
                local line = dropListView:AddLine(dropList.name, tostring(enabled))
                line.DropList = dropList
            end
        
            function dropListView:DoDoubleClick(lineID, line)
                if line and line.DropList then
                    -- Toggle the enabled value
                    line.DropList.enabled = not line.DropList.enabled
                    line:SetValue(2, tostring(line.DropList.enabled))
        
                    -- Update the value in the existing drop group data
                    local dropListName = line.DropList.name
                    local enabled = line.DropList.enabled
        
                    if enabled then
                        table.insert(existingDropList, dropListName)
                    else
                        table.RemoveByValue(existingDropList, dropListName)
                    end
                end
            end
        
            -- Function to handle editing the drop group
            local function editDropGroup()
                local updatedGroupName = dropGroupNameTextEntry:GetText()
            
                -- Update the group name in the existing drop group data
                dropGroupData.groupName = updatedGroupName
                dropGroupData.dropList = existingDropList
            
                -- Update the list item in the dropGroupsList view
                listItem:SetValue(1, updatedGroupName)
                local updatedDropList = table.concat(existingDropList, ",")
                listItem:SetValue(2, updatedDropList)
            
                WriteDropGroupsDataToFile()
            end
        
            -- Add button to confirm editing the drop group
            local confirmButton = vgui.Create("DButton", frame)
            confirmButton:Dock(BOTTOM)
            confirmButton:DockMargin(10, 10, 10, 10)
            confirmButton:SetText("Edit Drop Group")
        
            confirmButton.DoClick = function()
                editDropGroup()
                frame:Close()
            end
        end

        local removeGroupButton = vgui.Create("DButton", dropGroupsTab)
        removeGroupButton:Dock(BOTTOM)
        removeGroupButton:DockMargin(10, 10, 10, 0)
        removeGroupButton:SetText("Remove")

        removeGroupButton.DoClick = function()
            local selectedLine = dropGroupsList:GetSelectedLine()
            if not selectedLine then return end
        
            -- Retrieve the data associated with the selected line
            local listItem = dropGroupsList:GetLine(selectedLine)
            local groupName = listItem:GetValue(1)
        
            -- Remove the drop group from dropGroupsData
            for i, dropGroup in ipairs(dropGroupsData) do
                if dropGroup.groupName == groupName then
                    table.remove(dropGroupsData, i)
                    break
                end
            end
        
            -- Remove the selected line from the dropGroupsList view
            dropGroupsList:RemoveLine(selectedLine)
        
            WriteDropGroupsDataToFile()
        end
    end)
end