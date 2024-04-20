/******************************************************
*             L4D2: Satellite Cannon v2.0
*                    Author: ztar, faketuna
*             Web: http://ztar.blog7.fc2.com/
*******************************************************/

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0"

#define SURVIVOR        2
#define INFECTED        3

/* Sound */
#define SOUND_NEGATIVE    "npc/soldier1/misc18.wav"
#define SOUND_SHOOT01    "npc/soldier1/misc17.wav"
#define SOUND_SHOOT02    "npc/soldier1/misc19.wav"
#define SOUND_SHOOT03    "npc/soldier1/misc20.wav"
#define SOUND_SHOOT04    "npc/soldier1/misc21.wav"
#define SOUND_SHOOT05    "npc/soldier1/misc22.wav"
#define SOUND_SHOOT06    "npc/soldier1/misc23.wav"
#define SOUND_SHOOT07    "npc/soldier1/misc08.wav"
#define SOUND_SHOOT08    "npc/soldier1/misc02.wav"
#define SOUND_SHOOT09    "npc/soldier1/misc07.wav"
#define SOUND_TRACING    "items/suitchargeok1.wav"
#define SOUND_IMPACT01    "animation/van_inside_hit_wall.wav"
#define SOUND_IMPACT02    "ambient/explosions/explode_3.wav"
#define SOUND_IMPACT03    "ambient/atmosphere/firewerks_burst_01.wav"
#define SOUND_FREEZE    "physics/glass/glass_pottery_break3.wav"
#define SOUND_DEFROST    "physics/glass/glass_sheet_break1.wav"

/* Model */
#define ENTITY_GASCAN    "models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE    "models/props_junk/propanecanister001a.mdl"

/* Sprite */
#define SPRITE_BEAM        "materials/sprites/laserbeam.vmt"
#define SPRITE_HALO        "materials/sprites/halo01.vmt"
#define SPRITE_GLOW        "materials/sprites/glow01.vmt"

/* Particle */
#define PARTICLE_FIRE01    "molotov_explosion"
#define PARTICLE_FIRE02    "molotov_explosion_child_burst"
#define PARTICLE_FIREBLUE01    "fire_pipe_blue"
#define PARTICLE_FIREBLUE02    "flame_blue"


#define DUMMY_CVAR_NAME "sm_satellite_dummy_cvar_for_prevent_error_output"
#define DUMMY_CVAR_DESCRIPTION "This convar is dummy"


// Satellite ammo type.
#define SATELLITE_AMMO_TYPE_COUNT 5
enum {
    AMMO_TYPE_IDLE = 0,
    AMMO_TYPE_ALL,
    AMMO_TYPE_JUDGEMENT,
    AMMO_TYPE_BLIZZARD,
    AMMO_TYPE_INFERNO,
}

// Reset timings of usage limit 
enum {
    RT_ROUND_START = (1 << 0),
    RT_MAP_START = (1 << 1),
    RT_ON_DEATH = (1 << 2),
}

// Laser Effect type
enum {
    LASER_EFFECT_TYPE_NORMAL = 0,
    LASER_EFFECT_TYPE_VERTICAL,
}

// Explosion Type
enum {
    EXPLOSION_TYPE_MOLOTOV = 0,
    EXPLOSION_TYPE_EXPLODE,
}


enum struct SatelliteSettingsCvars {
    ConVar enabled;
    ConVar damage;
    ConVar radius;
    ConVar maxUses;
    ConVar cooldown;
    ConVar usageResetTiming;
    ConVar burstDelay;
    ConVar pushForce;
    ConVar ammoAbillity1;
    ConVar ammoAbillity2;
    ConVar hasFriendlyFire;

    void addChangeHook(ConVarChanged callback) {
        this.enabled.AddChangeHook(callback);
        this.damage.AddChangeHook(callback);
        this.radius.AddChangeHook(callback);
        this.maxUses.AddChangeHook(callback);
        this.cooldown.AddChangeHook(callback);
        this.usageResetTiming.AddChangeHook(callback);
        this.burstDelay.AddChangeHook(callback);
        this.pushForce.AddChangeHook(callback);
        this.ammoAbillity1.AddChangeHook(callback);
        this.ammoAbillity2.AddChangeHook(callback);
        this.hasFriendlyFire.AddChangeHook(callback);
    }
}


// Cached value are 10x faster than retrieve value from ConVar.
// See: https://gist.github.com/faketuna/95080c8892c4a72c0f958f279572cfa4
enum struct SatelliteSettingsValues {
    bool enabled;
    float damage;
    float radius;
    int maxUses;
    float cooldown;
    int usageResetTiming;
    float burstDelay;
    float pushForce;
    float ammoAbillity1;
    float ammoAbillity2;
    bool hasFriendlyFire;

    void setValues(
        ConVar enabled,
        ConVar damage,
        ConVar radius,
        ConVar maxUses,
        ConVar cooldown,
        ConVar usageRestTiming,
        ConVar burstDelay,
        ConVar pushForce,
        ConVar ammoAbillity1,
        ConVar ammoAbillity2,
        ConVar hasFriendlyFire
    ) {
        this.enabled = enabled.BoolValue;
        this.damage = damage.FloatValue;
        this.radius = radius.FloatValue;
        this.maxUses = maxUses.IntValue;
        this.cooldown = cooldown.FloatValue;
        this.usageResetTiming = usageRestTiming.IntValue;
        this.burstDelay = burstDelay.FloatValue;
        this.pushForce = pushForce.FloatValue;
        this.ammoAbillity1 = ammoAbillity1.FloatValue;
        this.ammoAbillity2 = ammoAbillity2.FloatValue;
        this.hasFriendlyFire = hasFriendlyFire.BoolValue;
    }
}

enum struct SatelliteSettings {
    SatelliteSettingsCvars cvars;
    SatelliteSettingsValues values;

    void updateCache() {
        this.values.setValues(
            this.cvars.enabled,
            this.cvars.damage,
            this.cvars.radius,
            this.cvars.maxUses,
            this.cvars.cooldown,
            this.cvars.usageResetTiming,
            this.cvars.burstDelay,
            this.cvars.pushForce,
            this.cvars.ammoAbillity1,
            this.cvars.ammoAbillity2,
            this.cvars.hasFriendlyFire
        );
    }
}

// I think there is a better way, But I don't have math knowledge to solve this.
int getResetTiming(int resetTiming) {
    int toReturn;
    switch(resetTiming) {
        case 1: {
            toReturn |= RT_ROUND_START;
        }
        case 2: {
            toReturn |= RT_MAP_START;
        }
        case 4: {
            toReturn |= RT_ON_DEATH;
        }

        case 3: {
            toReturn |= RT_ROUND_START;
            toReturn |= RT_MAP_START;
        }
        case 5: {
            toReturn |= RT_ROUND_START;
            toReturn |= RT_ON_DEATH;
        }
        case 6: {
            toReturn |= RT_MAP_START;
            toReturn |= RT_ON_DEATH;
        }
        case 7: {
            toReturn |= RT_ROUND_START;
            toReturn |= RT_MAP_START;
            toReturn |= RT_ON_DEATH;
        }

        default: {
            toReturn = 0;
        }
    }
    
    return toReturn;
}

enum struct PluginSettingsCVars {
    ConVar enabled;
    ConVar burstDelay;
    ConVar globalBurstDelay;
    ConVar pushForce;
    ConVar globalPushForce;
    ConVar friendlyFire;
    ConVar globalFriendlyFire;
    ConVar laserVisualHeight;
    ConVar adminOnly;
    ConVar adminFlags;
    ConVar usageResetTiming;
    ConVar globalUsageResetTiming;

    void addChangeHook(ConVarChanged callback) {
        this.enabled.AddChangeHook(callback);
        this.burstDelay.AddChangeHook(callback);
        this.globalBurstDelay.AddChangeHook(callback);
        this.pushForce.AddChangeHook(callback);
        this.globalPushForce.AddChangeHook(callback);
        this.friendlyFire.AddChangeHook(callback);
        this.globalFriendlyFire.AddChangeHook(callback);
        this.laserVisualHeight.AddChangeHook(callback);
        this.adminOnly.AddChangeHook(callback);
        this.adminFlags.AddChangeHook(callback);
        this.usageResetTiming.AddChangeHook(callback);
        this.globalUsageResetTiming.AddChangeHook(callback);
    }
}

