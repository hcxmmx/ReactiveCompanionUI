extends Control

# Visual-only script: the game integration sends scene and reaction changes here.
signal peek_requested
signal potion_odds_requested
signal juggling_count_requested
signal removal_price_requested
signal sl_requested

const FRONT_ATLAS: Texture2D = preload("res://ReactiveCompanionUI_hcxmmx/images/chino/front.png")
const SIDE_ATLAS: Texture2D = preload("res://ReactiveCompanionUI_hcxmmx/images/chino/side.png")
const FRONT_6_ATLAS: Texture2D = preload("res://ReactiveCompanionUI_hcxmmx/images/chino/variants/front_day_6.png")
const FRONT_9_ATLAS: Texture2D = preload("res://ReactiveCompanionUI_hcxmmx/images/chino/variants/front_day_9.png")
const SIDE_1_ATLAS: Texture2D = preload("res://ReactiveCompanionUI_hcxmmx/images/chino/variants/side_day_1.png")
const SIDE_3_ATLAS: Texture2D = preload("res://ReactiveCompanionUI_hcxmmx/images/chino/variants/side_day_3.png")
const SETTINGS_DIR := "user://ReactiveCompanionUI"
const SETTINGS_PATH := SETTINGS_DIR + "/settings.json"
const DEFAULT_SCALE := 0.6
const DEFAULT_BUBBLE_SCALE := 1.0
const INTERACTION_IDLE_TIMEOUT := 10.0

const EXPRESSIONS := {
	"idle": {
		"front": {"eye_source": "front_9", "eye": 14, "mouth_source": "front_9", "mouth": 12},
		"battle": {"eye_source": "side_2", "eye": 1, "mouth_source": "side_2", "mouth": 0},
	},
	"thinking": {
		"front": {"eye_source": "front_6", "eye": 8, "mouth_source": "front_4", "mouth": 1},
		"battle": {"eye_source": "side_2", "eye": 4, "mouth_source": "side_3", "mouth": 18},
	},
	"happy": {
		"front": {"eye_source": "front_6", "eye": 21, "mouth_source": "front_6", "mouth": 17},
		"battle": {"eye_source": "side_2", "eye": 2, "mouth_source": "side_2", "mouth": 0},
	},
	"surprised": {
		"front": {"eye_source": "front_6", "eye": 14, "mouth_source": "front_4", "mouth": 3},
		"battle": {"eye_source": "side_1", "eye": 7, "mouth_source": "side_2", "mouth": 3},
	},
	"worried": {
		"front": {"eye_source": "front_6", "eye": 3, "mouth_source": "front_6", "mouth": 1},
		"battle": {"eye_source": "side_3", "eye": 5, "mouth_source": "side_3", "mouth": 15},
	},
}
const EXPRESSION_SOURCES := {
	"front_4": {
		"atlas": FRONT_ATLAS, "eye_origin": Vector2i(238, 0), "eye_size": Vector2i(121, 70),
		"eye_rows": [2, 1, 1, 1, 1, 1, 1], "eye_order": "column_first", "eye_at": Vector2(55, 98),
		"mouth_origin": Vector2i(481, 0), "mouth_size": Vector2i(14, 17), "mouth_at": Vector2(109, 180),
	},
	"front_6": {
		"atlas": FRONT_6_ATLAS, "eye_origin": Vector2i(238, 0), "eye_size": Vector2i(198, 97),
		"eye_rows": [5, 5, 5, 4, 4], "eye_at": Vector2(19, 98),
		"mouth_origin": Vector2i(1229, 0), "mouth_size": Vector2i(14, 17), "mouth_at": Vector2(108, 182),
	},
	"front_9": {
		"atlas": FRONT_9_ATLAS, "eye_origin": Vector2i(238, 0), "eye_size": Vector2i(198, 97),
		"eye_rows": [4, 4, 4, 4, 4], "eye_at": Vector2(19, 98),
		"mouth_origin": Vector2i(1031, 0), "mouth_size": Vector2i(14, 17), "mouth_at": Vector2(108, 182),
	},
	"side_2": {
		"atlas": SIDE_ATLAS, "eye_origin": Vector2i(314, 0), "eye_size": Vector2i(115, 74),
		"eye_rows": [1, 1, 1, 1, 1], "eye_at": Vector2(133, 94),
		"mouth_origin": Vector2i(430, 0), "mouth_size": Vector2i(12, 14), "mouth_at": Vector2(192, 182),
	},
	"side_1": {
		"atlas": SIDE_1_ATLAS, "eye_origin": Vector2i(314, 0), "eye_size": Vector2i(114, 81),
		"eye_rows": [4, 4, 3, 3, 3, 3], "eye_at": Vector2(133, 88),
		"mouth_origin": Vector2i(771, 0), "mouth_size": Vector2i(14, 15), "mouth_at": Vector2(190, 182),
	},
	"side_3": {
		"atlas": SIDE_3_ATLAS, "eye_origin": Vector2i(314, 0), "eye_size": Vector2i(115, 81),
		"eye_rows": [4, 4, 3, 3, 3, 3], "eye_at": Vector2(133, 88),
		"mouth_origin": Vector2i(775, 0), "mouth_size": Vector2i(14, 15), "mouth_at": Vector2(190, 182),
	},
}
const BLINK_FRAMES := {
	"front_4": Vector2i(3, 2),
	"front_6": Vector2i(0, 7),
	"front_9": Vector2i(0, 13),
	"side_1": Vector2i(0, 9),
	"side_2": Vector2i(0, 2),
	"side_3": Vector2i(0, 9),
}

