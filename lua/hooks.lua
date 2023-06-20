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

    -- Rest of your server-side code...

    -- When an NPC is killed, roll a chance to determine if a crate will drop
    hook.Add("OnNPCKilled", "NPCDropCrate", function(npc, attacker, inflictor)
        local npcClass = npc:GetClass()
        local crateChance = npcCrateChances[npcClass] or 0
        print(crateChance)
        -- Roll a chance based on crateChance value
        if math.random(0,100) <= crateChance then

            local crate = ents.Create("npc_drop_crate")
            crate:SetPos(npc:GetPos())
            crate:Spawn()
        end
    end)
end