enum struct PluginSettingsValues {
    bool enabled;
    float burstDelay;
    bool globalBurstDelay;
    float pushForce;
    bool globalPushForce;
    bool friendlyFire;
    bool globalFriendlyFire;
    int laserVisualHeight;
    int adminOnly;
    char adminFlags;
    int usageResetTiming;
    bool globalUsageResetTiming;

    void setValues(
        ConVar enabled,
        ConVar burstDelay,
        ConVar globalBurstDelay,
        ConVar pushForce,
        ConVar globalPushForce,
        ConVar friendlyFire,
        ConVar globalFriendlyFire,
        ConVar laserVisualHeight,
        ConVar adminOnly,
        ConVar adminFlags,
        ConVar usageResetTiming,
        ConVar globalUsageResetTiming
    ) {
        this.enabled = enabled.BoolValue;
        this.burstDelay = burstDelay.FloatValue;
        this.globalBurstDelay = globalBurstDelay.BoolValue;
        this.pushForce = pushForce.FloatValue;
        this.globalPushForce = globalPushForce.BoolValue;
        this.friendlyFire = friendlyFire.BoolValue;
        this.globalFriendlyFire = globalFriendlyFire.BoolValue;
        this.laserVisualHeight = laserVisualHeight.IntValue;
        this.adminOnly = adminOnly.IntValue;
        GetConVarString(adminFlags, this.adminFlags, sizeof(this.adminFlags));
        this.usageResetTiming = getResetTiming(usageResetTiming.IntValue);
        this.globalUsageResetTiming = globalUsageResetTiming.BoolValue;
    }
}

enum struct PluginSettings {
    PluginSettingsCVars cvars;
    PluginSettingsValues values;

    void updateCache() {
        this.values.setValues(
            this.cvars.enabled,
            this.cvars.burstDelay,
            this.cvars.globalBurstDelay,
            this.cvars.pushForce,
            this.cvars.globalPushForce,
            this.cvars.friendlyFire,
            this.cvars.globalFriendlyFire,
            this.cvars.laserVisualHeight,
            this.cvars.adminOnly,
            this.cvars.adminFlags,
            this.cvars.usageResetTiming,
            this.cvars.globalUsageResetTiming
        );
    }
}


enum struct SatelliteAmmo {
    int usesLeft;
    bool isInfinityAmmo;

    bool isAmmoEmpty() {
        return this.usesLeft < 1 ? true : false;
    }
}

enum struct SatellitePlayer {
    int currentAmmoType;
    int lastAmmoType;
    bool isInCooldown;
    bool isMoveBlocked;
    bool isActionBlocked;
    bool selfInjury;
    float tracePosition[3];

    SatelliteAmmo ammoJudgement;
    SatelliteAmmo ammoBlizzard;
    SatelliteAmmo ammoInferno;
}




SatellitePlayer g_spSatellitePlayers[MAXPLAYERS+1];
SatelliteSettings g_ssSatelliteSettings[SATELLITE_AMMO_TYPE_COUNT];
PluginSettings g_psPluginSettings;

int g_hiClip1;
int g_hActiveWeapon;
int g_BeamSprite;
int g_HaloSprite;
int g_GlowSprite;
int tEntity;

int raycount[MAXPLAYERS+1];


public Plugin myinfo = 
{
    name = "[L4D2] Satellite Cannon",
    author = "ztar",
    description = "Vertical laser launches by shooting magnum.",
    version = PLUGIN_VERSION,
    url = "http://ztar.blog7.fc2.com/"
}