const CHAT_LINES := {
	"front": [
		{"expression": "happy", "text": "今天也一起加油。"},
		{"expression": "idle", "text": "我会在这里陪着你的。"},
		{"expression": "thinking", "text": "下一步要去哪里呢？"},
		{"expression": "happy", "text": "稍微休息一下也可以哦。"},
		{"expression": "idle", "text": "我正看着这一路的冒险呢。"},
		{"expression": "surprised", "text": "啊，叫我吗？"},
	],
	"battle": [
		{"expression": "thinking", "text": "嗯……我也在想办法。"},
		{"expression": "idle", "text": "别急，我们慢慢来。"},
		{"expression": "happy", "text": "这一步看起来不错呢。"},
		{"expression": "worried", "text": "要记得看看剩下的体力哦。"},
		{"expression": "surprised", "text": "哇，刚才那一下真厉害。"},
		{"expression": "idle", "text": "我一直都在哦。"},
	],
}

@onready var portrait_pivot: Control = $PortraitPivot
@onready var portrait_group: CanvasGroup = $PortraitPivot/PortraitGroup
@onready var front_pose: Control = $PortraitPivot/PortraitGroup/FrontPose
@onready var side_pose: Control = $PortraitPivot/PortraitGroup/SidePose
@onready var front_eyes: TextureRect = $PortraitPivot/PortraitGroup/FrontPose/Eyes
@onready var front_mouth: TextureRect = $PortraitPivot/PortraitGroup/FrontPose/Mouth
@onready var side_eyes: TextureRect = $PortraitPivot/PortraitGroup/SidePose/Eyes
@onready var side_mouth: TextureRect = $PortraitPivot/PortraitGroup/SidePose/Mouth
@onready var bubble_anchor: Control = $BubbleAnchor
@onready var bubble_group: CanvasGroup = $BubbleAnchor/BubbleGroup
@onready var bubble: PanelContainer = $BubbleAnchor/BubbleGroup/Bubble
@onready var bubble_text: Label = $BubbleAnchor/BubbleGroup/Bubble/Margin/Text
@onready var interaction_toggle: Button = $InteractionToggle
@onready var peek_button: Button = $PeekButton
@onready var potion_button: Button = $PotionButton
@onready var juggling_button: Button = $JugglingButton
@onready var removal_button: Button = $RemovalButton
@onready var settings_button: Button = $SettingsButton
@onready var sl_button: Button = $SlButton
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var scale_slider: HSlider = $SettingsPanel/SettingsMargin/SettingsContent/ScaleRow/ScaleSlider
@onready var opacity_slider: HSlider = $SettingsPanel/SettingsMargin/SettingsContent/OpacityRow/OpacitySlider
@onready var bubble_scale_slider: HSlider = $SettingsPanel/SettingsMargin/SettingsContent/BubbleScaleRow/BubbleScaleSlider
@onready var bubble_opacity_slider: HSlider = $SettingsPanel/SettingsMargin/SettingsContent/BubbleOpacityRow/BubbleOpacitySlider
@onready var bubble_reset_button: Button = $SettingsPanel/SettingsMargin/SettingsContent/BubbleResetButton
@onready var controls_reset_button: Button = $SettingsPanel/SettingsMargin/SettingsContent/SettingsActions/ControlsResetButton
@onready var reset_button: Button = $SettingsPanel/SettingsMargin/SettingsContent/SettingsActions/ResetButton
@onready var done_button: Button = $SettingsPanel/SettingsMargin/SettingsContent/SettingsActions/DoneButton

