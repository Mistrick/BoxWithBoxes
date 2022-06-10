// Credits: R3X@Box System
#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <xs>

#include <box_with_boxes_stocks>

#define PLUGIN "Box with Boxes"
#define AUTHOR "Mistrick"
#define VERSION "0.0.6"

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

enum _:TypeStruct {
    Type[32],
    Color[3]
};

new type_info[TypeStruct];
new Array:g_aTypes;

enum Forwards {
    StartTouch,
    StopTouch,
    FrameTouch,
    BoxCreated,
    BoxDeleted,
    InvalidTouch
};

new g_hForwards[Forwards];

enum _:HistoryStruct {
    BoxEnt,
    Float:AbsMins[3],
    Float:AbsMaxs[3]
};
new Array:g_aHistory;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_clcmd("bwb", "cmd_bwb", ADMIN_CFG);
    register_clcmd("radio1", "cmd_undo");

    register_think(BOX_CLASSNAME, "fwd_box_think");

    register_forward(FM_TraceLine, "fwd_trace_line", 1);
    register_forward(FM_PlayerPreThink, "fwd_player_prethink", 1);

    register_touch(BOX_CLASSNAME, "*", "fwd_box_touch");

    g_hForwards[StartTouch] = CreateMultiForward("bwb_box_start_touch", ET_STOP, FP_CELL, FP_CELL, FP_STRING);
    g_hForwards[StopTouch] = CreateMultiForward("bwb_box_stop_touch", ET_STOP, FP_CELL, FP_CELL, FP_STRING);
    g_hForwards[FrameTouch] = CreateMultiForward("bwb_box_touch", ET_STOP, FP_CELL, FP_CELL, FP_STRING);
    g_hForwards[BoxCreated] = CreateMultiForward("bwb_box_created", ET_STOP, FP_CELL, FP_STRING);
    g_hForwards[BoxDeleted] = CreateMultiForward("bwb_box_deleted", ET_STOP, FP_CELL, FP_STRING);
    g_hForwards[InvalidTouch] = CreateMultiForward("bwb_box_invalid_touch", ET_STOP, FP_CELL, FP_CELL, FP_STRING);

    g_aHistory = ArrayCreate(HistoryStruct, 1);
}
public plugin_precache()
{
    precache_model(g_szModel);

    g_iSpriteLine = precache_model("sprites/white.spr");
}
public plugin_natives()
{
    register_library("box_with_boxes");

    register_native("bwb_create_box", "native_create_box");
}
public native_create_box(plugin, params)
{
    enum {
        arg_type = 1,
        arg_origin,
        arg_mins,
        arg_maxs
    };

    new type[32];
    get_string(arg_type, type, charsmax(type));
    new Float:origin[3];
    get_array_f(arg_origin, origin, sizeof(origin));
    new Float:mins[3];
    get_array_f(arg_mins, mins, sizeof(mins));
    new Float:maxs[3];
    get_array_f(arg_maxs, maxs, sizeof(maxs));

    create_box(origin, type, mins, maxs);
}
public plugin_cfg()
{
    load_types();
}
load_types()
{
    g_aTypes = ArrayCreate(TypeStruct, 1);

    new INIParser:parser = INI_CreateParser();

    INI_SetParseEnd(parser, "ini_parse_end");
    INI_SetReaders(parser, "ini_key_value", "ini_new_section");
    new bool:result = INI_ParseFile(parser, "addons/amxmodx/configs/box_with_boxes/types.ini");
    
    if(!result) {
        // TODO
    }
}
public ini_new_section(INIParser:handle, const section[], bool:invalid_tokens, bool:close_bracket, bool:extra_tokens, curtok, any:data)
{
    if(type_info[Type]) {
        // push type
        server_print("Type: %s, rgb %d %d %d", type_info[Type], type_info[Color][0], type_info[Color][1], type_info[Color][2]);
        ArrayPushArray(g_aTypes, type_info);
    }
    
    copy(type_info[Type], charsmax(type_info[Type]), section);

    return true;
}
public ini_key_value(INIParser:handle, const key[], const value[], bool:invalid_tokens, bool:equal_token, bool:quotes, curtok, any:data)
{
    new k[32];
    copy(k, charsmax(k), key);
    remove_quotes(k);
    if(equal(k, "color")) {
        new color[3];
        parse_color(value, color);
        /* for(new i; i < 3; i++) {
            type_info[Color][i] = color[i];
        } */
        type_info[Color] = color;
    }

    return true;
}
public ini_parse_end(INIParser:handle, bool:halted, any:data)
{
    if(type_info[Type]) {
        // push type
        server_print("Type: %s, rgb %d %d %d", type_info[Type], type_info[Color][0], type_info[Color][1], type_info[Color][2]);
        ArrayPushArray(g_aTypes, type_info);
    }

    INI_DestroyParser(handle);
}