public void OnPluginStart() {

    // INITIALIZE PROPERY
    PluginSettingsCVars settingsCVars;
    PluginSettingsValues settingsValues;
    g_psPluginSettings.cvars = settingsCVars;
    g_psPluginSettings.values = settingsValues;

    g_psPluginSettings.cvars.enabled =              CreateConVar("sm_satellite_enable",                 "1",        "0:OFF 1:ON", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_psPluginSettings.cvars.laserVisualHeight =    CreateConVar("sm_satellite_laser_visual_height",    "650",      "Height of launching point visual laser.", FCVAR_NOTIFY);
    g_psPluginSettings.cvars.burstDelay =           CreateConVar("sm_satellite_burst_delay",            "1.0",      "Launching delay of Satellite cannon. This value is only be used when sm_satellite_burst_delay_global is 1", FCVAR_NOTIFY);
    g_psPluginSettings.cvars.globalBurstDelay =     CreateConVar("sm_satellite_burst_delay_global",     "1.0",      "Toggle global burst delay. When set to 0 it uses individual burst delay based on satellite ammo settings.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_psPluginSettings.cvars.pushForce =            CreateConVar("sm_satellite_push_force",             "600.0",    "Push force of Satellite cannon. This value is only be used when sm_satellite_push_force_global is 1", FCVAR_NOTIFY);
    g_psPluginSettings.cvars.globalPushForce =      CreateConVar("sm_satellite_push_force_global",      "1.0",      "Toggle global push force. When set to 0 it uses individual push force based on satellite ammo settings.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_psPluginSettings.cvars.friendlyFire =         CreateConVar("sm_satellite_friendly_fire",      "1.0",      "Toggle friendly fire. This value is only be used when sm_satellite_friendly_fire_global is 1", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_psPluginSettings.cvars.globalFriendlyFire =   CreateConVar("sm_satellite_friendly_fire_global",      "1.0",      "Toggle global friendly fire. When set to 0 it uses individual push force based on satellite ammo settings.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    // TODO Implement admin only feature
    //g_psPluginSettings.cvars.adminFlags =           CreateConVar("sm_satellite_admin_flags",            "z",        "SourceMod admin flag", FCVAR_NOTIFY);
    //g_psPluginSettings.cvars.adminOnly =            CreateConVar("sm_satellite_admin_only",             "1.0",      "Toggle sattelite cannon admin only.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
    g_psPluginSettings.cvars.adminFlags =           CreateConVar(DUMMY_CVAR_NAME,              "0",    DUMMY_CVAR_DESCRIPTION, FCVAR_DONTRECORD);
    g_psPluginSettings.cvars.adminOnly =            CreateConVar(DUMMY_CVAR_NAME,              "0",    DUMMY_CVAR_DESCRIPTION, FCVAR_DONTRECORD);
    g_psPluginSettings.cvars.usageResetTiming =     CreateConVar("sm_satellite_usage_reset_timing",             "1",      "When ammo will reset. | 1: Round start, 2: Map start, 4: Death | If you want to use multiple timings you can set the combined number. For example Round start and death is 5.", FCVAR_NOTIFY);
    g_psPluginSettings.cvars.globalUsageResetTiming =   CreateConVar("sm_satellite_usage_reset_timing_global",      "1",      "Toggle global usage reset timing. When set to 0 it uses individual usage reset timing based on satellite ammo settings.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_psPluginSettings.cvars.addChangeHook(OnPluginSettingsUpdated);
    g_psPluginSettings.updateCache();

    SatelliteSettingsCvars blizzardCvars;
    SatelliteSettingsValues blizzardValues;
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].cvars = blizzardCvars;
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].values = blizzardValues;

    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].cvars.enabled =           CreateConVar("sm_satellite_ammo_blizzard_enable",            "1",        "0:OFF 1:ON", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].cvars.damage =            CreateConVar(DUMMY_CVAR_NAME,              "0",    DUMMY_CVAR_DESCRIPTION, FCVAR_DONTRECORD);
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].cvars.radius =            CreateConVar("sm_satellite_ammo_blizzard_radius",            "200.0",    "Radius of this cannon.", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].cvars.maxUses =           CreateConVar("sm_satellite_ammo_blizzard_limit",             "5",        "Limit of uses. reset timing is depends on usage_reset_timing cvar", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].cvars.cooldown =          CreateConVar("sm_satellite_ammo_blizzard_cooldown",          "0.0",      "Cooldown per shot. 0 means you can use immediately when your guns reloaded.", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].cvars.usageResetTiming =  CreateConVar("sm_satellite_ammo_blizzard_usage_reset_timing","1",        "When ammo will reset. | 1: Round start, 2: Map start, 4: Death | If you want to use multiple timings you can set the combined number. For example Round start and death is 5.", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].cvars.burstDelay =        CreateConVar("sm_satellite_ammo_blizzard_burst_delay",       "1.0",      "Launching delay of this cannon. this value will only used when sm_satellite_burst_delay_global is 0", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].cvars.pushForce =         CreateConVar(DUMMY_CVAR_NAME,              "0",    DUMMY_CVAR_DESCRIPTION, FCVAR_DONTRECORD);
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].cvars.ammoAbillity1 =     CreateConVar("sm_satellite_ammo_blizzard_time",              "5.0",    "Freeze time.", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].cvars.ammoAbillity2 =     CreateConVar(DUMMY_CVAR_NAME,              "0",    DUMMY_CVAR_DESCRIPTION, FCVAR_DONTRECORD);
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].cvars.hasFriendlyFire =   CreateConVar("sm_satellite_ammo_blizzard_friendly_fire",            "1",        "0:OFF 1:ON. This value is only be used when sm_satellite_friendly_fire_global is 0", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].cvars.addChangeHook(OnPluginSettingsUpdated);
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].updateCache();

    SatelliteSettingsCvars infernoCvars;
    SatelliteSettingsValues infernoValues;
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].cvars = infernoCvars;
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].values = infernoValues;

    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].cvars.enabled =           CreateConVar("sm_satellite_ammo_inferno_enable",            "1",        "0:OFF 1:ON", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].cvars.damage =            CreateConVar("sm_satellite_ammo_inferno_damage",            "420.0",    "Damage of this cannon.", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].cvars.radius =            CreateConVar("sm_satellite_ammo_inferno_radius",            "200.0",    "Radius of this cannon.", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].cvars.maxUses =           CreateConVar("sm_satellite_ammo_inferno_limit",             "5",        "Limit of uses. reset timing is depends on usage_reset_timing cvar", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].cvars.cooldown =          CreateConVar("sm_satellite_ammo_inferno_cooldown",          "0.0",      "Cooldown per shot. 0 means you can use immediately when your guns reloaded.", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].cvars.usageResetTiming =  CreateConVar("sm_satellite_ammo_inferno_usage_reset_timing","1",        "When ammo will reset. | 1: Round start, 2: Map start, 4: Death | If you want to use multiple timings you can set the combined number. For example Round start and death is 5.", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].cvars.burstDelay =        CreateConVar("sm_satellite_ammo_inferno_burst_delay",       "1.0",      "Launching delay of this cannon. this value will only used when sm_satellite_burst_delay_global is 0", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].cvars.pushForce =         CreateConVar("sm_satellite_ammo_inferno_push_force",        "600.0",    "Push force of this cannon. this value will only used when sm_satellite_push_force_global is 0");
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].cvars.ammoAbillity1 =     CreateConVar(DUMMY_CVAR_NAME,              "0",    DUMMY_CVAR_DESCRIPTION, FCVAR_DONTRECORD);
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].cvars.ammoAbillity2 =     CreateConVar(DUMMY_CVAR_NAME,              "0",    DUMMY_CVAR_DESCRIPTION, FCVAR_DONTRECORD);
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].cvars.hasFriendlyFire =   CreateConVar("sm_satellite_ammo_inferno_friendly_fire",            "1",        "0:OFF 1:ON. This value is only be used when sm_satellite_friendly_fire_global is 0", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].cvars.addChangeHook(OnPluginSettingsUpdated);
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].updateCache();


    SatelliteSettingsCvars judgementCvars;
    SatelliteSettingsValues judgementValues;
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].cvars = judgementCvars;
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].values = judgementValues;

    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].cvars.enabled =           CreateConVar("sm_satellite_ammo_judgement_enable",            "1",        "0:OFF 1:ON", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].cvars.damage =            CreateConVar("sm_satellite_ammo_judgement_damage",            "300.0",    "Damage of this cannon.", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].cvars.radius =            CreateConVar("sm_satellite_ammo_judgement_radius",            "200.0",    "Radius of this cannon.", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].cvars.maxUses =           CreateConVar("sm_satellite_ammo_judgement_limit",             "5",        "Limit of uses. reset timing is depends on usage_reset_timing cvar", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].cvars.cooldown =          CreateConVar("sm_satellite_ammo_judgement_cooldown",          "0.0",      "Cooldown per shot. 0 means you can use immediately when your guns reloaded.", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].cvars.usageResetTiming =  CreateConVar("sm_satellite_ammo_judgement_usage_reset_timing","1",        "When ammo will reset. | 1: Round start, 2: Map start, 4: Death | If you want to use multiple timings you can set the combined number. For example Round start and death is 5.", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].cvars.burstDelay =        CreateConVar("sm_satellite_ammo_judgement_burst_delay",       "1.0",      "Launching delay of this cannon. this value will only used when sm_satellite_burst_delay_global is 0", FCVAR_NOTIFY);
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].cvars.pushForce =         CreateConVar("sm_satellite_ammo_judgement_push_force",        "600.0",    "Push force of this cannon. this value will only used when sm_satellite_push_force_global is 0");
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].cvars.ammoAbillity1 =     CreateConVar(DUMMY_CVAR_NAME,              "0",    DUMMY_CVAR_DESCRIPTION, FCVAR_DONTRECORD);
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].cvars.ammoAbillity2 =     CreateConVar(DUMMY_CVAR_NAME,              "0",    DUMMY_CVAR_DESCRIPTION, FCVAR_DONTRECORD);
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].cvars.hasFriendlyFire =   CreateConVar("sm_satellite_ammo_judgement_friendly_fire",            "1",        "0:OFF 1:ON. This value is only be used when sm_satellite_friendly_fire_global is 0", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].cvars.addChangeHook(OnPluginSettingsUpdated);
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].updateCache();

    LoadTranslations("l4d2_satellite.phrases");

    HookEvent("weapon_fire", onWeaponFired);
    HookEvent("item_pickup", onItemPickUp);
    HookEvent("round_start", onRoundStart);
    HookEvent("player_death", onPlayerDeath);
    g_hActiveWeapon = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
    g_hiClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");

    initPlayersAmmo();
    for(int i = 1; i <= MaxClients; i++) {
        if(!IsClientConnected(i) || !IsClientInGame(i))
            continue;
        
        SDKHook(i, SDKHook_OnTakeDamage, onTakeDamage);
    }

    AutoExecConfig(true,"l4d2_sm_satellite");
}

public void OnPluginEnd() {
    for(int i = 1; i <= MaxClients; i++) {
        if(!IsClientConnected(i) || !IsClientInGame(i))
            continue;
        
        SDKUnhook(i, SDKHook_OnTakeDamage, onTakeDamage);
    }
}

public void OnPluginSettingsUpdated(ConVar convar, const char[] oldValue, const char[] newValue) {
    g_psPluginSettings.updateCache();
    g_ssSatelliteSettings[AMMO_TYPE_BLIZZARD].updateCache();
    g_ssSatelliteSettings[AMMO_TYPE_INFERNO].updateCache();
    g_ssSatelliteSettings[AMMO_TYPE_JUDGEMENT].updateCache();
}

public void OnClientPutInServer(int client) {
    SDKHook(client, SDKHook_OnTakeDamage, onTakeDamage);
}

public void OnClientDisconnect(int client) {
    SDKUnhook(client, SDKHook_OnTakeDamage, onTakeDamage);
}


