extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://ReactiveCompanionUI_hcxmmx/scenes/companion_hud.tscn")
	var hud: Control = scene.instantiate()
	root.add_child(hud)
	await process_frame
	hud._restore_defaults()
	hud._restore_bubble_defaults()

	var toggle: Button = hud.get_node("InteractionToggle")
	var peek: Button = hud.get_node("PeekButton")
	var potion: Button = hud.get_node("PotionButton")
	var settings: Button = hud.get_node("SettingsButton")
	var sl: Button = hud.get_node("SlButton")
	var panel: PanelContainer = hud.get_node("SettingsPanel")
	var portrait: Control = hud.get_node("PortraitPivot")
	var portrait_group: CanvasGroup = hud.get_node("PortraitPivot/PortraitGroup")
	var bubble_anchor: Control = hud.get_node("BubbleAnchor")
	var bubble: PanelContainer = hud.get_node("BubbleAnchor/BubbleGroup/Bubble")
	var bubble_group: CanvasGroup = hud.get_node("BubbleAnchor/BubbleGroup")
	assert(portrait.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(not peek.visible)
	assert(not potion.visible)
	assert(not sl.visible)

	await _click(toggle.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	assert(portrait.mouse_filter == Control.MOUSE_FILTER_STOP)
	assert(toggle.text == "互动中")
	assert(not portrait._has_point(Vector2(0, 0)))
	assert(portrait._has_point(Vector2(153, 300)))
	hud.set_sl_available(true)
	assert(sl.visible)
	var sl_count := [0]
	hud.sl_requested.connect(func() -> void: sl_count[0] += 1)
	await _click(sl.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	assert(sl_count[0] == 1)
	await _click(portrait.get_global_transform() * Vector2(153, 300), MOUSE_BUTTON_LEFT)
	assert(bubble_anchor.visible)
	assert(bubble.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	var original_x := portrait.offset_left
	var original_toggle_x := toggle.offset_left
	var drag_from: Vector2 = portrait.get_global_transform() * Vector2(153, 300)
	await _drag(drag_from, drag_from + Vector2(32, -18))
	assert(is_equal_approx(portrait.offset_left, original_x + 32))
	assert(is_equal_approx(toggle.offset_left, original_toggle_x + 32))

	hud.set_pose("battle")
	assert(peek.visible)
	assert(not potion.visible)
	hud.set_potion_available(true)
	assert(potion.visible)
	assert(is_equal_approx(portrait.offset_left, original_x + 32))
	var peek_count := [0]
	hud.peek_requested.connect(func() -> void: peek_count[0] += 1)
	await _click(peek.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	assert(peek_count[0] == 1)
	var potion_count := [0]
	hud.potion_odds_requested.connect(func() -> void: potion_count[0] += 1)
	await _click(potion.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	assert(potion_count[0] == 1)
	await _click(settings.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	assert(panel.visible)
	assert(bubble_anchor.visible)
	assert(bubble.mouse_filter == Control.MOUSE_FILTER_STOP)
	var original_bubble_x := bubble_anchor.offset_left
	var bubble_drag_from := bubble.get_global_rect().get_center()
	await _drag(bubble_drag_from, bubble_drag_from + Vector2(40, -24))
	assert(is_equal_approx(bubble_anchor.offset_left, original_bubble_x + 40))
	assert(is_equal_approx(portrait.offset_left, original_x + 32))
	var scale_slider: HSlider = hud.get_node("SettingsPanel/SettingsMargin/SettingsContent/ScaleRow/ScaleSlider")
	var opacity_slider: HSlider = hud.get_node("SettingsPanel/SettingsMargin/SettingsContent/OpacityRow/OpacitySlider")
	var bubble_scale_slider: HSlider = hud.get_node("SettingsPanel/SettingsMargin/SettingsContent/BubbleScaleRow/BubbleScaleSlider")
	var bubble_opacity_slider: HSlider = hud.get_node("SettingsPanel/SettingsMargin/SettingsContent/BubbleOpacityRow/BubbleOpacitySlider")
	scale_slider.value = 0.75
	opacity_slider.value = 0.7
	bubble_scale_slider.value = 1.25
	bubble_opacity_slider.value = 0.65
	assert(is_equal_approx(portrait.scale.x, 0.75))
	assert(is_equal_approx(portrait_group.self_modulate.a, 0.7))
	assert(is_equal_approx(portrait.modulate.a, 1.0))
	assert(is_equal_approx(bubble_anchor.scale.x, 1.25))
	assert(is_equal_approx(bubble_group.self_modulate.a, 0.65))
	assert(is_equal_approx(portrait_group.self_modulate.a, 0.7))
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://ReactiveCompanionUI/settings.json"))
	assert(is_equal_approx(float(saved["scale"]), 0.75))
	assert(is_equal_approx(float(saved["opacity"]), 0.7))
	assert(is_equal_approx(float(saved["x"]), 32.0))
	assert(is_equal_approx(float(saved["bubble_x"]), 40.0))
	assert(is_equal_approx(float(saved["bubble_y"]), -24.0))
	assert(is_equal_approx(float(saved["bubble_scale"]), 1.25))
	assert(is_equal_approx(float(saved["bubble_opacity"]), 0.65))
	var reloaded_hud: Control = scene.instantiate()
	root.add_child(reloaded_hud)
	await process_frame
	assert(is_equal_approx(reloaded_hud.get_node("BubbleAnchor").offset_left, original_bubble_x + 40))
	assert(is_equal_approx(reloaded_hud.get_node("BubbleAnchor").scale.x, 1.25))
	assert(is_equal_approx(reloaded_hud.get_node("BubbleAnchor/BubbleGroup").self_modulate.a, 0.65))
	reloaded_hud.queue_free()
	await process_frame
	hud.get_node("SettingsPanel/SettingsMargin/SettingsContent/SettingsActions/ResetButton").pressed.emit()
	assert(is_equal_approx(portrait.offset_left, original_x))
	assert(is_equal_approx(portrait_group.self_modulate.a, 1.0))
	assert(is_equal_approx(bubble_anchor.offset_left, original_bubble_x + 40))
	hud.get_node("SettingsPanel/SettingsMargin/SettingsContent/BubbleResetButton").pressed.emit()
	assert(is_equal_approx(bubble_anchor.offset_left, original_bubble_x))
	assert(is_equal_approx(bubble_anchor.scale.x, 1.0))
	assert(is_equal_approx(bubble_group.self_modulate.a, 1.0))
	hud.get_node("SettingsPanel/SettingsMargin/SettingsContent/SettingsActions/DoneButton").pressed.emit()
	assert(not bubble_anchor.visible)
	assert(bubble.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	hud.react("thinking", "调整后继续显示。")
	assert(bubble_anchor.visible)

	await _click(toggle.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	assert(portrait.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(not peek.visible)
	assert(not potion.visible)
	assert(not sl.visible)
	assert(not panel.visible)
	print("Companion input smoke test passed")
	quit(0)


func _click(position: Vector2, button_index: MouseButton) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = button_index
	down.position = position
	down.global_position = position
	down.pressed = true
	root.push_input(down, true)
	await process_frame
	var up := InputEventMouseButton.new()
	up.button_index = button_index
	up.position = position
	up.global_position = position
	up.pressed = false
	root.push_input(up, true)
	await process_frame


func _drag(start: Vector2, finish: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_RIGHT
	down.position = start
	down.global_position = start
	down.pressed = true
	root.push_input(down, true)
	await process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = finish
	motion.global_position = finish
	motion.relative = finish - start
	motion.button_mask = MOUSE_BUTTON_MASK_RIGHT
	root.push_input(motion, true)
	await process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_RIGHT
	up.position = finish
	up.global_position = finish
	up.pressed = false
	root.push_input(up, true)
	await process_frame
