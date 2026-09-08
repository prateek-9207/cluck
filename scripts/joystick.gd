extends Control
var value = Vector2.ZERO
var origin = Vector2.ZERO
var knob = Vector2.ZERO
var finger = -1
var enabled = false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _input(event):
	if not enabled: return
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1 and event.position.y > size.y * .25:
			finger = event.index; origin = event.position; knob = origin
		elif not event.pressed and event.index == finger: release()
	elif event is InputEventScreenDrag and event.index == finger: update_stick(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.position.y > size.y * .25:
			finger = 99; origin = event.position; knob = origin
		elif not event.pressed: release()
	elif event is InputEventMouseMotion and finger == 99: update_stick(event.position)
	queue_redraw()

func update_stick(pos):
	value = (pos - origin).limit_length(64) / 64
	knob = origin + value * 64

func release():
	finger = -1; value = Vector2.ZERO; queue_redraw()

func _draw():
	if not enabled: return
	var p = origin if finger >= 0 else Vector2(size.x * .5, size.y - 122)
	draw_circle(p, 67, Color(1, .94, .75, .08))
	draw_arc(p, 67, 0, TAU, 48, Color(1, .94, .75, .3), 2, true)
	draw_circle(knob if finger >= 0 else p, 27, Color(1, .94, .75, .32))
