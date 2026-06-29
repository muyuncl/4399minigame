class_name CardData
extends RefCounted

enum Kind {
    NORMAL,
    WAREHOUSE
}

var kind: int = Kind.NORMAL
var talent_type: String = ""
var label: String = ""
var short_label: String = ""
var color_hex: String = "#ffffff"
var value: int = 1


static func create_normal(type_id: String, type_label: String, type_short: String, card_color: String, card_value: int) -> CardData:
    var card := CardData.new()
    card.kind = Kind.NORMAL
    card.talent_type = type_id
    card.label = type_label
    card.short_label = type_short
    card.color_hex = card_color
    card.value = card_value
    return card


static func create_warehouse(type_label: String, type_short: String, card_color: String, card_value: int) -> CardData:
    var card := CardData.new()
    card.kind = Kind.WAREHOUSE
    card.label = type_label
    card.short_label = type_short
    card.color_hex = card_color
    card.value = card_value
    return card


func clone() -> CardData:
    var card := CardData.new()
    card.kind = kind
    card.talent_type = talent_type
    card.label = label
    card.short_label = short_label
    card.color_hex = color_hex
    card.value = value
    return card


func is_normal() -> bool:
    return kind == Kind.NORMAL


func is_warehouse() -> bool:
    return kind == Kind.WAREHOUSE


func display_name() -> String:
    return "%s %d" % [label, value]