public Action onTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if(damage < 0.1)
        return Plugin_Continue;

    char ammoType[1];
    GetEntPropString(attacker, Prop_Data, "m_iName", ammoType, sizeof(ammoType));

    if ((damagetype & DMG_BLAST || damagetype & DMG_BLAST_SURFACE || damagetype & DMG_AIRBOAT || damagetype & DMG_PLASMA))
    {
        if(satelliteHasFriendlyFire(StringToInt(ammoType)))
            return Plugin_Continue;

        damage = 0.0;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void OnMapStart() {
    resetAllPlayersAmmo();

    PrecacheModel(ENTITY_PROPANE, true);
    PrecacheModel(ENTITY_GASCAN, true);

    g_BeamSprite = PrecacheModel(SPRITE_BEAM);
    g_HaloSprite = PrecacheModel(SPRITE_HALO);
    g_GlowSprite = PrecacheModel(SPRITE_GLOW);
    PrecacheParticle(PARTICLE_FIRE01);
    PrecacheParticle(PARTICLE_FIRE02);
    PrecacheParticle(PARTICLE_FIREBLUE01);
    PrecacheParticle(PARTICLE_FIREBLUE02);

    PrecacheSound(SOUND_NEGATIVE, true);
    PrecacheSound(SOUND_SHOOT01, true);
    PrecacheSound(SOUND_SHOOT02, true);
    PrecacheSound(SOUND_SHOOT03, true);
    PrecacheSound(SOUND_SHOOT04, true);
    PrecacheSound(SOUND_SHOOT05, true);
    PrecacheSound(SOUND_SHOOT06, true);
    PrecacheSound(SOUND_SHOOT07, true);
    PrecacheSound(SOUND_SHOOT08, true);
    PrecacheSound(SOUND_SHOOT09, true);
    PrecacheSound(SOUND_TRACING, true);
    PrecacheSound(SOUND_IMPACT01, true);
    PrecacheSound(SOUND_IMPACT02, true);
    PrecacheSound(SOUND_IMPACT03, true);
    PrecacheSound(SOUND_FREEZE, true);
    PrecacheSound(SOUND_DEFROST, true);

    for(int i = 0; i < SATELLITE_AMMO_TYPE_COUNT; i++) {
        if(i == AMMO_TYPE_ALL || i == AMMO_TYPE_IDLE)
            continue;

        if(getSatelliteUsageResetTiming(i) & RT_MAP_START) {
            for(int client = 1; client <= MaxClients; client++) {
                resetPlayerAmmo(client, i);
            }
        }
    }
}

void initPlayersAmmo() {
    for(int i = 1; i <= MaxClients; i++) {
        SatelliteAmmo blizzard;
        SatelliteAmmo inferno;
        SatelliteAmmo judgement;
        g_spSatellitePlayers[i].ammoBlizzard = blizzard;
        g_spSatellitePlayers[i].ammoInferno = inferno;
        g_spSatellitePlayers[i].ammoJudgement = judgement;
        g_spSatellitePlayers[i].ammoBlizzard.isInfinityAmmo = false;
        g_spSatellitePlayers[i].ammoInferno.isInfinityAmmo = false;
        g_spSatellitePlayers[i].ammoJudgement.isInfinityAmmo = false;
        resetPlayerAmmo(i, AMMO_TYPE_ALL);
    }
}

void resetAllPlayersAmmo() {
    for(int i = 1; i <= MaxClients; i++) {
        resetPlayerAmmo(i, AMMO_TYPE_ALL);
    }
}

/**
 * Reset the player's satellite cannon ammo.
 *
 * @param client      Client index
 * @param ammoType    Ammo type with enum.
 */
void resetPlayerAmmo(int client, int ammoType) {
    switch(ammoType) {
        case AMMO_TYPE_BLIZZARD: {
            setPlayerAmmo(client, ammoType, getSatelliteMaxUses(AMMO_TYPE_BLIZZARD));
        }

        case AMMO_TYPE_INFERNO: {
            setPlayerAmmo(client, ammoType, getSatelliteMaxUses(AMMO_TYPE_INFERNO));
        }

        case AMMO_TYPE_JUDGEMENT: {
            setPlayerAmmo(client, ammoType, getSatelliteMaxUses(AMMO_TYPE_JUDGEMENT));
        }

        case AMMO_TYPE_ALL: {
            setPlayerAmmo(client, ammoType, getSatelliteMaxUses(AMMO_TYPE_BLIZZARD));
            setPlayerAmmo(client, ammoType, getSatelliteMaxUses(AMMO_TYPE_INFERNO));
            setPlayerAmmo(client, ammoType, getSatelliteMaxUses(AMMO_TYPE_JUDGEMENT));
        }
    }
}

void setPlayerAmmo(int client, int ammoType, int ammoCount) {
    switch(ammoType) {
        case AMMO_TYPE_BLIZZARD: {
            g_spSatellitePlayers[client].ammoBlizzard.usesLeft = ammoCount;
        }

        case AMMO_TYPE_INFERNO: {
            g_spSatellitePlayers[client].ammoInferno.usesLeft = ammoCount;
        }

        case AMMO_TYPE_JUDGEMENT: {
            g_spSatellitePlayers[client].ammoJudgement.usesLeft = ammoCount;
        }

        case AMMO_TYPE_ALL: {
            g_spSatellitePlayers[client].ammoBlizzard.usesLeft = ammoCount;
            g_spSatellitePlayers[client].ammoInferno.usesLeft = ammoCount;
            g_spSatellitePlayers[client].ammoJudgement.usesLeft = ammoCount;
        }
    }
}

bool isValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client);
}

public Action onPlayerDeath(Handle event, const char[] name, bool dontBroadcast) {
    for(int i = 0; i < SATELLITE_AMMO_TYPE_COUNT; i++) {
        if(i == AMMO_TYPE_ALL || i == AMMO_TYPE_IDLE)
            continue;
        
        if(getSatelliteUsageResetTiming(i) & RT_ON_DEATH) {
            int client = GetClientOfUserId(GetEventInt(event, "userid"));
            resetPlayerAmmo(client, i);
        }
    }
    return Plugin_Continue;
}

public Action onRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    for(int i = 1; i < SATELLITE_AMMO_TYPE_COUNT; i++) {
        if(i == AMMO_TYPE_ALL || i == AMMO_TYPE_IDLE)
            continue;

        if(getSatelliteUsageResetTiming(i) & RT_ROUND_START) {
            for(int client = 1; client <= MaxClients; client++) {
                resetPlayerAmmo(client, i);
            }
        }
    }
    if(g_psPluginSettings.values.usageResetTiming & RT_ROUND_START) {
        resetAllPlayersAmmo();
    }
    ResetParameter();
    return Plugin_Continue;
}

public void ResetParameter()
{
    for(int j = 0; j < MAXPLAYERS+1; j++)
        g_spSatellitePlayers[j].isActionBlocked = false;
}

/******************************************************
*    Event when using magnum pistol
*******************************************************/    
public Action onWeaponFired(Handle event, const char[] name, bool dontBroadcast)
{
    if(!g_psPluginSettings.values.enabled)
        return Plugin_Continue;

    int attacker = GetClientOfUserId(GetEventInt(event, "userid"));

    /* Bot can't use */
    if(GetClientTeam(attacker) != SURVIVOR || IsFakeClient(attacker))
        return Plugin_Continue;

    char mode[16];
    GetConVarString(FindConVar("mp_gamemode"), mode, sizeof(mode));
    if(StrEqual(mode, "versus"))
        return Plugin_Continue;
    
    char weapon[64];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    
    /* Admin only? */
    if(!StrEqual(weapon, "pistol_magnum"))
        return Plugin_Continue;
    
    if(g_spSatellitePlayers[attacker].currentAmmoType <= AMMO_TYPE_ALL)
        return Plugin_Continue;

    if(!checkSatelliteCanShoot(attacker)) {
        warnEmptyAmmo(attacker, g_spSatellitePlayers[attacker].currentAmmoType);
        return Plugin_Continue;
    }

    g_spSatellitePlayers[attacker].lastAmmoType = g_spSatellitePlayers[attacker].currentAmmoType;

    /* Emit sound */
    int soundNo = GetRandomInt(1, 9);
    if(soundNo == 1)  EmitSoundToAll(SOUND_SHOOT01, attacker);
    else if(soundNo == 2)  EmitSoundToAll(SOUND_SHOOT02, attacker);
    else if(soundNo == 3)  EmitSoundToAll(SOUND_SHOOT03, attacker);
    else if(soundNo == 4)  EmitSoundToAll(SOUND_SHOOT04, attacker);
    else if(soundNo == 5)  EmitSoundToAll(SOUND_SHOOT05, attacker);
    else if(soundNo == 6)  EmitSoundToAll(SOUND_SHOOT06, attacker);
    else if(soundNo == 7)  EmitSoundToAll(SOUND_SHOOT07, attacker);
    else if(soundNo == 8)  EmitSoundToAll(SOUND_SHOOT08, attacker);
    else if(soundNo == 9)  EmitSoundToAll(SOUND_SHOOT09, attacker);
        
    /* Trace and show effect */
    GetTracePosition(attacker);
    EmitAmbientSound(SOUND_TRACING, g_spSatellitePlayers[attacker].tracePosition);
    CreateLaserEffect(attacker, 150, 150, 230, 230, 0.5, 0.2, LASER_EFFECT_TYPE_NORMAL);
    CreateSparkEffect(attacker, 1200, 5);
    
    /* Ready to launch */
    CreateTimer(0.2, TraceTimer, attacker);
    subtractSatelliteUses(attacker);
    notifyWhenAmmoEmpty(attacker);
    
    /* Reload compulsorily */
    int wData = GetEntDataEnt2(attacker, g_hActiveWeapon);
    SetEntData(wData, g_hiClip1, 0);
    return Plugin_Continue;
}

