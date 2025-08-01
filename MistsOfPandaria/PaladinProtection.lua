-- PaladinProtection.lua
-- Updated May 28, 2025 - Modern Structure
-- Mists of Pandaria module for Paladin: Protection spec

-- MoP: Use UnitClass instead of UnitClassBase
local _, playerClass = UnitClass('player')
if playerClass ~= 'PALADIN' then return end

local addon, ns = ...
local Hekili = _G[ "Hekili" ]
local class = Hekili.Class
local state = Hekili.State
local spec = Hekili:NewSpecialization( 66 )

local function getReferences()
    -- Legacy function for compatibility
    return class, state
end

local strformat = string.format
local FindUnitBuffByID, FindUnitDebuffByID = ns.FindUnitBuffByID, ns.FindUnitDebuffByID
local function UA_GetPlayerAuraBySpellID(spellID)
    for i = 1, 40 do
        local name, _, count, _, duration, expires, caster, _, _, id = UnitBuff("player", i)
        if not name then break end
        if id == spellID then return name, _, count, _, duration, expires, caster end
    end
    for i = 1, 40 do
        local name, _, count, _, duration, expires, caster, _, _, id = UnitDebuff("player", i)
        if not name then break end
        if id == spellID then return name, _, count, _, duration, expires, caster end
    end
    return nil
end

spec:RegisterResource( 9, { -- Holy Power with Protection-specific mechanics
    -- Grand Crusader reset proc (Protection signature)
    grand_crusader = {
        last = function ()
            return state.query_time
        end,
        interval = 1,
        value = function()
            -- Grand Crusader doesn't generate Holy Power directly, but resets Avenger's Shield
            return 0 -- No direct HP generation, but tracks proc for ability resets
        end,
    },
    
    -- Bastion of Glory stack building (Protection mastery interaction)
    bastion_of_glory = {
        last = function ()
            return state.query_time
        end,
        interval = 1,
        value = function()
            -- Tracks Bastion of Glory stacks for defensive benefit calculation
            local stacks = state.buff.bastion_of_glory.stack or 0
            return stacks * 0.1 -- Each stack provides defensive value
        end,
    },
    
    -- Shield of Vengeance proc (Protection talent)
    shield_of_vengeance = {
        last = function ()
            return state.query_time
        end,
        interval = 1,
        value = function()
            if state.talent.shield_of_vengeance.enabled and (state.last_ability and state.last_ability == "word_of_glory") then
                return 0 -- Shield of Vengeance procs from Holy Power consumption
            end
            return 0
        end,
    },
    
    -- Eternal Flame synergy (if talented)
    eternal_flame_protection = {
        last = function ()
            return state.query_time
        end,
        interval = 1,
        value = function()
            if state.talent.eternal_flame.enabled and (state.last_ability and state.last_ability == "word_of_glory") then
                return 0 -- Eternal Flame effectiveness scales with Holy Power spent
            end
            return 0
        end,
    },
}, {
    -- Base Holy Power mechanics for Protection
    max_holy_power = function ()
        return 3 -- Maximum 3 Holy Power in MoP
    end,
    
    -- Protection's enhanced Holy Power generation
    protection_generation = function ()
        return 1.0 -- Standard HP generation rate
    end,
    
    -- Divine Purpose proc effects for Protection
    divine_purpose_efficiency = function ()
        return state.talent.divine_purpose.enabled and (state.buff.divine_purpose.up and 1.5 or 1.0) or 1.0
    end,
} )

-- Tier sets
spec:RegisterGear( "tier14", 85345, 85346, 85347, 85348, 85349 ) -- T14 Protection Paladin Set
spec:RegisterGear( "tier15", 95268, 95270, 95266, 95269, 95267 ) -- T15 Protection Paladin Set