var _pose := "front"
var _expression := "idle"
var _interactive := false
var _interaction_idle_remaining := 0.0
var _portrait_dragging := false
var _potion_available := false
var _juggling_available := false
var _removal_available := false
var _sl_available := false
var _last_chat_index := {"front": -1, "battle": -1}
var _hud_offset := Vector2.ZERO
var _controls_offset := Vector2.ZERO
var _bubble_offset := Vector2.ZERO
var _base_scale := DEFAULT_SCALE
var _opacity := 1.0
var _bubble_scale := DEFAULT_BUBBLE_SCALE
var _bubble_opacity := 1.0
var _base_rects := {}
var _base_bubble_rect := Vector4.ZERO
var _bubble_dragging := false
var _bubble_last_drag_position := Vector2.ZERO
var _controls_dragging := false
var _controls_last_drag_position := Vector2.ZERO
var _bubble_previewing := false
var _breath_tween: Tween
var _blink_wait := 4.0
var _expression_generation := 0
var _line_generation := 0
var _pose_tween: Tween


func _ready() -> void:
	portrait_pivot.connect("portrait_clicked", Callable(self, "_on_portrait_clicked"))
	portrait_pivot.connect("portrait_drag_started", Callable(self, "_on_portrait_drag_started"))
	portrait_pivot.connect("portrait_dragged", Callable(self, "_on_portrait_dragged"))
	portrait_pivot.connect("portrait_drag_finished", Callable(self, "_on_portrait_drag_finished"))
	interaction_toggle.gui_input.connect(_on_toggle_gui_input)
	interaction_toggle.pressed.connect(_toggle_interaction)
	peek_button.pressed.connect(_on_peek_pressed)
	potion_button.pressed.connect(_on_potion_pressed)
	juggling_button.pressed.connect(_on_juggling_pressed)
	removal_button.pressed.connect(_on_removal_pressed)
	settings_button.pressed.connect(_toggle_settings_panel)
	sl_button.pressed.connect(_on_sl_pressed)
	reset_button.pressed.connect(_restore_defaults)
	controls_reset_button.pressed.connect(_restore_controls_defaults)
	bubble_reset_button.pressed.connect(_restore_bubble_defaults)
	done_button.pressed.connect(_close_settings_panel)
	bubble.gui_input.connect(_on_bubble_gui_input)
	for node: Control in [portrait_pivot, interaction_toggle, peek_button, potion_button, juggling_button, removal_button, settings_button, sl_button]:
		_base_rects[node.name] = Vector4(node.offset_left, node.offset_top, node.offset_right, node.offset_bottom)
	_base_bubble_rect = Vector4(bubble_anchor.offset_left, bubble_anchor.offset_top, bubble_anchor.offset_right, bubble_anchor.offset_bottom)
	_load_settings()
	scale_slider.value = _base_scale
	opacity_slider.value = _opacity
	bubble_scale_slider.value = _bubble_scale
	bubble_opacity_slider.value = _bubble_opacity
	scale_slider.value_changed.connect(_on_scale_changed)
	opacity_slider.value_changed.connect(_on_opacity_changed)
	bubble_scale_slider.value_changed.connect(_on_bubble_scale_changed)
	bubble_opacity_slider.value_changed.connect(_on_bubble_opacity_changed)
	_apply_hud_offset()
	_apply_bubble_layout()
	_apply_opacity()
	_apply_bubble_opacity()
	resized.connect(_on_viewport_resized)
	_set_interactive(false)
	set_expression("idle")
	_start_breathing()
	_blink_wait = randf_range(3.0, 6.0)


func _process(delta: float) -> void:
	if not visible:
		return
	if _interactive and not settings_panel.visible and not _portrait_dragging:
		_interaction_idle_remaining -= delta
		if _interaction_idle_remaining <= 0.0:
			_set_interactive(false)
	_blink_wait -= delta
	if _blink_wait <= 0.0:
		_blink_wait = randf_range(3.0, 7.0)
		_blink()


