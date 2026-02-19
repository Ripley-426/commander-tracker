extends RefCounted
class_name PersistenceStore

const ACTIVE_SAVE_PATH := "user://active_game.save"
const BACKUP_SAVE_PATH := "user://active_game.backup.save"
const TEMP_SAVE_PATH := "user://active_game.tmp.save"

func has_active_game() -> bool:
	return FileAccess.file_exists(ACTIVE_SAVE_PATH) or FileAccess.file_exists(BACKUP_SAVE_PATH)

func load_active_game() -> Dictionary:
	var data := _load_path(ACTIVE_SAVE_PATH)
	if not data.is_empty():
		return data
	data = _load_path(BACKUP_SAVE_PATH)
	if not data.is_empty():
		# Promote backup to active for the next boot.
		save_active_game(data)
		return data
	return {}

func clear_active_game() -> void:
	_remove_file(ACTIVE_SAVE_PATH)
	_remove_file(BACKUP_SAVE_PATH)
	_remove_file(TEMP_SAVE_PATH)

func save_active_game(data: Dictionary) -> bool:
	var to_save: Dictionary = data.duplicate(true)
	to_save["updated_at_unix"] = Time.get_unix_time_from_system()

	var payload := JSON.stringify(to_save)
	if payload.is_empty():
		push_error("Could not encode save payload.")
		return false

	if not _write_text_file(TEMP_SAVE_PATH, payload):
		return false

	if FileAccess.file_exists(ACTIVE_SAVE_PATH):
		var copied := _copy_file(ACTIVE_SAVE_PATH, BACKUP_SAVE_PATH)
		if not copied:
			push_warning("Could not refresh backup file before active save.")

	if not _promote_temp_to_active():
		# Final fallback: write directly to active file.
		return _write_text_file(ACTIVE_SAVE_PATH, payload)

	return true

func _load_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open save file for read: %s" % path)
		return {}

	var raw := file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save data invalid at: %s" % path)
		return {}

	var parsed_dict: Dictionary = parsed
	if not GameState.validate(parsed_dict):
		push_warning("Save data invalid at: %s" % path)
		return {}

	var normalized: Dictionary = GameState.normalize_loaded_state(parsed_dict)
	return normalized

func _promote_temp_to_active() -> bool:
	var temp_abs := ProjectSettings.globalize_path(TEMP_SAVE_PATH)
	var active_abs := ProjectSettings.globalize_path(ACTIVE_SAVE_PATH)

	if FileAccess.file_exists(ACTIVE_SAVE_PATH):
		DirAccess.remove_absolute(active_abs)
	var result := DirAccess.rename_absolute(temp_abs, active_abs)
	return result == OK

func _write_text_file(path: String, payload: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file for write: %s" % path)
		return false
	file.store_string(payload)
	return true

func _copy_file(source: String, destination: String) -> bool:
	var source_file := FileAccess.open(source, FileAccess.READ)
	if source_file == null:
		return false
	var bytes := source_file.get_buffer(source_file.get_length())

	var destination_file := FileAccess.open(destination, FileAccess.WRITE)
	if destination_file == null:
		return false
	destination_file.store_buffer(bytes)
	return true

func _remove_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.remove_absolute(absolute)