-- Talents (MoP 6-tier talent system)
spec:RegisterTalents( {
    -- Tier 1 (Level 15) - Movement
    speed_of_light            = { 1, 1, 85499  }, -- +70% movement speed for 8 sec
    long_arm_of_the_law       = { 1, 2, 87172  }, -- Judgments increase movement speed by 45% for 3 sec
    pursuit_of_justice        = { 1, 3, 26023  }, -- +15% movement speed per Holy Power charge

    -- Tier 2 (Level 30) - Control
    fist_of_justice           = { 2, 1, 105593 }, -- Reduces Hammer of Justice cooldown by 50%
    repentance                = { 2, 2, 20066  }, -- Puts the enemy target in a state of meditation, incapacitating them for up to 1 min.
    blinding_light            = { 2, 3, 115750 }, -- Emits dazzling light in all directions, blinding enemies within 10 yards for 6 sec.

    -- Tier 3 (Level 45) - Healing/Defense
    selfless_healer           = { 3, 1, 85804  }, -- Your Holy power spending abilities reduce the cast time and mana cost of your next Flash of Light.
    eternal_flame             = { 3, 2, 114163 }, -- Consumes all Holy Power to place a protective Holy flame on a friendly target, which heals over 30 sec.
    sacred_shield             = { 3, 3, 20925  }, -- Places a Sacred Shield on a friendly target, absorbing damage every 6 sec for 30 sec.

    -- Tier 4 (Level 60) - Utility/CC
    hand_of_purity            = { 4, 1, 114039 }, -- Protects a party or raid member, reducing harmful periodic effects by 70% for 6 sec.
    unbreakable_spirit        = { 4, 2, 114154 }, -- Reduces the cooldown of your Divine Shield, Divine Protection, and Lay on Hands by 50%.
    clemency                  = { 4, 3, 105622 }, -- Increases the number of charges on your Hand spells by 1.

    -- Tier 5 (Level 75) - Holy Power
    divine_purpose            = { 5, 1, 86172  }, -- Your Holy Power abilities have a 15% chance to make your next Holy Power ability free and more effective.
    holy_avenger              = { 5, 2, 105809 }, -- Your Holy power generating abilities generate 3 charges of Holy Power for 18 sec.
    sanctified_wrath          = { 5, 3, 53376  }, -- Increases the duration of Avenging Wrath by 5 sec. While Avenging Wrath is active, your abilities generate 1 additional Holy Power.

    -- Tier 6 (Level 90) - Tanking
    holy_prism                = { 6, 1, 114165 }, -- Fires a beam of light that hits a target for Holy damage or healing.
    lights_hammer             = { 6, 2, 114158 }, -- Hurls a Light-infused hammer to the ground, dealing Holy damage to enemies and healing allies.
    execution_sentence        = { 6, 3, 114157 }  -- A hammer slowly falls from the sky, dealing Holy damage to an enemy or healing an ally.
} )

-- Protection-specific Glyphs
spec:RegisterGlyphs( {
    -- Major Glyphs
    [56414] = "alabaster_shield",   -- When your Avenger's Shield hits a target, the shield has a 100% chance to instantly bounce to 1 additional nearby target.
    [56420] = "focused_shield",     -- Your Avenger's Shield hits 1 fewer target, but deals 30% increased damage.
    [57937] = "divine_protection",  -- Divine Protection reduces magical damage taken by an additional 20%, but no longer reduces physical damage taken.
    [56416] = "word_of_glory",      -- Increases the effectiveness of your Word of Glory by 20% when used on yourself.
    [54935] = "battle_healer",      -- Your successful melee attacks heal a nearby injured friendly target within 30 yards for 10% of the damage done.
    [63219] = "final_wrath",        -- Avenging Wrath increases the damage of Hammer of Wrath by 50%.
    
    -- Minor Glyphs
    [57954] = "dazing_shield",      -- Your Avenger's Shield now also dazes targets for 10 sec.
    [57947] = "blessed_life",       -- You have a 50% chance to generate 1 charge of Holy Power when you take damage.
    [43367] = "righteous_retreat",  -- When you use Divine Shield, you also become immune to disarm effects, but the cooldown of Divine Shield is increased by 50%.
} )