func set_pose(pose_name: String) -> void:
	if pose_name != "front" and pose_name != "battle":
		return
	if pose_name == _pose:
		return
	_pose = pose_name
	portrait_pivot.set("pose_name", _pose)
	_apply_hud_offset()
	_update_interaction_ui()
	_expression_generation += 1
	if _pose_tween and _pose_tween.is_running():
		_pose_tween.kill()
	_pose_tween = create_tween().set_parallel(true)
	_pose_tween.tween_property(front_pose, "modulate:a", 1.0 if _pose == "front" else 0.0, 0.22)
	_pose_tween.tween_property(side_pose, "modulate:a", 1.0 if _pose == "battle" else 0.0, 0.22)
	set_expression(_expression)


func set_expression(expression_name: String) -> void:
	if not EXPRESSIONS.has(expression_name):
		expression_name = "idle"
	_expression = expression_name
	_expression_generation += 1
	var mapping: Dictionary = EXPRESSIONS[_expression]
	for pose_name in ["front", "battle"]:
		var choice: Dictionary = mapping[pose_name]
		_set_eye(pose_name, choice["eye_source"], int(choice["eye"]))
		_set_mouth(pose_name, choice["mouth_source"], int(choice["mouth"]))


func react(expression_name: String, message: String, duration: float = 3.2) -> void:
	set_expression(expression_name)
	_line_generation += 1
	var line_id := _line_generation
	_bubble_previewing = false
	bubble_text.text = message
	bubble_anchor.visible = not message.is_empty()
	if bubble_anchor.visible:
		_apply_bubble_layout()
	if not message.is_empty():
		await get_tree().create_timer(duration).timeout
	if is_inside_tree() and line_id == _line_generation:
		bubble_anchor.visible = false
		if settings_panel.visible:
			_show_bubble_preview()
		set_expression("idle")


func _on_toggle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and settings_panel.visible:
			_controls_dragging = true
			_controls_last_drag_position = event.global_position
		interaction_toggle.accept_event()


func _input(event: InputEvent) -> void:
	if not _controls_dragging:
		return
	if event is InputEventMouseMotion:
		_controls_offset += event.global_position - _controls_last_drag_position
		_controls_last_drag_position = event.global_position
		_apply_hud_offset()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		_controls_dragging = false
		if settings_panel.visible:
			_place_settings_panel()
		_save_settings()
		get_viewport().set_input_as_handled()


func _toggle_interaction() -> void:
	_set_interactive(not _interactive)


func _set_interactive(enabled: bool) -> void:
	_interactive = enabled
	_interaction_idle_remaining = INTERACTION_IDLE_TIMEOUT if enabled else 0.0
	if not enabled:
		_portrait_dragging = false
	portrait_pivot.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	interaction_toggle.text = "互动中" if enabled else "互动"
	_update_interaction_ui()


func _mark_companion_activity() -> void:
	if _interactive:
		_interaction_idle_remaining = INTERACTION_IDLE_TIMEOUT


func _update_interaction_ui() -> void:
	peek_button.visible = _interactive and _pose == "battle"
	potion_button.visible = _interactive and _pose == "battle" and _potion_available
	juggling_button.visible = _interactive and _pose == "battle" and _juggling_available
	removal_button.visible = _interactive and _removal_available
	settings_button.visible = _interactive
	sl_button.visible = _interactive and _sl_available
	if not _interactive and settings_panel.visible:
		_close_settings_panel()


func set_sl_available(available: bool) -> void:
	if _sl_available == available:
		return
	_sl_available = available
	_update_interaction_ui()


func set_potion_available(available: bool) -> void:
	if _potion_available == available:
		return
	_potion_available = available
	_update_interaction_ui()


func set_juggling_available(available: bool) -> void:
	if _juggling_available == available:
		return
	_juggling_available = available
	_update_interaction_ui()


func set_removal_available(available: bool) -> void:
	if _removal_available == available:
		return
	_removal_available = available
	_update_interaction_ui()


