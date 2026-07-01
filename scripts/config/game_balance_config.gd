class_name GameBalanceConfig
extends RefCounted

const WILD_TYPE_ID := "wild"
const WILD_CARD_WEIGHT := 0.1

const NORMAL_CARD_TYPES := [
	{"type_id": "game", "label": "游戏", "short": "游", "color": Color(0.24, 0.48, 0.95)},
	{"type_id": "chat", "label": "聊天", "short": "聊", "color": Color(0.95, 0.62, 0.22)},
	{"type_id": "talent", "label": "才艺", "short": "艺", "color": Color(0.82, 0.34, 0.78)}
]

const WILD_CARD_DATA := {
	"type_id": WILD_TYPE_ID,
	"label": "万能",
	"short": "万",
	"color": Color(0.25, 0.65, 0.38)
}

const VALUE_PROBABILITY_BY_ROUND := [
	{"from": 1, "to": 5, "weights": [0.2, 0.25, 0.25, 0.2, 0.1, 0.0, 0.0, 0.0]},
	{"from": 6, "to": 10, "weights": [0.2, 0.2, 0.25, 0.15, 0.1, 0.1, 0.0, 0.0]},
	{"from": 11, "to": 15, "weights": [0.15, 0.15, 0.15, 0.2, 0.15, 0.1, 0.1, 0.0]},
	{"from": 16, "to": 20, "weights": [0.1, 0.1, 0.15, 0.15, 0.1, 0.1, 0.1, 0.1]},
	{"from": 21, "to": 25, "weights": [0.1, 0.1, 0.1, 0.1, 0.15, 0.15, 0.15, 0.15]}
]


static func roll_card(rng: RandomNumberGenerator, round_number: int) -> PvpCardData:
	var value: int = roll_card_value(rng, round_number)
	var data: Dictionary = WILD_CARD_DATA
	if rng.randf() >= WILD_CARD_WEIGHT:
		data = NORMAL_CARD_TYPES[rng.randi_range(0, NORMAL_CARD_TYPES.size() - 1)]

	var card_color: Color = data["color"]
	return PvpCardData.create(
		str(data["type_id"]),
		str(data["label"]),
		str(data["short"]),
		value,
		card_color
	)


static func roll_card_value(rng: RandomNumberGenerator, round_number: int) -> int:
	var weights: Array = get_value_weights(round_number)
	var total: float = 0.0
	for weight_value in weights:
		total += float(weight_value)

	if total <= 0.0:
		return 1

	var roll: float = rng.randf() * total
	var cursor: float = 0.0
	for i in range(weights.size()):
		cursor += float(weights[i])
		if roll <= cursor:
			return i + 1

	return weights.size()


static func get_value_weights(round_number: int) -> Array:
	for row in VALUE_PROBABILITY_BY_ROUND:
		var row_data: Dictionary = row
		if round_number >= int(row_data["from"]) and round_number <= int(row_data["to"]):
			return row_data["weights"]
	return VALUE_PROBABILITY_BY_ROUND[VALUE_PROBABILITY_BY_ROUND.size() - 1]["weights"]
