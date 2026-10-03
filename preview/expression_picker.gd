extends Control

const FRONT_ATLAS: Texture2D = preload("res://ReactiveCompanionUI_hcxmmx/images/chino/front.png")
const SIDE_ATLAS: Texture2D = preload("res://ReactiveCompanionUI_hcxmmx/images/chino/side.png")
const MOD_VISUAL = preload("res://ReactiveCompanionUI_hcxmmx/scripts/companion_visual.gd")
const CHOICES_PATH := "res://preview/expression_choices.json"
const PRESET_KEYS := ["idle", "thinking", "happy", "surprised", "worried"]
const PRESET_NAMES := ["默认", "思考", "开心", "惊讶", "担心"]
const SOURCE_IDS := {
	"front": ["front_4", "front_6", "front_9"],
	"battle": ["side_2", "side_1", "side_3", "side_5"],
}
const SOURCES := {
	"front_4": {
		"label": "day_4 · 现用（眼8 / 嘴9）",
		"path": "res://ReactiveCompanionUI_hcxmmx/images/chino/front.png",
		"eye_origin": Vector2i(238, 0), "eye_size": Vector2i(121, 70),
		"eye_rows": [2, 1, 1, 1, 1, 1, 1], "eye_order": "column_first", "eye_at": Vector2(55, 98),
		"mouth_origin": Vector2i(481, 0), "mouth_size": Vector2i(14, 17),
		"mouth_count": 9, "mouth_at": Vector2(109, 180),
	},
	"front_6": {
		"label": "day_6 · 更多表情（眼23 / 嘴23）",
		"path": "res://ReactiveCompanionUI_hcxmmx/images/chino/variants/front_day_6.png",
		"eye_origin": Vector2i(238, 0), "eye_size": Vector2i(198, 97),
		"eye_rows": [5, 5, 5, 4, 4], "eye_at": Vector2(19, 98),
		"mouth_origin": Vector2i(1229, 0), "mouth_size": Vector2i(14, 17),
		"mouth_count": 23, "mouth_at": Vector2(108, 182),
	},
	"front_9": {
		"label": "day_9 · 更多表情（眼20 / 嘴20）",
		"path": "res://ReactiveCompanionUI_hcxmmx/images/chino/variants/front_day_9.png",
		"eye_origin": Vector2i(238, 0), "eye_size": Vector2i(198, 97),
		"eye_rows": [4, 4, 4, 4, 4], "eye_at": Vector2(19, 98),
		"mouth_origin": Vector2i(1031, 0), "mouth_size": Vector2i(14, 17),
		"mouth_count": 20, "mouth_at": Vector2(108, 182),
	},
	"side_2": {
		"label": "day_2 · 现用（眼5 / 嘴5）",
		"path": "res://ReactiveCompanionUI_hcxmmx/images/chino/side.png",
		"eye_origin": Vector2i(314, 0), "eye_size": Vector2i(115, 74),
		"eye_rows": [1, 1, 1, 1, 1], "eye_at": Vector2(133, 94),
		"mouth_origin": Vector2i(430, 0), "mouth_size": Vector2i(12, 14),
		"mouth_count": 5, "mouth_at": Vector2(192, 182),
	},
	"side_1": {
		"label": "day_1 · 更多表情（眼20 / 嘴20）",
		"path": "res://ReactiveCompanionUI_hcxmmx/images/chino/variants/side_day_1.png",
		"eye_origin": Vector2i(314, 0), "eye_size": Vector2i(114, 81),
		"eye_rows": [4, 4, 3, 3, 3, 3], "eye_at": Vector2(133, 88),
		"mouth_origin": Vector2i(771, 0), "mouth_size": Vector2i(14, 15),
		"mouth_count": 20, "mouth_at": Vector2(190, 182),
	},
	"side_3": {
		"label": "day_3 · 更多表情（眼20 / 嘴20）",
		"path": "res://ReactiveCompanionUI_hcxmmx/images/chino/variants/side_day_3.png",
		"eye_origin": Vector2i(314, 0), "eye_size": Vector2i(115, 81),
		"eye_rows": [4, 4, 3, 3, 3, 3], "eye_at": Vector2(133, 88),
		"mouth_origin": Vector2i(775, 0), "mouth_size": Vector2i(14, 15),
		"mouth_count": 20, "mouth_at": Vector2(190, 182),
	},
	"side_5": {
		"label": "day_5 · 另组表情（眼8 / 嘴8）",
		"path": "res://ReactiveCompanionUI_hcxmmx/images/chino/variants/side_day_5.png",
		"eye_origin": Vector2i(314, 0), "eye_size": Vector2i(114, 74),
		"eye_rows": [2, 1, 1, 1, 1, 1, 1], "eye_order": "column_first", "eye_at": Vector2(133, 94),
		"mouth_origin": Vector2i(543, 0), "mouth_size": Vector2i(14, 13),
		"mouth_count": 8, "mouth_at": Vector2(190, 183),
	},
}

