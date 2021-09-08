tool
extends EditorPlugin

const Util = preload("utilities.gd")
var debug_show_collider:bool = false

var ui_sidebar
var ui_activate_button
var brush_cursor

var edit_mode:bool setget _set_edit_mode

var current_tool = "_paint_tool"
var process_drawing:bool = false
var brush_size:float = 1
var calculated_size:float = 1.0
var brush_density:float = 1.0;

var current_multimesh: MultiMeshInstance
var editable_object:bool = false

var raycast_hit:bool = false
var hit_position: Vector3
var hit_normal

export(Vector2) var blade_width = Vector2(0.1, 0.2);
export(Vector2) var blade_height = Vector2(1, 1.5);
export(Vector2) var sway_yaw = Vector2(0.0, 10.0);
export(Vector2) var sway_pitch = Vector2(0.0, 10.0);


func handles(obj) -> bool:
    return editable_object;


func forward_spatial_gui_input(camera, event) -> bool:
    if !edit_mode:
        return false

    _display_brush()
    _raycast(camera, event)


    if raycast_hit:
        return _user_input(event) #the returned value blocks or unblocks the default input from godot
    else:
        return false

func _user_input(event) -> bool:
    if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
        if event.is_pressed():
            process_drawing = true
            _process_drawing()
            return true
        else:
            process_drawing = false
            _set_collision()
            return false
    else:
        return false

func _process_drawing():
    while process_drawing:
        _paint_tool();
        yield(get_tree().create_timer(1.0), "timeout")

func _display_brush() -> void:    
    if raycast_hit:
        brush_cursor.visible = true
        brush_cursor.translation = hit_position        
        (brush_cursor.mesh as SphereMesh).radius = brush_size;
    else:
        brush_cursor.visible = false

func _raycast(camera:Camera, event:InputEvent) -> void:
    if event is InputEventMouse:
        #RAYCAST FROM CAMERA:
        var ray_origin = camera.project_ray_origin(event.position)
        var ray_dir = camera.project_ray_normal(event.position)
        var ray_distance = camera.far

        var space_state =  get_viewport().world.direct_space_state
        var hit = space_state.intersect_ray(ray_origin, ray_origin + ray_dir * ray_distance, [])
        #IF RAYCAST HITS A DRAWABLE SURFACE:
        if !hit:
            return
        if hit:
            raycast_hit = true
            hit_position = hit.position
            hit_normal = hit.normal

func _paint_tool() -> void:
    var multimesh = current_multimesh.multimesh;
    var cursor_position = hit_position;
    var cursor_radius = (brush_cursor.mesh as SphereMesh).radius;
    var overlapping_instances = 0;

    # preserve existing instances
    # and count existing density
    var prior_transforms = []
    for i in multimesh.instance_count:
        var transform = multimesh.get_instance_transform(i);
        prior_transforms.append(transform);
        if Util.is_point_inside_circle(cursor_position, cursor_radius, transform.origin):
            overlapping_instances += 1;
    
    var instances_to_create = brush_density - overlapping_instances;
    print('brush_density: ' + String(brush_density));
    print('overlapping instances: ' + String(overlapping_instances));
    if instances_to_create <= 0:
        return;
    
    multimesh.instance_count += instances_to_create;
    
    # add new instances
    for i in instances_to_create:
        var mesh_index = multimesh.instance_count - (i + 1);
        var position = Util.rand_point_inside_circle(cursor_position, cursor_radius);
        var basis = Basis(Vector3.UP, deg2rad(rand_range(0,359)));
        multimesh.set_instance_transform(mesh_index, Transform(basis, position));
        multimesh.set_instance_custom_data(mesh_index, Color(
            rand_range(blade_width.x, blade_width.y),
            rand_range(blade_height.x, blade_height.y),
            deg2rad(rand_range(sway_pitch.x, sway_pitch.y)),
            deg2rad(rand_range(sway_yaw.x, sway_yaw.y))
         ));        
    
    # reset old instances
    for i in prior_transforms.size()-1:
        multimesh.set_instance_transform(i, prior_transforms[i]);
        multimesh.set_instance_custom_data(i, Color(
          rand_range(blade_width.x, blade_width.y),
          rand_range(blade_height.x, blade_height.y),
          deg2rad(rand_range(sway_pitch.x, sway_pitch.y)),
          deg2rad(rand_range(sway_yaw.x, sway_yaw.y)))
        );    
    
    #multimesh.set_instance_transform(mesh_index, Transform(basis, position));
    #multimesh.set_instance_custom_data(mesh_index, Color(
    #    rand_range(blade_width.x, blade_width.y),
    #    rand_range(blade_height.x, blade_height.y),
    #    deg2rad(rand_range(sway_pitch.x, sway_pitch.y)),
    #    deg2rad(rand_range(sway_yaw.x, sway_yaw.y)))
    #);

