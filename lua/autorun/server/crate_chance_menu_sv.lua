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

    -- When an NPC is killed, roll a chance to determine if a crate will drop
    hook.Add("OnNPCKilled", "NPCDropCrate", function(npc, attacker, inflictor)
        local npcClass = npc:GetClass()
        local crateChance = 0
    
        local npcNWFloat = npc:GetNWFloat("CrateChance")
        if npcNWFloat ~= 0 then
            crateChance = npcNWFloat
        else
            crateChance = npcCrateChances[npcClass] or 0
        end
        print(crateChance)
        -- Roll a chance based on crateChance value
        if math.random(0, 100) <= crateChance then
            local spawnPosition = npc:GetPos() + Vector(0, 0, 10)
    
            local crate = ents.Create("npc_drop_crate")
            crate:SetPos(spawnPosition)
            crate:Spawn()
        end
    end)
end