stock parse_color(const string[], color[3])
{
    new r[4], g[4], b[4];
    parse(string, r, charsmax(r), g, charsmax(g), b, charsmax(b));
    color[0] = str_to_num(r);
    color[1] = str_to_num(g);
    color[2] = str_to_num(b);
}

public cmd_bwb(id, level, cid)
{
    if(!cmd_access(id, level, cid, 1)) {
        return PLUGIN_HANDLED;
    }

    show_bwb_menu(id);

    return PLUGIN_HANDLED;
}

show_bwb_menu(id)
{
    new menu = menu_create("Box with Boxes", "bwb_menu_handler");

    menu_additem(menu, "Create box", "1");

    if(g_iSelectedBox[id]) {
        new type[32], index[32];
        pev(g_iSelectedBox[id], PEV_ID, index, charsmax(index));
        pev(g_iSelectedBox[id], PEV_TYPE, type, charsmax(type));
        menu_additem(menu, fmt("Select next \y[Current: %s, Type: %s]", index, type), "3");
    } else {
        menu_additem(menu, "Select next", "3");
    }

    menu_additem(menu, "Select the nearest", "4");
    menu_additem(menu, "Remove selected box", "5");
    menu_additem(menu, "Move to selected box", "6");
    menu_additem(menu, "Change box type", "7");

    // TODO: player noclip

    menu_display(id, menu);

    if(!g_bEditMode[id]) {
        g_bEditMode[id] = true;
        switch_edit_mode(id);
    }

    return PLUGIN_HANDLED;
}
public bwb_menu_handler(id, menu, item)
{
    if(item == MENU_EXIT) {
        menu_destroy(menu);
        g_bEditMode[id] = false;
        switch_edit_mode(id);
        return PLUGIN_HANDLED;
    }

    new item_info[8];
    menu_item_getinfo(menu, item, _, item_info, charsmax(item_info));
    menu_destroy(menu);

    new index = str_to_num(item_info);

    switch(index) {
        case 1: {
            new Float:origin[3];
            pev(id, pev_origin, origin);
            new ent = create_box(origin);

            if(pev_valid(g_iSelectedBox[id])) {
                // remove_task(g_iSelectedBox[id]);
                // remove_anchors(g_iSelectedBox[id]);
                remove_selected_anchor(id);
            }
            
            g_iSelectedBox[id] = ent;

            if(g_bEditMode[id]) {
                set_task(BOX_VISUAL_THINK_TIMER, "box_visual_think", ent, .flags = "b");
                create_anchors(ent);
                // create_selected_anchor(id, g_iSelectedBox[id]);
            }
        }
        case 2: {
            g_bEditMode[id] = !g_bEditMode[id];

            if(g_bEditMode[id]) {
                new ent = -1;
                while((ent = find_ent_by_class(ent, BOX_CLASSNAME))) {
                    set_task(BOX_VISUAL_THINK_TIMER, "box_visual_think", ent, .flags = "b");
                    create_anchors(ent);
                }

                if(pev_valid(g_iSelectedBox[id])) {
                    /* ent = g_iSelectedBox[id];
                    set_task(BOX_VISUAL_THINK_TIMER, "box_visual_think", ent, .flags = "b");
                    create_anchors(ent); */

                    create_selected_anchor(id, g_iSelectedBox[id]);
                }
            } else {
                new ent = -1;
                while((ent = find_ent_by_class(ent, BOX_CLASSNAME))) {
                    remove_task(ent);
                    remove_anchors(ent);
                }
                if(pev_valid(g_iSelectedBox[id])) {
                    /* new ent = g_iSelectedBox[id];
                    remove_task(ent);
                    remove_anchors(ent); */

                    remove_selected_anchor(id);
                }
            }
        }
        case 3: {
            new ent = g_iSelectedBox[id] ? g_iSelectedBox[id] : -1;
            new start = ent;
            new found;

            while(!(start == -1 && ent == 0) && !found) {
                while((ent = find_ent_by_class(ent, BOX_CLASSNAME))) {

                    /* if(pev_valid(g_iSelectedBox[id])) {
                        remove_task(g_iSelectedBox[id]);
                        remove_anchors(g_iSelectedBox[id]);
                    } */

                    g_iSelectedBox[id] = ent;
                    found = true;
                    break;
                }
            }

            if(found) {
                remove_selected_anchor(id);
                if(g_bEditMode[id]) {
                    create_selected_anchor(id, ent);

                    /* set_task(BOX_VISUAL_THINK_TIMER, "box_visual_think", ent, .flags = "b");
                    create_anchors(ent); */
                }
            }
        }
        case 4: {
            new nearest;
            new Float:ndist, Float:dist;

            new ent = -1;
            while((ent = find_ent_by_class(ent, BOX_CLASSNAME))) {
                dist = entity_range(id, ent);
                if(!nearest || dist < ndist) {
                    ndist = dist;
                    nearest = ent;
                }
            }

            if(nearest) {
                remove_selected_anchor(id);
                if(g_bEditMode[id]) {
                    /* if(pev_valid(g_iSelectedBox[id])) {
                        remove_task(g_iSelectedBox[id]);
                        remove_anchors(g_iSelectedBox[id]);
                    } */

                    create_selected_anchor(id, nearest);

                    /* set_task(BOX_VISUAL_THINK_TIMER, "box_visual_think", nearest, .flags = "b");
                    create_anchors(nearest); */
                }

                g_iSelectedBox[id] = nearest;
            }
        }
        case 5: {
            if(pev_valid(g_iSelectedBox[id])) {
                new ent = g_iSelectedBox[id];
                remove_task(ent);
                remove_anchors(ent);
                remove_selected_anchor(id);

                remove_box(ent);
                g_iSelectedBox[id] = 0;
            }
        }
        case 6: {
            if(pev_valid(g_iSelectedBox[id])) {
                new ent = g_iSelectedBox[id];
                new Float:origin[3];
                pev(ent, pev_origin, origin);
                set_pev(id, pev_origin, origin);
            }
        }
        case 7: {
            if(pev_valid(g_iSelectedBox[id])) {
                show_type_menu(id);
                return PLUGIN_HANDLED;
            }
        }
    }

    show_bwb_menu(id);

    return PLUGIN_HANDLED;
}