var _choices: Dictionary = {}
var _current := "idle"
var _editing_pose := "front"
var _face_zoom := false
var _art_roots := {}
var _eye_nodes := {}
var _mouth_nodes := {}
var _frames := {}
var _number_labels := {}
var _summary_labels := {}
var _source_selectors := {}
var _source_cache := {}
var _source_limit_labels := {}
var _status_label: Label


func _ready() -> void:
	_choices = _default_choices()
	_load_choices()
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.075, 0.11, 0.15)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	_add_label("表情组合预览", Vector2(30, 12), Vector2(560, 38), 28)
	_add_label("正面和侧面可分别混搭不同图集的眼型与嘴型；这里只记录选择。", Vector2(30, 52), Vector2(1000, 28), 17)
	_build_portrait("front", FRONT_ATLAS, Vector2(35, 102), Vector2(280, 552), Vector2(230, 538), Vector2(55, 98), Vector2(108, 182))
	_build_portrait("battle", SIDE_ATLAS, Vector2(340, 102), Vector2(340, 552), Vector2(306, 534), Vector2(133, 94), Vector2(192, 182))
	_add_label("正面 · 场外", Vector2(35, 74), Vector2(280, 26), 21)
	_add_label("侧面 · 战斗", Vector2(340, 74), Vector2(340, 26), 21)
	_summary_labels["front"] = _add_label("", Vector2(35, 664), Vector2(280, 32), 16)
	_summary_labels["battle"] = _add_label("", Vector2(340, 664), Vector2(340, 32), 16)

	_add_panel(Vector2(712, 102), Vector2(535, 594))
	_add_label("选择表情", Vector2(738, 116), Vector2(430, 30), 21)
	var selector := OptionButton.new()
	selector.position = Vector2(738, 152)
	selector.size = Vector2(480, 36)
	selector.focus_mode = Control.FOCUS_NONE
	for index in PRESET_KEYS.size():
		selector.add_item("%s  (%s)" % [PRESET_NAMES[index], PRESET_KEYS[index]])
	selector.item_selected.connect(_on_preset_selected)
	add_child(selector)

	_add_label("正在调整", Vector2(738, 206), Vector2(430, 30), 21)
	var pose_selector := OptionButton.new()
	pose_selector.position = Vector2(738, 240)
	pose_selector.size = Vector2(480, 36)
	pose_selector.focus_mode = Control.FOCUS_NONE
	pose_selector.add_item("正面 · 场外")
	pose_selector.add_item("侧面 · 战斗")
	pose_selector.item_selected.connect(_on_pose_selected)
	add_child(pose_selector)

	_add_label("眼型来源", Vector2(738, 290), Vector2(430, 30), 20)
	_source_selectors["eye"] = _build_source_selector("eye", 321)
	_build_stepper("eye", "眼型编号", 363)
	_add_label("嘴型来源", Vector2(738, 413), Vector2(430, 30), 20)
	_source_selectors["mouth"] = _build_source_selector("mouth", 444)
	_build_stepper("mouth", "嘴型编号", 486)

	_add_button("重置当前表情", Vector2(738, 548), Vector2(148, 38), Callable(self, "_reset_current"))
	_add_button("放大面部", Vector2(898, 548), Vector2(138, 38), Callable(self, "_toggle_zoom"))
	_add_button("返回普通预览", Vector2(1050, 548), Vector2(168, 38), Callable(self, "_return_to_preview"))
	_add_button("保存选择", Vector2(738, 598), Vector2(148, 40), Callable(self, "_save_choices"))
	_add_button("复制选择结果", Vector2(898, 598), Vector2(148, 40), Callable(self, "_copy_summary"))
	_status_label = _add_label("", Vector2(738, 650), Vector2(480, 42), 16)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.text = "已读取上次选择。" if FileAccess.file_exists(CHOICES_PATH) else "调整后点“保存选择”；结果会写到 preview/expression_choices.json。"


