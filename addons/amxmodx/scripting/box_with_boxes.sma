// Credits: R3X@Box System
#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <xs>

#include <box_with_boxes_stocks>

#define PLUGIN "Box with Boxes"
#define AUTHOR "Mistrick"
#define VERSION "0.0.2"

#pragma semicolon 1

#define BOX_THINK_TIMER 0.001
#define BOX_VISUAL_THINK_TIMER 0.3


#define DEFAULT_MINSIZE { -32.0, -32.0, -32.0 }
#define DEFAULT_MAXSIZE { 32.0, 32.0, 32.0 }

#define PEV_TYPE pev_netname
#define PEV_ID pev_message

#define m_flNextAttack 83

#define BOX_CLASSNAME "bwb"
#define ANCHOR_CLASSNAME "bwb_anchor"
#define SELECTED_ANCHOR_CLASSNAME "bwb_selected_anchor"

new const g_szModel[] = "sprites/cnt1.spr";
new g_iSpriteLine;


new Float:g_fDistance[33];
new g_iCatched[33];
new g_iMarked[33];

new g_iSelectedBox[33];

new bool:g_bEditMode[33];

new giUNIQUE = 1;


public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_clcmd("bwb", "cmd_bwb");

    register_think(BOX_CLASSNAME, "Box_Think");

    register_forward(FM_TraceLine, "fwTraceLine", 1);
    register_forward(FM_PlayerPreThink, "fwPlayerPreThink", 1);

    register_touch(BOX_CLASSNAME, "*", "fwBoxTouch");
}
public plugin_precache()
{
    precache_model(g_szModel);

    g_iSpriteLine = precache_model("sprites/white.spr");
}
public cmd_bwb(id)
{
    new menu = menu_create("Box with Boxes", "bwbmenu_handler");

    menu_additem(menu, "Create Box");
    menu_additem(menu, fmt("Edit Mode%s", g_bEditMode[id] ? "\y[ON]" : "\r[OFF]"));

    if(g_iSelectedBox[id]) {
        new type[32], index[32];
        pev(g_iSelectedBox[id], PEV_ID, index, charsmax(index));
        pev(g_iSelectedBox[id], PEV_TYPE, type, charsmax(type));
        menu_additem(menu, fmt("Select next\y[Current: %s, Type: %s]", index, type));
    } else {
        menu_additem(menu, "Select next");
    }
    

    menu_display(id, menu);

    return PLUGIN_HANDLED;
}
public bwbmenu_handler(id, menu, item)
{
    if(item == MENU_EXIT) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    switch(item) {
        case 0: {
            new Float:origin[3];
            pev(id, pev_origin, origin);
            new ent = create_box(origin);

            if(g_bEditMode[id]) {
                set_task(BOX_VISUAL_THINK_TIMER, "box_visual_think", ent, .flags = "b");
                create_anchors(ent);
            }
        }
        case 1: {
            g_bEditMode[id] = !g_bEditMode[id];

            if(g_bEditMode[id]) {
                new ent = -1;
                while((ent = find_ent_by_class(ent, BOX_CLASSNAME))) {
                    set_task(BOX_VISUAL_THINK_TIMER, "box_visual_think", ent, .flags = "b");
                    create_anchors(ent);
                }

                if(pev_valid(g_iSelectedBox[id])) {
                    create_selected_anchor(id, g_iSelectedBox[id]);
                }
            } else {
                new ent = -1;
                while((ent = find_ent_by_class(ent, BOX_CLASSNAME))) {
                    remove_task(ent);
                    remove_anchors(ent);
                }
                remove_selected_anchor(id);
            }
        }
        case 2: {
            new ent = g_iSelectedBox[id] ? g_iSelectedBox[id] : -1;
            new start = ent;
            new found;

            while(!(start == -1 && ent == 0) && !found) {
                while((ent = find_ent_by_class(ent, BOX_CLASSNAME))) {
                    g_iSelectedBox[id] = ent;
                    found = true;
                    break;
                }
            }

            if(found) {
                remove_selected_anchor(id);
                create_selected_anchor(id, ent);
            }
        }
    }

    cmd_bwb(id);

    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

create_box(const Float:origin[3], const class[] = "box", const Float:mins[3] = DEFAULT_MINSIZE, const Float:maxs[3] = DEFAULT_MAXSIZE)
{
    new ent = create_entity("info_target");

    entity_set_string(ent, EV_SZ_classname, BOX_CLASSNAME);
    set_pev(ent, PEV_TYPE, class);

    set_pev(ent, PEV_ID, fmt("Box#%d", giUNIQUE++));

    DispatchSpawn(ent);

    // entity_set_model(ent, g_szModel);

    set_pev(ent, pev_effects, EF_NODRAW);
    set_pev(ent, pev_solid, SOLID_TRIGGER);
    set_pev(ent, pev_movetype, MOVETYPE_NONE);
    set_pev(ent, pev_enemy, 1);

    set_pev(ent, pev_nextthink, get_gametime() + 0.1);
    // BOX_Add(ent, editor);

    // touch info
    new Array:a = ArrayCreate(1, 1);
    set_pev(ent, pev_iuser3, a);

    entity_set_origin(ent, origin);
    entity_set_size(ent, mins, maxs);

    /* new iRet;
    ExecuteForward(fwOnCreate, iRet, ent, szClass); */

    return ent;
}

create_anchors(box)
{
    new Float:mins[3], Float:maxs[3];
    pev(box, pev_absmin, mins);
    pev(box, pev_absmax, maxs);

    create_anchor_entity(box, 0b000, mins[0], mins[1], mins[2]);
    create_anchor_entity(box, 0b001, mins[0], mins[1], maxs[2]);
    create_anchor_entity(box, 0b010, mins[0], maxs[1], mins[2]);
    create_anchor_entity(box, 0b011, mins[0], maxs[1], maxs[2]);
    create_anchor_entity(box, 0b100, maxs[0], mins[1], mins[2]);
    create_anchor_entity(box, 0b101, maxs[0], mins[1], maxs[2]);
    create_anchor_entity(box, 0b110, maxs[0], maxs[1], mins[2]);
    create_anchor_entity(box, 0b111, maxs[0], maxs[1], maxs[2]);
}

create_anchor_entity(box, vertex, Float:x, Float:y, Float:z)
{
    new Float:origin[3];
    origin[0] = x;
    origin[1] = y;
    origin[2] = z;

    new ent = create_entity("info_target");
    entity_set_string(ent, EV_SZ_classname, ANCHOR_CLASSNAME);


    entity_set_model(ent, g_szModel);
    entity_set_origin(ent, origin);

    entity_set_size(ent, Float:{ -3.0, -3.0, -3.0 }, Float:{ 3.0, 3.0, 3.0 });

    set_pev(ent, pev_solid, SOLID_BBOX);
    set_pev(ent, pev_movetype, MOVETYPE_NOCLIP);
    set_pev(ent, pev_owner, box);

    set_pev(ent, pev_iuser4, vertex);

    set_pev(ent, pev_scale, 0.25);

    set_rendering(ent, kRenderFxPulseFast, 0, 150, 0, kRenderTransAdd, 255);
}

remove_anchors(box)
{
    new ent = -1;
    while( (ent = find_ent_by_owner(ent, ANCHOR_CLASSNAME, box) ) ) {
        remove_entity(ent);
    }
}

get_anchor(box, num)
{
    new ent = 0;
    new a = -1;
    while((a = find_ent_by_owner(a, ANCHOR_CLASSNAME, box))) {
        if(pev(a, pev_iuser4) == num) {
            ent = a;
            break;
        }
    }
    return ent;
}

create_selected_anchor(id, box)
{
    new ent = create_entity("info_target");
    entity_set_string(ent, EV_SZ_classname, SELECTED_ANCHOR_CLASSNAME);

    new Float:origin[3];
    pev(box, pev_origin, origin);

    entity_set_model(ent, g_szModel);
    entity_set_origin(ent, origin);

    entity_set_size(ent, Float:{ -3.0, -3.0, -3.0 }, Float:{ 3.0, 3.0, 3.0 });

    set_pev(ent, pev_solid, SOLID_BBOX);
    set_pev(ent, pev_movetype, MOVETYPE_NOCLIP);
    set_pev(ent, pev_owner, box);

    set_pev(ent, pev_iuser3, id);

    set_pev(ent, pev_scale, 0.4);

    set_rendering(ent, kRenderFxPulseFast, 150, 150, 0, kRenderTransAdd, 255);
}
remove_selected_anchor(id)
{
    new ent = -1;
    while( (ent = find_ent_by_class(ent, SELECTED_ANCHOR_CLASSNAME) ) ) {
        if(pev(ent, pev_iuser3) == id) {
            remove_entity(ent);
        }
    }
}

// Visual
public box_visual_think(ent)
{
    new Float:mins[3], Float:maxs[3];
    pev(ent, pev_absmin, mins);
    pev(ent, pev_absmax, maxs);

    _draw_line(ent, maxs[0], maxs[1], maxs[2], maxs[0], maxs[1], mins[2]);
    _draw_line(ent, mins[0], maxs[1], maxs[2], mins[0], maxs[1], mins[2]);
    _draw_line(ent, maxs[0], mins[1], maxs[2], maxs[0], mins[1], mins[2]);
    _draw_line(ent, mins[0], mins[1], maxs[2], mins[0], mins[1], mins[2]);

    _draw_line(ent, maxs[0], maxs[1], maxs[2], mins[0], maxs[1], maxs[2]);
    _draw_line(ent, maxs[0], maxs[1], mins[2], mins[0], maxs[1], mins[2]);
    _draw_line(ent, maxs[0], mins[1], maxs[2], mins[0], mins[1], maxs[2]);
    _draw_line(ent, maxs[0], mins[1], mins[2], mins[0], mins[1], mins[2]);

    _draw_line(ent, maxs[0], maxs[1], maxs[2], maxs[0], mins[1], maxs[2]);
    _draw_line(ent, mins[0], maxs[1], maxs[2], mins[0], mins[1], maxs[2]);
    _draw_line(ent, maxs[0], maxs[1], mins[2], maxs[0], mins[1], mins[2]);
    _draw_line(ent, mins[0], maxs[1], mins[2], mins[0], mins[1], mins[2]);

    _draw_line(ent, mins[0], mins[1], mins[2], maxs[0], maxs[1], maxs[2]);
}

_draw_line(ent, Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    new Float:start[3];
    start[0] = x1;
    start[1] = y1;
    start[2] = z1;

    new Float:stop[3];
    stop[0] = x2;
    stop[1] = y2;
    stop[2] = z2;

    new color[3];
    get_type_color(ent, color);

    draw_line(start, stop, color, g_iSpriteLine);
}

get_type_color(ent, color[3])
{
    if( !pev_valid(ent) )
        return 0;

    /* new szNetName[32];
    pev(ent, PEV_TYPE, szNetName, 31);

    new iType;
    if ( TrieGetCell(gTypes, szNetName, iType) ) {
        color[0] = giTypeColors[iType][0];
        color[1] = giTypeColors[iType][1];
        color[2] = giTypeColors[iType][2];
    } else {
        color[0] = 50;
        color[1] = 255;
        color[2] = 50;
    } */

    color[0] = 50;
    color[1] = 255;
    color[2] = 50;

    return 1;
}


// Move Process
public fwPlayerPreThink(id)
{
    if( !g_bEditMode[id] ) {
        return FMRES_IGNORED;
    }

    set_pdata_float(id, m_flNextAttack, 1.0, 5);

    if( !is_valid_ent(g_iCatched[id]) ) {
        return FMRES_IGNORED;
    }

    if( pev(id, pev_button) & IN_ATTACK ) {
        anchor_move_process(id, g_iCatched[id]);
    }else {
        anchor_move_uninit(id, g_iCatched[id]);
    }

    return FMRES_IGNORED;
}
public fwTraceLine(const Float:v1[], const Float:v2[], fNoMonsters, id, ptr)
{
    if( !is_user_alive(id) ) {
        return FMRES_IGNORED;
    }

    if( !g_bEditMode[id] ) {
        return FMRES_IGNORED;
    }

    new ent = get_tr2(ptr, TR_pHit);

    if( !is_valid_ent(ent) ) {
        anchor_unmark(id, g_iMarked[id]);
        return FMRES_IGNORED;
    }

    if( g_iCatched[id] ) {
        if( pev(id, pev_button) & IN_ATTACK ) {
            anchor_move_process(id, g_iCatched[id]);
        } else {
            anchor_move_uninit(id, g_iCatched[id]);
        }
    } else {
        new szClass[32];
        pev(ent, pev_classname, szClass, 31);
        if(equal(szClass, ANCHOR_CLASSNAME) || equal(szClass, SELECTED_ANCHOR_CLASSNAME)) {
            if( pev(id, pev_button) & IN_ATTACK ) {
                anchor_move_init(id, ent);
            } else {
                anchor_mark(id, ent);
            }
        } else {
            anchor_unmark(id, g_iMarked[id]);
        }
    }

    return FMRES_IGNORED;
}

anchor_move_process(id, ent)
{
    if( g_iCatched[id] != ent ) {
        anchor_move_init(id, ent);
    }

    new Float:vec[3];
    pev(id, pev_v_angle, vec);
    angle_vector(vec, ANGLEVECTOR_FORWARD, vec);

    xs_vec_mul_scalar(vec, g_fDistance[id], vec);

    new Float:origin[3];
    pev(id, pev_origin, origin);

    new Float:view_ofs[3];
    pev(id, pev_view_ofs, view_ofs);

    xs_vec_add(origin, view_ofs, origin);
    xs_vec_add(origin, vec, vec);

    set_pev(ent, pev_origin, vec);

    new classname[32];
    pev(ent, pev_classname, classname, charsmax(classname));

    new box = pev(ent, pev_owner);

    if(equal(classname, SELECTED_ANCHOR_CLASSNAME)) {
        box_update_origin(box, vec);
        return;
    }

    
    new num1 = pev(ent, pev_iuser4);

    new num2 = (~num1) & 0b111;
    new ent2 = get_anchor(box, num2);

    new Float:vec2[3];
    pev(ent2, pev_origin, vec2);

    box_update_size(box, vec, vec2, num1);
}
box_update_size(box, const Float:vec[3], const Float:vec2[3], anchor = -1)
{
    new Float:mins[3];
    mins[0] = floatmin(vec[0], vec2[0]);
    mins[1] = floatmin(vec[1], vec2[1]);
    mins[2] = floatmin(vec[2], vec2[2]);

    new Float:maxs[3];
    maxs[0] = floatmax(vec[0], vec2[0]);
    maxs[1] = floatmax(vec[1], vec2[1]);
    maxs[2] = floatmax(vec[2], vec2[2]);

    anchor != 0b000 && box_update_anchors_entity(box, 0b000, mins[0], mins[1], mins[2]);
    anchor != 0b001 && box_update_anchors_entity(box, 0b001, mins[0], mins[1], maxs[2]);
    anchor != 0b010 && box_update_anchors_entity(box, 0b010, mins[0], maxs[1], mins[2]);
    anchor != 0b011 && box_update_anchors_entity(box, 0b011, mins[0], maxs[1], maxs[2]);
    anchor != 0b100 && box_update_anchors_entity(box, 0b100, maxs[0], mins[1], mins[2]);
    anchor != 0b101 && box_update_anchors_entity(box, 0b101, maxs[0], mins[1], maxs[2]);
    anchor != 0b110 && box_update_anchors_entity(box, 0b110, maxs[0], maxs[1], mins[2]);
    anchor != 0b111 && box_update_anchors_entity(box, 0b111, maxs[0], maxs[1], maxs[2]);

    new Float:origin[3];
    xs_vec_add(maxs, mins, origin);
    xs_vec_mul_scalar(origin, 0.5, origin);

    xs_vec_sub(maxs, origin, maxs);
    xs_vec_sub(mins, origin, mins);

    entity_set_origin(box, origin);
    entity_set_size(box, mins, maxs);

    new sanchor = -1;
    if((sanchor = find_ent_by_owner(sanchor, SELECTED_ANCHOR_CLASSNAME, box))) {
        entity_set_origin(sanchor, origin);
    }
}
box_update_origin(box, Float:vec[3])
{
    entity_set_origin(box, vec);

    new Float:mins[3], Float:maxs[3];
    pev(box, pev_absmin, mins);
    pev(box, pev_absmax, maxs);

    box_update_anchors_entity(box, 0b000, mins[0], mins[1], mins[2]);
    box_update_anchors_entity(box, 0b001, mins[0], mins[1], maxs[2]);
    box_update_anchors_entity(box, 0b010, mins[0], maxs[1], mins[2]);
    box_update_anchors_entity(box, 0b011, mins[0], maxs[1], maxs[2]);
    box_update_anchors_entity(box, 0b100, maxs[0], mins[1], mins[2]);
    box_update_anchors_entity(box, 0b101, maxs[0], mins[1], maxs[2]);
    box_update_anchors_entity(box, 0b110, maxs[0], maxs[1], mins[2]);
    box_update_anchors_entity(box, 0b111, maxs[0], maxs[1], maxs[2]);
}
box_update_anchors_entity(box, num, Float:x, Float:y, Float:z)
{
    new ent = get_anchor(box, num);

    if( is_valid_ent(ent) ) {
        new Float:origin[3];
        origin[0] = x;
        origin[1] = y;
        origin[2] = z;

        entity_set_origin(ent, origin);
    }
}
anchor_mark(id, ent)
{
    g_iMarked[id] = ent;
    set_pev(ent, pev_scale, 0.35);
}
anchor_unmark(id, ent)
{
    g_iMarked[id] = 0;
    set_pev(ent, pev_scale, 0.25);
}
anchor_move_init(id, ent)
{
    new Float:origin[3];
    pev(id, pev_origin, origin);

    new Float:view_ofs[3];
    pev(id, pev_view_ofs, view_ofs);

    xs_vec_add(origin, view_ofs, origin);

    new Float:eorigin[3];
    pev(ent, pev_origin, eorigin);

    g_fDistance[id] = get_distance_f(origin, eorigin);
    g_iCatched[id] = ent;

    set_rendering(ent, kRenderFxGlowShell, 255, 0, 0, kRenderTransAdd, 255);


    /* static szClass[32];
    new box = pev(ent, pev_owner);
    for( new i = 0; i < giZonesP; i++ ) {
        if( giZones[i] == box ) {
            giZonesLast[id] = i;


            pev(box, PEV_TYPE, szClass, 31);
            gszType[id] = getTypeId(szClass);
            refreshMenu(id);
            break;
        }
    } */

    // BOX_History_Push(pev(ent, pev_owner) );
}
anchor_move_uninit(id, ent)
{
    g_fDistance[id] = 0.0;
    g_iCatched[id] = 0;

    set_rendering(ent, kRenderFxNone, 0, 150, 0, kRenderTransAdd, 255);
}


// Touch Mechanic

public fwBoxTouch(box, ent)
{
    new Array:a = Array:pev(box, pev_iuser3);

    if(ArrayFindValue(a, ent) == -1) {
        ArrayPushCell(a, ent);
        box_start_touch(box, ent);
    }

    return PLUGIN_CONTINUE;
}

public Box_Think(box)
{
    new Float:gametime = get_gametime();
    new Array:a = Array:pev(box, pev_iuser3);
    new ent;
    for(new i = ArraySize(a) - 1; i >= 0; i--) {
        ent = ArrayGetCell(a, i);

        if(!pev_valid(ent)) {
            box_invalid_touch(box, ent);
            ArrayDeleteItem(a, i);
            continue;
        }

        new Float:d = fm_boxents_distance(box, ent);

        if(d > 0.0) {
            box_end_touch(box, ent);
            ArrayDeleteItem(a, i);
        }
    }

    set_pev(box, pev_nextthink, gametime + BOX_THINK_TIMER);
}

// Forwards

box_start_touch(box, ent)
{
    client_print(0, print_chat, "box %d, ent %d, start touch, t %f", box, ent, get_gametime());
    console_print(0, "%f :: box %d, ent %d, start touch", get_gametime(), box, ent);

    //TODO: forwards api
}
box_end_touch(box, ent)
{
    client_print(0, print_chat, "box %d, ent %d, end touch, t %f", box, ent, get_gametime());
    console_print(0, "%f :: box %d, ent %d, end touch", get_gametime(), box, ent);

    //TODO: forwards api
}
box_invalid_touch(box, ent)
{
    console_print(0, "%f :: box %d, ent %d, invalid ent", get_gametime(), box, ent);

    //TODO: forwards api
}
