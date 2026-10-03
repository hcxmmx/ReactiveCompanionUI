extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hud: Control = load("res://ReactiveCompanionUI_hcxmmx/scenes/companion_hud.tscn").instantiate()
	root.add_child(hud)
	await process_frame
	hud._hud_offset = Vector2.ZERO
	hud._controls_offset = Vector2.ZERO
	hud._apply_hud_offset()
	var toggle: Button = hud.get_node("InteractionToggle")
	var peek: Button = hud.get_node("PeekButton")
	var portrait: Control = hud.get_node("PortraitPivot")
	var settings: Button = hud.get_node("SettingsButton")
	var start_toggle := toggle.position
	var start_peek := peek.position
	var start_portrait := portrait.position
	await _click(toggle.get_global_rect().get_center(), MOUSE_BUTTON_RIGHT)
	if hud._interactive or toggle.position != start_toggle:
		_fail("right click changed the interaction mode or position")
		return
	await _click(toggle.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	if not hud._interactive:
		_fail("left click did not enable interaction")
		return
	await _click(settings.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	if not hud.settings_panel.visible:
		_fail("settings panel did not open")
		return
	if hud.settings_panel.get_global_rect().intersects(toggle.get_global_rect()):
		_fail("settings panel covered the interaction button")
		return
	if hud.settings_panel.get_global_rect().intersects(hud.bubble.get_global_rect()):
		_fail("settings panel covered the bubble preview")
		return
	var drag_start := toggle.get_global_rect().get_center()
	await _send_button(drag_start, MOUSE_BUTTON_RIGHT, true)
	var drag_end := drag_start + Vector2(42, -26)
	var motion := InputEventMouseMotion.new()
	motion.position = drag_end
	motion.global_position = drag_end
	motion.relative = drag_end - drag_start
	motion.button_mask = MOUSE_BUTTON_MASK_RIGHT
	root.push_input(motion, true)
	await process_frame
	if not toggle.position.is_equal_approx(start_toggle + Vector2(42, -26)):
		_fail("interaction button did not move")
		return
	if not peek.position.is_equal_approx(start_peek + Vector2(42, -26)):
		_fail("function buttons did not follow")
		return
	if not portrait.position.is_equal_approx(start_portrait):
		_fail("moving buttons also moved the portrait")
		return
	hud._controls_offset = Vector2(10000, 10000)
	hud._apply_hud_offset()
	var viewport_size := hud.get_viewport_rect().size
	for name in ["InteractionToggle", "PeekButton", "PotionButton", "JugglingButton", "RemovalButton", "SettingsButton", "SlButton"]:
		var rect: Rect2 = hud.get_node(name).get_global_rect()
		if rect.position.x < 8.0 or rect.position.y < 8.0 or rect.end.x > viewport_size.x - 8.0 or rect.end.y > viewport_size.y - 8.0:
			_fail("button group moved outside the viewport")
			return
	print("controls_drag_smoke: PASS")
	quit(0)


func _click(position: Vector2, button_index: MouseButton) -> void:
	await _send_button(position, button_index, true)
	await _send_button(position, button_index, false)


func _send_button(position: Vector2, button_index: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.position = position
	event.global_position = position
	event.pressed = pressed
	root.push_input(event, true)
	await process_frame


func _fail(reason: String) -> void:
	push_error("controls_drag_smoke: " + reason)
	quit(1)
