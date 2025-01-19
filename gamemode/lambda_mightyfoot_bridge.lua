if SERVER then
    AddCSLuaFile()
end

-- Function to check if Mighty Foot is installed
local function IsMightyFootInstalled()
    return ConVarExists("mf_kickspeed") and ConVarExists("mf_kickdelay")
end

-- Delay the check to ensure Mighty Foot has time to initialize
timer.Simple(1, function()
    if IsMightyFootInstalled() then
        local GAMEMODE = GAMEMODE or GM

        -- helper function to check if a player is kicking
        local function IsPlayerKicking(ply)
            return ply.MFKickTime and ply.MFDrawTime and 
                   ply.MFKickTime + ply.MFDrawTime > CurTime() and 
                   ply.MFKickTime + 0.1 < CurTime()
        end

        -- override calcmainactivity
        local originalCalcMainActivity = GAMEMODE.CalcMainActivity
        function GAMEMODE:CalcMainActivity(ply, velocity)
            if IsPlayerKicking(ply) then
                -- we don't change the main activity for mightyfoot!!!
                return ply.CalcIdeal, ply.CalcSeqOverride
            end
            return originalCalcMainActivity(self, ply, velocity)
        end

        -- override updateanimation
        local originalUpdateAnimation = GAMEMODE.UpdateAnimation
        function GAMEMODE:UpdateAnimation(ply, velocity, maxseqgroundspeed)
            if IsPlayerKicking(ply) then
                -- let mightyfoot handle its own animation update
                return
            end
            return originalUpdateAnimation(self, ply, velocity, maxseqgroundspeed)
        end

        -- override doanimationevent
        local originalDoAnimationEvent = GAMEMODE.DoAnimationEvent
        function GAMEMODE:DoAnimationEvent(ply, event, data)
            if IsPlayerKicking(ply) then
                -- let mightyfoot handle its own animation events
                return
            end
            return originalDoAnimationEvent(self, ply, event, data)
        end

        -- hook into the mightyfoot kick function
        hook.Add("MFEngaged", "LambdaMightyFootBridge", function(ply)
            -- network the kick animation to other players
            net.Start("MFKickAnimation")
            net.WriteEntity(ply)
            net.Broadcast()
        end)

        if SERVER then
            util.AddNetworkString("MFKickAnimation")
        else
            net.Receive("MFKickAnimation", function()
                local ply = net.ReadEntity()
                if IsValid(ply) and ply ~= LocalPlayer() then
                    ply.MFKickTime = CurTime()
                    ply.MFDrawTime = 0.75 / (GetConVar("mf_kickspeed"):GetFloat() or 1)
                    -- trigger mightyfoot's animation setup for other players
                    if ply.MFCreate then
                        ply.MFCreate(ply, ply:GetPos(), ply:GetAngles(), ply:GetFOV())
                    end
                end
            end)
        end

        -- make mightyfootengaged function to call our hook
        if MightyFootEngaged then
            local originalMightyFootEngaged = MightyFootEngaged
            function MightyFootEngaged(ply)
                local result = originalMightyFootEngaged(ply)
                hook.Run("MFEngaged", ply)
                return result
            end
        else
            -- If MightyFootEngaged doesn't exist yet, wait for it
            timer.Create("WaitForMightyFootEngaged", 0.1, 100, function()
                if MightyFootEngaged then
                    local originalMightyFootEngaged = MightyFootEngaged
                    function MightyFootEngaged(ply)
                        local result = originalMightyFootEngaged(ply)
                        hook.Run("MFEngaged", ply)
                        return result
                    end
                    timer.Remove("WaitForMightyFootEngaged")
                    print("[Lambda Compatibility] MightyFootEngaged function hooked successfully")
                end
            end)
        end

        print("[Lambda Compatibility] Lambda Mighty Foot Bridge activated")
    else
        print("[Lambda Compatibility] Mighty Foot not detected, bridge not activated")
    end
end)