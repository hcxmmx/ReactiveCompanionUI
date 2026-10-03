extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var picker: Control = load("res://preview/expression_picker.tscn").instantiate()
	var hud: Control = load("res://ReactiveCompanionUI_hcxmmx/scenes/companion_hud.tscn").instantiate()
	root.add_child(picker)
	root.add_child(hud)
	await process_frame
	for index in picker.PRESET_KEYS.size():
		var key: String = picker.PRESET_KEYS[index]
		picker._on_preset_selected(index)
		hud.set_expression(key)
		for pose in ["front", "battle"]:
			var chosen: Dictionary = picker._choices[key][pose]
			var applied: Dictionary = hud.EXPRESSIONS[key][pose]
			assert(chosen == applied)
			var pose_path := "FrontPose" if pose == "front" else "SidePose"
			var root_path := "PortraitPivot/PortraitGroup/" + pose_path + "/"
			var hud_eye: TextureRect = hud.get_node(root_path + "Eyes")
			var hud_mouth: TextureRect = hud.get_node(root_path + "Mouth")
			_assert_part_matches(hud_eye, picker._eye_nodes[pose])
			_assert_part_matches(hud_mouth, picker._mouth_nodes[pose])

	hud.set_pose("front")
	hud.set_expression("idle")
	picker._on_preset_selected(0)
	hud._blink()
	assert((hud.front_eyes.texture as AtlasTexture).atlas.resource_path == (picker._eye_nodes["front"].texture as AtlasTexture).atlas.resource_path)
	await create_timer(0.33).timeout
	_assert_part_matches(hud.front_eyes, picker._eye_nodes["front"])
	hud.set_pose("battle")
	hud.set_expression("surprised")
	picker._on_preset_selected(3)
	hud._blink()
	assert((hud.side_eyes.texture as AtlasTexture).atlas.resource_path == (picker._eye_nodes["battle"].texture as AtlasTexture).atlas.resource_path)
	await create_timer(0.33).timeout
	_assert_part_matches(hud.side_eyes, picker._eye_nodes["battle"])
	print("expression_application_smoke: PASS")
	quit(0)


func _assert_part_matches(actual: TextureRect, expected: TextureRect) -> void:
	var actual_atlas: AtlasTexture = actual.texture
	var expected_atlas: AtlasTexture = expected.texture
	assert(actual_atlas.filter_clip)
	assert(expected_atlas.filter_clip)
	assert(actual_atlas.region == expected_atlas.region)
	assert(actual_atlas.atlas.resource_path == expected_atlas.atlas.resource_path)
	assert(actual.position == expected.position)
	assert(actual.size == expected.size)