public Action onItemPickUp(Handle event, const char[] name, bool dontBroadcast)
{
    if(!g_psPluginSettings.values.enabled)
        return Plugin_Continue;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(!isValidClient(client)) 
        return Plugin_Continue;

    char item[64];
    GetEventString(event, "item", item, sizeof(item));
    
    if(!StrEqual(item, "pistol_magnum"))
        return Plugin_Continue;
    
    /* Display hint how to switch mode */
    CreateTimer(0.3, DisplayInstructorHint, client);
    g_spSatellitePlayers[client].currentAmmoType = AMMO_TYPE_IDLE;
    return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
    if(!g_psPluginSettings.values.enabled)
        return Plugin_Continue;

    if(IsClientInGame(client) && IsPlayerAlive(client) && IsPlayerAlive(client) && GetClientTeam(client) == SURVIVOR)
    {
        /* If freezing, block mouse operation */
        if(g_spSatellitePlayers[client].isActionBlocked)
        {
            if(buttons & IN_ATTACK)
                buttons &= ~IN_ATTACK;
            if(buttons & IN_ATTACK2)
                buttons &= ~IN_ATTACK2;
        }
        
        /* When zoom key is pushed */
        if(buttons & IN_ZOOM)
        {
            char weapon[64];
            GetClientWeapon(client, weapon, 64);
            
            if (StrEqual(weapon, "weapon_pistol_magnum"))
            {
                /* Mode change menu */
                ChangeMode(client);
            }
        }
    }
    return Plugin_Continue;
}

public void ChangeMode(int client)
{
    char mStrJud[64], mStrBli[64], mStrInf[64], mStrIdle[64],_ammoName[32];

    getAmmoName(_ammoName, sizeof(_ammoName), AMMO_TYPE_BLIZZARD, client);
    Format(mStrBli, sizeof(mStrBli), "%s %t", _ammoName, "sc menu ammo left", g_spSatellitePlayers[client].ammoBlizzard.usesLeft);
    getAmmoName(_ammoName, sizeof(_ammoName), AMMO_TYPE_INFERNO, client);
    Format(mStrInf, sizeof(mStrInf), "%s %t", _ammoName, "sc menu ammo left", g_spSatellitePlayers[client].ammoInferno.usesLeft);
    getAmmoName(_ammoName, sizeof(_ammoName), AMMO_TYPE_JUDGEMENT, client);
    Format(mStrJud, sizeof(mStrJud), "%s %t", _ammoName, "sc menu ammo left", g_spSatellitePlayers[client].ammoJudgement.usesLeft);
    getAmmoName(_ammoName, sizeof(_ammoName), AMMO_TYPE_IDLE, client);
    Format(mStrIdle, sizeof(mStrIdle), "%s", _ammoName);
    
    Handle menu = CreateMenu(ChangeModeMenu);
    SetMenuTitle(menu, "%t", "sc menu title");
    AddMenuItem(menu, "ammo_blizzard", mStrBli);
    AddMenuItem(menu, "ammo_inferno", mStrInf);
    AddMenuItem(menu, "ammo_judgement", mStrJud);
    AddMenuItem(menu, "ammo_idle", mStrIdle);
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 45);
}

public int ChangeModeMenu(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        char preference[32];
        GetMenuItem(menu, itemNum, preference, sizeof(preference));

        if(strcmp(preference, "ammo_blizzard") == 0) {
            g_spSatellitePlayers[client].currentAmmoType = AMMO_TYPE_BLIZZARD;

            printAmmoTypeChangeMessage(client, AMMO_TYPE_BLIZZARD);
        }
        else if(strcmp(preference, "ammo_inferno") == 0) {
            g_spSatellitePlayers[client].currentAmmoType = AMMO_TYPE_INFERNO;

            printAmmoTypeChangeMessage(client, AMMO_TYPE_INFERNO);
        }
        else if(strcmp(preference, "ammo_judgement") == 0) {
            g_spSatellitePlayers[client].currentAmmoType = AMMO_TYPE_JUDGEMENT;

            printAmmoTypeChangeMessage(client, AMMO_TYPE_JUDGEMENT);
        }
        else if(strcmp(preference, "ammo_idle") == 0) {
            g_spSatellitePlayers[client].currentAmmoType = AMMO_TYPE_IDLE;

            printAmmoTypeChangeMessage(client, AMMO_TYPE_IDLE);
        }


        if(!checkSatelliteCanShoot(client) && g_spSatellitePlayers[client].currentAmmoType != AMMO_TYPE_IDLE) {
            warnEmptyAmmo(client, g_spSatellitePlayers[client].currentAmmoType);
            EmitSoundToClient(client, SOUND_NEGATIVE);
            g_spSatellitePlayers[client].currentAmmoType = AMMO_TYPE_IDLE;
        }
        // Implement notifycation when ammo is out.
        // if(itemNum != 3 && energy[client][itemNum+1] <= 0)
        // {
        //     PrintHintText(client, MESSAGE_EMPTY1);
        //     EmitSoundToClient(client, SOUND_NEGATIVE);
        //     g_spSatellitePlayers[client].currentAmmoType = AMMO_TYPE_IDLE;
        // }
        // else
        // {
        //     EmitSoundToClient(client, SOUND_SHOOT02);
        // }
    }
    return 0;
}

/******************************************************
*    Timer functions about launching
*******************************************************/
public Action TraceTimer(Handle timer, any client)
{
    /* Ring laser effect */
    CreateRingEffect(client, 150, 150, 230, 230, 2.0,
                getClientSatelliteBurstDelay(client));
    
    /* Launch satellite cannon */
    raycount[client] = 0;
    
    CreateTimer(getClientSatelliteBurstDelay(client),
                SatelliteTimer, client);
    
    return Plugin_Continue;
}