func _on_portrait_clicked() -> void:
	if not _interactive:
		return
	_mark_companion_activity()
	var lines: Array = CHAT_LINES[_pose]
	var index := randi_range(0, lines.size() - 2)
	var previous := int(_last_chat_index[_pose])
	if previous >= 0 and index >= previous:
		index += 1
	_last_chat_index[_pose] = index
	var chosen: Dictionary = lines[index]
	react(str(chosen["expression"]), str(chosen["text"]))


func _on_peek_pressed() -> void:
	_mark_companion_activity()
	peek_requested.emit()


func _on_potion_pressed() -> void:
	_mark_companion_activity()
	potion_odds_requested.emit()


func _on_juggling_pressed() -> void:
	_mark_companion_activity()
	juggling_count_requested.emit()


func _on_removal_pressed() -> void:
	_mark_companion_activity()
	removal_price_requested.emit()


func _on_sl_pressed() -> void:
	_mark_companion_activity()
	sl_requested.emit()


func _on_portrait_drag_started() -> void:
	_portrait_dragging = true
	_mark_companion_activity()


func _on_portrait_dragged(delta: Vector2) -> void:
	_hud_offset += delta
	_apply_hud_offset()


func _on_portrait_drag_finished() -> void:
	_portrait_dragging = false
	_mark_companion_activity()
	_save_settings()


func _on_bubble_gui_input(event: InputEvent) -> void:
	if not settings_panel.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_bubble_dragging = true
			_bubble_last_drag_position = event.global_position
		elif _bubble_dragging:
			_bubble_dragging = false
			_save_settings()
		bubble.accept_event()
	elif event is InputEventMouseMotion and _bubble_dragging:
		_bubble_offset += event.global_position - _bubble_last_drag_position
		_bubble_last_drag_position = event.global_position
		_apply_bubble_layout()
		bubble.accept_event()


func _on_viewport_resized() -> void:
	_apply_hud_offset()
	_apply_bubble_layout()
	if settings_panel.visible:
		_place_settings_panel()


func _apply_hud_offset() -> void:
	if _base_rects.is_empty():
		return
	var viewport_size := get_viewport_rect().size
	var toggle_rect: Vector4 = _base_rects[interaction_toggle.name]
	_hud_offset.x = clampf(_hud_offset.x, 8.0 - toggle_rect.x, viewport_size.x - 8.0 - toggle_rect.z)
	_hud_offset.y = clampf(_hud_offset.y, 8.0 - viewport_size.y - toggle_rect.y, -8.0 - toggle_rect.w)
	var control_nodes: Array[Control] = [interaction_toggle, peek_button, potion_button, juggling_button, removal_button, settings_button, sl_button]
	var group_left := INF
	var group_top := INF
	var group_right := -INF
	var group_bottom := -INF
	for node: Control in control_nodes:
		var rect: Vector4 = _control_base_rect(node)
		group_left = minf(group_left, rect.x)
		group_top = minf(group_top, rect.y)
		group_right = maxf(group_right, rect.z)
		group_bottom = maxf(group_bottom, rect.w)
	var controls_position := _hud_offset + _controls_offset
	controls_position.x = clampf(controls_position.x, 8.0 - group_left, viewport_size.x - 8.0 - group_right)
	controls_position.y = clampf(controls_position.y, 8.0 - viewport_size.y - group_top, -8.0 - group_bottom)
	_controls_offset = controls_position - _hud_offset
	for node: Control in [portrait_pivot] + control_nodes:
		var rect: Vector4 = _control_base_rect(node)
		var offset: Vector2 = _hud_offset if node == portrait_pivot else controls_position
		node.offset_left = rect.x + offset.x
		node.offset_top = rect.y + offset.y
		node.offset_right = rect.z + offset.x
		node.offset_bottom = rect.w + offset.y


func _control_base_rect(node: Control) -> Vector4:
	if node == removal_button and _pose == "battle":
		return Vector4(320.0, -244.0, 392.0, -212.0)
	return _base_rects[node.name]


func _apply_bubble_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var base_left := _base_bubble_rect.x
	var base_top := viewport_size.y + _base_bubble_rect.y
	var scaled_size := bubble_anchor.size * _bubble_scale
	_bubble_offset.x = clampf(_bubble_offset.x, 8.0 - base_left, viewport_size.x - 8.0 - scaled_size.x - base_left)
	_bubble_offset.y = clampf(_bubble_offset.y, 8.0 - base_top, viewport_size.y - 8.0 - scaled_size.y - base_top)
	bubble_anchor.offset_left = _base_bubble_rect.x + _bubble_offset.x
	bubble_anchor.offset_top = _base_bubble_rect.y + _bubble_offset.y
	bubble_anchor.offset_right = _base_bubble_rect.z + _bubble_offset.x
	bubble_anchor.offset_bottom = _base_bubble_rect.w + _bubble_offset.y
	bubble_anchor.scale = Vector2.ONE * _bubble_scale


