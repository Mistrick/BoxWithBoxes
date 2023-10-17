#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <box_with_boxes>

#define PLUGIN "Box Storage"
#define AUTHOR "Mistrick"
#define VERSION "0.0.2"

#pragma semicolon 1

#define BOX_CLASSNAME "bwb"

#define PEV_TYPE pev_netname
#define PEV_ID pev_message

enum BoxStruct {
    Index[32],
    Type[32],
    Float:Origin[3],
    Float:Mins[3],
    Float:Maxs[3]
};

new box_info[BoxStruct];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
}
public plugin_cfg()
{
    load_boxes();
}
load_boxes()
{
    new configsdir[256];
    get_configsdir(configsdir, charsmax(configsdir));
    new map[32];
    get_mapname(map, charsmax(map));

    new INIParser:parser = INI_CreateParser();

    INI_SetParseEnd(parser, "ini_parse_end");
    INI_SetReaders(parser, "ini_key_value", "ini_new_section");
    new bool:result = INI_ParseFile(parser, fmt("%s/box_with_boxes/maps/%s.ini", configsdir, map));
    
    if(!result) {
        // TODO
    }
}
public ini_new_section(INIParser:handle, const section[], bool:invalid_tokens, bool:close_bracket, bool:extra_tokens, curtok, any:data)
{
    if(box_info[Index]) {
        create_box();
    }
    
    copy(box_info[Index], charsmax(box_info[Index]), section);

    return true;
}
public ini_key_value(INIParser:handle, const key[], const value[], bool:invalid_tokens, bool:equal_token, bool:quotes, curtok, any:data)
{
    new k[32];
    copy(k, charsmax(k), key);
    remove_quotes(k);

    if(equal(k, "type")) {
        copy(box_info[Type], charsmax(box_info[Type]), value);
        remove_quotes(box_info[Type]);
    } else if(equal(k, "origin")) {
        new Float:origin[3];
        parse_coords(value, origin);
        box_info[Origin] = origin;
    } else if(equal(k, "mins")) {
        new Float:mins[3];
        parse_coords(value, mins);
        box_info[Mins] = mins;
    } else if(equal(k, "maxs")) {
        new Float:maxs[3];
        parse_coords(value, maxs);
        box_info[Maxs] = maxs;
    }

    return true;
}
public ini_parse_end(INIParser:handle, bool:halted, any:data)
{
    if(box_info[Index]) {
        create_box();
    }

    INI_DestroyParser(handle);
}

create_box()
{
    new Float:origin[3], Float:mins[3], Float:maxs[3];
    for(new i; i < 3; i++) {
        origin[i] = box_info[Origin][i];
        mins[i] = box_info[Mins][i];
        maxs[i] = box_info[Maxs][i];
    }
    bwb_create_box(box_info[Type], origin, mins, maxs);
}

parse_coords(const string[], Float:coords[3])
{
    new x[16], y[16], z[16];
    parse(string, x, charsmax(x), y, charsmax(y), z, charsmax(z));
    coords[0] = str_to_float(x);
    coords[1] = str_to_float(y);
    coords[2] = str_to_float(z);
}

public plugin_end()
{
    save_boxes();
}
save_boxes()
{
    new configsdir[256];
    get_configsdir(configsdir, charsmax(configsdir));
    new map[32];
    get_mapname(map, charsmax(map));
    add(configsdir, charsmax(configsdir), fmt("/box_with_boxes/maps/%s.ini", map));

    new f = fopen(configsdir, "w");
    if(!f) {
        log_amx("Can't create or open save file <%s>.", configsdir);
        return;
    }

    new ent = -1;
    new bool:found;

    while((ent = find_ent_by_class(ent, BOX_CLASSNAME))) {
        found = true;
        new type[32], index[32];
        pev(ent, PEV_ID, index, charsmax(index));
        pev(ent, PEV_TYPE, type, charsmax(type));
        new Float:mins[3], Float:maxs[3];
        pev(ent, pev_mins, mins);
        pev(ent, pev_maxs, maxs);
        new Float:origin[3];
        pev(ent, pev_origin, origin);

        fputs(f, fmt("[%s]^n", index));
        fputs(f, fmt("^"type^" = ^"%s^"^n", type));
        fputs(f, fmt("^"origin^" = ^"%f %f %f^"^n", origin[0], origin[1], origin[2]));
        fputs(f, fmt("^"mins^" = ^"%f %f %f^"^n", mins[0], mins[1], mins[2]));
        fputs(f, fmt("^"maxs^" = ^"%f %f %f^"^n", maxs[0], maxs[1], maxs[2]));
    }
    if(f) {
        if(!found && file_exists(configsdir)) {
            delete_file(configsdir);
        }
        fclose(f);
    }
}