public Action SatelliteTimer(Handle timer, any client)
{
    if(!IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Handled;

    int ammoType = g_spSatellitePlayers[client].lastAmmoType;

    if(ammoType <= AMMO_TYPE_ALL)
        ammoType = AMMO_TYPE_JUDGEMENT;

    switch(g_spSatellitePlayers[client].lastAmmoType) {
        case AMMO_TYPE_BLIZZARD: {
            Blizzard(client);
        }
        case AMMO_TYPE_INFERNO: {
            castInferno(client);
        }
        case AMMO_TYPE_JUDGEMENT: {
            Judgement(client);
        }
    }

    return Plugin_Handled;
}

void notifyWhenAmmoEmpty(int client) {
    switch(g_spSatellitePlayers[client].currentAmmoType) {
        case AMMO_TYPE_BLIZZARD: {
            if(g_spSatellitePlayers[client].ammoBlizzard.usesLeft < 1) {
                printEmptyMessage(client, g_spSatellitePlayers[client].currentAmmoType);
                g_spSatellitePlayers[client].currentAmmoType = AMMO_TYPE_IDLE;
            }
        }

        case AMMO_TYPE_INFERNO: {
            if(g_spSatellitePlayers[client].ammoInferno.usesLeft < 1) {
                printEmptyMessage(client, g_spSatellitePlayers[client].currentAmmoType);
                g_spSatellitePlayers[client].currentAmmoType = AMMO_TYPE_IDLE;
            }
        }

        case AMMO_TYPE_JUDGEMENT: {
            if(g_spSatellitePlayers[client].ammoJudgement.usesLeft < 1) {
                printEmptyMessage(client, g_spSatellitePlayers[client].currentAmmoType);
                g_spSatellitePlayers[client].currentAmmoType = AMMO_TYPE_IDLE;
            }
        }
    }
}

void subtractSatelliteUses(int client) {
    switch(g_spSatellitePlayers[client].currentAmmoType) {
        case AMMO_TYPE_ALL, AMMO_TYPE_IDLE: {

        }

        case AMMO_TYPE_BLIZZARD: {
            if(!g_spSatellitePlayers[client].ammoBlizzard.isInfinityAmmo)
                g_spSatellitePlayers[client].ammoBlizzard.usesLeft--;
        }

        case AMMO_TYPE_INFERNO: {
            if(!g_spSatellitePlayers[client].ammoInferno.isInfinityAmmo)
                g_spSatellitePlayers[client].ammoInferno.usesLeft--;
        }

        case AMMO_TYPE_JUDGEMENT: {
            if(!g_spSatellitePlayers[client].ammoJudgement.isInfinityAmmo)
                g_spSatellitePlayers[client].ammoJudgement.usesLeft--;
        }
    }
}

public void Judgement(int client)
{
    float pos[3];
    int ammoType = AMMO_TYPE_JUDGEMENT;
    
    /* Emit impact sound */
    EmitAmbientSound(SOUND_IMPACT01, g_spSatellitePlayers[client].tracePosition);
    
    /* Laser effect */
    CreateLaserEffect(client, 230, 230, 80, 230, 6.0, 1.0, LASER_EFFECT_TYPE_VERTICAL);
    
    /* Damage to special infected */
    for(int i = 1; i <= MaxClients; i ++)
    {
        if(!IsClientInGame(i) || GetClientTeam(i) != 3)
            continue;
        GetClientAbsOrigin(i, pos);

        if(!(GetVectorDistance(pos, g_spSatellitePlayers[client].tracePosition) < getSatelliteRadius(ammoType)))
            continue;
        
        if (!satelliteHasFriendlyFire(ammoType))
            continue;

        DamageEffect(i, getSatelliteDamage(ammoType));
    }
    /* Explode */
    LittleFlower(client, EXPLOSION_TYPE_EXPLODE, ammoType);
    
    /* Push away */
    PushAway(client, getSatellitePushForce(ammoType),
            getSatelliteRadius(ammoType), 0.5);
}

public void Blizzard(int client)
{

    int MEspecialClassMag;
    MEspecialClassMag = FindSendPropInfo("CTerrorPlayer", "m_zombieClass");
    float pos[3];

    int ammoType = AMMO_TYPE_BLIZZARD;
    
    /* Emit impact sound */
    EmitAmbientSound(SOUND_IMPACT01, g_spSatellitePlayers[client].tracePosition);
    EmitAmbientSound(SOUND_IMPACT02, g_spSatellitePlayers[client].tracePosition);
    
    /* Laser effect */
    CreateLaserEffect(client, 80, 80, 230, 230, 6.0, 1.0, LASER_EFFECT_TYPE_VERTICAL);
    ShowParticle(g_spSatellitePlayers[client].tracePosition, PARTICLE_FIREBLUE01, 0.7);
    ShowParticle(g_spSatellitePlayers[client].tracePosition, PARTICLE_FIREBLUE02, 0.7);
    TE_SetupBeamRingPoint(g_spSatellitePlayers[client].tracePosition, 10.0, getSatelliteRadius(ammoType),
                        g_BeamSprite, g_HaloSprite, 0, 10, 0.3, 10.0, 0.5,
                        {40, 40, 230, 230}, 400, 0);
    TE_SendToAll();
    
    /* Freeze special infected and survivor in the radius */
    for(int i = 1; i <= MaxClients; i ++)
    {
        if(!IsClientInGame(i))
            continue;
        GetClientEyePosition(i, pos);

        if(!(GetVectorDistance(pos, g_spSatellitePlayers[client].tracePosition) < getSatelliteRadius(ammoType)))
            continue;
        
        switch(GetClientTeam(i)) {
            case SURVIVOR: {
                if(!satelliteHasFriendlyFire(ammoType) && i != client)
                    return;

                FreezePlayer(i, pos, g_ssSatelliteSettings[ammoType].values.ammoAbillity1);
            }

            case INFECTED: {
                int EventEClassMag = GetEntData(i, MEspecialClassMag);
                if(EventEClassMag <= 8)
                    FreezePlayer(i, pos, g_ssSatelliteSettings[ammoType].values.ammoAbillity1);
            }
        }

    }
    
    /* Freeze infected in the radius */
    int MaxEntities;
    char mName[64];
    float entPos[3];
    
    MaxEntities = GetMaxEntities();
    for (int i = 1; i <= MaxEntities; i++)
    {
        if (IsValidEdict(i) && IsValidEntity(i))
        {
            GetEntPropString(i, Prop_Data, "m_ModelName", mName, sizeof(mName));
            if (StrContains(mName, "infected") != -1)
            {
                GetEntPropVector(i, Prop_Send, "m_vecOrigin", entPos);
                if (GetVectorDistance(g_spSatellitePlayers[client].tracePosition, entPos) < getSatelliteRadius(ammoType))
                {
                    EmitAmbientSound(SOUND_FREEZE, entPos, i, SNDLEVEL_RAIDSIREN);
                    TE_SetupGlowSprite(entPos, g_GlowSprite, 5.0, 3.0, 130);
                    TE_SendToAll();
                    DamageEffect(i, 100.0);
                }
            }
        }
    }
    /* Push away */
    PushAway(client, getSatellitePushForce(ammoType),
            getSatelliteRadius(ammoType), 0.5);
    
}

public void castInferno(int client) {
    float eyePosition[3];

    /* Emit impact sound */
    EmitAmbientSound(SOUND_IMPACT01, g_spSatellitePlayers[client].tracePosition);
    EmitAmbientSound(SOUND_IMPACT03, g_spSatellitePlayers[client].tracePosition);
    
    /* Laser effect */
    CreateLaserEffect(client, 230, 40, 40, 230, 6.0, 1.0, LASER_EFFECT_TYPE_VERTICAL);
    ShowParticle(g_spSatellitePlayers[client].tracePosition, PARTICLE_FIRE01, 3.0);
    ShowParticle(g_spSatellitePlayers[client].tracePosition, PARTICLE_FIRE02, 3.0);

    /* Ignite special infected and survivor in the radius */
    for(int i = 1; i <= MaxClients; i++) {
        if(!IsClientConnected(i) || !IsClientInGame(i)) 
            continue;

        GetClientEyePosition(i, eyePosition);

        if(!(GetVectorDistance(eyePosition, g_spSatellitePlayers[client].tracePosition) < getSatelliteRadius(AMMO_TYPE_INFERNO)))
            continue;
            
        switch(GetClientTeam(i)) {
            case SURVIVOR: {
                if(!satelliteHasFriendlyFire(AMMO_TYPE_INFERNO))
                    continue;

                ScreenFade(i, 200, 0, 0, 150, 80, 1);
                DamageEffect(i, 5.0);
            }
            case INFECTED: {
                IgniteEntity(i, 10.0);
                DamageEffect(i, getSatelliteDamage(AMMO_TYPE_INFERNO));
            }
        }
    }

    /* Ignite infected in the radius */
    //int MaxEntities;
    char mName[64];
    float entPos[3];

    //MaxEntities = GetMaxEntities();
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsValidEdict(i) || !IsValidEntity(i))
            continue;
        
        GetEntPropString(i, Prop_Data, "m_ModelName", mName, sizeof(mName));
        if(StrContains(mName, "infected") == -1)
            continue;
        
        GetEntPropVector(i, Prop_Send, "m_vecOrigin", entPos);
        entPos[2] += 50;

        if(!(GetVectorDistance(g_spSatellitePlayers[client].tracePosition, entPos) < getSatelliteRadius(AMMO_TYPE_INFERNO))) 
            continue;

        if(!satelliteHasFriendlyFire(AMMO_TYPE_INFERNO))
            continue;

        IgniteEntity(i, 10.0);
        DamageEffect(i, 50.0);
    }

    PushAway(
        client,
        getSatellitePushForce(AMMO_TYPE_INFERNO),
        getSatelliteRadius(AMMO_TYPE_INFERNO),
        0.5
    );
}

