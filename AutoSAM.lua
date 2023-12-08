_addon.author = 'Syz'
_addon.name = 'AutoSAM'
_addon.commands = { 'sam', 'asam', 'autosam' }
_addon.version = "1.0.1"

-------------
-- Imports --
-------------
require('tables')
require('strings')
require('logger')

local config = require('config')

local defaults = {
  enabled = false,
  abilityTPThreshold = 500,
  hasso = false,
  meditate = {
    auto = false,
    useBelowTP = 2000,
  },
  warrior = {
    berserk = false,
    warcry = false,
    aggressor = false,
  },
  sekkanoki = false,
  sengikori = false,
  hagakure = false,
  konzen = false,
}

local nextActionTime = 0
local actionDelay = 1.2

local settings = config.load(defaults)

-------------
-- Helpers --
-------------
local Ability = {
  Hasso = 138,
  Meditate = 134,
  Sekkanoki = 140,
  Sengikori = 141,
  Hagakure = 54,
  KonzenIttai = 132,

  Berserk = 1,
  Warcry = 2,
  Aggressor = 4,
}

local Buff = {
  Hasso = 353,
  Sekkanoki = 408,
  Sengikori = 440,
  Hagakure = 483,
  Berserk = 56,
  Aggressor = 58,
  Warcry = 68,

  -- Beneficial
  Invisible = 69,
  Costume = 127,

  -- Impairments
  KO = 0,
  Sleep = 2,
  Petrify = 7,
  Stun = 10,
  Charm = 14,
  Amnesia = 16,
  SleepAlt = 19,
  Terror = 28,

  -- Other Restrictions
  SJRestriction = 157,
  Impairment = 261,   -- salvage or nyzul conditions -- no ability
  Obliviscence = 260, -- salvage or nyzul condition -- SJ Restriction
}

local AbilityImpaired = T {
  Buff.Costume,
  Buff.KO,
  Buff.Sleep,
  Buff.Petrify,
  Buff.Stun,
  Buff.Charm,
  Buff.Amnesia,
  Buff.SleepAlt,
  Buff.Terror,
  Buff.Costume,
  Buff.Impairment,
}

local SubJobImpaired = T {
  Buff.SJRestriction,
  Buff.Obliviscence,
}

local function debug(str)
  if (settings.debug) then
    log(string.color('Debug: ', string.char(0x1F, 0x79)), str)
  end
end

local function useJA(abi)
  actionDelay = 1.2
  windower.chat.input(abi)
end

local function ON()
  return string.color('ON', string.char(0x1F, 0x38))
end

local function OFF()
  return string.color('OFF', string.char(0x1F, 0x39))
end

local function colorUserInput(str)
  return string.color(str, string.char(0x1F, 0x1E))
end

---------------
-- Listeners --
---------------
local function onLoad()
  actionDelay = 0
end

local function prerender()
  if (not settings.enabled) then
    return
  end

  local currTime = os.clock()
  if (nextActionTime + actionDelay <= currTime) then
    nextActionTime = currTime
    actionDelay = 1.2

    local player = windower.ffxi.get_player()
    if (player.main_job ~= 'SAM' or player.status > 1) then
      return
    end

    local recasts = windower.ffxi.get_ability_recasts()

    local buffs = player.buffs

    local isAbilityImpaired = #table.filter(buffs, function(buff)
      return AbilityImpaired:contains(buff)
    end)
    debug('Ability Impaired: ' .. isAbilityImpaired)


    local isSubJobImpaired = #table.filter(buffs, function(buff)
      return SubJobImpaired:contains(buff)
    end)
    debug('Is Subjob Impaired: ' .. isSubJobImpaired)

    if (isAbilityImpaired > 0 or isSubJobImpaired > 0 or buffs[Buff.Invisible]) then
      debug('Impaired, waiting...')
      return
    end

    if (settings.hasso and recasts[Ability.Hasso] <= 0 and not table.contains(buffs, Buff.Hasso)) then
      debug('Using Hasso')
      useJA('/ja "Hasso" <me>')
      return
    end

    if (settings.meditate and recasts[Ability.Meditate] <= 0 and player.vitals.tp < 3000) then
      debug('Using Meditate')
      useJA('/ja "Meditate" <me>')
      return
    end

    if (settings.sekkanoki and recasts[Ability.Sekkanoki] <= 0 and player.vitals.tp >= 2000 and player.status == 1) then
      debug('Using Sekkanoki')
      useJA('/ja "Sekkanoki" <me>')
      return
    end

    if (settings.sengikori and recasts[Ability.Sengikori] <= 0 and player.vitals.tp >= settings.abilityTPThreshold and player.status == 1) then
      debug('Using Sengikori')
      useJA('/ja "Sengikori" <me>')
      return
    end

    if (settings.hagakure and recasts[Ability.Hagakure] <= 0 and player.vitals.tp >= settings.abilityTPThreshold and player.status == 1) then
      debug('Using Hagakure')
      useJA('/ja "Hagakure" <me>')
      return
    end

    if (settings.konzen and recasts[Ability.KonzenIttai] <= 0 and player.vitals.tp >= settings.abilityTPThreshold and player.status == 1) then
      debug('Using Konzen-Ittai')
      useJA('/ja "Konzen-Ittai" <t>')
      return
    end

    if (player.sub_job == 'WAR') then
      if (settings.warrior.berserk and recasts[Ability.Berserk] <= 0 and player.status == 1) then
        debug('Using Berserk')
        useJA('/ja "Berserk" <me>')
      end

      if (settings.warrior.aggressor and recasts[Ability.Aggressor] <= 0 and player.status == 1) then
        debug('Using Aggressor')
        useJA('/ja "Aggressor" <me>')
      end

      if (settings.warrior.warcry and recasts[Ability.Warcry] <= 0 and player.status == 1) then
        debug('Using Warcry')
        useJA('/ja "Warcry" <me>')
      end
    end
  end
