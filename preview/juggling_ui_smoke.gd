extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hud: Control = load("res://ReactiveCompanionUI_hcxmmx/scenes/companion_hud.tscn").instantiate()
	root.add_child(hud)
	await process_frame
	var button: Button = hud.get_node("JugglingButton")
	var requests := [0]
	hud.juggling_count_requested.connect(func() -> void: requests[0] += 1)
	hud.set_pose("battle")
	hud._set_interactive(true)
	if button.visible:
		_fail("button appeared without Juggling")
		return
	hud.set_juggling_available(true)
	if not button.visible:
		_fail("button did not appear with Juggling")
		return
	button.pressed.emit()
	if requests[0] != 1:
		_fail("query signal was not emitted")
		return
	hud.set_pose("front")
	if button.visible:
		_fail("button remained visible outside combat")
		return
	hud.set_pose("battle")
	hud.set_juggling_available(false)
	if button.visible:
		_fail("button remained visible after Juggling was removed")
		return
	print("juggling_ui_smoke: PASS")
	quit(0)


func _fail(reason: String) -> void:
	push_error("juggling_ui_smoke: " + reason)
	quit(1)