public Action DefrostPlayer(Handle timer, any entity)
{
    if(IsValidEdict(entity) && IsValidEntity(entity))
    {
        float entPos[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entPos);
        EmitAmbientSound(SOUND_DEFROST, entPos, entity, SNDLEVEL_RAIDSIREN);
        SetEntityMoveType(entity, MOVETYPE_WALK);
        SetEntityRenderColor(entity, 255, 255, 255, 255);
        ScreenFade(entity, 0, 0, 0, 0, 0, 1);
        g_spSatellitePlayers[entity].isActionBlocked = false;
    }
    return Plugin_Continue;
}

public Action DeletePushForce(Handle timer, any ent)
{
    if (IsValidEntity(ent))
    {
        char classname[64];
        GetEdictClassname(ent, classname, sizeof(classname));
        if (StrEqual(classname, "point_push", false))
        {
            AcceptEntityInput(ent, "Disable");
            AcceptEntityInput(ent, "Kill"); 
            RemoveEdict(ent);
        }
    }
    return Plugin_Continue;
}

/******************************************************
*    TE functions
*******************************************************/
public void GetTracePosition(int client)
{
    float myPos[3], myAng[3], tmpPos[3], entPos[3];
    
    GetClientEyePosition(client, myPos);
    GetClientEyeAngles(client, myAng);
    Handle trace = TR_TraceRayFilterEx(myPos, myAng, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceEntityFilterPlayer, client);
    if(TR_DidHit(trace))
    {
        tEntity = TR_GetEntityIndex(trace);
        GetEntPropVector(tEntity, Prop_Send, "m_vecOrigin", entPos);
        TR_GetEndPosition(tmpPos, trace);
    }
    CloseHandle(trace);
    for(int i = 0; i < 3; i++)
        g_spSatellitePlayers[client].tracePosition[i] = tmpPos[i];
}

public void MoveTracePosition(int client, int min, int max)
{
    int point = GetRandomInt(1, 4);
    int xOffset = GetRandomInt(min, max);
    int yOffset = GetRandomInt(min, max);
    
    if(point == 1)
    {
        g_spSatellitePlayers[client].tracePosition[0] -= xOffset;
        g_spSatellitePlayers[client].tracePosition[1] += yOffset;
    }
    else if(point == 2)
    {
        g_spSatellitePlayers[client].tracePosition[0] += xOffset;
        g_spSatellitePlayers[client].tracePosition[1] += yOffset;
    }
    else if(point == 3)
    {
        g_spSatellitePlayers[client].tracePosition[0] -= xOffset;
        g_spSatellitePlayers[client].tracePosition[1] -= yOffset;
    }
    else if(point == 4)
    {
        g_spSatellitePlayers[client].tracePosition[0] += xOffset;
        g_spSatellitePlayers[client].tracePosition[1] -= yOffset;
    }
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
    return entity > MaxClients || !entity;
}

public void CreateLaserEffect(int client, int colRed, int colGre, int colBlu, int alpha, float width, float duration, int mode)
{
    int color[4];
    color[0] = colRed;
    color[1] = colGre;
    color[2] = colBlu;
    color[3] = alpha;
    
    if(mode == LASER_EFFECT_TYPE_NORMAL)
    {
        /* Show laser between user and impact position */
        float myPos[3];
        
        GetClientEyePosition(client, myPos);
        TE_SetupBeamPoints(myPos, g_spSatellitePlayers[client].tracePosition, g_BeamSprite, 0, 0, 0,
                            duration, width, width, 1, 0.0, color, 0);
        TE_SendToAll();
    }
    else if(mode == LASER_EFFECT_TYPE_VERTICAL)
    {
        /* Show laser like lightning bolt */
        float lchPos[3];
        
        for(int i = 0; i < 3; i++)
            lchPos[i] = g_spSatellitePlayers[client].tracePosition[i];
        lchPos[2] += GetConVarInt(g_psPluginSettings.cvars.laserVisualHeight);
        TE_SetupBeamPoints(lchPos, g_spSatellitePlayers[client].tracePosition, g_BeamSprite, 0, 0, 0,
                            duration, width, width, 1, 2.0, color, 0);
        TE_SendToAll();
        TE_SetupGlowSprite(lchPos, g_GlowSprite, 1.5, 2.8, 230);
        TE_SendToAll();
    }
}

public void CreateRingEffect(int client, int colRed, int colGre, int colBlu, int alpha, float width, float duration)
{
    int color[4];
    color[0] = colRed;
    color[1] = colGre;
    color[2] = colBlu;
    color[3] = alpha;
    
    TE_SetupBeamRingPoint(g_spSatellitePlayers[client].tracePosition, 300.0, 10.0, g_BeamSprite,
                        g_HaloSprite, 0, 10, 1.2, 4.0, 0.5,
                        {150, 150, 230, 230}, 80, 0);
    TE_SendToAll();
}

public void CreateSparkEffect(int client, int size, int length)
{
    float spkVec[3];
    spkVec[0]=GetRandomFloat(-1.0, 1.0);
    spkVec[1]=GetRandomFloat(-1.0, 1.0);
    spkVec[2]=GetRandomFloat(-1.0, 1.0);
    
    TE_SetupSparks(g_spSatellitePlayers[client].tracePosition, spkVec, size, length);
    TE_SendToAll();
}

/******************************************************
*    Other functions
*******************************************************/

bool checkSatelliteCanShoot(int client) {

    switch(g_spSatellitePlayers[client].currentAmmoType) {
        case AMMO_TYPE_ALL, AMMO_TYPE_IDLE: {
            return false;
        }

        case AMMO_TYPE_BLIZZARD: {
            if(!isSatelliteEnabled(AMMO_TYPE_BLIZZARD)) {
                return false;
            }

            if(g_spSatellitePlayers[client].ammoBlizzard.isAmmoEmpty()) {
                return false;
            }
        }

        case AMMO_TYPE_INFERNO: {
            if(!isSatelliteEnabled(AMMO_TYPE_BLIZZARD)) {
                return false;
            }

            if(g_spSatellitePlayers[client].ammoInferno.isAmmoEmpty()) {
                return false;
            }
        }

        case AMMO_TYPE_JUDGEMENT: {
            if(!isSatelliteEnabled(AMMO_TYPE_BLIZZARD)) {
                return false;
            }
            
            if(g_spSatellitePlayers[client].ammoJudgement.isAmmoEmpty()) {
                return false;
            }
        }
    }
    return true;
}

void getAmmoName(char[] buffer, int bufferSize, int ammoType, int client) {
    SetGlobalTransTarget(client);
    switch(ammoType) {
        case AMMO_TYPE_BLIZZARD: {
            Format(buffer, bufferSize, "%t", "sc ammo name blizzard");
        }
        case AMMO_TYPE_INFERNO: {
            Format(buffer, bufferSize, "%t", "sc ammo name inferno");
        }
        case AMMO_TYPE_JUDGEMENT: {
            Format(buffer, bufferSize, "%t", "sc ammo name judgement");
        }
        case AMMO_TYPE_IDLE: {
            Format(buffer, bufferSize, "%t", "sc ammo name idle");
        }
        default: {
            Format(buffer, bufferSize, "%t", "sc ammo name invalid");
        }
    }
}

void printAmmoTypeChangeMessage(int client, int ammoType) {
    char ammoName[48];
    getAmmoName(ammoName, sizeof(ammoName), ammoType, client);

    PrintHintText(client, "%t %s", "sc ammo type change", ammoName);
}

void printEmptyMessage(int client, int ammoType) {
    char ammoName[48];
    getAmmoName(ammoName, sizeof(ammoName), ammoType, client);

    PrintHintText(client, "%t", "sc ammo now empty", ammoName);
}

void warnEmptyAmmo(int client, int ammoType) {
    char ammoName[48];
    getAmmoName(ammoName, sizeof(ammoName), ammoType, client);

    PrintHintText(client, "%t", "sc ammo empty", ammoName);
    g_spSatellitePlayers[client].currentAmmoType = AMMO_TYPE_IDLE;
}

bool isSatelliteEnabled(int ammoType) {
    return g_ssSatelliteSettings[ammoType].values.enabled;
}

