tool
extends VBoxContainer

var _selection
var plugin
var ticks_per_frame :float= 1

var last_selected_node_index :int= 0
var last_scene_root

func _ready() -> void:
	pass

func set_plugin(script):
	plugin = script
	_selection = plugin.get_editor_interface().get_selection()
	_selection.connect("selection_changed", self, "_on_selection_changed")
	
	$"%FrameStart".connect("pressed", self, "_on_set_frame_to_start_tick")
	$"%FrameEnd".connect("pressed", self, "_on_set_frame_to_end_tick")
	
	$"%BWD".connect("pressed", self, "_on_frame_adv_down")
	$"%FWD".connect("pressed", self, "_on_frame_adv_up")
	
	$"%AnimSync".connect("toggled", self, "_on_sync_toggled")
	$"%AnimSprites".connect("item_selected", self, "_on_animsprite_selected")
	
func _on_frame_adv_up():
	_adv_spriteframe(false)

func _on_frame_adv_down():
	_adv_spriteframe(true)
	
func _adv_spriteframe(back:bool):
	
	var selected := _get_single_selected_node()
#	if not _node_has_tick_fields(selected):
#		return
	
	var scene_root = plugin.get_editor_interface().get_edited_scene_root()
	if not scene_root: return
	
	var anim_sprite := _get_current_animsprite()
	if not anim_sprite or not anim_sprite.frames:
		return

	var anim_names := anim_sprite.frames.get_animation_names()
	var wanted_anim := _find_matching_name_from_hierarchy(selected, anim_names)

	var effective_anim := anim_sprite.animation
	if wanted_anim != "":
		effective_anim = wanted_anim

	if effective_anim == "": return

	var frame_count := anim_sprite.frames.get_frame_count(effective_anim)
	if frame_count <= 0: return

	var adv = 1
	if back: adv = -1
	
	anim_sprite.frame = Utils.int_clamp(anim_sprite.frame+adv, 0, frame_count)
	set_frame(anim_sprite.frame)
	
	
	
	
	

	
	
	
	
	
func _on_set_frame_to_start_tick() -> void:
	_apply_sync(null, false)

func _on_set_frame_to_end_tick() -> void:
	_apply_sync(null, true)
	
func _apply_sync(start_node:Node2D, use_end_tick = false) -> void:
	var scene_root = plugin.get_editor_interface().get_edited_scene_root()
	if not scene_root: return
	
	var anim_sprite := _get_current_animsprite()
	if not anim_sprite or not anim_sprite.frames: return
	var anim_names := anim_sprite.frames.get_animation_names()

	if start_node == null:
		var selected := _get_single_selected_node()
		if not _node_has_tick_fields(selected):
			return
		
		var wanted_anim := _find_matching_name_from_hierarchy(selected, anim_names)
		var effective_anim := anim_sprite.animation
		if wanted_anim != "":
			effective_anim = wanted_anim
		if effective_anim == "": return
	
		var frame_count := anim_sprite.frames.get_frame_count(effective_anim)
		if frame_count <= 0: return

		var start_tick := int(selected.get("start_tick"))
		var active_ticks := int(selected.get("active_ticks"))
		if active_ticks < 1:
			active_ticks = 1

		var tick := start_tick
		if use_end_tick:
			tick = start_tick + (active_ticks - 1)

		var desired_frame := _tick_to_frame_index_for_node(tick, selected)
		if desired_frame < 0:
			desired_frame = 0
		elif desired_frame > frame_count - 1:
			desired_frame = frame_count - 1
		
		var will_change_anim := (wanted_anim != "" and anim_sprite.animation != wanted_anim)
		var will_change_frame := (anim_sprite.frame != desired_frame)
		if not will_change_anim and not will_change_frame:
			return

		var undo = plugin.get_undo_redo()
		undo.create_action("Hitbox Options: sync anim + set frame")

		if will_change_anim:
			undo.add_do_property(anim_sprite, "animation", wanted_anim)
			undo.add_undo_property(anim_sprite, "animation", anim_sprite.animation)

		if will_change_frame:
			undo.add_do_property(anim_sprite, "frame", desired_frame)
			undo.add_undo_property(anim_sprite, "frame", anim_sprite.frame)

		undo.commit_action()
		set_frame(anim_sprite.frame)
		return
		

	if not scene_root: return
	if not anim_sprite or not anim_sprite.frames: return

	var wanted_anim := _find_matching_name_from_hierarchy(start_node, anim_names)
	var effective_anim := anim_sprite.animation

	if wanted_anim != "":
		effective_anim = wanted_anim
	if effective_anim == "": return
	
	var frame_count := anim_sprite.frames.get_frame_count(effective_anim)
	if frame_count <= 0: return
	
	var desired_frame := _hitbox_matching_frame(start_node)
	if desired_frame < 0:
		desired_frame = 0
	elif desired_frame > frame_count - 1:
		desired_frame = frame_count - 1
	
	var will_change_anim := (wanted_anim != "" and anim_sprite.animation != wanted_anim)
	var will_change_frame := (anim_sprite.frame != desired_frame) and (start_node is Hitbox or start_node is HurtboxState or start_node is LimbHurtbox)
	if not will_change_anim and not will_change_frame:
		return
		
	if will_change_anim or will_change_frame:
		var undo = plugin.get_undo_redo()
		undo.create_action("Sync AnimatedSprite animation to state")

		undo.add_do_property(anim_sprite, "animation", wanted_anim)
		undo.add_undo_property(anim_sprite, "animation", anim_sprite.animation)

		undo.add_do_property(anim_sprite, "frame", desired_frame)
		undo.add_undo_property(anim_sprite, "frame", anim_sprite.frame)

		undo.commit_action()
















