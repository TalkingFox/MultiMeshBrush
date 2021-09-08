tool
extends Control

var painter

export var button_paint_dir:NodePath
var button_paint:ToolButton

#BRUSH SLIDERS:
export var brush_size_slider_dir:NodePath
export var brush_size_label_dir: NodePath
var brush_size_slider: HSlider;
var brush_size_label: Label;

export var brush_density_slider_dir:NodePath
export var brush_density_label_dir: NodePath;
var brush_density_slider: HSlider
var brush_density_label: Label;

func _enter_tree():
    button_paint = get_node(button_paint_dir)
    button_paint.connect("toggled", self, "_set_paint_tool")

    brush_size_slider = get_node(brush_size_slider_dir)
    brush_size_slider.connect("value_changed", self, "_set_brush_size")

    brush_size_label = get_node(brush_size_label_dir);    

    brush_density_slider = get_node(brush_density_slider_dir)
    brush_density_slider.connect("value_changed", self, "_set_brush_density")

    brush_density_label = get_node(brush_density_label_dir);
    

func _exit_tree():
    pass

func _make_local_copy():
    painter._make_local_copy()

func _set_paint_tool(value):
    if value:
        painter.current_tool = "_paint_tool"
        button_paint.set_pressed(true)

func _set_brush_size(value):
    brush_size_slider.value = value
    brush_size_label.text = String(value);
    painter.brush_size = value
    painter.brush_cursor.scale = Vector3.ONE * value

func _set_brush_density(value):
    brush_density_slider.value = value
    brush_density_label.text = String(value);
    painter.brush_density = value