func _toggle_settings_panel() -> void:
	if settings_panel.visible:
		_close_settings_panel()
		return
	_place_settings_panel()
	settings_panel.visible = true
	bubble_anchor.mouse_filter = Control.MOUSE_FILTER_STOP
	bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	_show_bubble_preview()


func _place_settings_panel() -> void:
	var viewport_width := get_viewport_rect().size.x
	var panel_width := settings_panel.offset_right - settings_panel.offset_left
	var panel_x := 24.0
	var default_rect := Rect2(Vector2(panel_x, settings_panel.offset_top), Vector2(panel_width, settings_panel.offset_bottom - settings_panel.offset_top))
	if not default_rect.intersects(interaction_toggle.get_global_rect()):
		settings_panel.offset_left = panel_x
		settings_panel.offset_right = panel_x + panel_width
		return
	var group_left := INF
	var group_right := -INF
	for node: Control in [interaction_toggle, peek_button, potion_button, juggling_button, removal_button, settings_button, sl_button]:
		group_left = minf(group_left, node.offset_left)
		group_right = maxf(group_right, node.offset_right)
	var right_x := group_right + 12.0
	var left_x := group_left - panel_width - 12.0
	panel_x = right_x
	if right_x + panel_width > viewport_width - 8.0:
		panel_x = left_x if left_x >= 8.0 else clampf(left_x, 8.0, viewport_width - panel_width - 8.0)
	settings_panel.offset_left = panel_x
	settings_panel.offset_right = panel_x + panel_width


func _show_bubble_preview() -> void:
	_line_generation += 1
	_bubble_previewing = true
	set_expression("idle")
	bubble_text.text = "右键拖动这里，调整对话框位置。"
	bubble_anchor.visible = true
	_apply_bubble_layout()


func _close_settings_panel() -> void:
	settings_panel.visible = false
	_mark_companion_activity()
	_bubble_dragging = false
	_controls_dragging = false
	bubble_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _bubble_previewing:
		bubble_anchor.visible = false
		_bubble_previewing = false
	_save_settings()


func _on_scale_changed(value: float) -> void:
	_base_scale = value
	_start_breathing()
	_save_settings()


func _on_opacity_changed(value: float) -> void:
	_opacity = value
	_apply_opacity()
	_save_settings()


func _on_bubble_scale_changed(value: float) -> void:
	_bubble_scale = value
	_apply_bubble_layout()
	_save_settings()


func _on_bubble_opacity_changed(value: float) -> void:
	_bubble_opacity = value
	_apply_bubble_opacity()
	_save_settings()


func _apply_opacity() -> void:
	var tint := portrait_group.self_modulate
	tint.a = _opacity
	portrait_group.self_modulate = tint


func _apply_bubble_opacity() -> void:
	var tint := bubble_group.self_modulate
	tint.a = _bubble_opacity
	bubble_group.self_modulate = tint


func _restore_defaults() -> void:
	_hud_offset = Vector2.ZERO
	_base_scale = DEFAULT_SCALE
	_opacity = 1.0
	scale_slider.set_value_no_signal(_base_scale)
	opacity_slider.set_value_no_signal(_opacity)
	_apply_hud_offset()
	_apply_opacity()
	_start_breathing()
	_save_settings()


func _restore_controls_defaults() -> void:
	_controls_offset = Vector2.ZERO
	_apply_hud_offset()
	if settings_panel.visible:
		_place_settings_panel()
	_save_settings()


