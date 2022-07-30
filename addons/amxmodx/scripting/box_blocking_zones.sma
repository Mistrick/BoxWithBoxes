#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <box_with_boxes>
#include <box_with_boxes_stocks>
#include <xs>

#define PLUGIN "Box Blocking Zones"
#define AUTHOR "Mistrick"
#define VERSION "0.1.0"

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

    find_valid_spot(box, ent);

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

find_valid_spot(box, id)
{
    new Float:box_origin[3], Float:ent_origin[3];
    pev(box, pev_origin, box_origin);
    pev(id, pev_origin, ent_origin);

    new Float:vec[3];
    xs_vec_sub(ent_origin, box_origin, vec);
    vec[2] = 0.0;
    xs_vec_normalize(vec, vec);

    new hull = pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN;

    new Float:check_origin[3];
    xs_vec_copy(ent_origin, check_origin);
    new Float:vec_add[3];
    xs_vec_mul_scalar(vec, 16.0, vec_add);

    while(engfunc(EngFunc_TraceHull, check_origin, check_origin, IGNORE_MONSTERS, hull, id, 0)) {
        if(!intersect(box, id)) {
            break;
        }
        xs_vec_add(check_origin, vec_add, check_origin);
        entity_set_origin(id, check_origin);
    }

    UTIL_UnstickPlayer(id, 16, 128);

    set_pev(id, pev_velocity, {0.0, 0.0, 0.0});
}

#define GetPlayerHullSize(%1)  ( ( pev ( %1, pev_flags ) & FL_DUCKING ) ? HULL_HEAD : HULL_HUMAN )

UTIL_UnstickPlayer ( const id, const i_StartDistance, const i_MaxAttempts )
{
    // --| Not alive, ignore.
    if ( !is_user_alive ( id ) ) return -1;

    // --| Just for readability.
    enum Coord_e { Float:x, Float:y, Float:z };

    static Float:vf_OriginalOrigin[ Coord_e ], Float:vf_NewOrigin[ Coord_e ];
    static i_Attempts, i_Distance;

    // --| Get the current player's origin.
    pev ( id, pev_origin, vf_OriginalOrigin );

    i_Distance = i_StartDistance;

    while ( i_Distance < 1000 )
    {
        i_Attempts = i_MaxAttempts;

        while ( i_Attempts-- )
        {
            vf_NewOrigin[ x ] = random_float ( vf_OriginalOrigin[ x ] - i_Distance, vf_OriginalOrigin[ x ] + i_Distance );
            vf_NewOrigin[ y ] = random_float ( vf_OriginalOrigin[ y ] - i_Distance, vf_OriginalOrigin[ y ] + i_Distance );
            vf_NewOrigin[ z ] = random_float ( vf_OriginalOrigin[ z ] - i_Distance, vf_OriginalOrigin[ z ] + i_Distance );

            engfunc ( EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, GetPlayerHullSize ( id ), id, 0 );

            // --| Free space found.
            if ( get_tr2 ( 0, TR_InOpen ) && !get_tr2 ( 0, TR_AllSolid ) && !get_tr2 ( 0, TR_StartSolid ) )
            {
                // --| Set the new origin .
                engfunc ( EngFunc_SetOrigin, id, vf_NewOrigin );
                return 1;
            }
        }

        i_Distance += i_StartDistance;
    }

    // --| Could not be found.
    return 0;
}
