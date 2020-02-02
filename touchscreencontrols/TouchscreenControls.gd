extends Node2D

onready var directional_button_group = $DirectionalButtonGroup
onready var action_button_group = $ActionButtonGroup

func _ready():
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()

func _on_viewport_size_changed():
	var viewport_size = get_viewport().get_visible_rect().size
	directional_button_group.set_position(Vector2(160, viewport_size.y-120))
	action_button_group.set_position(Vector2(viewport_size.x-200, viewport_size.y-160))
