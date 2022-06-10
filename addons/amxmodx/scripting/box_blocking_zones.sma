#include <amxmodx>
#include <fakemeta>
#include <box_with_boxes>
#include <xs>

#define PLUGIN "Box Blocking Zones"
#define AUTHOR "Mistrick"
#define VERSION "0.0.1"

#pragma semicolon 1

new Trie:g_tTypes;

new const BLOCKING_ZONE[] = "Blocking Zone";
new const BLOCKING_ZONE_T[] = "Blocking Zone T";
new const BLOCKING_ZONE_CT[] = "Blocking Zone CT";

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
}

public plugin_cfg()
{
    if(!g_tTypes) {
        g_tTypes = TrieCreate();
        TrieSetCell(g_tTypes, BLOCKING_ZONE_T, 1);
        TrieSetCell(g_tTypes, BLOCKING_ZONE_CT, 2);
        TrieSetCell(g_tTypes, BLOCKING_ZONE, 3);
    }
}

public bwb_box_touch(box, ent, const type[])
{
    new block_type;
    if(!TrieGetCell(g_tTypes, type, block_type)) {
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
