extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://preview/expression_picker.tscn")
	assert(scene != null)
	var picker: Control = scene.instantiate()
	root.add_child(picker)
	await process_frame
	picker._choices = picker._default_choices()
	picker._refresh()
	for source_id in picker.SOURCES:
		var source: Dictionary = picker.SOURCES[source_id]
		var atlas: Texture2D = picker._source_texture(source_id)
		assert(atlas != null)
		for index in picker._eye_count(source):
			var eye_region: Rect2 = picker._eye_region(source, index)
			assert(eye_region.end.x <= atlas.get_width())
			assert(eye_region.end.y <= atlas.get_height())
		var mouth_size: Vector2i = source["mouth_size"]
		var mouth_end: Vector2i = source["mouth_origin"] + Vector2i(mouth_size.x, mouth_size.y * source["mouth_count"])
		assert(mouth_end.x <= atlas.get_width())
		assert(mouth_end.y <= atlas.get_height())
	assert(picker._choices["idle"]["front"]["eye"] == 14)
	assert((picker._eye_nodes["front"].texture as AtlasTexture).region == Rect2(634, 291, 198, 97))
	assert((picker._eye_nodes["battle"].texture as AtlasTexture).region == Rect2(314, 74, 115, 74))

	picker._adjust("eye", 1)
	assert(picker._choices["idle"]["front"]["eye"] == 15)
	assert((picker._eye_nodes["front"].texture as AtlasTexture).region == Rect2(832, 291, 198, 97))
	picker._on_preset_selected(3)
	assert(picker._choices["surprised"]["front"]["eye"] == 14)
	assert((picker._eye_nodes["front"].texture as AtlasTexture).region == Rect2(1030, 194, 198, 97))
	assert((picker._mouth_nodes["front"].texture as AtlasTexture).region == Rect2(481, 51, 14, 17))
	picker._on_source_selected(2, "eye")
	assert(picker._choices["surprised"]["front"]["eye_source"] == "front_9")
	assert((picker._eye_nodes["front"].texture as AtlasTexture).region == Rect2(238, 0, 198, 97))
	picker._adjust("eye", 19)
	assert((picker._eye_nodes["front"].texture as AtlasTexture).region == Rect2(832, 388, 198, 97))
	picker._on_source_selected(2, "mouth")
	picker._adjust("mouth", 19)
	assert((picker._mouth_nodes["front"].texture as AtlasTexture).region == Rect2(1031, 323, 14, 17))
	picker._on_pose_selected(1)
	picker._on_source_selected(1, "eye")
	picker._adjust("eye", 19)
	assert((picker._eye_nodes["battle"].texture as AtlasTexture).region == Rect2(542, 405, 114, 81))
	picker._on_source_selected(2, "mouth")
	picker._adjust("mouth", 19)
	assert((picker._mouth_nodes["battle"].texture as AtlasTexture).region == Rect2(775, 285, 14, 15))
	picker._toggle_zoom()
	assert(picker._art_roots["front"].scale == Vector2(2, 2))
	picker._reset_current()
	assert(picker._choices["surprised"]["battle"]["eye"] == 7)
	assert(picker._as_json()["idle"]["front"]["eye"] == 15)
	assert(picker._as_json()["idle"]["front"]["eye_source"] == "front_9")
	print("expression_picker_smoke: PASS")
	quit(0)
