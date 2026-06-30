extends Node

const LiveAccountScript := preload("res://scripts/live/live_account.gd")

var _failures: Array[String] = []


func _ready() -> void:
	_test_create_trims_name_and_reserves_id()
	_test_create_uses_default_name_when_blank()
	_test_id_format_is_six_digits()

	if _failures.is_empty():
		print("LiveAccount tests passed.")
		await get_tree().create_timer(0.2).timeout
		get_tree().quit(0)
		return

	for failure in _failures:
		push_error(failure)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(1)


func _test_create_trims_name_and_reserves_id() -> void:
	var used_ids := {}
	var account = LiveAccountScript.create("  花火主播  ", 2, used_ids)

	_expect(account.display_name == "花火主播", "create should trim display names.")
	_expect(account.avatar_index == 2, "create should keep the selected avatar index.")
	_expect(account.heat == 0, "new accounts should start with zero heat.")
	_expect(used_ids.has(account.account_id), "create should reserve the generated id.")


func _test_create_uses_default_name_when_blank() -> void:
	var account = LiveAccountScript.create("   ", 0, {})

	_expect(account.display_name == "P1 主播", "blank names should fall back to P1 主播.")


func _test_id_format_is_six_digits() -> void:
	var account = LiveAccountScript.create("测试主播", 1, {})

	_expect(LiveAccountScript.is_valid_id(account.account_id), "generated ids should be six digits.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
