#include <amxmodx>
#include <fakemeta>
#include <box_with_boxes>
#include <xs>

#define PLUGIN "Box Blocking Zones"
#define AUTHOR "Mistrick"
#define VERSION "0.0.2"

#pragma semicolon 1

new const BLOCKING_ZONE[] = "Blocking Zone";
new const BLOCKING_ZONE_T[] = "Blocking Zone T";
new const BLOCKING_ZONE_CT[] = "Blocking Zone CT";

new g_iBlockingZoneTypes[3];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_iBlockingZoneTypes[2] = bwb_register_box_type(BLOCKING_ZONE, {255, 255, 0});
    g_iBlockingZoneTypes[0] = bwb_register_box_type(BLOCKING_ZONE_T, {255, 55, 0});
    g_iBlockingZoneTypes[1] = bwb_register_box_type(BLOCKING_ZONE_CT, {0, 55, 255});
}

public bwb_box_touch(box, ent, type_index)
{
    new block_type = get_block_type(type_index);
    if(!block_type) {
        return PLUGIN_CONTINUE;
    }

    new team;
    if(ent > 0 && ent <= MaxClients) {
        team = get_user_team(ent);
    }

    if(!(team & block_type)) {
        return PLUGIN_CONTINUE;
    }

    new Float:box_origin[3], Float:ent_origin[3];
    pev(box, pev_origin, box_origin);
    pev(ent, pev_origin, ent_origin);

    new Float:vec[3];
    xs_vec_sub(ent_origin, box_origin, vec);
    xs_vec_normalize(vec, vec);

    new Float:velocity[3];
    pev(ent, pev_velocity, velocity);
    new Float:l = vector_length(velocity);
    
    if(l < 10.0) {
        l = 10.0;
    }

    xs_vec_mul_scalar(vec, l, vec);

    set_pev(ent, pev_velocity, vec);

    return PLUGIN_CONTINUE;
}

get_block_type(type_index)
{
    for(new i; i < sizeof(g_iBlockingZoneTypes); i++) {
        if(type_index == g_iBlockingZoneTypes[i]) {
            return i + 1;
        }
    }
    return 0;
}
