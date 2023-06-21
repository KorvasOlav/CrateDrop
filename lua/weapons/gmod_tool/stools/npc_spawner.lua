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
        panel:NumSlider("Respawn Timer", "npc_spawner_respawn_timer", 0, 60, 0)
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







-- TOOL.ClientConVar = {
--     ["npc_class"] = "",
--     ["crate_chance"] = "0",
--     ["respawn_enabled"] = "0", 
--     ["respawn_interval"] = "60"  
-- }

-- if CLIENT then
--     language.Add("tool.npc_spawner.name", "Crate Chance")
--     language.Add("tool.npc_spawner.desc", "Set the crate chance for an NPC")
--     language.Add("tool.npc_spawner.0", "Left-click: Set Crate Chance")
-- end

-- local function SpawnNPC(pos, npcClass, crateChance)
--     if npcClass ~= "" then
--         local npc = ents.Create(npcClass)
--         npc:SetPos(pos)
--         npc:Spawn()
--         npc:Activate()

--         npc:SetNWFloat("CrateChance", crateChance)
--     end
-- end

-- -- RespawnNPC currently infinitely spawns NPC's without ever stopping, even if one is still alive, it will spawn another.

-- local function RespawnNPC(npcClass, crateChance, respawnInterval, pos)


--     SpawnNPC(pos, npcClass, crateChance)

--     -- Schedule the next respawn if enabled
--     if GetConVar("npc_spawner_respawn_enabled"):GetBool() then
--         local interval = GetConVar("npc_spawner_respawn_interval"):GetFloat()
--         timer.Simple(interval, function()
--             RespawnNPC(npcClass, crateChance, respawnInterval, pos)
--         end)
--     end
-- end



-- function TOOL:LeftClick(trace)
--     if CLIENT then return true end

--     if not IsValid(trace.Entity) or not trace.Entity:IsNPC() then
--         if not IsFirstTimePredicted() then return end -- Ensure the code only runs on the client

--         if IsValid(trace.Entity) and trace.Entity:IsPlayer() then return end -- Don't spawn NPCs on players

--         local npcClass = self:GetClientInfo("npc_class")
--         local crateChance = tonumber(self:GetClientInfo("crate_chance")) or 0
--         local respawnEnabled = self:GetClientNumber("respawn_enabled") == 1
--         local respawnInterval = tonumber(self:GetClientInfo("respawn_interval")) or 60

--         SpawnNPC(trace.HitPos, npcClass, crateChance)

--         -- Schedule respawn if enabled
--         if respawnEnabled then
--             timer.Simple(respawnInterval, function()
--                 RespawnNPC(npcClass, crateChance, respawnInterval, trace.HitPos)
--             end)
--         end

--         return true
--     end

--     local ply = self:GetOwner()
--     local crateChance = tonumber(self:GetClientInfo("crate_chance")) or 0

--     trace.Entity:SetNWFloat("CrateChance", crateChance)

--     return true
-- end


-- function TOOL.BuildCPanel(panel)
--     panel:AddControl("Header", {Text = "#tool.npc_spawner.name", Description = "#tool.npc_spawner.desc"})

--     local npcSelectionLabel = vgui.Create("DLabel")
--     npcSelectionLabel:SetText("Select NPC:")
--     npcSelectionLabel:SetDark(true)
--     panel:AddItem(npcSelectionLabel)

--     local npcComboBox = vgui.Create("DComboBox")
--     npcComboBox:SetSize(200, 20)
--     npcComboBox:SetSortItems(false)

--     -- Add NPC options to the combobox
--     for _, npcData in pairs(list.Get("NPC")) do
--         npcComboBox:AddChoice(npcData.Name, npcData.Class)
--     end

--     npcComboBox.OnSelect = function(_, index, value, data)
--         RunConsoleCommand("npc_spawner_npc_class", data) -- Set the convar to the selected NPC class
--     end

--     panel:AddItem(npcComboBox)

--     local form = vgui.Create("DForm", panel)
--     form:SetName("Crate Chance")

--     local crateChanceSlider = form:NumSlider("Chance", "npc_spawner_crate_chance", 0, 100, 2)
--     crateChanceSlider.OnValueChanged = function(_, value)
--         RunConsoleCommand("npc_spawner_crate_chance", tostring(value)) -- Set the convar to the slider value
--     end

--     panel:AddItem(form)

--     local respawnCheckbox = panel:CheckBox("Enable NPC Respawn", "npc_spawner_respawn_enabled")
--     local respawnIntervalSlider = panel:NumSlider("Respawn Interval (seconds)", "npc_spawner_respawn_interval", 0, 600, 0)

--     local respawnIntervalDelay = 0.5  -- Adjust the delay time as needed
--     local respawnIntervalTimer = nil

--     respawnCheckbox.OnChange = function(_, value)
--         if value then
--             LocalPlayer():ConCommand("npc_spawner_respawn_enabled 1")
--         else
--             LocalPlayer():ConCommand("npc_spawner_respawn_enabled 0")
--         end
--     end

--     respawnIntervalSlider.OnValueChanged = function(_, value)
--         -- Clear the previous timer, if any
--         if respawnIntervalTimer then
--             timer.Remove(respawnIntervalTimer)
--         end

--         -- Set a new timer to execute the command after the delay
--         respawnIntervalTimer = "npc_spawner_respawn_interval_timer" .. tostring(math.random(1, 99999))
--         timer.Create(respawnIntervalTimer, respawnIntervalDelay, 1, function()
--             LocalPlayer():ConCommand("npc_spawner_respawn_interval " .. tostring(value))
--         end)
--     end

--     panel:AddItem(respawnCheckbox)
--     panel:AddItem(respawnIntervalSlider)
-- end

-- if CLIENT then
--     cleanup.Register("npc_spawner")
-- end