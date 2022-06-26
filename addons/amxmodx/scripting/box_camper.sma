#include <amxmodx>
#include <hamsandwich>
#include <hlsdk_const>
#include <box_with_boxes>

#define PLUGIN "Box Camper"
#define AUTHOR "Mistrick"
#define VERSION "0.0.2"

#pragma semicolon 1

#define CAMPING_ALLOWED_TIME 10.0
#define DAMAGE_TICK 3.0
#define DAMAGE_AMOUNT 1.0

new const CAMPER_TYPE[] = "Camper Zone";

new Float:g_fStartCamping[33];
new g_iCamperBoxType;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_iCamperBoxType = bwb_register_box_type(CAMPER_TYPE, {255, 0, 0});
}

public bwb_box_start_touch(box, id, type_index)
{
    if(id < 1 || id > MaxClients) {
        return PLUGIN_CONTINUE;
    }
    if(type_index != g_iCamperBoxType) {
        return PLUGIN_CONTINUE;
    }

    g_fStartCamping[id] = get_gametime();

    return PLUGIN_CONTINUE;
}

public bwb_box_stop_touch(box, id, type_index)
{
    if(id < 1 || id > MaxClients) {
        return PLUGIN_CONTINUE;
    }
    if(type_index != g_iCamperBoxType) {
        return PLUGIN_CONTINUE;
    }

    g_fStartCamping[id] = 0.0;

    return PLUGIN_CONTINUE;
}

public bwb_box_touch(box, id, type_index)
{
    if(id < 1 || id > MaxClients) {
        return PLUGIN_CONTINUE;
    }
    if(type_index != g_iCamperBoxType) {
        return PLUGIN_CONTINUE;
    }

    if(!g_fStartCamping[id]) {
        return PLUGIN_CONTINUE;
    }

    new Float:t = get_gametime();

    if(t < g_fStartCamping[id] + CAMPING_ALLOWED_TIME) {
        return PLUGIN_CONTINUE;
    }

    static Float:last_tick[33];

    if(t < last_tick[id] + DAMAGE_TICK) {
        return PLUGIN_CONTINUE;
    }

    last_tick[id] = t;
    ExecuteHamB(Ham_TakeDamage, id, 0, 0, DAMAGE_AMOUNT, DMG_GENERIC);

    return PLUGIN_CONTINUE;
}