end

local function showCommands()
  log('//autosam | //sam | //asam')
  log('  debug                      Enable debug logs')
  log('  start | enable             Enable automatic usage of abilities')
  log('  stop | disable | end       Enable automatic usage of abilities')
  log('  hasso                      Enable usage of Hasso')
  log('  meditate                   Enable usage of Meditate')
  log('  meditate below <number>    Uses meditate below TP')
  log('  minAbilityTP <number>      Uses all SAM abilities excluding Meditate when above set threshold')
  log('  sekkanoki                  Enable usage of Sekkanoki')
  log('  sengikori                  Enable usage of Sengikori')
  log('  hagakure                   Enable usage of Hagakure')
  log('  konzen                     Enable usage of Konzen-Ittai')
  log('  berserk                    Enable usage of Berserk')
  log('  warcry                     Enable usage of Warcry')
  log('  aggressor                  Enable usage of Aggressor')
  log('  save                       Save current settings for current character')
  log('  save all                   Save current settings for all characters')
  log('  reload                     Reload the addon')
  log('  unload                     Reload the addon')
  log('Most commands can be stacked. Example:')
  log('//sam start hasso meditate')
end

local function onAddonCommand(...)
  local args = T { ... }
  local formattedArgs = args:map(string.lower)

  if (#formattedArgs == 0) then
    settings.enabled = not settings.enabled
    log('AutoSAM ' .. (settings.enabled and ON() or OFF()))
    return
  end

  if (formattedArgs:contains('help')) then
    showCommands()
    return
  end

  if (formattedArgs:contains('unload')) then
    windower.send_command('lua unload AutoSAM')
  end

  if (formattedArgs:contains('reload')) then
    windower.send_command('lua reload AutoSAM')
    return
  end

  if (formattedArgs:contains('minabilitytp')) then
    local minAbilityTPIndex = formattedArgs:find('minabilitytp')
    settings.abilityTPThreshold = tonumber(formattedArgs[minAbilityTPIndex + 1])
    log('Samurai Abilities will now use when above ' .. colorUserInput(formattedArgs[minAbilityTPIndex + 1]) .. ' TP')
    return
  end

  if (formattedArgs:contains('debug')) then
    settings.debug = not settings.debug
    log('Debug mode: ' .. (settings.debug and ON() or OFF()))
  end

  if (formattedArgs:contains('start') or formattedArgs:contains('enable')) then
    settings.enabled = true
    log('AutoSAM ' .. ON())
  elseif (formattedArgs:contains('stop') or formattedArgs:contains('end') or formattedArgs:contains('disable')) then
    settings.enabled = false
    log('AutoSAM ' .. OFF())
  end

  if (formattedArgs:contains('hasso')) then
    settings.hasso = not settings.hasso
    log('Hasso: ' .. (settings.hasso and ON() or OFF()))
  end

  if (formattedArgs:contains('meditate')) then
    local meditateIndex = formattedArgs:find('meditate')
    if (formattedArgs[meditateIndex + 1] and formattedArgs[meditateIndex + 1] == 'below' and formattedArgs[meditateIndex + 2]) then
      settings.meditate.useBelowTP = tonumber(formattedArgs[meditateIndex + 2])
      log('Using Meditate below ' .. colorUserInput(formattedArgs[meditateIndex + 2]) .. ' TP')
    else
      settings.meditate.auto = not settings.meditate.auto
      log('Meditate: ' .. (settings.meditate.auto and ON() or OFF()))
    end
  end

  if (formattedArgs:contains('sekkanoki')) then
    settings.sekkanoki = not settings.sekkanoki
    log('Sekkanoki: ' .. (settings.sekkanoki and ON() or OFF()))
  end

  if (formattedArgs:contains('sengikori')) then
    settings.sengikori = not settings.sengikori
    log('Sengikori: ' .. (settings.sengikori and ON() or OFF()))
  end

  if (formattedArgs:contains('hagakure')) then
    settings.hagakure = not settings.hagakure
    log('Hagakure: ' .. (settings.hagakure and ON() or OFF()))
  end

  if (formattedArgs:contains('konzen')) then
    settings.konzen = not settings.konzen
    log('Konzen-Ittai: ' .. (settings.konzen and ON() or OFF()))
  end

  if (formattedArgs:contains('berserk')) then
    settings.warrior.berserk = not settings.warrior.berserk
    log('Berserk: ' .. (settings.warrior.berserk and ON() or OFF()))
  end

  if (formattedArgs:contains('warcry')) then
    settings.warrior.warcry = not settings.warrior.warcry
    log('Warcry: ' .. (settings.warrior.warcry and ON() or OFF()))
  end

  if (formattedArgs:contains('aggressor')) then
    settings.warrior.aggressor = not settings.warrior.aggressor
    log('Aggressor: ' .. (settings.warrior.aggressor and ON() or OFF()))
  end

  if (formattedArgs:contains('save')) then
    local saveIndex = formattedArgs:find('save')
    if (formattedArgs[saveIndex + 1] and formattedArgs[saveIndex + 1] == 'all') then
      log('Saving settings for all characters')
      config.save(settings, 'all')
    else
      log('Saving settings for current character')
      config.save(settings)
    end
  end
end

windower.register_event('load', 'login', onLoad)
windower.register_event('prerender', prerender)

windower.register_event('addon command', onAddonCommand)
