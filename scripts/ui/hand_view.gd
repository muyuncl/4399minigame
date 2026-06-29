class_name HandView
extends VBoxContainer

signal card_drag_started(card_view: CardView, hand_index: int, grab_position: Vector2)

func _ready() -> void:
    add_theme_constant_override("separation", 12)


func refresh(cards: Array, game_over: bool) -> void:
    for child in get_children():
        remove_child(child)
        child.queue_free()

    for i in range(cards.size()):
        var card_view := CardView.new()
        card_view.set_card(cards[i], i, not game_over)
        card_view.custom_minimum_size = CardView.CARD_SIZE
        card_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        card_view.manual_drag_started.connect(_on_card_manual_drag_started)
        add_child(card_view)


func _on_card_manual_drag_started(card_view: CardView, hand_index: int, grab_position: Vector2) -> void:
    card_drag_started.emit(card_view, hand_index, grab_position)
