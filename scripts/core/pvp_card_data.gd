class_name PvpCardData
extends RefCounted

var type_id: String = ""
var label: String = ""
var short_label: String = ""
var value: int = 1
var color: Color = Color.WHITE
var art_path: String = ""


static func create(type_id_value: String, label_value: String, short_value: String, card_value: int, card_color: Color, card_art_path: String = "") -> PvpCardData:
	var card := PvpCardData.new()
	card.type_id = type_id_value
	card.label = label_value
	card.short_label = short_value
	card.value = card_value
	card.color = card_color
	card.art_path = card_art_path
	return card


func clone() -> PvpCardData:
	return PvpCardData.create(type_id, label, short_label, value, color, art_path)


func is_wild() -> bool:
	return type_id == "wild"
