AddCSLuaFile()

-- Define the entity
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Spawned NPC Entity"
ENT.Author = "Korvas"

-- Initialize the entity
function ENT:Initialize()
    if SERVER then
        -- Set up entity variables
        -- self:SetModel("models/props_junk/wood_crate001a.mdl")
        self:SetSolid(SOLID_NONE)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetNoDraw(true)

        -- Assign the NPC class and crate chance
        self.NPCClass = ""
        self.CrateChance = 0

        -- Spawn NPC and assign crate chance
        -- self:SpawnNPC()

        -- Initialize respawn timer variables
        self.RespawnEnabled = false
        self.RespawnTimer = 0
        
    end
end

-- Spawn NPC and assign crate chance
function ENT:SpawnNPC()
    local npc = ents.Create(self.NPCClass) -- Use self:GetNPCClass() to retrieve the assigned NPC class
    npc:SetPos(self:GetPos())
    npc:Spawn()
    npc.SpawnerEntity = self

    -- Assign crate chance to the NPC
    npc.CrateChance = self.CrateChance or 0

    -- Store the spawned NPC for removal when necessary
    self.SpawnedNPC = npc
end

-- Handle entity removal
function ENT:OnRemove()
    if SERVER then
        -- Remove the spawned NPC
        if IsValid(self.SpawnedNPC) then
            self.SpawnedNPC:Remove()
        end
    end
end

-- Handle NPC death
function ENT:HandleNPCDeath()
    if SERVER then
        -- Check if respawn is enabled
        if self.RespawnEnabled then
            -- Start respawn timer
            timer.Simple(self.RespawnTimer, function()
                if IsValid(self) then
                    -- Respawn NPC
                    self:SpawnNPC()
                end
            end)
        else
            -- Remove the entity if respawn is disabled
            self:Remove()
        end
    end
end

-- Set the variables passed from the GMod tool
function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "CrateChance")
    self:NetworkVar("String", 0, "NPCClass")
    self:NetworkVar("Bool", 0, "RespawnEnabled")
    self:NetworkVar("Float", 1, "RespawnTimer")
end


-- Handle NPC death and removal
hook.Add("OnNPCKilled", "HandleNPCDeath", function(npc, attacker, inflictor)
    if npc.SpawnerEntity then
        npc.SpawnerEntity:HandleNPCDeath()
    end
end)
