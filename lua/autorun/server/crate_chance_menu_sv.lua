include("hooks.lua")

concommand.Add("npcmenu", function(ply)
        local npcClasses = GetNPCClasses()
        net.Start("OpenNPCMenu")
        net.WriteTable(npcClasses)
        net.Send(ply)
    end)

if ( SERVER) then
    
    util.AddNetworkString("OpenNPCMenu")
    util.AddNetworkString("SetNPCCrateChance")
    util.AddNetworkString("GetNPCCrateChance")

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

    local crateChances = LoadCrateChances()

    net.Receive("GetNPCCrateChance", function(_, ply)
        local selectedNPCClass = net.ReadString()
        local crateChance = crateChances[selectedNPCClass] or 0

        net.Start("SetNPCCrateChance")
        net.WriteInt(crateChance, 32)
        net.Send(ply)
    end)

    net.Receive("SetNPCCrateChance", function(_, ply)
        local selectedNPCClass = net.ReadString()
        local newValue = net.ReadInt(32)
        npcCrateChances[selectedNPCClass] = newValue

        crateChances[selectedNPCClass] = newValue
        SaveCrateChances(crateChances)
    end)

    function GetNPCClasses()
        local npcClasses = {}
        for npcClass, npcInfo in pairs(list.Get("NPC")) do
            table.insert(npcClasses, {
                class = npcClass,
                name = npcInfo.Name or npcClass,
                category = npcInfo.Category or "Unknown"
            })
        end
        return npcClasses
    end


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

    local npcCrateChances = LoadCrateChances()

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
        local crateChance = npcCrateChances[npcClass] or 0

        -- Roll a chance based on crateChance value
        if math.random() <= crateChance then
            local crate = ents.Create("npc_drop_crate")
            crate:SetPos(npc:GetPos())
            crate:Spawn()
        end
    end)
end
