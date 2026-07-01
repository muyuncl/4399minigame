class_name DraftPoolView
extends GridContainer

signal card_clicked(index: int)

const SELF_SELECTION_COLOR := Color(0.18, 0.52, 1.0)
const REMOTE_SELECTION_COLOR := Color(0.92, 0.14, 0.12)

var _card_views: Array[CardView] = []


func _ready() -> void:
    columns = 2
    add_theme_constant_override("h_separation", 12)
    add_theme_constant_override("v_separation", 8)


func refresh(cards: Array, can_claim: bool, self_selected_index: int = -1, remote_selected_index: int = -1) -> void:
    for child in get_children():
        remove_child(child)
        child.queue_free()
    _card_views.clear()

    for i in range(cards.size()):
        var card = cards[i]
        var holder := CenterContainer.new()
        holder.custom_minimum_size = Vector2(82, 98)
        add_child(holder)

        if card == null:
            var empty := Label.new()
            empty.text = "已抢"
            empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            empty.add_theme_font_size_override("font_size", 14)
            empty.add_theme_color_override("font_color", Color(0.24, 0.16, 0.1, 0.55))
            holder.add_child(empty)
            continue

        var card_view := CardView.new()
        card_view.set_compact(true)
        var selected_by_self := i == self_selected_index
        var selected_by_remote := i == remote_selected_index
        card_view.set_card(card, i, can_claim and not selected_by_remote)
        if selected_by_self:
            card_view.set_selection_outline(SELF_SELECTION_COLOR)
        elif selected_by_remote:
            card_view.set_selection_outline(REMOTE_SELECTION_COLOR)
        card_view.manual_drag_started.connect(_on_card_clicked)
        holder.add_child(card_view)
        _card_views.append(card_view)


func _on_card_clicked(_card_view: CardView, index: int, _grab_position: Vector2) -> void:
    card_clicked.emit(index)
