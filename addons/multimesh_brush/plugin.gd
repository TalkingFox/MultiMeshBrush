tool
extends EditorPlugin

const Util = preload("utilities.gd");
var ui_sidebar;
var ui_activate_button;
var brush_cursor;

var current_tool = "_paint_tool"
var process_drawing: bool = false
var brush_size: float = 1
var brush_density: float = 1.0;

var current_multimesh: MultiMeshInstance
var is_selection_editable: bool = false

var is_edit_mode: bool setget _set_edit_mode;
func _set_edit_mode(value) -> void:
    is_edit_mode = value;
    if !is_edit_mode:
        ui_sidebar.hide();

var is_cursor_raycast_hit: bool = false
var hit_position: Vector3;
var hit_normal: Vector3;

export(Vector2) var blade_width = Vector2(0.1, 0.2);
export(Vector2) var blade_height = Vector2(1, 1.5);
export(Vector2) var sway_yaw = Vector2(0.0, 10.0);
export(Vector2) var sway_pitch = Vector2(0.0, 10.0);

func handles(obj) -> bool:
    return is_selection_editable;

func forward_spatial_gui_input(camera, event) -> bool:
    if !is_edit_mode:
        return false;
        
    _display_brush()
    _raycast(camera, event)

    if is_cursor_raycast_hit:
        return _user_input(event) #the returned value blocks or unblocks the default input from godot
    else:
        return false

func _user_input(event) -> bool:
    if not (event is InputEventMouseButton) or event.button_index != BUTTON_LEFT:
        return false;
    
    if event.is_pressed():
        process_drawing = true
        _process_drawing()
        return true
    else:
        process_drawing = false
        return false

func _process_drawing():
    while process_drawing:
        match current_tool:
            'painter':
                _paint_tool();
            'eraser':
                _erase_tool();
        yield(get_tree().create_timer(1.0), "timeout")

func _display_brush() -> void:    
    if is_cursor_raycast_hit:
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
            is_cursor_raycast_hit = true
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
    
    var new_starting_index = prior_transforms.size();
    # add new instances
    for i in instances_to_create:
        var mesh_index = new_starting_index + i;
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
    for i in prior_transforms.size():
        multimesh.set_instance_transform(i, prior_transforms[i]);
        multimesh.set_instance_custom_data(i, Color(
          rand_range(blade_width.x, blade_width.y),
          rand_range(blade_height.x, blade_height.y),
          deg2rad(rand_range(sway_pitch.x, sway_pitch.y)),
          deg2rad(rand_range(sway_yaw.x, sway_yaw.y)))
        );

func _erase_tool() -> void:
    print('erase_tool');
    var multimesh = current_multimesh.multimesh;
    var cursor_position = hit_position;
    var cursor_radius = (brush_cursor.mesh as SphereMesh).radius;
    
    var transforms_to_keep = []
    for i in multimesh.instance_count:
        var transform = multimesh.get_instance_transform(i);
        if !Util.is_point_inside_circle(cursor_position, cursor_radius, transform.origin):
            transforms_to_keep.append(transform);
    
    if transforms_to_keep.size() == multimesh.instance_count:
        print('To Keep: ' + String(transforms_to_keep.size()));
        print('Instances Total: ' + String(multimesh.instance_count));
        return;
    
    multimesh.instance_count = transforms_to_keep.size();
    
    # reset old instances
    for i in transforms_to_keep.size():
        multimesh.set_instance_transform(i, transforms_to_keep[i]);
        multimesh.set_instance_custom_data(i, Color(
          rand_range(blade_width.x, blade_width.y),
          rand_range(blade_height.x, blade_height.y),
          deg2rad(rand_range(sway_pitch.x, sway_pitch.y)),
          deg2rad(rand_range(sway_yaw.x, sway_yaw.y)))
        );

func _change_tool(selected_tool: String) -> void:
    current_tool = selected_tool;

func _selection_changed() -> void:
    ui_activate_button._set_ui_sidebar(false)
    var selection = get_editor_interface().get_selection().get_selected_nodes()
    if selection.size() == 1 and selection[0] is MultiMeshInstance:
        current_multimesh = selection[0]
        if current_multimesh.multimesh == null:
            ui_activate_button._set_ui_sidebar(false)
            ui_activate_button._hide()
            is_selection_editable = false
        else:
            ui_activate_button._show()
            is_selection_editable = true
    else:
        is_selection_editable = false
        ui_activate_button._set_ui_sidebar(false) #HIDE THE SIDEBAR
        ui_activate_button._hide()

func _enter_tree() -> void:
    #SETUP THE SIDEBAR:
    ui_sidebar = preload("res://addons/multimesh_brush/scenes/brush_ui.tscn").instance()
    ui_sidebar.connect('tool_changed', self, '_change_tool');
    add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, ui_sidebar)
    ui_sidebar.hide()
    ui_sidebar.painter = self
    ui_sidebar._toggle_paint_tool(true);
    
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
