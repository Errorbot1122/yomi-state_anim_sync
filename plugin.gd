tool
extends EditorPlugin

const HITBOX_ANIM := preload("res://addons/state_anim_sync/HitboxAnim.tscn")
var panel_instance


func _enter_tree() -> void:
	panel_instance = HITBOX_ANIM.instance()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, panel_instance)
	
	panel_instance.set_plugin(self)
	panel_instance._update_hitbox_panel_state()
	panel_instance._sync_for_current_selection()

func _exit_tree() -> void:
	remove_control_from_docks(panel_instance)
	
	if panel_instance:
		panel_instance.queue_free()


	















	



