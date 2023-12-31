include("hooks.lua")

concommand.Add("npcmenu", function(ply)
    -- local npcClasses = GetNPCClasses()
    net.Start("OpenNPCMenu")
    net.Send(ply)
end)



if ( SERVER ) then
    util.AddNetworkString("OpenNPCMenu")
    util.AddNetworkString("SetNPCCrateChance")
    util.AddNetworkString("SaveNPCCrateChance")
    util.AddNetworkString("GetNPCCrateChance")
    util.AddNetworkString("Cratedrop_ViewNPCSpawnLocations")
    util.AddNetworkString("NPCDataUpdate")

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

    net.Receive("SaveNPCCrateChance", function(_, ply)
        local selectedNPCClass = net.ReadString()
        local newValue = net.ReadInt(32)
        npcCrateChances[selectedNPCClass] = newValue

        crateChances[selectedNPCClass] = newValue
        SaveCrateChances(crateChances)
    end)

    
end