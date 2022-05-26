#if defined _box_with_boxes_stocks_included
  #endinput
#endif
#define _box_with_boxes_stocks_included

stock intersect(a, b) {
    new Float:amins[3], Float:amaxs[3];
    pev(a, pev_absmin, amins);
    pev(a, pev_absmax, amaxs);
    new Float:bmins[3], Float:bmaxs[3];
    pev(b, pev_absmin, bmins);
    pev(b, pev_absmax, bmaxs);

    return (amins[0] <= bmaxs[0] && amaxs[0] >= bmins[0]) &&
         (amins[1] <= bmaxs[1] && amaxs[1] >= bmins[1]) &&
         (amins[2] <= bmaxs[2] && amaxs[2] >= bmins[2]);
}

stock Float:fm_boxes_distance(const Float:mins1[3], const Float:maxs1[3], const Float:mins2[3], const Float:maxs2[3]) {
    new Float:dist[3];
    for (new i = 0; i < 3; ++i) {
        if (mins1[i] > maxs2[i])
            dist[i] = mins1[i] - maxs2[i];
        else if (mins2[i] > maxs1[i])
            dist[i] = mins2[i] - maxs1[i];
    }

    return vector_length(dist);
}

stock Float:fm_boxents_distance(boxent1, boxent2) {
    new Float:mins1[3], Float:maxs1[3];
    pev(boxent1, pev_absmin, mins1);
    pev(boxent1, pev_absmax, maxs1);

    new Float:mins2[3], Float:maxs2[3];
    pev(boxent2, pev_absmin, mins2);
    pev(boxent2, pev_absmax, maxs2);

    return fm_boxes_distance(mins1, maxs1, mins2, maxs2);
}

stock draw_line(Float:start[], Float:stop[], iColor[3], sprite_line)
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(0);
    engfunc(EngFunc_WriteCoord, start[0]);
    engfunc(EngFunc_WriteCoord, start[1]);
    engfunc(EngFunc_WriteCoord, start[2]);
    engfunc(EngFunc_WriteCoord, stop[0]);
    engfunc(EngFunc_WriteCoord, stop[1]);
    engfunc(EngFunc_WriteCoord, stop[2]);
    write_short(sprite_line);
    write_byte(1);
    write_byte(5);
    write_byte(5);
    write_byte(7);
    write_byte(0);
    write_byte(iColor[0]); /* RED */
    write_byte(iColor[1]); /* GREEN */
    write_byte(iColor[2]); /* BLUE */
    write_byte(250);       /* brightness */
    write_byte(5);
    message_end();
}
