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

/**
 * Creates a box of the specified type with the specified origin, minimums, and maximums.
 *
 * @param type      The type of the box.
 * @param origin    The origin of the box.
 * @param mins      The minimums of the box.
 * @param maxs      The maximums of the box.
 */
native bwb_create_box(const type[], Float:origin[3], Float:mins[3], Float:maxs[3]);

/**
 * Registers a box type with the specified type and color.
 *
 * @param type      The type of the box.
 * @param color     The color of the box.
 */
native bwb_register_box_type(const type[], color[3] = {255, 255, 255});

/**
 * Gets the index of the specified box type.
 *
 * @param type      The type of the box.
 *
 * @return          The index of the box type.
 */
native bwb_get_type_index(const type[]);

/**
 * Gets the type of the specified box.
 *
 * @param box       The index of the box.
 * @param type      The type of the box.
 * @param len       The length of the type of the box.
 */
native bwb_get_box_type(box, type[], len);

/**
 * Called when an entity starts touching a box.
 *
 * @param box           The index of the box.
 * @param ent           The entity that is touching the box.
 * @param type_index    The index of the box type.
 */
forward bwb_box_start_touch(box, ent, type_index);

/**
 * Called when an entity stops touching a box.
 *
 * @param box           The index of the box.
 * @param ent           The entity that stopped touching the box.
 * @param type_index    The index of the box type.
 */
forward bwb_box_stop_touch(box, ent, type_index);

/**
 * Called when an entity touches a box.
 *
 * @param box           The index of the box.
 * @param ent           The entity that is touching the box.
 * @param type_index    The index of the box type.
 */
forward bwb_box_touch(box, ent, type_index);

/**
 * Called when an entity invalidly touches a box.
 *
 * @param box           The index of the box.
 * @param ent           The entity that invalidly touched the box.
 * @param type_index    The index of the box type.
 */
forward bwb_box_invalid_touch(box, ent, type_index);

/**
 * Called when a box is created.
 *
 * @param box           The index of the box.
 * @param type          The type of the box.
 */
forward bwb_box_created(box, const type[]);

/**
 * Called when a box is deleted.
 *
 * @param box           The index of the box.
 * @param type          The type of the box.
 */
forward bwb_box_deleted(box, const type[]);
