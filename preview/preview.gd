extends Control

const MOODS := ["idle", "thinking", "happy", "surprised", "worried"]

@onready var hud: Control = $CompanionHud
var battle := false


func _ready() -> void:
	hud.peek_requested.connect(func() -> void: hud.react("thinking", "预览：下一张是「打击」。"))
	$OpenExpressionPicker.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://preview/expression_picker.tscn"))
	hud.react("idle", "今天也一起加油。")


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_SPACE:
		battle = not battle
		hud.set_pose("battle" if battle else "front")
		get_viewport().set_input_as_handled()
	elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
		var index: int = int(event.keycode) - KEY_1
		hud.react(MOODS[index], "表情预览：" + MOODS[index])
		get_viewport().set_input_as_handled()