func _restore_bubble_defaults() -> void:
	_bubble_offset = Vector2.ZERO
	_bubble_scale = DEFAULT_BUBBLE_SCALE
	_bubble_opacity = 1.0
	bubble_scale_slider.set_value_no_signal(_bubble_scale)
	bubble_opacity_slider.set_value_no_signal(_bubble_opacity)
	_apply_bubble_layout()
	_apply_bubble_opacity()
	_save_settings()


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	_hud_offset = Vector2(float(parsed.get("x", 0.0)), float(parsed.get("y", 0.0)))
	_controls_offset = Vector2(float(parsed.get("controls_x", 0.0)), float(parsed.get("controls_y", 0.0)))
	_base_scale = clampf(float(parsed.get("scale", DEFAULT_SCALE)), 0.35, 1.1)
	_opacity = clampf(float(parsed.get("opacity", 1.0)), 0.3, 1.0)
	_bubble_offset = Vector2(float(parsed.get("bubble_x", 0.0)), float(parsed.get("bubble_y", 0.0)))
	_bubble_scale = clampf(float(parsed.get("bubble_scale", DEFAULT_BUBBLE_SCALE)), 0.7, 1.5)
	_bubble_opacity = clampf(float(parsed.get("bubble_opacity", 1.0)), 0.3, 1.0)


func _save_settings() -> void:
	var folder := ProjectSettings.globalize_path(SETTINGS_DIR)
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"x": _hud_offset.x,
		"y": _hud_offset.y,
		"controls_x": _controls_offset.x,
		"controls_y": _controls_offset.y,
		"scale": _base_scale,
		"opacity": _opacity,
		"bubble_x": _bubble_offset.x,
		"bubble_y": _bubble_offset.y,
		"bubble_scale": _bubble_scale,
		"bubble_opacity": _bubble_opacity,
	}, "  "))


func _start_breathing() -> void:
	if _breath_tween and _breath_tween.is_running():
		_breath_tween.kill()
	portrait_pivot.scale = Vector2(_base_scale, _base_scale)
	_breath_tween = create_tween().set_loops()
	_breath_tween.tween_property(portrait_pivot, "scale", Vector2(_base_scale * 1.005, _base_scale * 1.01), 1.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breath_tween.tween_property(portrait_pivot, "scale", Vector2(_base_scale, _base_scale), 1.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _blink() -> void:
	var generation := _expression_generation
	var current: Dictionary = EXPRESSIONS[_expression][_pose]
	var blink_source: String = current["eye_source"]
	var frames: Vector2i = BLINK_FRAMES[blink_source]
	_set_eye(_pose, blink_source, frames.x)
	await get_tree().create_timer(0.08).timeout
	if not is_inside_tree() or generation != _expression_generation:
		return
	_set_eye(_pose, blink_source, frames.y)
	await get_tree().create_timer(0.09).timeout
	if not is_inside_tree() or generation != _expression_generation:
		return
	_set_eye(_pose, blink_source, frames.x)
	await get_tree().create_timer(0.07).timeout
	if is_inside_tree() and generation == _expression_generation:
		_set_eye(_pose, current["eye_source"], int(current["eye"]))


func _set_eye(pose_name: String, source_id: String, index: int) -> void:
	var source: Dictionary = EXPRESSION_SOURCES[source_id]
	var origin: Vector2i = source["eye_origin"]
	var tile_size: Vector2i = source["eye_size"]
	var rows: Array = source["eye_rows"]
	var cell := Vector2i.ZERO
	if source.get("eye_order", "") == "column_first":
		cell = Vector2i(0, index) if index < rows.size() else Vector2i(index - rows.size() + 1, 0)
	else:
		var column := index
		for row in rows.size():
			if column < int(rows[row]):
				cell = Vector2i(column, row)
				break
			column -= int(rows[row])
	var atlas := AtlasTexture.new()
	atlas.atlas = source["atlas"]
	atlas.region = Rect2(origin + cell * tile_size, tile_size)
	atlas.filter_clip = true
	var node: TextureRect = front_eyes if pose_name == "front" else side_eyes
	node.texture = atlas
	node.position = source["eye_at"]
	node.size = tile_size


func _set_mouth(pose_name: String, source_id: String, index: int) -> void:
	var source: Dictionary = EXPRESSION_SOURCES[source_id]
	var origin: Vector2i = source["mouth_origin"]
	var tile_size: Vector2i = source["mouth_size"]
	var atlas := AtlasTexture.new()
	atlas.atlas = source["atlas"]
	atlas.region = Rect2(origin + Vector2i(0, index * tile_size.y), tile_size)
	atlas.filter_clip = true
	var node: TextureRect = front_mouth if pose_name == "front" else side_mouth
	node.texture = atlas
	node.position = source["mouth_at"]
	node.size = tile_size
