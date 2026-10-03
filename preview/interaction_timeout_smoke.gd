extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hud: Control = load("res://ReactiveCompanionUI_hcxmmx/scenes/companion_hud.tscn").instantiate()
	root.add_child(hud)
	await process_frame
	var toggle: Button = hud.get_node("InteractionToggle")
	var settings: Button = hud.get_node("SettingsButton")
	var peek: Button = hud.get_node("PeekButton")
	assert(is_equal_approx(hud.INTERACTION_IDLE_TIMEOUT, 10.0))

	await _click(toggle.get_global_rect().get_center())
	assert(hud._interactive)
	hud._interaction_idle_remaining = 0.05
	await create_timer(0.15).timeout
	assert(not hud._interactive)
	assert(toggle.text == "互动")

	await _click(toggle.get_global_rect().get_center())
	hud.set_pose("battle")
	hud._interaction_idle_remaining = 0.05
	await _click(peek.get_global_rect().get_center())
	assert(hud._interactive and hud._interaction_idle_remaining > 9.0)

	await _click(settings.get_global_rect().get_center())
	assert(hud.settings_panel.visible)
	hud._interaction_idle_remaining = 0.05
	await create_timer(0.15).timeout
	assert(hud._interactive)
	await _click(hud.get_node("SettingsPanel/SettingsMargin/SettingsContent/SettingsActions/DoneButton").get_global_rect().get_center())
	assert(not hud.settings_panel.visible and hud._interaction_idle_remaining > 9.0)

	hud._interaction_idle_remaining = 0.05
	var game_key := InputEventKey.new()
	game_key.keycode = KEY_A
	game_key.pressed = true
	root.push_input(game_key, true)
	await create_timer(0.15).timeout
	assert(not hud._interactive)
	print("interaction_timeout_smoke: PASS")
	quit(0)


func _click(position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.global_position = position
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event.pressed = false
	root.push_input(event, true)
	await process_frame
