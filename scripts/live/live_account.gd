class_name LiveAccount
extends RefCounted

const DEFAULT_DISPLAY_NAME := "P1 主播"

var display_name: String = DEFAULT_DISPLAY_NAME
var account_id: String = ""
var avatar_index: int = 0
var heat: int = 0


static func create(raw_name: String, selected_avatar_index: int, used_ids: Dictionary) -> RefCounted:
	var account = load("res://scripts/live/live_account.gd").new()
	account.display_name = _clean_display_name(raw_name)
	account.avatar_index = max(selected_avatar_index, 0)
	account.heat = 0
	account.account_id = _generate_unique_id(used_ids)
	used_ids[account.account_id] = true
	return account


static func is_valid_id(value: String) -> bool:
	if value.length() != 6:
		return false
	for index in range(value.length()):
		var code := value.unicode_at(index)
		if code < 48 or code > 57:
			return false
	return true


static func _clean_display_name(raw_name: String) -> String:
	var cleaned := raw_name.strip_edges()
	if cleaned.is_empty():
		return DEFAULT_DISPLAY_NAME
	return cleaned


static func _generate_unique_id(used_ids: Dictionary) -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for _attempt in range(200):
		var candidate := "%06d" % rng.randi_range(0, 999999)
		if not used_ids.has(candidate):
			return candidate

	var fallback := 0
	while fallback <= 999999:
		var candidate := "%06d" % fallback
		if not used_ids.has(candidate):
			return candidate
		fallback += 1

	return "000000"