show_type_menu(id)
{
    new type[32], index[32];
    pev(g_iSelectedBox[id], PEV_ID, index, charsmax(index));
    pev(g_iSelectedBox[id], PEV_TYPE, type, charsmax(type));

    new menu = menu_create(fmt("Type menu^nCurrent box: %s, type: %s", index, type), "type_menu_handler");

    for(new i, size = ArraySize(g_aTypes); i < size; i++) {
        ArrayGetArray(g_aTypes, i, type_info);
        menu_additem(menu, type_info[Type]);
    }

    menu_display(id, menu);
}

public type_menu_handler(id, menu, item)
{
    if(item == MENU_EXIT) {
        menu_destroy(menu);
        if(is_user_connected(id)) {
            show_bwb_menu(id);
        }
        return PLUGIN_HANDLED;
    }

    new item_name[32];
    menu_item_getinfo(menu, item, _, _, _, item_name, charsmax(item_name));
    menu_destroy(menu);

    if(pev_valid(g_iSelectedBox[id])) {
        set_pev(g_iSelectedBox[id], PEV_TYPE, item_name);
    }

    // TODO: forward type changed

    show_bwb_menu(id);

    return PLUGIN_HANDLED;
}

switch_edit_mode(id)
{
    if(g_bEditMode[id]) {
        new ent = -1;
        while((ent = find_ent_by_class(ent, BOX_CLASSNAME))) {
            set_task(BOX_VISUAL_THINK_TIMER, "box_visual_think", ent, .flags = "b");
            create_anchors(ent);
        }

        if(pev_valid(g_iSelectedBox[id])) {
            /* ent = g_iSelectedBox[id];
            set_task(BOX_VISUAL_THINK_TIMER, "box_visual_think", ent, .flags = "b");
            create_anchors(ent); */

            create_selected_anchor(id, g_iSelectedBox[id]);
        }
    } else {
        new ent = -1;
        while((ent = find_ent_by_class(ent, BOX_CLASSNAME))) {
            remove_task(ent);
            remove_anchors(ent);
        }
        if(pev_valid(g_iSelectedBox[id])) {
            /* new ent = g_iSelectedBox[id];
            remove_task(ent);
            remove_anchors(ent); */

            remove_selected_anchor(id);
        }
    }
}

public cmd_undo(id)
{
    if(!g_bEditMode[id]) {
        return PLUGIN_CONTINUE;
    }

    box_history_pop();

    return PLUGIN_HANDLED;
}

