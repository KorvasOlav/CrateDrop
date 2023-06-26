npcCrateChances = {}
npcUpdates = {}

if SERVER then
    local function LoadCrateChances()
        if not file.Exists("crate_chances.txt", "DATA") then
            return {}
        end

        local contents = file.Read("crate_chances.txt", "DATA")
        return util.JSONToTable(contents) or {}
    end

    local function SaveCrateChances(crateChances)
        local contents = util.TableToJSON(crateChances)
        file.Write("crate_chances.txt", contents)
    end

    npcCrateChances = LoadCrateChances()

    local function InitializeNPCCrateChances()
        for npcClass, _ in pairs(list.Get("NPC")) do
            if npcCrateChances[npcClass] == nil then
                npcCrateChances[npcClass] = 0 -- Set initial crate chance to 0 for NPC classes not found in the file
            end
        end
    end

    hook.Add("Initialize", "InitializeNPCCrateChances", InitializeNPCCrateChances)

    hook.Add("Initialize", "RegisterNPCSpawnCommand", function()
        concommand.Add("view_npc_spawn_locations", function(ply, _, _)
            -- Send the network message to the specific player
            net.Start("Cratedrop_ViewNPCSpawnLocations")
            net.Send(ply)
        end)
    end)

    -- When an NPC is killed, roll a chance to determine if a crate will drop
    hook.Add("OnNPCKilled", "NPCDropCrate", function(npc, attacker, inflictor)
        local npcClass = npc:GetClass()
        local crateChance = 0
        if npc.CrateChance ~= nil then
            crateChance = npc.CrateChance
            money = npc.money or 0
            xp = npc.xp or 0
        else
            crateChance = npcCrateChances[npcClass] or 0
        end
        -- Roll a chance based on crateChance value
        if math.random(0, 100) <= crateChance then
            local spawnPosition = npc:GetPos() + Vector(0, 0, 10)
    
            local crate = ents.Create("npc_drop_crate")
            crate:SetPos(spawnPosition)
            crate:Spawn()
            crate.money = money
            crate.xp = xp
            npc.CrateChance = nil
        end
    end)

    hook.Add("InitPostEntity", "LoadNPCDataForPersist", function()
        local data = file.Read("npc_data.txt", "DATA")
        if data then
            npcData = util.JSONToTable(data)
            SpawnNPCsFromTable()
            return npcData
        end
        return nil
    end)

    function SpawnNPCsFromTable()
        for _, npcEntry in ipairs(npcData) do
            local uniqueID = npcEntry.uniqueID
            local npcClass = npcEntry.npcClass
            local crateChance = npcEntry.crateChance
            local timeInterval = npcEntry.timeInterval
            local money = npcEntry.money
            local xp = npcEntry.xp
            local xPos = npcEntry.xPos
            local yPos = npcEntry.yPos
            local zPos = npcEntry.zPos
    
            local npcPosition = Vector(xPos, yPos, zPos)
            local npcEntity = ents.Create(npcClass)
            if IsValid(npcEntity) then
                npcEntity:SetPos(npcPosition)
                npcEntity:Spawn()
                npcEntity.TimeInterval = tonumber(timeInterval)
                npcEntity.UniqueID = tonumber(uniqueID)
                npcEntity.CrateChance = tonumber(crateChance)
                npcEntity.money = tonumber(money)
                npcEntity.xp = tonumber(xp)
                npcEntity.SpawnPos = npcPosition
            end
        end
    end

    hook.Add("OnNPCKilled", "PersistantNPCRespawn", function(npc, attacker, inflictor)
        if npc.TimeInterval ~= nil then

            
            local uniqueID = 0
            local npcClass = 0
            local crateChance = 0
            local money = 0
            local xp = 0
            local npcPosition = 0
            local timeInterval = 0
            if #npcUpdates > 0 then
                for _, npcEntry in pairs(npcUpdates) do 
                    if npcEntry.uniqueID == npc.UniqueID then
                        if npcEntry.remove then 
                            table.RemoveByValue(npcUpdates, npcEntry)
                            return
                        end
                        uniqueID = tonumber(npcEntry.uniqueID)
                        npcClass = npcEntry.npcClass
                        crateChance = tonumber(npcEntry.crateChance)
                        timeInterval = tonumber(npcEntry.timeInterval)
                        money = tonumber(npcEntry.money)
                        xp = tonumber(npcEntry.xp)
                        xPos = npcEntry.xPos
                        yPos = npcEntry.yPos
                        zPos = npcEntry.zPos
                        npcPosition = Vector(xPos, yPos, zPos)
                    else
                        uniqueID = npc.UniqueID
                        npcClass = npc:GetClass()
                        crateChance = npc.CrateChance
                        money = npc.money
                        xp = npc.xp
                        npcPosition = npc.SpawnPos
                        timeInterval = npc.TimeInterval
                    end
                end
            else
                uniqueID = npc.UniqueID
                npcClass = npc:GetClass()
                crateChance = npc.CrateChance
                money = npc.money
                xp = npc.xp
                npcPosition = npc.SpawnPos
                timeInterval = tonumber(npc.TimeInterval)
            end
            timer.Simple(timeInterval, function()
                local npcEntity = ents.Create(npcClass)
                if IsValid(npcEntity) then
                    npcEntity:SetPos(npcPosition)
                    npcEntity:Spawn()
                    npcEntity.UniqueID = uniqueID
                    npcEntity.TimeInterval = timeInterval
                    npcEntity.CrateChance = crateChance
                    npcEntity.money = money
                    npcEntity.xp = xp
                    npcEntity.SpawnPos = npcPosition
                end
            end)
        end
    end)

    net.Receive("NPCDataUpdate", function(len, ply)
        local updateData = net.ReadTable()
        local action = updateData.action
        local data = updateData.data
    
        if action == "add" then
            HandleAddAction(data)
        elseif action == "edit" then
            HandleEditAction(data)
        elseif action == "remove" then
            HandleRemoveAction(data)
        end
    end)

    function HandleAddAction(data)
        if type(data) == "table" then
            local uniqueID = data.uniqueID
            local npcClass = data.npcClass
            local crateChance = data.crateChance
            local timeInterval = data.timeInterval
            local money = data.money
            local xp = data.xp
            local xPos = data.xPos
            local yPos = data.yPos
            local zPos = data.zPos
    
            local npcPosition = Vector(xPos, yPos, zPos)
            local npcEntity = ents.Create(npcClass)
            if IsValid(npcEntity) then
                npcEntity:SetPos(npcPosition)
                npcEntity:Spawn()
                npcEntity.TimeInterval = tonumber(timeInterval)
                npcEntity.UniqueID = tonumber(uniqueID)
                npcEntity.CrateChance = tonumber(crateChance)
                npcEntity.money = tonumber(money)
                npcEntity.xp = tonumber(xp)
                npcEntity.SpawnPos = npcPosition
            end
        end
    end
    
    function HandleEditAction(data)
        if type(data) == "table" then
            if #npcUpdates > 0 then
                for i, npcEntry in ipairs(npcUpdates) do
                    if !npcUpdates[i] then
                        table.insert(npcUpdates, data)
                    end
                end
            else
                table.insert(npcUpdates, data)
            end
        end
    end
    
    function HandleRemoveAction(data)
        if type(data) == "table" then
            data.remove = true
            if #npcUpdates > 0 then
                for i, npcEntry in ipairs(npcUpdates) do
                    if !npcUpdates[i] then
                        table.insert(npcUpdates, data)
                    end
                end
            else
                table.insert(npcUpdates, data)
            end
        end
    end
end