func _build_portrait(pose: String, atlas: Texture2D, frame_position: Vector2, frame_size: Vector2, body_size: Vector2, eye_position: Vector2, mouth_position: Vector2) -> void:
	var frame := ColorRect.new()
	frame.position = frame_position
	frame.size = frame_size
	frame.color = Color(0.115, 0.165, 0.21)
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	_frames[pose] = frame

	var art := Control.new()
	art.size = body_size
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(art)
	_art_roots[pose] = art
	_add_atlas_part(art, atlas, Rect2(Vector2.ZERO, body_size), Vector2.ZERO, body_size)
	var eye_size := Vector2(121, 70) if pose == "front" else Vector2(115, 74)
	var mouth_size := Vector2(14, 17) if pose == "front" else Vector2(12, 14)
	_eye_nodes[pose] = _add_atlas_part(art, atlas, Rect2(Vector2.ZERO, eye_size), eye_position, eye_size)
	_mouth_nodes[pose] = _add_atlas_part(art, atlas, Rect2(Vector2.ZERO, mouth_size), mouth_position, mouth_size)
	_layout_portrait(pose)


func _add_atlas_part(parent: Node, atlas: Texture2D, region: Rect2, at: Vector2, size: Vector2) -> TextureRect:
	var tile := AtlasTexture.new()
	tile.atlas = atlas
	tile.region = region
	tile.filter_clip = true
	var part := TextureRect.new()
	part.texture = tile
	part.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	part.position = at
	part.size = size
	part.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(part)
	return part


func _build_source_selector(part: String, y: float) -> OptionButton:
	var selector := OptionButton.new()
	selector.position = Vector2(738, y)
	selector.size = Vector2(480, 34)
	selector.focus_mode = Control.FOCUS_NONE
	selector.item_selected.connect(_on_source_selected.bind(part))
	add_child(selector)
	return selector


func _build_stepper(part: String, title: String, y: float) -> void:
	_add_label(title, Vector2(738, y + 4), Vector2(108, 30), 18)
	_add_button("−", Vector2(851, y), Vector2(42, 36), Callable(self, "_adjust").bind(part, -1))
	_number_labels[part] = _add_label("", Vector2(906, y + 4), Vector2(64, 30), 20)
	_add_button("+", Vector2(974, y), Vector2(42, 36), Callable(self, "_adjust").bind(part, 1))
	_source_limit_labels[part] = _add_label("", Vector2(1032, y + 4), Vector2(88, 30), 17)


func _adjust(part: String, delta: int) -> void:
	var choice: Dictionary = _choices[_current][_editing_pose]
	var source: Dictionary = SOURCES[choice[part + "_source"]]
	var count := _eye_count(source) if part == "eye" else int(source["mouth_count"])
	choice[part] = clampi(int(choice[part]) + delta, 0, count - 1)
	_status_label.text = "选择已修改，记得保存。"
	_refresh()


