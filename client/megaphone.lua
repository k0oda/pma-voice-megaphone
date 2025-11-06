-- Megaphone Submix Module
-- Monitors proximity mode changes and applies audio submix effects

local megaphoneEffectId = nil
local playersWithMegaphone = {} -- Track which players currently have megaphone active
local disableOwnSubmix = false -- Disable submix for own voice only
local disabledPlayers = {} -- Tracks which server ids opted out (so we don't apply submix to them)

-- Load saved preference from KVP (persists between restarts)
CreateThread(function()
    local saved = GetResourceKvpString('megaphone_disable_own_submix')
    if saved == 'true' then
        disableOwnSubmix = true
        LocalPlayer.state:set('disableOwnMegaphoneSubmix', true, true)
        print('^3[Megaphone Submix] Your own submix effects are DISABLED (using custom audio software)^7')
    end
end)

-- Command to toggle own submix on/off for this player
RegisterCommand('togglemegaphonesubmix', function()
    disableOwnSubmix = not disableOwnSubmix
    
    -- Save preference
    SetResourceKvp('megaphone_disable_own_submix', tostring(disableOwnSubmix))
    
    -- Set state bag so others know not to apply submix to this player
    LocalPlayer.state:set('disableOwnMegaphoneSubmix', disableOwnSubmix, true)
    
    if disableOwnSubmix then
        print('^3[Megaphone Submix] YOUR submix effects DISABLED. Others will not hear effects from your voice.^7')
    else
        print('^2[Megaphone Submix] YOUR submix effects ENABLED. Others will hear megaphone effects from you.^7')
    end
end, false)

RegisterCommand('megaphonesubmix', function(source, args)
    if args[1] == 'off' or args[1] == 'disable' then
        disableOwnSubmix = true
        SetResourceKvp('megaphone_disable_own_submix', 'true')
        LocalPlayer.state:set('disableOwnMegaphoneSubmix', true, true)
        print('^3[Megaphone Submix] YOUR submix effects DISABLED. Others will not hear effects from your voice.^7')
    elseif args[1] == 'on' or args[1] == 'enable' then
        disableOwnSubmix = false
        SetResourceKvp('megaphone_disable_own_submix', 'false')
        LocalPlayer.state:set('disableOwnMegaphoneSubmix', false, true)
        print('^2[Megaphone Submix] YOUR submix effects ENABLED. Others will hear megaphone effects from you.^7')
    else
        print('^6[Megaphone Submix] Usage: /megaphonesubmix [on/off]^7')
        print('^6[Megaphone Submix] Your submix status: ' .. (disableOwnSubmix and 'DISABLED' or 'ENABLED') .. '^7')
        print('^6[Megaphone Submix] This only affects YOUR voice. You will still hear others with effects.^7')
    end
end, false)

-- Initialize megaphone audio submix
if GetConvar('voice_useNativeAudio', 'false') == 'true' then
    CreateThread(function()
        Wait(1000) -- Wait for pma-voice to initialize
        
        -- Create megaphone audio submix with effects
        megaphoneEffectId = CreateAudioSubmix('Megaphone')
        
        SetAudioSubmixEffectRadioFx(megaphoneEffectId, 1)
        SetAudioSubmixEffectParamInt(megaphoneEffectId, 1, GetHashKey('default'), 1)
        SetAudioSubmixEffectParamFloat(megaphoneEffectId, 1, GetHashKey('freq_low'), MegaphoneConfig.submixParams.freq_low)
        SetAudioSubmixEffectParamFloat(megaphoneEffectId, 1, GetHashKey('freq_hi'), MegaphoneConfig.submixParams.freq_hi)
        SetAudioSubmixEffectParamFloat(megaphoneEffectId, 1, GetHashKey('fudge'), MegaphoneConfig.submixParams.fudge)
        SetAudioSubmixEffectParamFloat(megaphoneEffectId, 1, GetHashKey('rm_mod_freq'), MegaphoneConfig.submixParams.rm_mod_freq)
        SetAudioSubmixEffectParamFloat(megaphoneEffectId, 1, GetHashKey('rm_mix'), MegaphoneConfig.submixParams.rm_mix)
        AddAudioSubmixOutput(megaphoneEffectId, 1)
        
        print('^2[Megaphone Submix] Audio submix initialized^7')
    end)
end

-- Monitor pma-voice proximity mode state bag
-- When a player switches to configured proximity mode, apply submix
AddStateBagChangeHandler(
    "proximity",
    nil,
    function(bagName, key, value, _reserved, replicated)
        if not megaphoneEffectId or GetConvar('voice_useNativeAudio', 'false') ~= 'true' then
            return
        end
        
        local player = bagName:gsub("player:", "")
        if not player then return end
        
        player = tonumber(player)
        
        -- If this player opted out of submix, skip applying
        if disabledPlayers[player] then
            return
        end
        
        -- Check if player switched to megaphone voice mode (by index)
        local currentModeIndex = value and value.index
        local isMegaphoneMode = currentModeIndex == MegaphoneConfig.voiceModeIndex
        local hadMegaphone = playersWithMegaphone[player]
        
        if isMegaphoneMode and not hadMegaphone then
            -- Player switched TO megaphone - apply submix
            playersWithMegaphone[player] = true
            MumbleSetSubmixForServerId(player, megaphoneEffectId)
            print(string.format('^2[Megaphone Submix] Applied to player %d^7', player))
            
        elseif not isMegaphoneMode and hadMegaphone then
            -- Player switched FROM megaphone - remove submix
            playersWithMegaphone[player] = nil
            MumbleSetSubmixForServerId(player, -1)
            print(string.format('^3[Megaphone Submix] Removed from player %d^7', player))
        end
    end
)

-- Track players who disabled their own megaphone submix via state bag
AddStateBagChangeHandler(
    "disableOwnMegaphoneSubmix",
    nil,
    function(bagName, key, value, _reserved, replicated)
        local player = bagName:gsub("player:", "")
        if not player then return end
        player = tonumber(player)

        if value then
            disabledPlayers[player] = true
            -- Immediately remove submix if this player had it applied
            if playersWithMegaphone[player] then
                MumbleSetSubmixForServerId(player, -1)
                playersWithMegaphone[player] = nil
            end
        else
            disabledPlayers[player] = nil
        end
    end
)

print('^2[Megaphone Submix] Client module loaded. Monitoring voice mode index: ' .. MegaphoneConfig.voiceModeIndex .. '^7')
