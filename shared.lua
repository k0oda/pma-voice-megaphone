-- Shared configuration for megaphone module
MegaphoneConfig = {
    -- Voice mode index for megaphone (4 = 4th element in voiceModes array)
    -- Check your pma-voice shared config to confirm the index
    voiceModeIndex = 4, -- 1=Whisper, 2=Normal, 3=Shouting, 4=Megaphone
    
    -- Audio submix parameters
    submixParams = {
        freq_low = 300.0,    -- Lower frequency for deeper megaphone sound
        freq_hi = 8000.0,    -- Higher frequency cutoff
        fudge = 0.5,         -- Fudge factor
        rm_mod_freq = 1.0,   -- Ring modulation frequency
        rm_mix = 0.0         -- DISABLED: This causes volume fluctuation
    }
}
