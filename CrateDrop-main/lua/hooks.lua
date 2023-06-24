npcCrateChances = {}

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
        else
            crateChance = npcCrateChances[npcClass] or 0
        end
        -- Roll a chance based on crateChance value
        if math.random(0, 100) <= crateChance then
            local spawnPosition = npc:GetPos() + Vector(0, 0, 10)
    
            local crate = ents.Create("npc_drop_crate")
            crate:SetPos(spawnPosition)
            crate:Spawn()
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
            local npcClass = npcEntry.npcClass
            local crateChance = npcEntry.crateChance
            local timeInterval = npcEntry.timeInterval
            local xPos = npcEntry.xPos
            local yPos = npcEntry.yPos
            local zPos = npcEntry.zPos
    
            local npcPosition = Vector(xPos, yPos, zPos)
            local npcEntity = ents.Create(npcClass)
            if IsValid(npcEntity) then
                npcEntity:SetPos(npcPosition)
                npcEntity:Spawn()
                npcEntity.TimeInterval = tonumber(npcEntry.timeInterval)
                npcEntity.CrateChance = tonumber(npcEntry.crateChance)
                npcEntity.SpawnPos = npcPosition
            end
        end
    end

    hook.Add("OnNPCKilled", "PersistantNPCRespawn", function(npc, attacker, inflictor)
        if npc.TimeInterval ~= nil then
            local npcClass = npc:GetClass()
            local crateChance = npc.CrateChance
            local npcPosition = npc.SpawnPos
            local timeInterval = npc.TimeInterval
            timer.Simple(timeInterval, function()
                local npcEntity = ents.Create(npcClass)
                if IsValid(npcEntity) then
                    npcEntity:SetPos(npcPosition)
                    npcEntity:Spawn()
                    npcEntity.TimeInterval = timeInterval
                    npcEntity.CrateChance = crateChance
                    npcEntity.SpawnPos = npcPosition
                end
            end)
        end
    end)
end

