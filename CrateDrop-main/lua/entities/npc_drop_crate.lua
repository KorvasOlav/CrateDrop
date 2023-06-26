AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName = "Drop Crate"
ENT.Author = "Korvas"
ENT.Information = "A crate that has a chance for this and a chance for that"
ENT.Category = ""

ENT.Editable = true
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.Model = "models/hunter/blocks/cube025x025x025.mdl"


function ENT:Initialize()
    if SERVER then
        self:SetModel(self.Model)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self.xp = 1
        self.money = 10
        
        
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end
end

function ENT:Draw()
    self:DrawModel()
end

-- Probability table for crate contents
local probabilities = {
    {type = "entity", chance = 0.1},
    {type = "money", chance = 0.5},
    {type = "xp", chance = 1},
}

-- Function to determine the crate contents
local function DetermineCrateContents()
    -- Generate a random number between 0 and 1
    local rand = math.random()

    -- Iterate over the probabilities table
    for _, data in ipairs(probabilities) do
        if rand <= data.chance then
            return data.type
        end
    end

    return nil
end


local entityTable = {
    "sent_ball",
    "item_healthcharger",
    "item_suitcharger",
}

-- Function to spawn the entity dropped from the crate
local function SpawnDroppedEntity(position)
    -- Randomly choose an entity from the entityTable
    local randomIndex = math.random(1, #entityTable)
    local entityClass = entityTable[randomIndex]

    local spawnPosition = position + Vector(0, 0, 10)

    -- Spawn the chosen entity
    local droppedEntity = ents.Create(entityClass)
    droppedEntity:SetPos(spawnPosition)
    droppedEntity:Spawn()
end

-- Function to give XP to the player
local function GiveXP(ply, xp)
    -- -- Get the current value of "wOS.ProficiencyExperience" or use 0 if it doesn't exist
    -- local currentExperience = ply:GetNW2Int("wOS.ProficiencyExperience", 0)

    -- -- Increase xp by 250
    -- ply:SetNW2Int("wOS.ProficiencyExperience", currentExperience + 250)
end

-- Function to give money to the player
local function GiveMoney(ply, money)
    if ply.addMoney and isfunction(ply.addMoney) then
        -- Gives the player 500 money
        ply:addMoney(money)
    end
end

-- Function called when the crate is used
function ENT:Use(activator, caller)
    -- Determine the contents of the crate
    local contents = DetermineCrateContents()

    local money = self.money
    local xp = self.xp

    if contents == "xp" then
        -- Give XP to the player
        GiveXP(activator, xp)
        self:Remove()
    elseif contents == "money" then
        -- Give money to the player
        GiveMoney(activator, money)
        self:Remove()
    elseif contents == "entity" then
        -- Spawn the dropped entity
        SpawnDroppedEntity(self:GetPos())
        self:Remove()
    end
end
