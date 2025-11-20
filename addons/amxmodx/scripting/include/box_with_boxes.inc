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
 * Creates a new box entity.
 *
 * @param type          Type name of the box to create. This type should be registered.
 * @param origin        A vector representing the world coordinates for the box's center.
 * @param mins          A vector for the minimum bounding box coordinates, relative to the origin.
 * @param maxs          A vector for the maximum bounding box coordinates, relative to the origin.
 *
 * @return              Entity index of the newly created box, or 0 on failure.
 */
native bwb_create_box(const type[], Float:origin[3], Float:mins[3], Float:maxs[3]);

/**
 * Registers a new box type or retrieves index of an existing one.
 * This allows for custom categorization and visualization of boxes.
 *
 * @param type          Name of the type to register (e.g., "teleport", "damage_zone").
 * @param color         Optional RGB color array for visualizing the box in edit mode.
 *
 * @return              Unique index for Registered type.
 */
native bwb_register_box_type(const type[], color[3] = {255, 255, 255});

/**
 * Retrieves index of a registered box type.
 *
 * @param type          Name of the type to look up.
 *
 * @return              Index of the type if found, -1 otherwise.
 */
native bwb_get_type_index(const type[]);

/**
 * Gets the type name of a given box entity.
 *
 * @param box           Entity index of the box.
 * @param type          Output buffer to store the type name.
 * @param len           Maximum length of the output buffer.
 *
 * @noreturn
 */
native bwb_get_box_type(box, type[], len);

/**
 * Called when an entity starts touching a box (i.e., on the first frame of collision).
 *
 * @param box           Entity index of the box being touched.
 * @param ent           Entity index that is touching the box.
 * @param type_index    Registered index of the box's type.
 *
 * @noreturn
 */
forward bwb_box_start_touch(box, ent, type_index);

/**
 * Called when an entity stops touching a box (i.e., on the first frame it is no longer colliding).
 *
 * @param box           Entity index of the box.
 * @param ent           Entity index that was touching the box.
 * @param type_index    Registered index of the box's type.
 *
 * @noreturn
 */
forward bwb_box_stop_touch(box, ent, type_index);

/**
 * Called every frame an entity is touching/colliding with a box.
 * This is called continuously between bwb_box_start_touch and bwb_box_stop_touch.
 *
 * @param box           Entity index of the box being touched.
 * @param ent           Entity index that is touching the box.
 * @param type_index    Registered index of the box's type.
 *
 * @noreturn
 */
forward bwb_box_touch(box, ent, type_index);

/**
 * Called when an entity that was touching a box becomes invalid.
 * This typically happens if a player disconnects or an entity is removed
 * while inside a box volume.
 *
 * @note The 'ent' parameter is an invalid entity index. Do not use it
 *       with any engine functions that expect a valid entity.
 *
 * @param box           Entity index of the box.
 * @param ent           Entity index (now invalid) that was touching the box.
 * @param type_index    Registered index of the box's type.
 *
 * @noreturn
 */
forward bwb_box_invalid_touch(box, ent, type_index);

/**
 * Called after a new box has been created.
 *
 * @param box           Entity index of the newly created box.
 * @param type          Type name of the created box.
 *
 * @noreturn
 */
forward bwb_box_created(box, const type[]);

/**
 * Called just before a box is deleted.
 *
 * @param box           Entity index of the box being deleted.
 * @param type          Type name of the box being deleted.
 *
 * @noreturn
 */
forward bwb_box_deleted(box, const type[]);