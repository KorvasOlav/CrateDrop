TOOL.Category = "Korvas Tools"
TOOL.Name = "#tool.npc_spawner.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
    ["npc_class"] = "",
    ["crate_chance"] = "0",
    ["respawn_enabled"] = "0", 
    ["respawn_timer"] = "60"  
}

-- Add tool parameters
if CLIENT then
    language.Add("tool.npc_spawner.name", "NPC Spawner Tool")
    language.Add("tool.npc_spawner.desc", "Spawns an NPC entity with configurable settings.")
    language.Add("tool.npc_spawner.0", "Left-click to spawn the entity.")

    function TOOL.BuildCPanel(panel)
        -- Crate Chance
        panel:NumSlider("Crate Chance", "npc_spawner_crate_chance", 0, 100, 2)

        -- NPC Class
        local npcClassCombo = panel:ComboBox("NPC Class", "npc_spawner_npc_class")
        local npcClasses = list.Get("NPC")
        for npcClass, npcData in pairs(npcClasses) do
            local displayName = npcData.Name or npcClass
            npcClassCombo:AddChoice(displayName, npcClass)
        end

        -- Respawn Enabled
        panel:CheckBox("Respawn Enabled", "npc_spawner_respawn_enabled")

        -- Respawn Timer
        panel:NumSlider("Respawn Timer", "npc_spawner_respawn_timer", 0, 1800, 0)
    end
end

-- Spawn the entity when the tool is used
function TOOL:LeftClick(trace)
    if CLIENT then return true end

    -- Retrieve tool parameters
    local crateChance = self:GetClientNumber("crate_chance")
    local npcClass = self:GetClientInfo("npc_class")
    local respawnEnabled = self:GetClientNumber("respawn_enabled") == 1
    local respawnTimer = self:GetClientNumber("respawn_timer")
    local owner = self:GetOwner()

    -- Create the entity
    local ent = ents.Create("spawn_npc_stool")
    -- print(npcClass)
    if not IsValid(ent) then return end

    -- Set entity variables
    ent:SetPos(trace.HitPos)
    ent:SetAngles(trace.HitNormal:Angle())
    ent:Spawn()

    -- Set tool parameters to entity variables
    ent.CrateChance = crateChance
    ent.NPCClass = npcClass
    -- print(ent.NPCClass)
    ent.RespawnEnabled = respawnEnabled
    ent.RespawnTimer = respawnTimer
    
    undo.Create("NPC Spawner")
        undo.AddEntity(ent)
        undo.SetPlayer(owner)
    undo.Finish()
    ent:SpawnNPC()

    -- Store entity reference in NPC for event handling
    if IsValid(trace.Entity) and trace.Entity:IsNPC() then
        trace.Entity.SpawnerEntity = ent
    end

    return true
end