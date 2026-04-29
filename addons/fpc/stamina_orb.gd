extends Control

const ORB_RADIUS := 32.0
const CENTER := Vector2(40.0, 40.0)
const LOW_THRESHOLD := 0.3

var _character : CharacterBody3D
var _pulse_time := 0.0

func _ready() -> void:
	_character = get_parent().get_parent() as CharacterBody3D
	custom_minimum_size = Vector2(80.0, 80.0)

func _process(delta: float) -> void:
	if not _character or not _character.stamina_enabled:
		visible = false
		return
	visible = true
	_pulse_time += delta
	queue_redraw()

func _draw() -> void:
	if not _character:
		return

	var pct := clamp(_character.stamina / _character.max_stamina, 0.0, 1.0)
	var is_low := pct < LOW_THRESHOLD

	_draw_glow(is_low)
	_draw_base()
	_draw_fill(pct, is_low)
	_draw_scanlines()
	_draw_border(is_low)
	_draw_highlight()

func _draw_glow(is_low: bool) -> void:
	var r := 0.45
	var g := 0.0
	var b := 0.05
	var base_a := 0.06

	if is_low:
		var pulse := sin(_pulse_time * 5.0) * 0.5 + 0.5
		r = 0.9
		g = 0.0
		b = 0.0
		base_a = 0.09 + pulse * 0.14

	for i in range(5):
		var radius := ORB_RADIUS + 6.0 + i * 5.0
		var a := base_a * (1.0 - i * 0.18)
		draw_circle(CENTER, radius, Color(r, g, b, a))

func _draw_base() -> void:
	draw_circle(CENTER, ORB_RADIUS, Color(0.04, 0.01, 0.04, 0.95))

func _draw_fill(pct: float, is_low: bool) -> void:
	if pct <= 0.001:
		return

	var fill_color := Color(0.52, 0.03, 0.08, 0.85)
	if is_low:
		var pulse := sin(_pulse_time * 6.0) * 0.5 + 0.5
		fill_color = Color(0.72 + pulse * 0.18, 0.01, 0.04, 0.9)

	if pct >= 0.999:
		draw_circle(CENTER, ORB_RADIUS - 2.0, fill_color)
		return

	_draw_liquid(pct, fill_color)

func _draw_liquid(pct: float, color: Color) -> void:
	var r := ORB_RADIUS - 2.0
	# Slight slosh on surface for horror feel
	var slosh := sin(_pulse_time * 2.3) * 0.018 * r + sin(_pulse_time * 3.7) * 0.009 * r
	var surface_y_local := clamp(r * (1.0 - 2.0 * pct) + slosh, -r * 0.98, r * 0.98)
	var surface_y := CENTER.y + surface_y_local

	# Circle intersection angles at the surface line
	var sin_val := clamp(surface_y_local / r, -1.0, 1.0)
	var angle_r := asin(sin_val)
	var angle_l := PI - angle_r

	# Arc from right intersection clockwise through bottom to left intersection
	var segments := 52
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t := float(i) / segments
		var angle := lerp(angle_r, angle_l, t)
		points.append(CENTER + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color)

	# Liquid surface shimmer
	var sx := sqrt(max(0.0, r * r - surface_y_local * surface_y_local))
	draw_line(
		Vector2(CENTER.x - sx, surface_y),
		Vector2(CENTER.x + sx, surface_y),
		Color(1.0, 0.45, 0.45, 0.28),
		1.5
	)

func _draw_scanlines() -> void:
	var lines := 9
	for i in range(lines):
		var y := CENTER.y - ORB_RADIUS + (2.0 * ORB_RADIUS / (lines - 1)) * i
		var dy := y - CENTER.y
		if abs(dy) >= ORB_RADIUS:
			continue
		var hw := sqrt(ORB_RADIUS * ORB_RADIUS - dy * dy)
		draw_line(Vector2(CENTER.x - hw, y), Vector2(CENTER.x + hw, y), Color(0.0, 0.0, 0.0, 0.07), 1.0)

func _draw_border(is_low: bool) -> void:
	var col := Color(0.28, 0.05, 0.1, 0.85)
	if is_low:
		var pulse := sin(_pulse_time * 5.0) * 0.5 + 0.5
		col = Color(0.6 + pulse * 0.3, 0.04, 0.06, 0.9)
	draw_arc(CENTER, ORB_RADIUS, 0.0, TAU, 64, col, 2.0)

func _draw_highlight() -> void:
	draw_circle(CENTER + Vector2(-9.0, -9.0), 7.0, Color(1.0, 0.65, 0.65, 0.055))