create_box(const Float:origin[3], const class[] = "box", const Float:mins[3] = DEFAULT_MINSIZE, const Float:maxs[3] = DEFAULT_MAXSIZE)
{
    new ent = create_entity("info_target");

    entity_set_string(ent, EV_SZ_classname, BOX_CLASSNAME);
    set_pev(ent, PEV_TYPE, class);

    set_pev(ent, PEV_ID, fmt("Box#%d", giUNIQUE++));

    DispatchSpawn(ent);

    entity_set_model(ent, g_szModel);

    set_pev(ent, pev_effects, EF_NODRAW);
    set_pev(ent, pev_solid, SOLID_TRIGGER);
    set_pev(ent, pev_movetype, MOVETYPE_NONE);
    set_pev(ent, pev_enemy, 1);

    set_pev(ent, pev_nextthink, get_gametime() + 0.1);

    // touch info
    new Array:a = ArrayCreate(1, 1);
    set_pev(ent, pev_iuser3, a);

    entity_set_origin(ent, origin);
    entity_set_size(ent, mins, maxs);

    new ret;
    ExecuteForward(g_hForwards[BoxCreated], ret, ent, class);

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
    while((ent = find_ent_by_owner(ent, ANCHOR_CLASSNAME, box))) {
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
    while((ent = find_ent_by_class(ent, SELECTED_ANCHOR_CLASSNAME))) {
        if(pev(ent, pev_iuser3) == id) {
            remove_entity(ent);
        }
    }
}

remove_box(box)
{
    // TODO: add forward
    new type[32];
    pev(box, PEV_TYPE, type, charsmax(type));

    new ret;
    ExecuteForward(g_hForwards[BoxDeleted], ret, box, type);

    new Array:a = Array:pev(box, pev_iuser3);
    ArrayDestroy(a);
    remove_entity(box);
}

// Visual
public box_visual_think(ent)
{
    new Float:mins[3], Float:maxs[3];
    pev(ent, pev_absmin, mins);
    pev(ent, pev_absmax, maxs);

    new color[3];
    get_type_color(ent, color);

    _draw_line(color, maxs[0], maxs[1], maxs[2], maxs[0], maxs[1], mins[2]);
    _draw_line(color, mins[0], maxs[1], maxs[2], mins[0], maxs[1], mins[2]);
    _draw_line(color, maxs[0], mins[1], maxs[2], maxs[0], mins[1], mins[2]);
    _draw_line(color, mins[0], mins[1], maxs[2], mins[0], mins[1], mins[2]);

    _draw_line(color, maxs[0], maxs[1], maxs[2], mins[0], maxs[1], maxs[2]);
    _draw_line(color, maxs[0], maxs[1], mins[2], mins[0], maxs[1], mins[2]);
    _draw_line(color, maxs[0], mins[1], maxs[2], mins[0], mins[1], maxs[2]);
    _draw_line(color, maxs[0], mins[1], mins[2], mins[0], mins[1], mins[2]);

    _draw_line(color, maxs[0], maxs[1], maxs[2], maxs[0], mins[1], maxs[2]);
    _draw_line(color, mins[0], maxs[1], maxs[2], mins[0], mins[1], maxs[2]);
    _draw_line(color, maxs[0], maxs[1], mins[2], maxs[0], mins[1], mins[2]);
    _draw_line(color, mins[0], maxs[1], mins[2], mins[0], mins[1], mins[2]);

    _draw_line(color, mins[0], mins[1], mins[2], maxs[0], maxs[1], maxs[2]);
}

_draw_line(color[3], Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    new Float:start[3];
    start[0] = x1;
    start[1] = y1;
    start[2] = z1;

    new Float:stop[3];
    stop[0] = x2;
    stop[1] = y2;
    stop[2] = z2;

    draw_line(start, stop, color, g_iSpriteLine);
}

get_type_color(ent, color[3])
{
    if(!pev_valid(ent))
        return 0;

    new type[32];
    pev(ent, PEV_TYPE, type, charsmax(type));

    new r = ArrayFindString(g_aTypes, type);

    if(r != -1) {
        ArrayGetArray(g_aTypes, r, type_info);
        color[0] = type_info[Color][0];
        color[1] = type_info[Color][1];
        color[2] = type_info[Color][2];
    } else {
        color[0] = 50;
        color[1] = 255;
        color[2] = 50;
    }

    return 1;
}


// Move Process
public fwd_player_prethink(id)
{
    if(!g_bEditMode[id]) {
        return FMRES_IGNORED;
    }

    set_pdata_float(id, m_flNextAttack, 1.0, 5);

    if(!is_valid_ent(g_iCatched[id])) {
        return FMRES_IGNORED;
    }

    if(pev(id, pev_button) & IN_ATTACK) {
        anchor_move_process(id, g_iCatched[id]);
    }else {
        anchor_move_uninit(id, g_iCatched[id]);
    }

    return FMRES_IGNORED;
}
public fwd_trace_line(const Float:v1[], const Float:v2[], fNoMonsters, id, ptr)
{
    if(!is_user_alive(id)) {
        return FMRES_IGNORED;
    }

    if(!g_bEditMode[id]) {
        return FMRES_IGNORED;
    }

    new ent = get_tr2(ptr, TR_pHit);

    if(!is_valid_ent(ent)) {
        anchor_unmark(id, g_iMarked[id]);
        return FMRES_IGNORED;
    }

    if(g_iCatched[id]) {
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

    // TODO: settings for delay and distance in menu
    const Float:TIME_DELAY = 0.05;

    new buttons = pev(id, pev_button);
    static Float:last_change;
    if(buttons & IN_USE && get_gametime() > last_change + TIME_DELAY) {
        g_fDistance[id] -= 1.0;
        last_change = get_gametime();
    }

    if(buttons & IN_RELOAD && get_gametime() > last_change + TIME_DELAY) {
        g_fDistance[id] += 1.0;
        last_change = get_gametime();
    }

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

    new box = pev(ent, pev_owner);
    box_history_push(box);
}
anchor_move_uninit(id, ent)
{
    g_fDistance[id] = 0.0;
    g_iCatched[id] = 0;

    set_rendering(ent, kRenderFxNone, 0, 150, 0, kRenderTransAdd, 255);
}

// History
box_history_push(box)
{
    new history_info[HistoryStruct];
    history_info[BoxEnt] = box;
    new Float:mins[3], Float:maxs[3];
    pev(box, pev_absmin, mins);
    pev(box, pev_absmax, maxs);
    history_info[AbsMins] = mins;
    history_info[AbsMaxs] = maxs;

    ArrayPushArray(g_aHistory, history_info);
}
box_history_pop()
{
    new size = ArraySize(g_aHistory);
    if(!size) {
        return;
    }

    new history_info[HistoryStruct];
    ArrayGetArray(g_aHistory, size - 1, history_info);

    new box = history_info[BoxEnt];

    new Float:mins[3], Float:maxs[3];
    for(new i; i < 3; i++) {
        mins[i] = history_info[AbsMins][i];
        maxs[i] = history_info[AbsMaxs][i];
    }

    ArrayDeleteItem(g_aHistory, size - 1);

    box_update_size(box, mins, maxs);
}

// Touch Mechanic

public fwd_box_touch(box, ent)
{
    new Array:a = Array:pev(box, pev_iuser3);

    if(ArrayFindValue(a, ent) == -1) {
        ArrayPushCell(a, ent);
        box_start_touch(box, ent);
    }

    new type[32];
    pev(box, PEV_TYPE, type, charsmax(type));

    new ret;
    ExecuteForward(g_hForwards[FrameTouch], ret, box, ent, type);

    return PLUGIN_CONTINUE;
}

public fwd_box_think(box)
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

        new collision = intersect(box, ent);

        new flags = pev(ent, pev_flags);
        new Float:v[3];
        pev(ent, pev_velocity, v);

        if(!collision || ent > MaxClients && flags & FL_ONGROUND && vector_length(v) == 0.0) {
            box_end_touch(box, ent);
            ArrayDeleteItem(a, i);
        }
    }

    set_pev(box, pev_nextthink, gametime + BOX_THINK_TIMER);
}

// Forwards
box_start_touch(box, ent)
{
    // client_print(0, print_chat, "box %d, ent %d, start touch, t %f", box, ent, get_gametime());
    // console_print(0, "%f :: box %d, ent %d, start touch", get_gametime(), box, ent);

    new type[32];
    pev(box, PEV_TYPE, type, charsmax(type));

    new ret;
    ExecuteForward(g_hForwards[StartTouch], ret, box, ent, type);
}
box_end_touch(box, ent)
{
    // client_print(0, print_chat, "box %d, ent %d, end touch, t %f", box, ent, get_gametime());
    // console_print(0, "%f :: box %d, ent %d, end touch", get_gametime(), box, ent);

    new type[32];
    pev(box, PEV_TYPE, type, charsmax(type));

    new ret;
    ExecuteForward(g_hForwards[StopTouch], ret, box, ent, type);
}
box_invalid_touch(box, ent)
{
    // console_print(0, "%f :: box %d, ent %d, invalid ent", get_gametime(), box, ent);

    new type[32];
    pev(box, PEV_TYPE, type, charsmax(type));

    new ret;
    ExecuteForward(g_hForwards[InvalidTouch], ret, box, ent, type);
}