-- Protection Paladin specific auras
spec:RegisterAuras( {
    -- Grand Crusader: Chance for free Avenger's Shield after Crusader Strike or Hammer of the Righteous
    grand_crusader = {
        id = 85416,
        duration = 6,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 85416 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Shield of the Righteous: Active mitigation ability
    shield_of_the_righteous = {
        id = 132403,
        duration = 3,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 132403 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Bastion of Glory: Increases healing of Word of Glory on self
    bastion_of_glory = {
        id = 114637,
        duration = 20,
        max_stack = 5,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 114637 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Divine Plea: Restore mana over time, but reduce healing done
    divine_plea = {
        id = 54428,
        duration = 15,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 54428 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Sacred Shield: Absorbs damage periodically
    sacred_shield = {
        id = 65148,
        duration = 30,
        tick_time = 6,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 65148 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Holy Avenger: Holy Power abilities more effective
    holy_avenger = {
        id = 105809,
        duration = 18,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 105809 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Avenging Wrath: Increased damage and healing
    avenging_wrath = {
        id = 31884,
        duration = function() 
            return state.talent.sanctified_wrath.enabled and 25 or 20
        end,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 31884 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Divine Protection: Reduces damage taken
    divine_protection = {
        id = 498,
        duration = 10,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 498 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Divine Shield: Complete immunity
    divine_shield = {
        id = 642,
        duration = 8,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 642 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Forbearance: Cannot receive certain immunities again
    forbearance = {
        id = 25771,
        duration = 60,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitDebuffByID( "player", 25771 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Speed of Light: Increased movement speed
    speed_of_light = {
        id = 85499,
        duration = 8,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 85499 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Long Arm of the Law: Increased movement speed after Judgment
    long_arm_of_the_law = {
        id = 114158,
        duration = 3,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 114158 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Pursuit of Justice: Increased movement speed from Holy Power
    pursuit_of_justice = {
        id = 26023,
        duration = 3600,
        max_stack = 3,
        generate = function( t )
            t.count = state.holy_power.current
            t.expires = 3600
            t.applied = 0
            t.caster = "player"
        end
    },
    
    -- Divine Purpose: Free and enhanced Holy Power ability
    divine_purpose = {
        id = 86172,
        duration = 8,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 86172 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Eternal Flame: HoT from talent
    eternal_flame = {
        id = 114163,
        duration = function() return 30 + (3 * state.holy_power.current) end,
        tick_time = 3,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 114163, "PLAYER" )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Guardian of Ancient Kings: Major defensive cooldown
    guardian_of_ancient_kings = {
        id = 86659,
        duration = 12,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 86659 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Ardent Defender: Emergency defensive cooldown
    ardent_defender = {
        id = 31850,
        duration = 10,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 31850 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Hand of Freedom: Immunity to movement impairing effects
    hand_of_freedom = {
        id = 1044,
        duration = 6,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 1044, "PLAYER" )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Hand of Protection: Immunity to physical damage
    hand_of_protection = {
        id = 1022,
        duration = 10,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 1022, "PLAYER" )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Hand of Sacrifice: Redirects damage to Paladin
    hand_of_sacrifice = {
        id = 6940,
        duration = 12,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "target", 6940, "PLAYER" )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
} )

-- Protection Paladin abilities
spec:RegisterAbilities( {
    -- Core Protection abilities
    shield_of_the_righteous = {
        id = 53600,
        cast = 0,
        cooldown = 1.5,
        gcd = "spell",
        
        spend = function() 
            if state.buff.divine_purpose.up then return 0 end
            return 3 
        end,
        spendType = "holy_power",
        
        startsCombat = true,
        texture = 236265,
        
        handler = function()
            -- Shield of the Righteous mechanic
            if state.buff.divine_purpose.up then
                removeBuff("divine_purpose")
            end
            
            applyBuff("shield_of_the_righteous")
            
            -- Divine Purpose talent proc chance
            if state.talent.divine_purpose.enabled and not state.buff.divine_purpose.up and math.random() < 0.15 then
                applyBuff("divine_purpose")
            end
        end
    },
    
    avengers_shield = {
        id = 31935,
        cast = 0,
        cooldown = 15,
        gcd = "spell",
        
        spend = 0.10,
        spendType = "mana",
        
        startsCombat = true,
        texture = 135874,
        
        usable = function()
            if state.buff.grand_crusader.up then return true end
            return not (cooldown.avengers_shield.remains > 0)
        end,
        
        handler = function()
            if state.buff.grand_crusader.up then
                removeBuff("grand_crusader")
            end
        end
    },
    
    guardian_of_ancient_kings = {
        id = 86659,
        cast = 0,
        cooldown = 180,
        gcd = "off",
        
        toggle = "defensives",
        
        startsCombat = false,
        texture = 409594,
        
        handler = function()
            applyBuff("guardian_of_ancient_kings")
        end
    },
    
    ardent_defender = {
        id = 31850,
        cast = 0,
        cooldown = 180,
        gcd = "off",
        
        toggle = "defensives",
        
        startsCombat = false,
        texture = 135870,
        
        handler = function()
            applyBuff("ardent_defender")
        end
    },
    
    word_of_glory = {
        id = 85673,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        
        spend = function() 
            if state.buff.divine_purpose.up then return 0 end
            return 3 
        end,
        spendType = "holy_power",
        
        startsCombat = false,
        texture = 646176,
        
        handler = function()
            -- Word of Glory mechanic - consumes all Holy Power and Bastion of Glory
            if state.buff.divine_purpose.up then
                removeBuff("divine_purpose")
            else
                -- Modify healing based on Holy Power consumed
                -- Word of Glory's base healing amount is multiplied per Holy Power
                
                -- Bastion of Glory effect - increases healing of Word of Glory on self
                if state.buff.bastion_of_glory.up then
                    -- Increased healing based on Bastion of Glory stacks (30% per stack)
                    removeBuff("bastion_of_glory")
                end
            end
            
            -- Selfless Healer reductions for next Flash of Light if talented
            if state.talent.selfless_healer.enabled then
                applyBuff("selfless_healer", nil, 3)
            end
            
            -- Eternal Flame talent application instead of direct heal
            if state.talent.eternal_flame.enabled then
                applyBuff("eternal_flame")
            end
            
            -- Divine Purpose talent proc chance
            if state.talent.divine_purpose.enabled and not state.buff.divine_purpose.up and math.random() < 0.15 then
                applyBuff("divine_purpose")
            end
        end
    },
    
    hammer_of_the_righteous = {
        id = 53595,
        cast = 0,
        cooldown = 4.5,
        gcd = "spell",
        
        spend = 0.06,
        spendType = "mana",
        
        startsCombat = true,
        texture = 236157,
        
        range = 8,
        
        handler = function()
            gain(1, "holy_power")
            
            -- Grand Crusader proc chance (12%)
            if math.random() < 0.12 then
                applyBuff("grand_crusader")
                setCooldown("avengers_shield", 0)
            end
            
            -- Bastion of Glory proc - 1 stack per target hit
            applyBuff("bastion_of_glory", nil, 1)
        end
    },
    
    holy_prism = {
        id = 114165,
        cast = 0,
        cooldown = 20,
        gcd = "spell",
        
        spend = 0.35,
        spendType = "mana",
        
        talent = "holy_prism",
        
        startsCombat = function() return not state.option.holy_prism_heal end,
        texture = 613407,
        
        handler = function()
            -- Holy Prism mechanic
            -- If cast on enemy, damages target and heals 5 nearby friendlies
            -- If cast on friendly, heals target and damages 5 nearby enemies
        end
    },
    
    lights_hammer = {
        id = 114158,
        cast = 0,
        cooldown = 60,
        gcd = "spell",
        
        spend = 0.38,
        spendType = "mana",
        
        talent = "lights_hammer",
        
        startsCombat = true,
        texture = 613952,
        
        handler = function()
            -- Light's Hammer mechanic - ground target AoE that heals allies and damages enemies
        end
    },
    
    execution_sentence = {
        id = 114157,
        cast = 0,
        cooldown = 60,
        gcd = "spell",
        
        spend = 0.38,
        spendType = "mana",
        
        talent = "execution_sentence",
        
        startsCombat = function() return not state.option.execution_sentence_heal end,
        texture = 613954,
        
        handler = function()
            -- Execution Sentence mechanic
            -- If cast on enemy, damages after 10 seconds
            -- If cast on friendly, heals after 10 seconds
        end
    },
    
    divine_plea = {
        id = 54428,
        cast = 0,
        cooldown = 120,
        gcd = "spell",
        
        toggle = "cooldowns",
        
        startsCombat = false,
        texture = 237537,
        
        handler = function()
            applyBuff("divine_plea")
        end
    },
    
    avenging_wrath = {
        id = 31884,
        cast = 0,
        cooldown = 180,
        gcd = "off",
        
        toggle = "cooldowns",
        
        startsCombat = false,
        texture = 135875,
        
        handler = function()
            applyBuff("avenging_wrath")
        end
    },
    
    holy_avenger = {
        id = 105809,
        cast = 0,
        cooldown = 180,
        gcd = "off",
        
        toggle = "cooldowns",
        
        talent = "holy_avenger",
        
        startsCombat = false,
        texture = 571555,
        
        handler = function()
            applyBuff("holy_avenger")
        end
    },
    
    divine_shield = {
        id = 642,
        cast = 0,
        cooldown = function()
            return state.talent.unbreakable_spirit.enabled and 150 or 300
        end,
        gcd = "spell",
        
        toggle = "defensives",
        
        startsCombat = false,
        texture = 524354,
        
        handler = function()
            applyBuff("divine_shield")
            applyDebuff("player", "forbearance")
        end
    },
    
    divine_protection = {
        id = 498,
        cast = 0,
        cooldown = function()
            return state.talent.unbreakable_spirit.enabled and 30 or 60
        end,
        gcd = "off",
        
        toggle = "defensives",
        
        startsCombat = false,
        texture = 524353,
        
        handler = function()
            applyBuff("divine_protection")
        end
    },
    
    lay_on_hands = {
        id = 633,
        cast = 0,
        cooldown = function() 
            return state.talent.unbreakable_spirit.enabled and 360 or 600
        end,
        gcd = "spell",
        
        toggle = "defensives",
        
        startsCombat = false,
        texture = 135928,
        
        handler = function()
            -- Heals target for Paladin's maximum health
            -- Applies Forbearance
            applyDebuff("target", "forbearance")
        end
    },
    
    hand_of_freedom = {
        id = 1044,
        cast = 0,
        cooldown = function() 
            if state.talent.clemency.enabled then
                return { charges = 2, execRate = 25 }
            end
            return 25
        end,
        gcd = "spell",
        
        startsCombat = false,
        texture = 135968,
        
        handler = function()
            applyBuff("hand_of_freedom")
        end
    },
    
    hand_of_protection = {
        id = 1022,
        cast = 0,
        cooldown = function() 
            if state.talent.clemency.enabled then
                return { charges = 2, execRate = 300 }
            end
            return 300
        end,
        gcd = "spell",
        
        toggle = "defensives",
        
        startsCombat = false,
        texture = 135964,
        
        handler = function()
            applyBuff("hand_of_protection")
            applyDebuff("player", "forbearance")
        end
    },
    
    hand_of_sacrifice = {
        id = 6940,
        cast = 0,
        cooldown = function() 
            if state.talent.clemency.enabled then
                return { charges = 2, execRate = 120 }
            end
            return 120
        end,
        gcd = "off",
        
        toggle = "defensives",
        
        startsCombat = false,
        texture = 135966,
        
        handler = function()
            applyBuff("hand_of_sacrifice", "target")
        end
    },
    
    hand_of_purity = {
        id = 114039,
        cast = 0,
        cooldown = 30,
        gcd = "off",
        
        talent = "hand_of_purity",
        
        startsCombat = false,
        texture = 458726,
        
        handler = function()
            -- Applies Hand of Purity effect
        end
    },
    
    -- Shared Paladin abilities
    crusader_strike = {
        id = 35395,
        cast = 0,
        cooldown = 4.5,
        gcd = "spell",
        
        spend = 0.06,
        spendType = "mana",
        
        startsCombat = true,
        texture = 135891,
        
        handler = function()
            gain(1, "holy_power")
            
            -- Grand Crusader proc chance (12%)
            if math.random() < 0.12 then
                applyBuff("grand_crusader")
                setCooldown("avengers_shield", 0)
            end
            
            -- Bastion of Glory proc
            applyBuff("bastion_of_glory", nil, 1)
        end
    },
    
    judgment = {
        id = 20271,
        cast = 0,
        cooldown = 6,
        gcd = "spell",
        
        spend = 0.05,
        spendType = "mana",
        
        startsCombat = true,
        texture = 135959,
        
        handler = function()
            gain(1, "holy_power")
            
            -- Long Arm of the Law movement speed
            if state.talent.long_arm_of_the_law.enabled then
                applyBuff("long_arm_of_the_law")
            end
        end
    },
    
    cleanse = {
        id = 4987,
        cast = 0,
        cooldown = 8,
        gcd = "spell",
        
        spend = 0.14,
        spendType = "mana",
        
        startsCombat = false,
        texture = 135949,
        
        handler = function()
            -- Removes 1 Poison effect, 1 Disease effect, and 1 Magic effect from a friendly target
        end
    },
    
    hammer_of_justice = {
        id = 853,
        cast = 0,
        cooldown = function() 
            if state.talent.fist_of_justice.enabled then
                return 30
            end
            return 60
        end,
        gcd = "spell",
        
        startsCombat = true,
        texture = 135963,
        
        handler = function()
            -- Stuns target for 6 seconds
        end
    },
    
    hammer_of_wrath = {
        id = 24275,
        cast = 0,
        cooldown = 6,
        gcd = "spell",
        
        spend = 0.12,
        spendType = "mana",
        
        usable = function()
            return target.health_pct < 20
        end,
        
        startsCombat = true,
        texture = 138168,
        
        handler = function()
            gain(1, "holy_power")
        end
    },
    
    consecration = {
        id = 26573,
        cast = 0,
        cooldown = 9,
        gcd = "spell",
        
        spend = 0.24,
        spendType = "mana",
        
        startsCombat = true,
        texture = 135926,
        
        handler = function()
            -- Creates consecrated ground that deals Holy damage over time
        end
    },
    
    repentance = {
        id = 20066,
        cast = 1.5,
        cooldown = 15,
        gcd = "spell",
        
        talent = "repentance",
        
        spend = 0.09,
        spendType = "mana",
        
        startsCombat = false,
        texture = 135942,
        
        handler = function()
            -- Incapacitates target for up to 1 minute
        end
    },
    
    blinding_light = {
        id = 115750,
        cast = 0,
        cooldown = 120,
        gcd = "spell",
        
        talent = "blinding_light",
        
        spend = 0.18,
        spendType = "mana",
        
        startsCombat = true,
        texture = 571553,
        
        handler = function()
            -- Disorients all nearby enemies
        end
    },
    
    speed_of_light = {
        id = 85499,
        cast = 0,
        cooldown = 45,
        gcd = "off",
        
        talent = "speed_of_light",
        
        startsCombat = false,
        texture = 538056,
        
        handler = function()
            applyBuff("speed_of_light")
        end
    },
    
    sacred_shield = {
        id = 20925,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        
        talent = "sacred_shield",
        
        spend = 0.23,
        spendType = "mana",
        
        startsCombat = false,
        texture = 612316,
        
        handler = function()
            applyBuff("sacred_shield")
        end
    },
} )

-- States and calculations for Protection specific mechanics
local function trackBastion()
    if buff.bastion_of_glory.stack > 0 then
        -- Each stack of Bastion of Glory increases Word of Glory healing by 10% when used on self
        local modifier = 1 + (0.1 * buff.bastion_of_glory.stack)
        -- Apply the healing modifier
    end
end

-- state.RegisterFunctions( {
--     ['trackBastion'] = function()
--         return trackBastion()
--     end
-- } )

-- local function checkGrandCrusader()
--     -- 12% chance to proc Grand Crusader on Crusader Strike or Hammer of the Righteous
--     return buff.grand_crusader.up
-- end

-- state.RegisterExpressions( {
--     ['grandCrusaderActive'] = function()
--         return checkGrandCrusader()
--     end
-- } )

-- Range
spec:RegisterRanges( "judgment", "avengers_shield", "hammer_of_justice", "rebuke", "crusader_strike", "hammer_of_the_righteous" )

-- Options
spec:RegisterOptions( {
    enabled = true,
    
    aoe = 3,
    
    nameplates = true,
    nameplateRange = 8,
    
    damage = true,
    damageExpiration = 8,
    
    potion = "jade_serpent_potion",
    
    package = "Protection",
    
    holy_prism_heal = false,
    execution_sentence_heal = false,
} )

-- Register default pack for MoP Protection Paladin
spec:RegisterPack( "Protection", 20250515, [[Hekili:T1PBVTTn04FlXjHj0OfnrQ97Lvv9n0KxkzPORkyzyV1ikA2JC7fSOhtkfLjjRKKGtkLQfifs4YC7O3MF11Fw859fNZXPb72TQWN3yiOtto8jREEP(D)CaaR7oXR]hYdVp)NhS4(SZdhFpzmYBPn2qGdjcw5Jt8jc((52Lbb6W0P)MM]] )