func _on_preset_selected(index: int) -> void:
	_current = PRESET_KEYS[index]
	_refresh()


func _on_pose_selected(index: int) -> void:
	_editing_pose = "front" if index == 0 else "battle"
	_refresh()


func _on_source_selected(index: int, part: String) -> void:
	var source_id: String = SOURCE_IDS[_editing_pose][index]
	var choice: Dictionary = _choices[_current][_editing_pose]
	if choice[part + "_source"] == source_id:
		return
	choice[part + "_source"] = source_id
	choice[part] = 0
	_status_label.text = "已切换%s来源，编号从 0 开始；记得保存。" % ("眼型" if part == "eye" else "嘴型")
	_refresh()


func _refresh() -> void:
	for pose in ["front", "battle"]:
		var choice: Dictionary = _choices[_current][pose]
		var eye_source: Dictionary = SOURCES[choice["eye_source"]]
		var mouth_source: Dictionary = SOURCES[choice["mouth_source"]]
		_summary_labels[pose].text = "%s 眼%d · %s 嘴%d" % [_short_source(choice["eye_source"]), choice["eye"], _short_source(choice["mouth_source"]), choice["mouth"]]
		var eye_tile := AtlasTexture.new()
		var mouth_tile := AtlasTexture.new()
		eye_tile.atlas = _source_texture(choice["eye_source"])
		eye_tile.region = _eye_region(eye_source, int(choice["eye"]))
		eye_tile.filter_clip = true
		mouth_tile.atlas = _source_texture(choice["mouth_source"])
		var mouth_size: Vector2i = mouth_source["mouth_size"]
		var mouth_origin: Vector2i = mouth_source["mouth_origin"]
		mouth_tile.region = Rect2(mouth_origin + Vector2i(0, int(choice["mouth"]) * mouth_size.y), mouth_size)
		mouth_tile.filter_clip = true
		_eye_nodes[pose].texture = eye_tile
		_eye_nodes[pose].position = eye_source["eye_at"]
		_eye_nodes[pose].size = eye_source["eye_size"]
		_mouth_nodes[pose].texture = mouth_tile
		_mouth_nodes[pose].position = mouth_source["mouth_at"]
		_mouth_nodes[pose].size = mouth_size

	var active: Dictionary = _choices[_current][_editing_pose]
	for part in ["eye", "mouth"]:
		var selector: OptionButton = _source_selectors[part]
		selector.clear()
		var ids: Array = SOURCE_IDS[_editing_pose]
		for source_id in ids:
			selector.add_item(SOURCES[source_id]["label"])
		selector.select(ids.find(active[part + "_source"]))
		_number_labels[part].text = str(active[part])
		var source: Dictionary = SOURCES[active[part + "_source"]]
		var count := _eye_count(source) if part == "eye" else int(source["mouth_count"])
		_source_limit_labels[part].text = "0–%d" % (count - 1)


func _source_texture(source_id: String) -> Texture2D:
	if not _source_cache.has(source_id):
		_source_cache[source_id] = load(SOURCES[source_id]["path"])
	return _source_cache[source_id]


func _short_source(source_id: String) -> String:
	return source_id.replace("front_", "day_").replace("side_", "day_")


func _eye_count(source: Dictionary) -> int:
	var count := 0
	for length in source["eye_rows"]:
		count += int(length)
	return count


func _eye_region(source: Dictionary, index: int) -> Rect2:
	var column := index
	var rows: Array = source["eye_rows"]
	var tile_size: Vector2i = source["eye_size"]
	var origin: Vector2i = source["eye_origin"]
	if source.get("eye_order", "") == "column_first":
		var cell := Vector2i(0, index) if index < rows.size() else Vector2i(index - rows.size() + 1, 0)
		return Rect2(origin + cell * tile_size, tile_size)
	for row in rows.size():
		if column < int(rows[row]):
			return Rect2(origin + Vector2i(column * tile_size.x, row * tile_size.y), tile_size)
		column -= int(rows[row])
	return Rect2(origin, tile_size)