stock int getSatelliteUsageResetTiming(int ammoType) {
    if(g_psPluginSettings.values.globalUsageResetTiming) {
        return g_psPluginSettings.values.usageResetTiming; 
    }

    return g_ssSatelliteSettings[ammoType].values.usageResetTiming;
}

stock float getClientSatelliteBurstDelay(int client) {
    return getSatelliteBurstDelay(g_spSatellitePlayers[client].currentAmmoType);
}

stock float getSatelliteBurstDelay(int ammoType) {
    if(g_psPluginSettings.values.globalBurstDelay)
        return g_psPluginSettings.values.burstDelay;
    
    return g_ssSatelliteSettings[ammoType].values.burstDelay;
}


stock float getClientSatellitePushForce(int client) {
    return getSatellitePushForce(g_spSatellitePlayers[client].currentAmmoType);
}

stock float getSatellitePushForce(int ammoType) {
    if(g_psPluginSettings.values.globalPushForce)
        return g_psPluginSettings.values.pushForce;
    
    return g_ssSatelliteSettings[ammoType].values.pushForce;
}


stock float getClientSatelliteRadius(int client) {
    return getSatelliteRadius(g_spSatellitePlayers[client].currentAmmoType);
}

stock float getSatelliteRadius(int ammoType) {
    return g_ssSatelliteSettings[ammoType].values.radius;
}


stock float getClientSatelliteDamage(int client) {
    return getSatelliteDamage(g_spSatellitePlayers[client].currentAmmoType);
}

stock float getSatelliteDamage(int ammoType) {
    return g_ssSatelliteSettings[ammoType].values.damage;
}


stock float getClientSatelliteCooldown(int client) {
    return getSatelliteCooldown(g_spSatellitePlayers[client].currentAmmoType);
}

stock float getSatelliteCooldown(int ammoType) {
    return g_ssSatelliteSettings[ammoType].values.cooldown;
}

stock int getSatelliteMaxUses(int ammoType) {
    return g_ssSatelliteSettings[ammoType].values.maxUses;
}


stock bool clientSatelliteHasFriendlyFire(int client) {
    return satelliteHasFriendlyFire(g_spSatellitePlayers[client].currentAmmoType);
}

stock bool satelliteHasFriendlyFire(int ammoType) {
    if(g_psPluginSettings.values.globalFriendlyFire) 
        return g_psPluginSettings.values.friendlyFire;
    
    return g_ssSatelliteSettings[ammoType].values.hasFriendlyFire;
}

stock void DamageEffect(int target, float damage)
{
    char tName[20];
    Format(tName, 20, "target%d", target);
    int pointHurt = CreateEntityByName("point_hurt");
    DispatchKeyValue(target, "targetname", tName);
    DispatchKeyValueFloat(pointHurt, "Damage", damage);
    DispatchKeyValue(pointHurt, "DamageTarget", tName);
    DispatchKeyValue(pointHurt, "DamageType", "65536");
    DispatchSpawn(pointHurt);
    AcceptEntityInput(pointHurt, "Hurt");
    AcceptEntityInput(pointHurt, "Kill");

}

public void PushAway(int client, float force, float radius, float duration)
{
    int push = CreateEntityByName("point_push");
    DispatchKeyValueFloat (push, "magnitude", force);
    DispatchKeyValueFloat (push, "radius", radius);
    SetVariantString("spawnflags 24");
    AcceptEntityInput(push, "AddOutput");
    DispatchSpawn(push);
    TeleportEntity(push, g_spSatellitePlayers[client].tracePosition, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(push, "Enable", -1, -1);
    CreateTimer(duration, DeletePushForce, push);
}

public void LittleFlower(int client, int explosionType, int ammoType)
{
    /* Cause fire(type=0) or explosion(type=1) */
    int entity = CreateEntityByName("prop_physics");
    if (IsValidEntity(entity))
    {
        g_spSatellitePlayers[client].tracePosition[2] += 20;

        switch(explosionType) {
            case EXPLOSION_TYPE_MOLOTOV: {
                /* fire */
                DispatchKeyValue(entity, "model", ENTITY_GASCAN);
            }

            case EXPLOSION_TYPE_EXPLODE: {
                /* explode */
                DispatchKeyValue(entity, "model", ENTITY_PROPANE);
            }

            default: {
                RemoveEntity(entity);
                return;
            }
        }

        char ammoTypeStr[1];
        Format(ammoTypeStr, sizeof(ammoTypeStr), "%d", ammoType);
        DispatchKeyValue(entity, "targetname", ammoTypeStr);
        DispatchSpawn(entity);
        SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
        TeleportEntity(entity, g_spSatellitePlayers[client].tracePosition, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(entity, "break");
    }
}

public void ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
    Handle msg = StartMessageOne("Fade", target);
    BfWriteShort(msg, 500);
    BfWriteShort(msg, duration);
    if (type == 0)
        BfWriteShort(msg, (0x0002 | 0x0008));
    else
        BfWriteShort(msg, (0x0001 | 0x0010));
    BfWriteByte(msg, red);
    BfWriteByte(msg, green);
    BfWriteByte(msg, blue);
    BfWriteByte(msg, alpha);
    EndMessage();
}

public void FreezePlayer(int entity, float pos[3], float time)
{
    SetEntityMoveType(entity, MOVETYPE_NONE);
    SetEntityRenderColor(entity, 0, 128, 255, 135);
    ScreenFade(entity, 0, 128, 255, 192, 2000, 1);
    EmitAmbientSound(SOUND_FREEZE, pos, entity, SNDLEVEL_RAIDSIREN);
    TE_SetupGlowSprite(pos, g_GlowSprite, time, 0.5, 130);
    TE_SendToAll();
    g_spSatellitePlayers[entity].isActionBlocked = true;
    CreateTimer(time, DefrostPlayer, entity);
}

/******************************************************
*    Particle control functions
*******************************************************/
public void ShowParticle(float pos[3], char[] particlename, float time)
{
    /* Show particle effect you like */
    int particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particlename);
        DispatchKeyValue(particle, "targetname", "particle");
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, particle);
    }  
}

public Action DeleteParticles(Handle timer, any particle)
{
    /* Delete particle */
    if (IsValidEntity(particle))
    {
        char classname[64];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
            RemoveEdict(particle);
    }
    return Plugin_Handled;
}

public void PrecacheParticle(char[] particlename)
{
    /* Precache particle */
    int particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        DispatchKeyValue(particle, "effect_name", particlename);
        DispatchKeyValue(particle, "targetname", "particle");
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(0.01, DeleteParticles, particle);
    }  
}


/******************************************************
*    Display hint functions
*******************************************************/
public Action DisplayInstructorHint(Handle  timer, any client)
{
    int entity;
    char tName[32];
    Handle hRemovePack;
    
    entity = CreateEntityByName("env_instructor_hint");
    FormatEx(tName, sizeof(tName), "hint%d", client);
    
    DispatchKeyValue(client, "targetname", tName);
    DispatchKeyValue(entity, "hint_target", tName);
    DispatchKeyValue(entity, "hint_timeout", "5");
    DispatchKeyValue(entity, "hint_range", "0.01");
    DispatchKeyValue(entity, "hint_color", "255 255 255");
    DispatchKeyValue(entity, "hint_icon_onscreen", "use_binding");


    char infoText[16];
    Format(infoText, sizeof(infoText), "%t", "sc info change ammo type");

    DispatchKeyValue(entity, "hint_caption", infoText);
    DispatchKeyValue(entity, "hint_binding", "+zoom");
    DispatchSpawn(entity);
    AcceptEntityInput(entity, "ShowHint");
    
    hRemovePack = CreateDataPack();
    WritePackCell(hRemovePack, client);
    WritePackCell(hRemovePack, entity);
    CreateTimer(5.0, RemoveInstructorHint, hRemovePack);
    return Plugin_Continue;
}
    
public Action RemoveInstructorHint(Handle timer, Handle hPack)
{
    int entity, client;
    
    ResetPack(hPack, false);
    client = ReadPackCell(hPack);
    entity = ReadPackCell(hPack);
    CloseHandle(hPack);
    
    if (!client || !IsClientInGame(client))
        return Plugin_Continue;
    
    if (IsValidEntity(entity))
            RemoveEdict(entity);
    
    DispatchKeyValue(client, "targetname", "");
    return Plugin_Handled;
}