func _on_sync_toggled(on):
	pass

func _on_animsprite_selected(index:int):
	pass

func _get_current_animsprite() -> AnimatedSprite:
	var scene_root = plugin.get_editor_interface().get_edited_scene_root()
	if $"%AnimSprites".get_selected_id() == 0:
		if not scene_root:
			return null
		return _dfs_find_first_animated_sprite(scene_root)
		
	else:
		var nodes := get_animsprites(scene_root)
		return nodes[$"%AnimSprites".get_selected_id()-1]
		
func _update_hitbox_panel_state() -> void:
	var node = _get_single_selected_node()
	var ok := _node_has_tick_fields(node)
	$"%FrameStart".disabled = not ok
	$"%FrameEnd".disabled = not ok
	$"%FWD".disabled = false
	$"%BWD".disabled = false
	$"%AnimSync".disabled = false
	$"%AnimSprites".disabled = false
	
	var scene_root = plugin.get_editor_interface().get_edited_scene_root()
	if not scene_root:
		$"%AnimNumber".text = "   "
		return
		
	last_selected_node_index = $"%AnimSprites".get_selected_id()
	$"%AnimSprites".clear()
	$"%AnimSprites".add_item("Default")
	for i in get_animsprites(scene_root):
		if i is AnimatedSprite:
			var icon = plugin.get_editor_interface().get_base_control().get_icon("AnimatedSprite", "EditorIcons")
			$"%AnimSprites".add_icon_item(icon, i.name)
	if last_selected_node_index > $"%AnimSprites".get_item_count()-1:
		last_selected_node_index = $"%AnimSprites".get_item_count()-1
	if last_scene_root and scene_root == last_scene_root:
		$"%AnimSprites".select(last_selected_node_index)
		
	var anim_sprite := _get_current_animsprite()
	if not anim_sprite or not anim_sprite.frames:
		$"%AnimNumber".text = "   "
		$"%FWD".disabled = true
		$"%BWD".disabled = true
		$"%AnimSync".disabled = true
		$"%AnimSync".set_pressed_no_signal(false)
		return
	set_frame(anim_sprite.frame)

func _on_selection_changed() -> void:
	_update_hitbox_panel_state()
	var scene_root = plugin.get_editor_interface().get_edited_scene_root()
	last_scene_root = scene_root
	_sync_for_current_selection()

func _sync_for_current_selection() -> void:
	var nodes := []
	if _selection:
		nodes = _selection.get_selected_nodes()
	if nodes.empty():
		return
	var picked = nodes[0]
	if not $"%AnimSync".pressed:
		_apply_sync(picked)
	_update_hitbox_panel_state()

func _dfs_find_first_animated_sprite(n: Node) -> AnimatedSprite:
	if n is AnimatedSprite and n.name == "Sprite":
		return n as AnimatedSprite

	for c in n.get_children():
		if c is Node:
			var found := _dfs_find_first_animated_sprite(c)
			if found:
				return found
	return null

func get_animsprites(root: Node) -> Array:
	var result := []
	_collect_nodes(root, result)
	return result

func _collect_nodes(node: Node, result: Array) -> void:
	if node is AnimatedSprite:
		result.append(node)

	for child in node.get_children():
		_collect_nodes(child, result)
	
func _find_matching_name_from_hierarchy(node: Node, anim_names: PoolStringArray) -> String:
	var seen := {}
	var current := node
	while current:
		var candidate := String(current.name)
		if current is ObjectState and not current.sprite_animation.empty():
			candidate = String(current.sprite_animation)

		if not seen.has(candidate):
			seen[candidate] = true
			if _animation_exists(anim_names, candidate):
				return candidate

		current = current.get_parent()
	return ""

func _hitbox_matching_frame(node: Node) -> int:
	var current := node
	
	ticks_per_frame = 1.0
	if current.get_parent() is ObjectState:
		ticks_per_frame = current.get_parent().ticks_per_frame
		ticks_per_frame = max(ticks_per_frame, 1.0)
		
	if current is Hitbox:
		return int(ceil(current.start_tick/ticks_per_frame)) - 1
		
	elif current is HurtboxState or current is LimbHurtbox:
		return int(ceil(current.start_tick/ticks_per_frame))
		
	return 0
	
func _get_single_selected_node() -> Node:
	if not _selection:
		return null
	var nodes = _selection.get_selected_nodes()
	if nodes.empty():
		return null
	return nodes[0]

func _animation_exists(anim_names: PoolStringArray, name: String) -> bool:
	for n in anim_names:
		if n == name:
			return true
	return false
	
func _node_has_tick_fields(n: Node) -> bool:
	if not n:
		return false
	# Works for custom Hitbox/CollisionBox scripts as long as they expose these properties.
	return ("start_tick" in n) and ("active_ticks" in n)

func _tick_to_frame_index_for_node(tick: int, n: Node) -> int:

	if _is_hitbox(n):
		return int(ceil(tick/ticks_per_frame)) - 1

	if _is_collision_box(n):
		return int(ceil(tick/ticks_per_frame))

	return tick - 1

func _is_hitbox(n: Node) -> bool:
	return n is Hitbox

func _is_collision_box(n: Node) -> bool:
	return (n is HurtboxState) or (n is LimbHurtbox)

func set_frame(frame:int):
	$"%AnimNumber".text = str(" ", frame+1, " ")