func _set_collision() -> void:
    print('set_collision');
    # var temp_collision:StaticBody = current_multimesh.get_node_or_null(current_multimesh.name + "_col")
    # if (temp_collision == null):        
        # current_multimesh.create_trimesh_collision()
        # temp_collision = current_multimesh.get_node(current_multimesh.name + "_col")
        # temp_collision.set_collision_layer(524288)
        # temp_collision.set_collision_mask(524288)
    # else:
    # 	temp_collision.free()
    # 	current_multimesh.create_trimesh_collision()
    # 	temp_collision = current_multimesh.get_node(current_multimesh.name + "_col")
    # 	temp_collision.set_collision_layer(524288)
    # 	temp_collision.set_collision_mask(524288)
    
    # if !debug_show_collider:
    # 	temp_collision.hide()

func _delete_collision() -> void:
    print('delete_collision');
    # var temp_collision:StaticBody = current_multimesh.get_node_or_null(current_multimesh.name + "_col")
    # if (temp_collision != null):
    #     temp_collision.free()

func _set_edit_mode(value) -> void:
    print('Edit mode: ' + String(value));
    edit_mode = value
    if !current_multimesh:
        return
        if (!current_multimesh.mesh):
            return

    if edit_mode:
        _set_collision()
    else:
        ui_sidebar.hide()
        _delete_collision()

func _make_local_copy() -> void:
    print('make_local_copy');
    # current_multimesh.mesh = current_multimesh.mesh.duplicate(false)

func _selection_changed() -> void:
    print('selection_changed');
    ui_activate_button._set_ui_sidebar(false)

    var selection = get_editor_interface().get_selection().get_selected_nodes()
    print('selection size' + String(selection.size()));
    if selection.size() == 1 and selection[0] is MultiMeshInstance:
        print('selection was multimesh instance');
        current_multimesh = selection[0]
        if current_multimesh.multimesh == null:
            ui_activate_button._set_ui_sidebar(false)
            ui_activate_button._hide()
            editable_object = false
        else:
            print('selection was not multimesh instance');
            ui_activate_button._show()
            editable_object = true
    else:
        editable_object = false
        ui_activate_button._set_ui_sidebar(false) #HIDE THE SIDEBAR
        ui_activate_button._hide()

func _enter_tree() -> void:
    #SETUP THE SIDEBAR:
    ui_sidebar = preload("res://addons/multimesh_brush/scenes/brush_ui.tscn").instance()
    add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, ui_sidebar)
    ui_sidebar.hide()
    ui_sidebar.painter = self
    #SETUP THE EDITOR BUTTON:
    ui_activate_button = preload("res://addons/multimesh_brush/scenes/activate_button.tscn").instance()
    add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, ui_activate_button)
    ui_activate_button.hide()
    ui_activate_button.painter = self
    ui_activate_button.ui_sidebar = ui_sidebar
    #SELECTION SIGNAL:
    get_editor_interface().get_selection().connect("selection_changed", self, "_selection_changed")
    #LOAD BRUSH:
    brush_cursor = preload("res://addons/multimesh_brush/scenes/brush_cursor.tscn").instance()
    brush_cursor.visible = false
    add_child(brush_cursor)

func _exit_tree() -> void:
    #REMOVE THE SIDEBAR:
    remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, ui_sidebar)
    if ui_sidebar:
        ui_sidebar.free()
    #REMOVE THE EDITOR BUTTON:
    remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, ui_activate_button)
    if ui_activate_button:
        ui_activate_button.free()
