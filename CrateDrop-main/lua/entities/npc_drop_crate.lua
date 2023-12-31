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

ENT.Model = "models/starwars/syphadias/props/sw_tor/bioware_ea/items/harvesting/slicing/slicing_safeboxes_panel.mdl"


function ENT:Initialize()
    if SERVER then
        self:SetModel(self.Model)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_OBB)
        self:SetModelScale(1.5)
        self.xp = 1
        self.money = 1
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

-- Function to spawn the entity dropped from the crate
local function SpawnDroppedEntity(ply, itemNames)
    -- Randomly choose an entity from the itemNames
    local randomIndex = math.random(1, #itemNames)
    local item = itemNames[randomIndex]

    if wOS and isfunction(wOS:HandleItemPickup()) then
        -- UNCOMMENT WHEN ITEM LIST IS SET PROPERLY
        -- wOS:HandleItemPickup( ply, item )
    else 
        print("wOS does not exist, or HandleItemPickup() is not a function. You would have gotten " .. item)
    end
end

-- Function to give XP to the player
local function GiveXP(ply, xp)
    if wOS then
        -- Get the current value of "wOS.ProficiencyExperience" or use 0 if it doesn't exist
        local currentExperience = ply:GetNW2Int("wOS.SkillExperience", 0)

        -- Increase xp
        ply:SetNW2Int("wOS.SkillExperience", currentExperience + xp)
    else
        print("wOS does not exist. You would have gotten " .. xp .. " xp")
    end
end

-- Function to give XP to the player based on how much damage the player dealt
-- local function GiveXP(ply, xp, npcDamagers)
--     -- Get the current value of "wOS.ProficiencyExperience" or use 0 if it doesn't exist
--     local currentExperience = ply:GetNW2Int("wOS.SkillExperience", 0)

--     totalDamage = 0
--     for _, damage in pairs(npcDamagers) do
--         totalDamage = totalDamage + damage
--     end
--     local percentDamage = npcDamagers[ply] / totalDamage
--     percentDamage = percentDamage

--     xp = xp * percentDamage
--     xp = math.Round(xp, 0)

--     -- Increase xp
--     ply:SetNW2Int("wOS.SkillExperience", currentExperience + xp)
-- end

-- Function to give money to the player
local function GiveMoney(ply, money)
    if ply.addMoney and isfunction(ply.addMoney) then
        ply:addMoney(money)
    else
        print("addMoney() is not a function. You would have gotten " .. money .. " money")
    end
end


-- Function to give money based on how much damage the player dealt
-- local function GiveMoney(ply, money, npcDamagers)
--     totalDamage = 0
--     for _, damage in pairs(npcDamagers) do
--         totalDamage = totalDamage + damage
--     end
--     local percentDamage = npcDamagers[ply] / totalDamage
--     percentDamage = percentDamage

--     money = money * percentDamage
--     money = math.Round(money, 0)

--     if ply.addMoney and isfunction(ply.addMoney) then
--         ply:addMoney(money)
--     end
-- end

-- Function called when the crate is used
function ENT:Use(activator, caller)
    -- Determine the contents of the crate
    local contents = DetermineCrateContents()

    local money = self.money
    local xp = self.xp
    local npcDamagers = self.npcDamagers
    if npcDamagers[activator] and npcDamagers[activator] > 0 then
        if contents == "entity" then
            -- Spawn the dropped entity
            SpawnDroppedEntity(activator, self.ItemDrops)


            -- Below check is where you would check if the player is max level. If they are max level,
            -- we do not want them to make it to the next if check, as they cannot gain xp.
            -- Example of what to add, should be edited to whatever your values are:
            -- or activator.lvl == activator.hard
        elseif contents == "money" then
            -- Give money to the player, flat ammount to everyone
            GiveMoney(activator, money)


            -- -- Give money to the player, based on how much damage dealt
            -- GiveMoney(activator, money, npcDamagers)
        elseif contents == "xp" then
            -- Give XP to the player, flat ammount to everyone
            GiveXP(activator, xp)

            
            -- -- Give xp to the player, based on how much damage dealt
            -- GiveXP(activator, xp, npcDamagers)
        end
        npcDamagers[activator] = nil
    end
end