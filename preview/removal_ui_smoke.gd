extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hud: Control = load("res://ReactiveCompanionUI_hcxmmx/scenes/companion_hud.tscn").instantiate()
	root.add_child(hud)
	await process_frame
	var button: Button = hud.get_node("RemovalButton")
	var requests := [0]
	hud.removal_price_requested.connect(func() -> void: requests[0] += 1)
	hud._set_interactive(true)
	if button.visible:
		_fail("button appeared before a run was available")
		return
	hud.set_removal_available(true)
	if not button.visible:
		_fail("button did not appear outside combat")
		return
	button.pressed.emit()
	if requests[0] != 1:
		_fail("price query signal was not emitted")
		return
	hud.set_pose("battle")
	if not button.visible:
		_fail("button disappeared in combat")
		return
	var peek: Button = hud.get_node("PeekButton")
	var potion: Button = hud.get_node("PotionButton")
	var juggling: Button = hud.get_node("JugglingButton")
	if button.get_global_rect().intersects(peek.get_global_rect()) or button.get_global_rect().intersects(potion.get_global_rect()) or button.get_global_rect().intersects(juggling.get_global_rect()):
		_fail("button overlapped a combat action")
		return
	button.pressed.emit()
	if requests[0] != 2:
		_fail("price query signal was not emitted in combat")
		return
	hud.set_pose("front")
	hud.set_removal_available(false)
	if button.visible:
		_fail("button remained visible without a run")
		return
	print("removal_ui_smoke: PASS")
	quit(0)


func _fail(reason: String) -> void:
	push_error("removal_ui_smoke: " + reason)
	quit(1)