func _toggle_zoom() -> void:
	_face_zoom = not _face_zoom
	for pose in ["front", "battle"]:
		_layout_portrait(pose)


func _layout_portrait(pose: String) -> void:
	var art: Control = _art_roots[pose]
	var frame: ColorRect = _frames[pose]
	if _face_zoom:
		art.scale = Vector2(2.0, 2.0)
		var face_center := Vector2(115, 148) if pose == "front" else Vector2(185, 148)
		art.position = frame.size * 0.5 - face_center * 2.0
	else:
		art.scale = Vector2.ONE
		art.position = (frame.size - art.size) * 0.5


func _reset_current() -> void:
	_choices[_current] = _default_choices()[_current]
	_status_label.text = "当前表情已恢复到 Mod 现有配置，记得保存。"
	_refresh()


func _default_choices() -> Dictionary:
	return MOD_VISUAL.EXPRESSIONS.duplicate(true)


func _load_choices() -> void:
	if not FileAccess.file_exists(CHOICES_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CHOICES_PATH))
	if not parsed is Dictionary:
		return
	for key in PRESET_KEYS:
		var preset: Variant = parsed.get(key)
		if not preset is Dictionary:
			continue
		for pose in ["front", "battle"]:
			var values: Variant = preset.get(pose)
			if not values is Dictionary:
				continue
			var choice: Dictionary = _choices[key][pose]
			for part in ["eye", "mouth"]:
				var source_id: String = values.get(part + "_source", choice[part + "_source"])
				if not SOURCE_IDS[pose].has(source_id):
					continue
				var source: Dictionary = SOURCES[source_id]
				var count := _eye_count(source) if part == "eye" else int(source["mouth_count"])
				choice[part + "_source"] = source_id
				choice[part] = clampi(int(values.get(part, choice[part])), 0, count - 1)


func _as_json() -> Dictionary:
	var result := {}
	for key in PRESET_KEYS:
		result[key] = {}
		for pose in ["front", "battle"]:
			result[key][pose] = _choices[key][pose].duplicate(true)
	return result


func _save_choices() -> void:
	var file := FileAccess.open(CHOICES_PATH, FileAccess.WRITE)
	if file == null:
		_status_label.text = "保存失败：%s。可以点“复制选择结果”发给我。" % error_string(FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(_as_json(), "  "))
	file.close()
	_status_label.text = "已保存到 preview/expression_choices.json。选好后告诉我即可。"


func _copy_summary() -> void:
	var lines: PackedStringArray = []
	for index in PRESET_KEYS.size():
		var key: String = PRESET_KEYS[index]
		var front: Dictionary = _choices[key]["front"]
		var battle: Dictionary = _choices[key]["battle"]
		lines.append("%s：正面眼%s/%d 嘴%s/%d；侧面眼%s/%d 嘴%s/%d" % [PRESET_NAMES[index], front["eye_source"], front["eye"], front["mouth_source"], front["mouth"], battle["eye_source"], battle["eye"], battle["mouth_source"], battle["mouth"]])
	DisplayServer.clipboard_set("\n".join(lines))
	_status_label.text = "全部表情编号已复制，直接粘贴到聊天里即可。"


func _return_to_preview() -> void:
	get_tree().change_scene_to_file("res://preview/preview.tscn")


func _add_panel(at: Vector2, dimensions: Vector2) -> void:
	var panel := ColorRect.new()
	panel.position = at
	panel.size = dimensions
	panel.color = Color(0.105, 0.15, 0.2)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)


func _add_label(value: String, at: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.93, 0.97, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _add_button(value: String, at: Vector2, dimensions: Vector2, action: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.position = at
	button.size = dimensions
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	add_child(button)
	return button
