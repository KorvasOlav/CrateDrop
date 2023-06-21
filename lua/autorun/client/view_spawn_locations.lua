if (CLIENT) then

    local npcDataTable = {}

    local shouldDisplayNPCs = false

    net.Receive("Cratedrop_ViewNPCSpawnLocations", function()

        local data = file.Read("npc_data.txt", "DATA")
        if data then
            npcDataTable = util.JSONToTable(data)
        end
        
        if shouldDisplayNPCs then
            shouldDisplayNPCs = false
        else
            shouldDisplayNPCs = true
        end
        local function DisplayNPCSpawnLocations()
            if shouldDisplayNPCs then
                for _, npcData in ipairs(npcDataTable) do
                    local uniqueID = npcData.uniqueID
                    local xPos = npcData.xPos
                    local yPos = npcData.yPos
                    local zPos = npcData.zPos + 25
                    local textPosition = Vector(xPos, yPos, zPos)
        
                    -- Calculate the screen position of the text
                    local screenPos = textPosition:ToScreen()
        
                    cam.Start3D2D(textPosition, Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 1)
                    draw.DrawText(uniqueID, "DermaLarge", 0, 0, Color(255,0,0), TEXT_ALIGN_CENTER)
                    cam.End3D2D()
                end
            end
        end
    
        hook.Add("PostDrawOpaqueRenderables", "DisplayNPCData", DisplayNPCSpawnLocations)
    end)

    
end