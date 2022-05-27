#if defined _box_with_boxes_included
  #endinput
#endif
#define _box_with_boxes_included

#if AMXX_VERSION_NUM >= 175
    #pragma reqlib box_with_boxes
    #if !defined AMXMODX_NOAUTOLOAD
        #pragma loadlib box_with_boxes
    #endif
#else
    #pragma library box_with_boxes
#endif

/*
* TODO
*/
native bwb_create_box(const type[], Float:origin[3], Float:mins[3], Float:maxs[3]);
