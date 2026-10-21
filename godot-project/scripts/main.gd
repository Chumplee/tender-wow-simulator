extends Node2D
# TENDER: A World of Warcraft Life Simulator
# He sits at his PC playing WoW. Forever. There is no logout button.

const W := 1152.0
const H := 648.0
const DAY_LENGTH := 36.0

# ---------- palette ----------
const C_WALL := Color("#79a887")
const C_WALL_DARK := Color("#679579")
const C_FLOOR := Color("#8a5a33")
const C_FLOOR_DARK := Color("#754c2a")
const C_SKIN := Color("#f0c8a4")
const C_SKIN_SHADE := Color("#dfa878")
const C_HAIR := Color("#2e2119")
const C_HAIR_HI := Color("#4a3626")
const C_BEARD := Color("#38291b")
const C_BEARD_HI := Color("#5a422c")
const C_SHIRT := Color("#77755f")
const C_SLEEVE := Color("#4a4a3e")
const C_CHAIR := Color("#232c3f")
const C_CHAIR_HI := Color("#2f3c55")
const C_DESK := Color("#7a5230")
const C_DESK_EDGE := Color("#5f3e22")
const C_BLACK := Color("#14161c")
const C_GOLD := Color("#ffd75e")
const C_RED := Color("#e64545")
const C_GREEN := Color("#57e389")
const C_DEW := Color("#7ed957")

# ---------- state ----------
var started := false
var power_on := true
var wifi_on := true
var blinds_open := false
var mood := "focused" # focused / rage / shock / cry / hiss
var mood_time := 0.0
var t := 0.0
var day := 1
var day_clock := 6.0 # start mid-morning
var played_hours := 19432.0
var snacks := 0
var trash := 3
var rages := 0
var meltdowns := 0
var sunlight_avoided := 0
var offline_timer := 0.0
var mutter_timer := 9.0
var bubble_time := 0.0
var muted := false

var log_lines: Array[String] = []
var hair_curls: Array = []   # Vector3 offsets (x, y, r) around head centre
var beard_curls: Array = []
var beard_mass: Array = []   # solid beard silhouette blobs under the curls
var stars: Array = []        # Vector2 in window space
var trash_spots: Array = []  # precomputed Vector2 pile anchors

# ---------- nodes ----------
var pixel_font: Font
var scene_tex: Texture2D
var red_tex: Texture2D
var dusk_tex: Texture2D
var vid_player: VideoStreamPlayer
var video_mode := false
# animation life: layered slices of the illustrated scene, moved a few pixels to game with
var surge_until := -10.0
var next_surge := 6.0
var boss_hp := 1.0
var flashes: Array = []
var next_flash := 0.0
var last_click := 0.0
var click_player: AudioStreamPlayer
var cur_head_off := Vector2.ZERO
var blinds_anim := 1.0 # 0 = raised, 1 = fully closed; starts in cave mode
var snack_t0 := -10.0
var poke_t0 := -10.0
var sob_player: AudioStreamPlayer
var cry_t0 := -10.0
var dmg_numbers: Array = []
var next_dmg := 0.0
var bracket_pos := Vector2(250, 520)
var bracket_until := 0.0
var cast_f := 0.0
var big_label: Label
var last_mood := ""
var curtain_t0 := -10.0
var next_scream := 0.0
var next_wail := 0.0
var snack_kind := "cola"
const SNACK_KINDS := ["cola", "chipbag", "donut", "burger"]
var ui: CanvasLayer
var hud_label: Label
var log_label: Label
var bubble_panel: Panel
var bubble_label: Label
var monitor_label: Label
var ticker_label: Label
var ticker_width := 2600.0
var wifi_btn: Button
var plug_btn: Button
var curtain_btn: Button
var coin_label: Label
var start_layer: CanvasLayer
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var streams := {}

const FOCUS_LINES := [
	"one more quest.",
	"the mount drops tonight. i can feel it in the beard.",
	"almost honored with this faction. any year now.",
	"sleep is just a loading screen with worse graphics.",
	"rent is due, but so is my daily quest. priorities.",
	"i have eaten three meals in this chair today. a record. my record.",
]
const RAGE_LINES := [
	"MY PING. MY BEAUTIFUL PING.",
	"WHO MOVED ME TO THE ROUTER DIMENSION?",
	"I WAS MID-PULL. MID. PULL.",
	"THIS IS A WAR CRIME IN SEVEN KINGDOMS.",
]
const CRY_LINES := [
	"the lights... they took the lights...",
	"my rotation... it never got to finish...",
	"tell my guild i lagged out a hero.",
	"i can see my own room. i hate it here.",
]
const SCREAM_LINES := [
	"AAAAAARGH!!",
	"MY PING!! MY BEAUTIFUL PING!!",
	"SEVEN KINGDOMS WILL HEAR OF THIS!!",
	"THAT WAS A PERFECT PULL!!",
]
const WAIL_LINES := [
	"WAAAAAAH!!",
	"IT'S ALL GONE!!",
	"NOT THE RAID... NOT LIKE THIS...",
	"WHY WOULD YOU DO THIS TO ME!!",
]
const RAGE_BIG_LINES := [
	"FUCK!! FUCK!! FUCK!!",
	"MY FUCKING RAID!!",
	"GODDAMMIT!! NOT THE PULL!!",
	"SON OF A BITCH!!",
	"I'LL KILL THE GRID ITSELF!!",
]
const SKY_BIG_LINES := [
	"WHY, GOD?!",
	"THE WORLD HAS ENDED.",
	"EVEN HEAVEN LOGGED OUT.",
	"IT'S ALL OVER. ALL OF IT.",
]
const SKY_BUBBLE_LINES := [
	"the sky... even the sky left me...",
	"god has logged out of my life.",
	"everything is over. everything.",
	"i looked up and heaven was buffering.",
]
const POKE_LINES := [
	"hm? oh. it's you. the cursor of god.",
	"careful. this is a raid stance.",
	"you may touch the beard once. it stores my snacks.",
	"i felt that in real life. rude. accurate, but rude.",
]
const SNACK_LINES := [
	"fuel. premium fuel.",
	"the grind provides. and so do you.",
	"crumbs go in the beard for later. that's storage.",
	"a kingly feast. do not tell the guild it was just chips.",
]
const BED_LINES := [
	"bed? that's just a bigger chair that lies to you.",
	"sleep is a debuff and i refuse to spec into it.",
	"i'll sleep when the season ends. it never ends.",
	"the chair and i are in a committed relationship.",
]
const TICKER := "PATCH 99.7: SLEEP HAS BEEN NERFED +++ LOCAL MAN'S CHAIR NOW COUNTS AS A MOUNT +++ SUNLIGHT DEFEATED AGAIN BY CLOSED BLINDS +++ GUILD DENIES KNOWING HIM, GUILD IS ALSO HIM +++ HYDRATION DLC STILL UNPURCHASED +++ WITNESSES REPORT HE HAS NOT BLINKED SINCE TUESDAY +++ "

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1985
	# hair halo: a glorious cloud of curls around the head
	for i in range(78):
		var a := rng.randf_range(-PI * 0.98, PI * 0.35)
		var rad := rng.randf_range(58.0, 94.0)
		hair_curls.append(Vector3(cos(a) * rad, sin(a) * rad * 0.92, rng.randf_range(16.0, 30.0)))
	for i in range(20): # long side curtains of hair
		var side := -1.0 if i % 2 == 0 else 1.0
		var k := float(i / 2)
		hair_curls.append(Vector3(side * rng.randf_range(64.0, 80.0), 6.0 + k * 15.0, rng.randf_range(15.0, 24.0)))
	# solid beard silhouette: overlapping blobs, jaw to chest.
	# U-rule: keep the middle of the face clear (nose, mouth, chin window);
	# the beard wraps the jaw and hangs below it instead.
	var beard_profile: Array = [[48, 58], [72, 64], [96, 68], [120, 68], [144, 62], [168, 52], [190, 40], [206, 26]]
	for row in beard_profile:
		var ry: float = row[0]
		var hw: float = row[1]
		var x := -hw
		while x <= hw:
			if absf(x) >= 40.0 or ry >= 76.0:
				beard_mass.append(Vector3(x + rng.randf_range(-4.0, 4.0), ry + rng.randf_range(-4.0, 4.0), rng.randf_range(20.0, 27.0)))
			x += 22.0
	# beard texture: dense curls, same U-rule so his face survives
	for i in range(110):
		var yy := rng.randf_range(34.0, 205.0)
		var spread := 68.0 - maxf(0.0, yy - 120.0) * 0.26
		var xx := rng.randf_range(-spread, spread)
		if absf(xx) < 58.0 and yy < 58.0:
			continue # keep the cheeks clear; the beard frames the face, not eats it
		beard_curls.append(Vector3(xx, yy, rng.randf_range(12.0, 22.0)))
	for i in range(70):
		stars.append(Vector2(rng.randf_range(306.0, 542.0), rng.randf_range(78.0, 200.0)))
	for i in range(48):
		trash_spots.append(Vector2(985.0 + rng.randf_range(0.0, 140.0), 552.0 + rng.randf_range(0.0, 62.0)))

	var f = load("res://assets/fonts/PressStart2P-Regular.ttf")
	if f is Font:
		pixel_font = f
	var st = load("res://assets/art/scene_focused.png")
	if st is Texture2D:
		scene_tex = st
	var rt = load("res://assets/art/scene_red.png")
	if rt is Texture2D:
		red_tex = rt
	var dt = load("res://assets/art/scene_dusk.png")
	if dt is Texture2D:
		dusk_tex = dt

	_build_audio()
	_build_video()
	_build_ui()
	_build_start()
	add_log("Tender has logged in. Tender is always logged in.")
	queue_redraw()

# ================= VIDEO =================
# The idle world is real footage of him gaming (the clip he approved). It lives
# on a canvas layer beneath everything; the graded action states hide it.
func _build_video() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	vid_player = VideoStreamPlayer.new()
	vid_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	vid_player.expand = true
	vid_player.pivot_offset = Vector2(576, 324)
	vid_player.volume_db = -50.0
	layer.add_child(vid_player)
	var vs = load("res://assets/video/gaming.ogv")
	if vs:
		vid_player.stream = vs
		video_mode = true
		vid_player.finished.connect(func() -> void:
			if vid_player:
				vid_player.play())
		vid_player.play()

# ================= AUDIO =================
func _build_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -9.0
	add_child(music_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -4.0
	add_child(sfx_player)
	click_player = AudioStreamPlayer.new()
	click_player.volume_db = -17.0
	add_child(click_player)
	sob_player = AudioStreamPlayer.new()
	sob_player.volume_db = -13.0
	add_child(sob_player)
	for n in ["theme", "click", "rage", "powerdown", "powerup", "snack", "hiss", "sob"]:
		var s = load("res://assets/audio/%s.wav" % n)
		if s:
			streams[n] = s
	if streams.has("click"):
		click_player.stream = streams["click"]
	if streams.has("sob"):
		sob_player.stream = streams["sob"]
	if streams.has("theme"):
		music_player.stream = streams["theme"]
		music_player.finished.connect(func() -> void:
			if started and power_on and not muted:
				music_player.play())

func play_sfx(n: String) -> void:
	if streams.has(n):
		sfx_player.stream = streams[n]
		sfx_player.play()

# ================= UI =================
func make_label(text: String, x: float, y: float, w: float, h: float, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.position = Vector2(x, y)
	l.size = Vector2(w, h)
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	if pixel_font:
		l.add_theme_font_override("font", pixel_font)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func style_box(bg: Color, border: Color, bw := 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(3)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	return s

func make_button(text: String, x: float, y: float, w: float, h: float, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = Vector2(x, y)
	b.size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 10)
	if pixel_font:
		b.add_theme_font_override("font", pixel_font)
	b.add_theme_color_override("font_color", C_GOLD)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", style_box(Color(0.08, 0.09, 0.13, 0.95), Color("#8a6d2f")))
	b.add_theme_stylebox_override("hover", style_box(Color(0.16, 0.18, 0.25, 0.98), C_GOLD))
	b.add_theme_stylebox_override("pressed", style_box(Color(0.30, 0.24, 0.08, 0.98), C_GOLD))
	b.pressed.connect(fn)
	ui.add_child(b)
	return b

func make_hotspot(x: float, y: float, w: float, h: float, fn: Callable, tip: String) -> void:
	var b := Button.new()
	b.position = Vector2(x, y)
	b.size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tip
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", empty)
	b.add_theme_stylebox_override("hover", empty)
	b.add_theme_stylebox_override("pressed", empty)
	b.add_theme_stylebox_override("focus", empty)
	b.pressed.connect(fn)
	ui.add_child(b)

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)

	# HUD (top-left)
	hud_label = make_label("", 12, 8, 470, 66, 11, Color.WHITE)
	ui.add_child(hud_label)

	# top action bar
	wifi_btn = make_button("KILL WI-FI", 492, 10, 128, 36, toggle_wifi)
	plug_btn = make_button("YANK PLUG", 628, 10, 128, 36, toggle_plug)
	make_button("FEED SNACK", 764, 10, 128, 36, give_snack)
	curtain_btn = make_button("CURTAINS", 900, 10, 118, 36, toggle_curtains)
	make_button("POKE", 1026, 10, 60, 36, poke)
	make_button("MUTE", 1092, 10, 52, 36, toggle_mute)

	# witness log removed at Mochi's request (Oct 21); log() keeps its lines silently now

	# world labels
	ui.add_child(make_label("BED (UNUSED)", 26, 268, 220, 20, 11, Color(1, 1, 1, 0.85)))
	monitor_label = make_label("", 297, 392, 221, 24, 12, C_RED, HORIZONTAL_ALIGNMENT_CENTER)
	monitor_label.visible = false # the illustrated scene paints its own screen states in _draw now
	ui.add_child(monitor_label)

	# speech bubble
	bubble_panel = Panel.new()
	bubble_panel.position = Vector2(742, 56)
	bubble_panel.size = Vector2(372, 84)
	bubble_panel.add_theme_stylebox_override("panel", style_box(Color(0.98, 0.97, 0.92, 0.97), Color(0.1, 0.1, 0.12), 2))
	bubble_panel.visible = false
	ui.add_child(bubble_panel)
	bubble_label = make_label("", 756, 66, 346, 66, 11, Color(0.08, 0.08, 0.12))
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.visible = false
	ui.add_child(bubble_label)

	# the big feelings label: screams and wails, worn proudly above everything
	big_label = make_label("", 170, 50, 540, 46, 20, Color(1.0, 0.35, 0.2), HORIZONTAL_ALIGNMENT_CENTER)
	big_label.visible = false
	big_label.set_pivot_offset(Vector2(270, 23))
	ui.add_child(big_label)

	# patch-notes ticker (bottom bezel)
	var bar := ColorRect.new()
	bar.color = Color(0.02, 0.02, 0.04, 0.96)
	bar.position = Vector2(0, 624)
	bar.size = Vector2(W, 24)
	ui.add_child(bar)
	ticker_label = make_label(TICKER, 0, 629, 3000, 16, 9, C_GOLD)
	ui.add_child(ticker_label)
	if pixel_font:
		ticker_width = pixel_font.get_string_size(TICKER, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x

	# click hotspots over the drawn world
	make_hotspot(950, 408, 140, 66, toggle_wifi, "The router. His lifeline.")
	make_hotspot(942, 588, 196, 38, toggle_plug, "The power strip. Forbidden fruit.")
	make_hotspot(292, 60, 272, 204, toggle_curtains, "The window. He never looks at it.")
	make_hotspot(16, 292, 236, 132, suggest_bed, "The so-called bed.")
	make_hotspot(600, 84, 220, 300, poke, "Tender himself. Poke at your peril.")
	make_hotspot(930, 500, 190, 80, give_snack, "Snack reserves.")
	make_hotspot(285, 318, 250, 180, poke_monitor, "His window to another world.")

func _build_start() -> void:
	start_layer = CanvasLayer.new()
	start_layer.layer = 4
	add_child(start_layer)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.07)
	bg.size = Vector2(W, H)
	start_layer.add_child(bg)
	var title := make_label("TENDER", 0, 62, W, 80, 64, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	start_layer.add_child(title)
	start_layer.add_child(make_label("in", 0, 148, W, 24, 12, Color(0.8, 0.85, 0.9), HORIZONTAL_ALIGNMENT_CENTER))
	start_layer.add_child(make_label("WOW FOREVER", 0, 176, W, 60, 40, Color(0.55, 0.85, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	start_layer.add_child(make_label("A WORLD OF WARCRAFT LIFE SIMULATOR", 0, 244, W, 22, 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var scores := "HI-SCORES\n\n1ST   TENDER      999999\n2ND   CHUMPLEE    025000\n3RD   HANA        000404\n4TH   SLEEP       000000"
	start_layer.add_child(make_label(scores, 0, 292, W, 130, 12, Color(0.75, 0.9, 0.75), HORIZONTAL_ALIGNMENT_CENTER))
	coin_label = make_label("INSERT COIN", 0, 442, W, 22, 12, C_RED, HORIZONTAL_ALIGNMENT_CENTER)
	start_layer.add_child(coin_label)
	var start_btn := Button.new()
	start_btn.text = "PRESS START"
	start_btn.position = Vector2(W / 2 - 160, 486)
	start_btn.size = Vector2(320, 56)
	start_btn.focus_mode = Control.FOCUS_NONE
	start_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	start_btn.add_theme_font_size_override("font_size", 16)
	if pixel_font:
		start_btn.add_theme_font_override("font", pixel_font)
	start_btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.08))
	start_btn.add_theme_stylebox_override("normal", style_box(C_GOLD, Color.WHITE))
	start_btn.add_theme_stylebox_override("hover", style_box(Color.WHITE, C_GOLD))
	start_btn.add_theme_stylebox_override("pressed", style_box(C_RED, Color.WHITE))
	start_btn.pressed.connect(start_game)
	start_layer.add_child(start_btn)
	start_layer.add_child(make_label("CLICK EVERYTHING. SOUND ON FOR CHIPTUNE. THERE IS NO LOGOUT BUTTON.", 0, 566, W, 20, 10, Color(0.65, 0.7, 0.8), HORIZONTAL_ALIGNMENT_CENTER))
	start_layer.add_child(make_label("(C) 1985 LOMB ARCADE", 0, 606, W, 20, 10, Color(0.5, 0.55, 0.65), HORIZONTAL_ALIGNMENT_CENTER))

# ================= GAME FLOW =================
func start_game() -> void:
	if started:
		return
	started = true
	play_sfx("click")
	start_layer.visible = false
	if streams.has("theme") and not muted:
		music_player.play()
	show_bubble("session three hundred and twelve. let's make it count.", 3.5)
	add_log("You pressed start. He was already playing.")

func _unhandled_input(event: InputEvent) -> void:
	if not started and event is InputEventKey and event.pressed and not event.echo:
		start_game()

func show_bubble(text: String, dur := 3.2) -> void:
	bubble_label.text = text
	bubble_time = dur
	bubble_panel.visible = true
	bubble_label.visible = true

func add_log(s: String) -> void:
	log_lines.push_front(s)
	while log_lines.size() > 6:
		log_lines.pop_back()
	if log_label:
		var out := ""
		for line in log_lines:
			out += "- " + line + "\n"
		log_label.text = out

func fmt(n: int) -> String:
	var s := str(abs(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + out

# ================= ACTIONS =================
func toggle_wifi() -> void:
	if not started:
		return
	if not power_on:
		show_bubble("the router is dark. everything is dark. you monster.", 3.0)
		return
	if wifi_on:
		wifi_on = false
		meltdowns += 1
		mood = "skycry"
		mood_time = 600.0
		offline_timer = 10.0
		show_bubble(SKY_BUBBLE_LINES[randi() % SKY_BUBBLE_LINES.size()], 4.0)
		add_log("You killed the Wi-Fi. He turned his face to the heavens and wept.")
	else:
		restore_wifi("You restored the Wi-Fi. A hero, briefly.")
	update_buttons()

func restore_wifi(log_text: String) -> void:
	wifi_on = true
	offline_timer = 0.0
	if mood == "skycry":
		mood = "focused"
	show_bubble("and we're back. i was calm the whole time.", 3.0)
	add_log(log_text)
	update_buttons()

func toggle_plug() -> void:
	if not started:
		return
	if power_on:
		power_on = false
		rages += 1
		mood = "shock"
		mood_time = 1.0
		play_sfx("powerdown")
		music_player.stop()
		show_bubble("...no. NO. NO NO NO-", 2.6)
		add_log("You yanked the plug. The scream is still echoing.")
	else:
		power_on = true
		mood = "relief"
		mood_time = 2.2
		play_sfx("powerup")
		if streams.has("theme") and not muted:
			music_player.play()
		show_bubble("IT LIVES. never do that to us again.", 3.2)
		add_log("You plugged him back in. Forgiveness pending.")
	update_buttons()

func give_snack() -> void:
	if not started:
		return
	snacks += 1
	trash += 1
	snack_t0 = t
	snack_kind = SNACK_KINDS[randi() % SNACK_KINDS.size()]
	play_sfx("snack")
	show_bubble(SNACK_LINES[randi() % SNACK_LINES.size()], 2.8)
	if snacks % 5 == 0:
		add_log("Snack #%d. The can pyramid gains another brick." % snacks)
	else:
		add_log("You fed him snack #%d. He did not look away from the screen." % snacks)

func toggle_curtains() -> void:
	if not started:
		return
	if blinds_open:
		blinds_open = false
		show_bubble("better. cave mode restored.", 2.4)
		add_log("You closed the blinds. The cave is safe again.")
	else:
		blinds_open = true
		sunlight_avoided += 1
		mood = "hiss"
		mood_time = 2.6
		curtain_t0 = t
		play_sfx("hiss")
		show_bubble("HISSS. THE OUTSIDE BALL. IT BURNS US.", 2.6)
		add_log("You opened the curtains. He hissed at the sun like a raccoon.")
	update_buttons()

func suggest_bed() -> void:
	if not started:
		return
	play_sfx("click")
	show_bubble(BED_LINES[randi() % BED_LINES.size()], 3.4)
	add_log("You suggested bed. He looked at you like you spoke in riddles.")

func poke() -> void:
	if not started:
		return
	play_sfx("click")
	poke_t0 = t
	show_bubble(POKE_LINES[randi() % POKE_LINES.size()], 3.0)

func poke_monitor() -> void:
	if not started:
		return
	if not power_on:
		show_bubble("it's just his reflection now. he waves at it sometimes.", 3.0)
	elif not wifi_on:
		show_bubble("the login screen. his oldest enemy.", 2.6)
	else:
		show_bubble(FOCUS_LINES[randi() % FOCUS_LINES.size()], 3.0)

func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	if not muted and started and power_on and streams.has("theme"):
		music_player.play()

func update_buttons() -> void:
	wifi_btn.text = "RESTORE WI-FI" if not wifi_on else "KILL WI-FI"
	plug_btn.text = "PLUG BACK IN" if not power_on else "YANK PLUG"
	curtain_btn.text = "CLOSE BLINDS" if blinds_open else "CURTAINS"

func on_day_pass() -> void:
	trash += 2
	add_log("DAY %03d. He did not move. The trash grew bolder." % day)
	if day % 3 == 0:
		show_bubble("day %d in the chair. the chair provides." % day, 3.0)
	if trash > 30 and day % 4 == 0:
		add_log("The trash pile has been granted landmark status.")

# ================= LOOP =================
func _process(delta: float) -> void:
	t += delta
	if coin_label and not started:
		coin_label.visible = fmod(t, 1.1) < 0.65
	if not started:
		return

	day_clock += delta
	if day_clock >= DAY_LENGTH:
		day_clock -= DAY_LENGTH
		day += 1
		on_day_pass()
	if power_on and wifi_on:
		played_hours += delta * (24.0 / DAY_LENGTH)

	if mood_time > 0.0:
		mood_time -= delta
		if mood_time <= 0.0:
			if mood == "shock" and not power_on:
				mood = "bloodrage"
				mood_time = 600.0
				play_sfx("rage")
				show_bubble(RAGE_LINES[randi() % RAGE_LINES.size()], 3.6)
			elif mood == "hiss":
				blinds_open = false
				mood = "focused"
				update_buttons()
				add_log("He closed the blinds himself. At record speed.")
			elif mood == "relief":
				mood = "focused"

	if not wifi_on and power_on and offline_timer > 0.0:
		offline_timer -= delta
		if offline_timer <= 0.0:
			restore_wifi("The router reconnected itself. Tender takes full credit.")

	mutter_timer -= delta
	if mutter_timer <= 0.0:
		mutter_timer = randf_range(11.0, 18.0)
		if mood == "focused" and power_on and wifi_on and bubble_time <= 0.0:
			show_bubble(FOCUS_LINES[randi() % FOCUS_LINES.size()], 3.0)

	if bubble_time > 0.0:
		bubble_time -= delta
		if bubble_time <= 0.0:
			bubble_panel.visible = false
			bubble_label.visible = false

	# monitor status text
	if not power_on:
		monitor_label.text = "NO SIGNAL"
		monitor_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	elif not wifi_on:
		monitor_label.text = "DISCONNECTED"
		monitor_label.add_theme_color_override("font_color", C_RED)
	else:
		monitor_label.text = ""

	hud_label.text = "DAY %03d   /PLAYED %s HRS\nSNACKS %d  TRASH %d  RAGES %d  MELTDOWNS %d\nSUNLIGHT AVOIDED: %d" % [day, fmt(int(played_hours)), snacks, trash, rages, meltdowns, sunlight_avoided]

	# ---- animation drivers: combat surges, the boss, spell flashes, key clicks ----
	var surge_now := started and power_on and wifi_on and mood == "focused" and t < surge_until
	if started and power_on and wifi_on and mood == "focused":
		if t > next_surge:
			surge_until = t + randf_range(2.0, 3.2)
			next_surge = surge_until + randf_range(7.0, 12.0)
			surge_now = true
		boss_hp -= delta / 26.0
		if boss_hp <= 0.0:
			boss_hp = 1.0
			if bubble_time <= 0.0 and randf() < 0.45:
				show_bubble("boss down. next.", 2.2)
		if t > next_flash:
			next_flash = t + (randf_range(0.3, 0.9) if surge_now else randf_range(1.2, 2.8))
			var palette := [Color(0.45, 0.8, 1.0), Color(1.0, 0.62, 0.25), Color(0.72, 0.5, 1.0), Color(0.45, 1.0, 0.6)]
			flashes.append({"pos": Vector2(randf_range(180.0, 410.0), randf_range(480.0, 590.0)), "color": palette[randi() % palette.size()], "until": t + 0.28})
		var typing := surge_now or fmod(t, 1.9) < 1.25
		if typing and not muted and t - last_click > (0.085 if surge_now else 0.13):
			last_click = t
			if click_player and click_player.stream:
				click_player.play()
	flashes = flashes.filter(func(f) -> bool: return t < float(f["until"]))

	# blinds ease toward their state (and slam shut when he hisses)
	var b_target := 0.0 if blinds_open else 1.0
	blinds_anim = move_toward(blinds_anim, b_target, delta * (4.0 if mood == "hiss" else 1.6))

	# the footage runs only the monitor; the big emotions hide it entirely
	if vid_player:
		var show_clip := mood != "shock" and mood != "bloodrage" and mood != "skycry"
		vid_player.visible = show_clip
		vid_player.paused = not show_clip
		vid_player.modulate = Color.WHITE
		vid_player.position = Vector2.ZERO
		vid_player.scale = Vector2.ONE

	# the sob track runs while he weeps at the heavens over the dead Wi-Fi
	if sob_player and sob_player.stream:
		if mood == "skycry" and not muted:
			if not sob_player.playing:
				sob_player.play()
		elif sob_player.playing:
			sob_player.stop()

	# big feelings: bloodrage screams rotate, sky grief rotates slower
	if mood != last_mood:
		if mood == "bloodrage":
			big_label.text = RAGE_BIG_LINES[randi() % RAGE_BIG_LINES.size()]
			big_label.add_theme_color_override("font_color", Color(1.0, 0.22, 0.12))
			big_label.visible = true
			next_scream = t + 2.2
		elif mood == "skycry":
			cry_t0 = t
			big_label.text = SKY_BIG_LINES[randi() % SKY_BIG_LINES.size()]
			big_label.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0))
			big_label.visible = true
			next_wail = t + 3.0
		elif mood == "shock":
			big_label.text = "!!"
			big_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
			big_label.visible = true
		else:
			big_label.visible = false
		last_mood = mood
	if mood == "bloodrage" and t > next_scream:
		next_scream = t + 2.2
		big_label.text = RAGE_BIG_LINES[randi() % RAGE_BIG_LINES.size()]
		if randf() < 0.5:
			play_sfx("rage")
	if mood == "skycry" and t > next_wail:
		next_wail = t + 3.0
		big_label.text = SKY_BIG_LINES[randi() % SKY_BIG_LINES.size()]
	if big_label.visible:
		var pulse := 26.0 if mood == "bloodrage" else 7.0
		big_label.scale = Vector2.ONE * (1.0 + 0.07 * sin(t * pulse))
		big_label.rotation = 0.03 * sin(t * 2.0) if mood == "skycry" else 0.0

	# damage numbers and target practice on his screen
	if started and power_on and wifi_on:
		cast_f = fmod(cast_f + delta / 2.6, 1.0)
		if t > next_dmg:
			next_dmg = t + (randf_range(0.25, 0.6) if surge_now else randf_range(0.5, 1.4))
			var crit := randf() < 0.18
			dmg_numbers.append({"pos": Vector2(randf_range(190.0, 390.0), randf_range(500.0, 590.0)), "text": ("CRIT %d" % randi_range(4000, 9999)) if crit else str(randi_range(300, 3900)), "born": t, "color": Color(1.0, 0.55, 0.2) if crit else Color(1.0, 0.95, 0.75)})
		if t > bracket_until:
			bracket_until = t + randf_range(1.2, 2.2)
			bracket_pos = Vector2(randf_range(190.0, 400.0), randf_range(490.0, 590.0))
	dmg_numbers = dmg_numbers.filter(func(d) -> bool: return t - float(d["born"]) < 0.9)

	# ticker scroll
	var nx := ticker_label.position.x - delta * 55.0
	if nx < -ticker_width:
		nx = W
	ticker_label.position.x = nx

	queue_redraw()

# ================= DRAWING =================
func rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)

func circ(p: Vector2, r: float, c: Color) -> void:
	draw_circle(p, r, c)

func ellipse_pts(p: Vector2, rx: float, ry: float, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := TAU * float(i) / n
		pts.append(p + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

func shadow(p: Vector2, rx: float, ry: float, a := 0.18) -> void:
	draw_colored_polygon(ellipse_pts(p, rx, ry), Color(0, 0, 0, a))

func vgrad(x: float, y: float, w: float, h: float, top: Color, bottom: Color, steps := 24) -> void:
	for i in range(steps):
		var f0 := float(i) / float(steps)
		var f1 := float(i + 1) / float(steps)
		draw_rect(Rect2(x, y + h * f0, w, h * (f1 - f0) + 1.0), top.lerp(bottom, (f0 + f1) * 0.5))

func line(a: Vector2, b: Vector2, c: Color, w := 3.0) -> void:
	draw_line(a, b, c, w)

func sky_color(phase: float) -> Color:
	var keys: Array = [
		[0.00, Color("#d98a5f")], [0.08, Color("#a8d8ea")], [0.45, Color("#9fd4e8")],
		[0.62, Color("#8fc3dd")], [0.75, Color("#ef8f4d")], [0.86, Color("#0d1430")],
		[1.00, Color("#d98a5f")],
	]
	for i in range(keys.size() - 1):
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if phase >= a[0] and phase <= b[0]:
			var f: float = (phase - float(a[0])) / maxf(0.0001, float(b[0]) - float(a[0]))
			return (a[1] as Color).lerp(b[1] as Color, f)
	return Color("#9fd4e8")

func night_factor(phase: float) -> float:
	if phase < 0.78:
		return 0.0
	if phase < 0.88:
		return (phase - 0.78) / 0.10
	return 1.0 - max(0.0, phase - 0.97) / 0.03

func head_pos() -> Vector2:
	var p := Vector2(705, 252)
	if mood == "rage":
		p.x += sin(t * 45.0) * 3.0
	if mood == "cry":
		p.y += sin(t * 6.0) * 2.5
	p.y += sin(t * 1.4) * 1.5
	return p

const SCREEN_RECT := Rect2(144, 451, 295, 173) # the monitor screen inside the illustrated scene, measured from a zoomed crop
const VID_SCREEN_SRC := Rect2(147, 452, 285, 182) # the monitor screen inside the animated clip, measured from a zoomed frame
const HEAD_SRC := Rect2(552, 6, 474, 344) # his head and halo, a slice of the same art
const KB_SRC := Rect2(452, 486, 140, 98) # his keyboard hand and forearm, tight to skin and keys
const MS_SRC := Rect2(850, 478, 140, 116) # his mouse hand and forearm

# the snack arsenal: big, unmistakable, and drawn around a local origin
func draw_snack_shape(kind: String, center: Vector2, sc: float, rot: float, alpha: float) -> void:
	draw_set_transform(center, rot, Vector2.ONE)
	match kind:
		"cola":
			rect(-15 * sc, -23 * sc, 30 * sc, 46 * sc, Color(0.85, 0.16, 0.12, alpha))
			rect(-15 * sc, -23 * sc, 30 * sc, 8 * sc, Color(0.85, 0.87, 0.9, alpha))
			rect(-15 * sc, 15 * sc, 30 * sc, 8 * sc, Color(0.85, 0.87, 0.9, alpha))
			rect(-15 * sc, -3 * sc, 30 * sc, 7 * sc, Color(1, 1, 1, 0.85 * alpha))
		"chipbag":
			draw_colored_polygon(PackedVector2Array([Vector2(-24, -18) * sc, Vector2(24, -18) * sc, Vector2(20, 20) * sc, Vector2(-20, 20) * sc]), Color(0.98, 0.55, 0.1, alpha))
			rect(-24 * sc, -21 * sc, 48 * sc, 6 * sc, Color(0.9, 0.35, 0.05, alpha))
			rect(-24 * sc, 15 * sc, 48 * sc, 6 * sc, Color(0.9, 0.35, 0.05, alpha))
			circ(Vector2(0, 1), 10 * sc, Color(1, 0.85, 0.3, alpha))
		"donut":
			circ(Vector2.ZERO, 24 * sc, Color(0.98, 0.55, 0.7, alpha))
			circ(Vector2.ZERO, 15 * sc, Color(0.93, 0.72, 0.47, alpha))
			circ(Vector2.ZERO, 7 * sc, Color(0.13, 0.1, 0.09, alpha))
			for sp in [Vector2(-10, -8), Vector2(6, -13), Vector2(12, 4), Vector2(-13, 7), Vector2(1, 12)]:
				rect(sp.x * sc - 2, sp.y * sc - 1, 4, 2, Color(0.4, 0.9, 1.0, alpha))
		"burger":
			rect(-26 * sc, -17 * sc, 52 * sc, 13 * sc, Color(0.93, 0.68, 0.38, alpha))
			rect(-27 * sc, -4 * sc, 54 * sc, 5 * sc, Color(0.45, 0.75, 0.3, alpha))
			rect(-25 * sc, 1 * sc, 50 * sc, 7 * sc, Color(0.45, 0.25, 0.12, alpha))
			rect(-26 * sc, 8 * sc, 52 * sc, 10 * sc, Color(0.93, 0.68, 0.38, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw() -> void:
	var phase := day_clock / DAY_LENGTH
	# bloodrage shakes the whole world; slam beats hit every couple of seconds
	var shake := Vector2.ZERO
	if mood == "bloodrage":
		var slam := 2.3 if fmod(t, 2.3) < 0.16 else 1.0
		shake = Vector2(sin(t * 51.0) + sin(t * 37.0), sin(t * 45.0)) * 2.6 * slam
	# the room is the still illustration again (his first, favorite idle); only the
	# game window is alive. The graded renders still own the two big emotions.
	var slices_on := true
	var cur_tex: Texture2D = scene_tex
	if mood == "shock" or mood == "bloodrage":
		cur_tex = red_tex if red_tex else scene_tex
	elif mood == "skycry":
		cur_tex = dusk_tex if dusk_tex else scene_tex
	if cur_tex:
		draw_texture_rect(cur_tex, Rect2(shake.x, shake.y, W, H), false)
	else:
		rect(0, 0, W, H, C_WALL)
	if mood == "bloodrage":
		rect(0, 0, W, H, Color(0.55, 0.04, 0.02, 0.10 + 0.05 * sin(t * 9.0)))
		rect(0, 0, W, 30, Color(0.5, 0.02, 0.01, 0.16))
		rect(0, H - 30, W, 30, Color(0.5, 0.02, 0.01, 0.16))
		rect(0, 0, 30, H, Color(0.5, 0.02, 0.01, 0.16))
		rect(W - 30, 0, 30, H, Color(0.5, 0.02, 0.01, 0.16))
	if not started:
		rect(0, 0, W, H, Color(0.01, 0.01, 0.04, 0.80))
		return
	# ---- the blinds live again: a sunbeam when they are up, slats that slide over the art's window ----
	if blinds_anim < 0.35 and power_on and phase < 0.70:
		var beam_a := 0.055 * (1.0 - blinds_anim / 0.35)
		if mood == "hiss":
			beam_a = 0.13
		draw_colored_polygon(PackedVector2Array([Vector2(310, 228), Vector2(560, 228), Vector2(770, 480), Vector2(430, 480)]), Color(1.0, 0.95, 0.75, beam_a))
	# slats fitted to the measured glass: x 300..568, y 85..228
	if blinds_anim > 0.01:
		var covered := 143.0 * blinds_anim
		var yy := 85.0
		while yy < 85.0 + covered:
			rect(300 + shake.x, yy + shake.y, 268, 8, Color("#ccd5da"))
			rect(300 + shake.x, yy + 8 + shake.y, 268, 2, Color(0, 0, 0, 0.18))
			yy += 11.0
		rect(304 + shake.x, 85 + shake.y, 3, covered, Color(0, 0, 0, 0.20))
		rect(561 + shake.x, 85 + shake.y, 3, covered, Color(0, 0, 0, 0.20))
	# god rays for the sky grief: heaven shines on him, mockingly
	if mood == "skycry":
		var ra := 0.05 + 0.02 * sin(t * 2.0)
		for gi in range(3):
			var gx := 350.0 + gi * 90.0
			draw_colored_polygon(PackedVector2Array([Vector2(gx, 92), Vector2(gx + 34, 92), Vector2(763 + (gi - 1) * 42, 235), Vector2(763 + (gi - 1) * 42 - 26, 235)]), Color(1.0, 0.98, 0.9, ra))
	# a grief puddle gathers on the desk while he weeps
	if mood == "skycry" and cry_t0 > 0.0:
		var pw := minf(30.0 + (t - cry_t0) * 6.0, 95.0)
		draw_colored_polygon(ellipse_pts(Vector2(763 + cur_head_off.x, 608), pw, pw * 0.16), Color(0.45, 0.72, 1.0, 0.45))

	# ---- he is actually gaming now: slices of the same art, shifted a few pixels ----
	var surge := power_on and wifi_on and mood == "focused" and t < surge_until
	cur_head_off = Vector2(sin(t * 0.9) * 1.2, sin(t * 1.3) * 1.5)
	if mood == "bloodrage":
		cur_head_off += shake
	elif surge:
		cur_head_off += Vector2(2.0, 3.5 + sin(t * 9.0) * 1.2)
	elif mood == "focused":
		cur_head_off.y += sin(t * 6.0) * 0.4
	if cur_tex:
		var tap := 0.0
		if mood == "bloodrage":
			tap = -2.0 - absf(sin(t * 30.0)) * 4.0 # pounding the dead keyboard
		elif power_on and wifi_on and mood != "skycry":
			if surge:
				tap = -absf(sin(t * 26.0)) * 3.2
			elif fmod(t, 1.9) < 1.25:
				tap = -absf(sin(t * 15.0)) * 2.4
		if curtain_t0 > 0.0 and t - curtain_t0 < 0.18:
			tap = 9.0 # the hiss slam
		if slices_on:
			draw_texture_rect_region(cur_tex, Rect2(KB_SRC.position + Vector2(shake.x, tap + shake.y), KB_SRC.size), KB_SRC)
		var m_off := Vector2(sin(t * 0.7) * 1.5, -1.2 * pow(maxf(0.0, sin(t * 2.1)), 6.0))
		if surge:
			m_off.x += sin(t * 13.0) * 1.0
		if mood == "bloodrage":
			m_off = Vector2(sin(t * 23.0) * 4.0, -absf(sin(t * 27.0)) * 3.0)
		if poke_t0 > 0.0 and t - poke_t0 < 0.3:
			m_off.y -= sin((t - poke_t0) / 0.3 * PI) * 26.0 # the swat
		if slices_on:
			draw_texture_rect_region(cur_tex, Rect2(MS_SRC.position + m_off + shake, MS_SRC.size), MS_SRC)
		# the head rides a pivot at his neck, so moods can tilt it: skyward for the
		# Wi-Fi grief, jittering and swollen for bloodrage, slumped for relief
		var h_scale := 1.0
		var h_squash := 1.0
		var head_rot := 0.0
		if mood == "bloodrage":
			h_scale = 1.06 + 0.05 * sin(t * 24.0)
			head_rot = (sin(t * 43.0) + sin(t * 29.0)) * 0.02
			cur_head_off.x += (sin(t * 47.0) + sin(t * 31.0)) * 1.6
			cur_head_off.y += sin(t * 39.0) * 1.2
		elif mood == "shock":
			h_scale = 1.10
			for si in range(8):
				var ang := float(si) * PI / 4.0 + 0.4
				var c0 := Vector2(763, 190) + cur_head_off + Vector2(cos(ang), sin(ang)) * 185.0
				line(c0, c0 + Vector2(cos(ang), sin(ang)) * 26.0, Color(1, 1, 1, 0.7), 3)
		elif mood == "skycry":
			var sob2 := pow(maxf(0.0, sin(t * 7.5)), 3.0)
			h_squash = 1.0 - 0.03 * sob2
			head_rot = -0.09 + sin(t * 1.1) * 0.012
			cur_head_off.y += -3.0 + sob2 * 1.5
		elif mood == "relief":
			h_scale = 0.985
			head_rot = 0.03
			cur_head_off.y += 7.0
		elif mood == "hiss":
			cur_head_off.x += sin(t * 40.0) * 1.5
			cur_head_off.y += 3.0
		if poke_t0 > 0.0 and t - poke_t0 < 0.35:
			cur_head_off += Vector2(-1, 1) * sin((t - poke_t0) / 0.35 * PI) * 6.0
			head_rot += sin((t - poke_t0) / 0.35 * PI) * -0.05
		if snack_t0 > 0.0 and t - snack_t0 >= 0.45 and t - snack_t0 < 1.1:
			cur_head_off.y += absf(sin(t * 22.0)) * 2.0 # chewing
			if t - snack_t0 < 0.7:
				head_rot -= 0.05 # tipped back to catch
		# the head is drawn as a polygon hugging the halo and beard silhouette, so
		# scaling and tilting it never shows a rectangular seam
		var pivot := Vector2(763, 332)
		var hpts := PackedVector2Array()
		var huvs := PackedVector2Array()
		var hcols: Array[Color] = []
		for hi in range(28):
			var ang := TAU * float(hi) / 28.0
			var ep := Vector2(763 + cos(ang) * 200.0, 188 + sin(ang) * 156.0)
			if ep.y > 300.0:
				ep.x = 763 + (ep.x - 763) * 1.03
			hpts.append((ep - pivot) * Vector2(h_scale, h_scale * h_squash))
			huvs.append(Vector2(ep.x / 1152.0, ep.y / 648.0))
			hcols.append(Color(1, 1, 1))
		if slices_on:
			draw_set_transform(pivot + cur_head_off, head_rot, Vector2.ONE)
			draw_polygon(hpts, PackedColorArray(hcols), huvs, cur_tex)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# the flying snack: tossed in, caught in the beard, chewed, dropped as trash
		if snack_t0 > 0.0:
			var sa := t - snack_t0
			if sa < 1.3:
				var mouth := Vector2(770, 300) + cur_head_off
				var can_pos := mouth
				var can_rot := 0.0
				var can_a := 1.0
				var can_sc := 1.0
				if sa < 0.45:
					var ff := sa / 0.45
					can_pos = Vector2(lerpf(1010.0, mouth.x, ff), lerpf(650.0, mouth.y, ff) - sin(ff * PI) * 120.0)
					can_rot = ff * 9.0
					can_sc = 0.75 + 0.25 * ff
				elif sa < 1.1:
					can_pos = mouth + Vector2(6, 10)
					can_rot = 0.6
				else:
					var f2 := (sa - 1.1) / 0.2
					can_pos = Vector2(lerpf(mouth.x, 905.0, f2), lerpf(mouth.y, 605.0, f2 * f2))
					can_rot = 2.2
					can_a = 1.0 - f2
				draw_snack_shape(snack_kind, can_pos, can_sc, can_rot, can_a)
		# crumbs shed from the beard after a catch
		if snack_t0 > 0.0:
			var ca := t - snack_t0
			if ca >= 1.1 and ca < 1.6:
				var mouth2 := Vector2(770, 312) + cur_head_off
				for ci in range(5):
					circ(mouth2 + Vector2((ci - 2) * 7.0, (ca - 1.1) * 150.0 + ci * 3.0), 2.0, Color(0.55, 0.38, 0.2, 1.0 - (ca - 1.1) / 0.5))
		# the game window is alive: the clip plays inside the monitor, and only there
		if power_on and wifi_on and video_mode and vid_player:
			var vtex := vid_player.get_video_texture()
			if vtex and vtex.get_width() > 10:
				draw_texture_rect_region(vtex, SCREEN_RECT, VID_SCREEN_SRC)
		if power_on and wifi_on:
			rect(202.0 + 198.0 * boss_hp, 447, 198.0 * (1.0 - boss_hp), 9, Color(0.05, 0.02, 0.02, 0.60))
			for f in flashes:
				var fp: Vector2 = f["pos"]
				var fc: Color = f["color"]
				var fa: float = 0.16 * clampf((float(f["until"]) - t) / 0.28, 0.0, 1.0)
				circ(fp, 26, Color(fc, fa))
			# damage numbers float up, a target bracket hops between victims, the cast bar fills
			if pixel_font:
				for d in dmg_numbers:
					var age: float = t - float(d["born"])
					var dp: Vector2 = d["pos"]
					var dc: Color = d["color"]
					var dt: String = d["text"]
					draw_string(pixel_font, dp + Vector2(-30, -age * 26.0), dt, HORIZONTAL_ALIGNMENT_CENTER, 60, 8, Color(dc, clampf(1.0 - age / 0.9, 0.0, 1.0)))
			var bc := Color(1.0, 0.85, 0.3, 0.85)
			for sx in [-1.0, 1.0]:
				for sy in [-1.0, 1.0]:
					line(bracket_pos + Vector2(sx * 16, sy * 12), bracket_pos + Vector2(sx * 9, sy * 12), bc, 2)
					line(bracket_pos + Vector2(sx * 16, sy * 12), bracket_pos + Vector2(sx * 16, sy * 5), bc, 2)
			rect(190, 606, 220, 5, Color(0, 0, 0, 0.45))
			rect(190, 606, 220 * cast_f, 5, Color(1.0, 0.8, 0.3, 0.8))
	# night settles over the room
	var nf := night_factor(phase)
	if nf > 0.02 and power_on:
		rect(0, 0, W, H, Color(0.03, 0.05, 0.16, 0.30 * nf))
	# monitor states painted over the art's screen
	if not power_on:
		rect(SCREEN_RECT.position.x + shake.x, SCREEN_RECT.position.y + shake.y, SCREEN_RECT.size.x, SCREEN_RECT.size.y, Color("#05070a"))
		if pixel_font:
			draw_string(pixel_font, Vector2(SCREEN_RECT.position.x + shake.x, SCREEN_RECT.get_center().y + 5 + shake.y), "NO SIGNAL", HORIZONTAL_ALIGNMENT_CENTER, SCREEN_RECT.size.x, 13, Color("#5a6672"))
	elif not wifi_on:
		rect(SCREEN_RECT.position.x, SCREEN_RECT.position.y, SCREEN_RECT.size.x, SCREEN_RECT.size.y, Color("#2a0606"))
		line(SCREEN_RECT.position + Vector2(40, 25), SCREEN_RECT.position + Vector2(255, 148), C_RED, 8)
		line(SCREEN_RECT.position + Vector2(255, 25), SCREEN_RECT.position + Vector2(40, 148), C_RED, 8)
		if pixel_font:
			draw_string(pixel_font, Vector2(SCREEN_RECT.position.x, SCREEN_RECT.position.y + 165), "DISCONNECTED", HORIZONTAL_ALIGNMENT_CENTER, SCREEN_RECT.size.x, 11, C_RED)
	# his face lives around (763, 205) in the art: a rage flush + steam off the halo
	# the blue world's grief made literal: his tears are flooding the room
	if mood == "skycry" and cry_t0 > 0.0:
		var el := t - cry_t0
		var rise := clampf(el / 9.0, 0.0, 1.0) * 150.0 + clampf((el - 9.0) / 30.0, 0.0, 1.0) * 90.0
		if rise > 4.0:
			var wy := 648.0 - rise
			var wpts := PackedVector2Array()
			for wx in range(0, 1153, 48):
				wpts.append(Vector2(wx, wy + sin(t * 2.2 + wx * 0.02) * 3.0))
			wpts.append(Vector2(1152, 648))
			wpts.append(Vector2(0, 648))
			draw_colored_polygon(wpts, Color(0.25, 0.5, 0.95, 0.35))
			for wx in range(0, 1152, 48):
				line(Vector2(wx, wy + sin(t * 2.2 + wx * 0.02) * 3.0), Vector2(wx + 48, wy + sin(t * 2.2 + (wx + 48) * 0.02) * 3.0), Color(0.7, 0.88, 1.0, 0.65), 3)
			# snack cans ride the flood like little boats of shame
			for bi in range(3):
				var bx := 180.0 + bi * 330.0 + sin(t * 0.7 + bi * 2.1) * 12.0
				var by := wy + sin(t * 2.2 + bx * 0.02) * 3.0 + sin(t * 3.1 + bi * 1.7) * 2.5 - 10.0
				draw_snack_shape("cola", Vector2(bx, by), 0.85, sin(t * 1.3 + bi) * 0.18, 0.95)
			# his own tear streams splash where they land
			if rise > 40.0:
				var splash_xs := [717.0, 809.0]
				for sx in splash_xs:
					circ(Vector2(sx, wy - 2.0), 4.0 + sin(t * 10.0 + sx) * 1.2, Color(0.8, 0.92, 1.0, 0.8))
			# bubbles rising through the grief
			if rise > 24.0:
				for bu in range(6):
					var bub_x := 120.0 + bu * 170.0 + sin(t + bu) * 8.0
					var bub_y := 648.0 - fmod(t * 26.0 + bu * 61.0, rise - 14.0)
					circ(Vector2(bub_x, bub_y), 3.0, Color(0.8, 0.92, 1.0, 0.45))
	if mood == "bloodrage":
		circ(Vector2(763, 200) + cur_head_off, 150, Color(0.9, 0.25, 0.2, 0.11))
		for i in range(6):
			var side := -1.0 if i % 2 == 0 else 1.0
			var rise := fmod(t * 55.0 + i * 26.0, 84.0)
			var alpha := 0.75 * (1.0 - rise / 84.0)
			circ(Vector2(763 + side * (95 + (i % 3) * 16), 96 - rise) + cur_head_off, 13 + rise * 0.18, Color(0.92, 0.92, 0.94, alpha))
	# tears for the meltdown, streaming from his eyes down into the beard
	if mood == "bloodrage":
		for side in [-1.0, 1.0]:
			var ex: float = 763.0 + side * 46.0 + cur_head_off.x
			line(Vector2(ex, 212 + cur_head_off.y), Vector2(ex - side * 5.0, 340 + cur_head_off.y), Color(0.45, 0.75, 1.0, 0.0), 1)
	# tears for the meltdown, streaming from his eyes down into the beard
	if mood == "skycry":
		for side in [-1.0, 1.0]:
			var ex: float = 763.0 + side * 46.0 + cur_head_off.x
			line(Vector2(ex, 212 + cur_head_off.y), Vector2(ex - side * 5.0, 340 + cur_head_off.y), Color(0.45, 0.75, 1.0, 0.65), 12)
			for k in range(3):
				var fall := fmod(t * 210.0 + k * 48.0 + (24.0 if side > 0.0 else 0.0), 128.0)
				circ(Vector2(ex + sin(fall * 0.11 + side) * 4.0, 218 + fall + cur_head_off.y), 7, Color(0.45, 0.75, 1.0, 0.95))
			circ(Vector2(ex - side * 5.0, 346 + cur_head_off.y), 5.0 + sin(t * 9.0 + side) * 1.0, Color(0.45, 0.75, 1.0, 0.85))
	if not power_on:
		rect(0, 0, W, H, Color(0.02, 0.03, 0.10, 0.30))

func draw_wall_decor() -> void:
	# framed poster low on the left wall, tucked behind the couch:
	# a very serious fantasy map he has never finished
	shadow(Vector2(134, 258), 68, 82, 0.15)
	rect(70, 176, 120, 152, Color("#3d2c1c"))
	rect(76, 182, 108, 140, Color("#e8dcc0"))
	rect(84, 190, 92, 84, Color("#a8c8d8"))
	circ(Vector2(152, 210), 10, Color("#e8a13c"))
	draw_colored_polygon(PackedVector2Array([Vector2(84, 274), Vector2(118, 232), Vector2(146, 274)]), Color("#5a7a5e"))
	draw_colored_polygon(PackedVector2Array([Vector2(116, 274), Vector2(146, 240), Vector2(176, 274)]), Color("#476b52"))
	for i in range(4):
		rect(90, 284 + i * 10, 80 - i * 12, 4, Color("#8a7a5c"))
	# shelf of treasures high on the right wall, above the witness log
	rect(868, 128, 228, 10, Color("#5d4126"))
	rect(868, 138, 228, 4, Color(0, 0, 0, 0.25))
	rect(884, 92, 34, 36, Color("#2f6da3"))
	rect(884, 92, 34, 6, Color("#f0e6d0"))
	rect(924, 100, 28, 28, Color("#8e44ad"))
	circ(Vector2(990, 108), 13, Color("#a83a32"))
	draw_colored_polygon(PackedVector2Array([Vector2(982, 100), Vector2(972, 82), Vector2(986, 92)]), Color("#a83a32"))
	circ(Vector2(1052, 114), 12, Color("#3f7d4e"))
	line(Vector2(1052, 106), Vector2(1042, 88), Color("#3f7d4e"), 3)
	line(Vector2(1052, 106), Vector2(1062, 86), Color("#4c995f"), 3)
	line(Vector2(1052, 106), Vector2(1052, 84), Color("#3f7d4e"), 3)
	rect(1042, 114, 20, 14, Color("#b06a3a"))
	# sticky notes by the lamp, ancient wisdom
	rect(238, 196, 26, 26, Color("#f5e27a"))
	rect(242, 204, 18, 3, Color("#8a7a2c"))
	rect(246, 210, 12, 3, Color("#8a7a2c"))
	rect(232, 230, 22, 22, Color("#f2a7c3"))
	rect(236, 237, 14, 3, Color("#9c5570"))

func draw_window(phase: float) -> void:
	# frame
	rect(288, 56, 280, 212, Color("#596068"))
	rect(292, 60, 272, 204, Color("#c8ced2"))
	var sky := sky_color(phase)
	if not power_on:
		sky = sky.darkened(0.25)
	rect(302, 70, 252, 184, sky)
	var nf := night_factor(phase)
	if nf > 0.05:
		for s in stars:
			circ(s, 1.6, Color(1, 1, 1, 0.75 * nf))
	# sun / moon travel
	var sun_x := lerpf(322.0, 532.0, clampf(phase, 0.0, 1.0))
	if nf < 0.6:
		var sy := 210.0 - sin(clampf(phase, 0.0, 0.85) / 0.85 * PI) * 120.0
		circ(Vector2(sun_x, sy), 30, Color(1.0, 0.85, 0.4, 0.18))
		circ(Vector2(sun_x, sy), 22, Color(1.0, 0.88, 0.45, 0.25))
		circ(Vector2(sun_x, sy), 17, Color("#ffd75e"))
	else:
		circ(Vector2(500, 105), 13, Color("#e8ecf4"))
		circ(Vector2(494, 100), 11, sky)
	# city silhouette + palms
	var sil := Color("#1c2a30")
	var bx := 302.0
	var heights := [46, 70, 38, 84, 56, 66, 42, 74, 50, 60]
	for i in range(heights.size()):
		var bw := 26.0
		rect(bx + i * bw, 254 - heights[i], bw - 3, heights[i], sil)
	line(Vector2(340, 254), Vector2(336, 196), sil, 5)
	for a in range(5):
		var ang := -0.4 - a * 0.45
		line(Vector2(336, 196), Vector2(336 + cos(ang) * 30, 196 + sin(ang) * 22 - 8), sil, 4)
	line(Vector2(520, 254), Vector2(524, 204), sil, 5)
	for a in range(5):
		var ang2 := -2.7 + a * 0.45
		line(Vector2(524, 204), Vector2(524 + cos(ang2) * 27, 204 + sin(ang2) * 20 - 6), sil, 4)
	rect(302, 248, 252, 6, sil)
	# blinds
	if blinds_open:
		for i in range(3):
			rect(302, 70 + i * 9, 252, 6, Color("#ececea"))
		# sunlight beams
		var beam := PackedVector2Array([Vector2(310, 96), Vector2(430, 96), Vector2(560, 300), Vector2(400, 300)])
		draw_colored_polygon(beam, Color(1.0, 0.9, 0.45, 0.13))
	else:
		for i in range(6):
			rect(302, 70 + i * 17, 252, 11, Color("#ececea"))
		line(Vector2(540, 78), Vector2(540, 168), Color("#999"), 2)
	# frame cross
	rect(424, 70, 6, 184, Color("#c8ced2"))
	rect(292, 258, 272, 6, Color("#c8ced2"))

func draw_door() -> void:
	rect(548, 74, 96, 256, Color("#5f4028"))
	rect(556, 84, 80, 236, Color("#6b4a33"))
	rect(568, 100, 56, 84, Color("#5f4028"))
	rect(568, 204, 56, 84, Color("#5f4028"))
	circ(Vector2(628, 214), 5, C_GOLD)

func draw_couch() -> void:
	# floor lamp behind couch
	line(Vector2(264, 428), Vector2(264, 196), Color("#2b2b30"), 5)
	draw_colored_polygon(PackedVector2Array([Vector2(238, 196), Vector2(290, 196), Vector2(278, 168), Vector2(250, 168)]), Color("#2b2b30"))
	# couch
	rect(16, 322, 232, 108, Color("#87765e"))
	rect(16, 300, 232, 36, Color("#776850"))
	rect(124, 300, 4, 130, Color("#66583f"))
	rect(16, 380, 232, 10, Color("#66583f"))
	# seat cushions, seams, a throw pillow, and a soft shadow underneath
	shadow(Vector2(132, 440), 128, 12, 0.20)
	rect(22, 336, 102, 46, Color("#8f7d63"))
	rect(130, 336, 102, 46, Color("#8a7660"))
	rect(22, 336, 102, 6, Color(1, 1, 1, 0.08))
	rect(130, 336, 102, 6, Color(1, 1, 1, 0.08))
	draw_colored_polygon(PackedVector2Array([Vector2(196, 330), Vector2(232, 322), Vector2(238, 352), Vector2(202, 360)]), Color("#7a4a8e"))
	draw_colored_polygon(PackedVector2Array([Vector2(202, 356), Vector2(238, 352), Vector2(232, 322), Vector2(224, 348)]), Color("#67407a"))
	if power_on:
		circ(Vector2(264, 180), 34, Color(1.0, 0.85, 0.5, 0.10))
		circ(Vector2(264, 180), 20, Color(1.0, 0.87, 0.55, 0.12))
	rect(24, 424, 12, 14, Color("#4c4130"))
	rect(228, 424, 12, 14, Color("#4c4130"))
	# abandoned clothes
	draw_colored_polygon(PackedVector2Array([Vector2(28, 322), Vector2(96, 322), Vector2(88, 300), Vector2(40, 296)]), Color("#c0392b"))
	circ(Vector2(180, 318), 15, Color("#e67e22"))
	circ(Vector2(196, 324), 12, Color("#e67e22"))
	circ(Vector2(70, 352), 9, Color("#ecf0f1"))
	line(Vector2(58, 356), Vector2(84, 348), Color("#bdc3c7"), 4)
	# coffee table + mess in front
	rect(286, 428, 220, 12, Color("#5d4126"))
	rect(300, 440, 10, 26, Color("#4c3319"))
	rect(482, 440, 10, 26, Color("#4c3319"))
	rect(306, 408, 58, 20, Color("#e8e6df"))
	rect(330, 396, 52, 18, Color("#d5d2c8"))
	circ(Vector2(430, 420), 14, Color("#cfd4d8"))
	circ(Vector2(430, 420), 5, Color("#8f979e"))
	circ(Vector2(462, 414), 11, Color("#cfd4d8"))
	rect(372, 416, 34, 12, Color("#a83232"))

func draw_lamp_and_table() -> void:
	# side table, green lamp, tiny dragon (a guardian he ignores)
	rect(838, 470, 128, 14, Color("#54606e"))
	rect(848, 484, 10, 40, Color("#3d4652"))
	rect(946, 484, 10, 40, Color("#3d4652"))
	line(Vector2(884, 470), Vector2(884, 446), Color("#2b2b30"), 4)
	var glow := 0.65 + 0.2 * sin(t * 2.3)
	circ(Vector2(884, 436), 15, Color(0.45, 1.0, 0.55, glow) if power_on else Color(0.2, 0.3, 0.2))
	circ(Vector2(884, 436), 9, Color("#baffd0") if power_on else Color("#3d4a3d"))
	# dragon figurine
	circ(Vector2(936, 462), 8, Color("#a83a32"))
	draw_colored_polygon(PackedVector2Array([Vector2(930, 456), Vector2(918, 440), Vector2(934, 446)]), Color("#a83a32"))
	line(Vector2(944, 466), Vector2(958, 458), Color("#a83a32"), 3)
	rect(856, 452, 34, 8, Color("#2f6da3"))
	rect(856, 442, 30, 8, Color("#8e44ad"))

func draw_chair() -> void:
	rect(584, 112, 248, 430, C_CHAIR)
	rect(584, 112, 248, 16, C_CHAIR_HI)
	rect(610, 88, 196, 62, C_CHAIR_HI)
	rect(610, 88, 196, 10, Color(1, 1, 1, 0.07))
	rect(824, 112, 8, 430, Color(0, 0, 0, 0.25))
	rect(584, 112, 8, 430, Color(1, 1, 1, 0.05))
	line(Vector2(600, 300), Vector2(816, 300), Color(0, 0, 0, 0.22), 3)
	line(Vector2(600, 430), Vector2(816, 430), Color(0, 0, 0, 0.22), 3)
	# abandoned PC tower, left foreground, his old rig retired to lamp duty
	rect(28, 366, 138, 262, Color("#191b20"))
	rect(40, 378, 114, 238, Color("#7e1f1f") if power_on else Color("#3a2323"))
	circ(Vector2(97, 440), 30, Color(0, 0, 0, 0.55))
	circ(Vector2(97, 440), 22, Color(0.9, 0.3, 0.25, 0.5 + 0.3 * sin(t * 3.0)) if power_on else Color(0.2, 0.2, 0.2))
	circ(Vector2(97, 540), 20, Color(0, 0, 0, 0.5))
	line(Vector2(52, 596), Vector2(142, 596), Color("#e64545") if power_on else Color("#333"), 4)
	line(Vector2(52, 392), Vector2(90, 392), Color(0, 0, 0, 0.4), 4)

func draw_tender() -> void:
	var hp := head_pos()
	var bob := sin(t * 1.4) * 1.5
	# neck (mostly beard country, but the shirt needs somewhere to start)
	rect(676, 296 + bob, 58, 46, C_SKIN_SHADE)
	# torso: a big soft mountain of a man, shirt doing its best
	draw_colored_polygon(PackedVector2Array([
		Vector2(606, 356 + bob), Vector2(804, 356 + bob), Vector2(836, 448),
		Vector2(828, 548), Vector2(582, 548), Vector2(574, 448)]), C_SHIRT)
	# side shading + a belly that catches the monitor light
	draw_colored_polygon(PackedVector2Array([
		Vector2(574, 448), Vector2(600, 420), Vector2(606, 548), Vector2(582, 548)]), Color(0, 0, 0, 0.13))
	draw_colored_polygon(PackedVector2Array([
		Vector2(836, 448), Vector2(810, 420), Vector2(804, 548), Vector2(828, 548)]), Color(0, 0, 0, 0.13))
	draw_colored_polygon(ellipse_pts(Vector2(705, 468), 92, 62), Color(1, 1, 1, 0.05))
	# shirt folds straining heroically + collar + hem
	draw_arc(Vector2(660, 470), 44, 0.3, PI - 0.6, 18, Color(0, 0, 0, 0.13), 3.0)
	draw_arc(Vector2(750, 486), 40, 0.5, PI - 0.4, 18, Color(0, 0, 0, 0.11), 3.0)
	draw_arc(Vector2(705, 420), 60, 0.4, PI - 0.4, 20, Color(0, 0, 0, 0.09), 3.0)
	rect(664, 352 + bob, 82, 14, C_SLEEVE)
	rect(582, 538, 246, 10, Color(0, 0, 0, 0.18))
	# upper arms (sleeves); forearms and hands are drawn after the desk
	line(Vector2(618, 380 + bob), Vector2(572, 462), C_SLEEVE, 42)
	line(Vector2(792, 380 + bob), Vector2(850, 462), C_SLEEVE, 42)
	# solid beard silhouette first, so the beard reads as a beard
	for c in beard_mass:
		var v: Vector3 = c
		circ(hp + Vector2(v.x, v.y), v.z, C_BEARD.darkened(0.18))
	# hair underlayer: one dark mass so the halo has no gaps
	circ(hp + Vector2(0, -6), 82, C_HAIR.darkened(0.15))
	# face: bigger, rounder, jowls and all
	circ(hp, 72, C_SKIN)
	rect(hp.x - 72, hp.y - 6, 144, 54, C_SKIN)
	circ(hp + Vector2(-46, 30), 27, C_SKIN.darkened(0.05))
	circ(hp + Vector2(46, 30), 27, C_SKIN.darkened(0.05))
	circ(hp + Vector2(-40, 12), 15, Color(1, 1, 1, 0.07))
	circ(hp + Vector2(40, 12), 15, Color(1, 1, 1, 0.07))
	draw_arc(hp + Vector2(0, 34), 34, PI * 0.25, PI * 0.75, 20, C_SKIN_SHADE, 3.0)
	draw_arc(hp, 72, 0, TAU, 40, Color(0.09, 0.06, 0.03, 0.35), 3.0)
	# beard curl texture over the mass
	for c in beard_curls:
		var v: Vector3 = c
		circ(hp + Vector2(v.x, v.y), v.z, C_BEARD)
	# hair halo
	for c in hair_curls:
		var v: Vector3 = c
		circ(hp + Vector2(v.x, v.y), v.z, C_HAIR)
	# a few lighter curls + beard highlights for likeness
	for i in range(12):
		var v: Vector3 = hair_curls[i * 5]
		circ(hp + Vector2(v.x, v.y) * 0.98, v.z * 0.45, C_HAIR_HI)
	for i in range(9):
		var v: Vector3 = beard_curls[i * 7]
		circ(hp + Vector2(v.x, v.y), v.z * 0.5, C_BEARD_HI)
	# beard crumbs (emergency storage)
	circ(hp + Vector2(-26, 108), 3.5, Color("#e8c877"))
	circ(hp + Vector2(16, 142), 3.5, Color("#e8c877"))
	circ(hp + Vector2(36, 96), 3, Color("#e8c877"))
	circ(hp + Vector2(-8, 168), 3, Color("#e8c877"))
	# mustache: big, proud, mostly hiding the mouth
	circ(hp + Vector2(-19, 44), 14, C_BEARD)
	circ(hp + Vector2(19, 44), 14, C_BEARD)
	circ(hp + Vector2(0, 40), 13, C_BEARD)
	circ(hp + Vector2(0, 50), 9, C_BEARD.darkened(0.1))
	# eyes + brows by mood
	var look := Vector2(-3, 2)
	if mood == "rage":
		look = Vector2(0, 0)
		circ(hp + Vector2(0, -4), 86, Color(0.9, 0.25, 0.2, 0.15))
	if mood != "cry":
		var eye_r := 19.0 if mood == "shock" else 15.0
		var pup_r := 3.0 if mood == "shock" else 5.5
		circ(hp + Vector2(-29, -12), eye_r, Color.WHITE)
		circ(hp + Vector2(29, -12), eye_r, Color.WHITE)
		circ(hp + Vector2(-29, -12) + look, pup_r, Color("#241a12"))
		circ(hp + Vector2(29, -12) + look, pup_r, Color("#241a12"))
		circ(hp + Vector2(-29, -12) + look + Vector2(-2, -2), 1.8, Color.WHITE)
		circ(hp + Vector2(29, -12) + look + Vector2(-2, -2), 1.8, Color.WHITE)
		# heavy lids + the eye bags of a man who has seen many patch days
		draw_arc(hp + Vector2(-29, -13), eye_r + 1.5, PI * 1.08, PI * 1.92, 16, C_SKIN_SHADE, 3.0)
		draw_arc(hp + Vector2(29, -13), eye_r + 1.5, PI * 1.08, PI * 1.92, 16, C_SKIN_SHADE, 3.0)
		draw_arc(hp + Vector2(-29, -6), 13, PI * 0.2, PI * 0.8, 12, Color(0.4, 0.25, 0.15, 0.35), 2.5)
		draw_arc(hp + Vector2(29, -6), 13, PI * 0.2, PI * 0.8, 12, Color(0.4, 0.25, 0.15, 0.35), 2.5)
	else:
		line(hp + Vector2(-44, -10), hp + Vector2(-16, -6), Color("#241a12"), 4)
		line(hp + Vector2(16, -6), hp + Vector2(44, -10), Color("#241a12"), 4)
		# tears
		for side in [-1.0, 1.0]:
			for k in range(3):
				var fall := fmod(t * 150.0 + k * 46.0 + (30.0 if side > 0.0 else 0.0), 110.0)
				circ(hp + Vector2(side * 29, 2 + fall), 4.5, Color(0.45, 0.75, 1.0, 0.9))
			line(hp + Vector2(side * 29, 0), hp + Vector2(side * 27, 66), Color(0.45, 0.75, 1.0, 0.5), 5)
	# brows: thick, expressive, load-bearing
	match mood:
		"rage":
			line(hp + Vector2(-46, -38), hp + Vector2(-14, -25), Color("#1c130c"), 7)
			line(hp + Vector2(46, -38), hp + Vector2(14, -25), Color("#1c130c"), 7)
		"shock", "cry":
			line(hp + Vector2(-46, -42), hp + Vector2(-14, -47), Color("#1c130c"), 6)
			line(hp + Vector2(14, -47), hp + Vector2(46, -42), Color("#1c130c"), 6)
		"hiss":
			line(hp + Vector2(-46, -30), hp + Vector2(-14, -34), Color("#1c130c"), 6)
			line(hp + Vector2(14, -34), hp + Vector2(46, -30), Color("#1c130c"), 6)
		_:
			line(hp + Vector2(-46, -36), hp + Vector2(-14, -36), Color("#1c130c"), 6)
			line(hp + Vector2(14, -36), hp + Vector2(46, -36), Color("#1c130c"), 6)
	# mouth by mood (what little of it escapes the mustache)
	match mood:
		"rage":
			rect(hp.x - 15, hp.y + 56, 30, 14, Color("#4a1410"))
			rect(hp.x - 15, hp.y + 56, 30, 4, Color.WHITE)
		"shock":
			circ(hp + Vector2(0, 59), 10, Color("#4a1410"))
		"cry":
			draw_arc(hp + Vector2(0, 70), 12, PI + 0.4, TAU - 0.4, 12, Color("#4a2c20"), 3.5)
		"hiss":
			for i in range(4):
				line(hp + Vector2(-14 + i * 8, 59), hp + Vector2(-10 + i * 8, 66), Color("#4a2c20"), 3)
		_:
			line(hp + Vector2(-12, 61), hp + Vector2(12, 61), Color("#7a4a34"), 4)
	# steam when raging
	if mood == "rage":
		for i in range(6):
			var side := -1.0 if i % 2 == 0 else 1.0
			var rise := fmod(t * 55.0 + i * 26.0, 84.0)
			var alpha := 0.65 * (1.0 - rise / 84.0)
			circ(hp + Vector2(side * (84 + (i % 3) * 8), -60 - rise), 8 + rise * 0.12, Color(0.9, 0.9, 0.92, alpha))
	# nose
	line(hp + Vector2(3, 10), hp + Vector2(-4, 30), C_SKIN_SHADE, 5)
	circ(hp + Vector2(-7, 33), 2.2, C_SKIN_SHADE)
	circ(hp + Vector2(6, 33), 2.2, C_SKIN_SHADE)

func draw_hands() -> void:
	# forearms + hands rest ON the desk, so they are drawn after it
	var type_bounce := 0.0
	if power_on and wifi_on and mood == "focused":
		type_bounce = sin(t * 17.0) * 2.0
	line(Vector2(572, 462), Vector2(640, 532 + type_bounce), C_SKIN, 30)
	circ(Vector2(644, 537 + type_bounce), 17, C_SKIN)
	circ(Vector2(638, 530 + type_bounce), 7, Color(1, 1, 1, 0.10))
	line(Vector2(850, 462), Vector2(864, 530 - type_bounce), C_SKIN, 30)
	circ(Vector2(856, 500 - type_bounce), 19, Color("#22252b")) # wrist brace
	circ(Vector2(866, 537 - type_bounce), 17, C_SKIN)
	circ(Vector2(860, 530 - type_bounce), 7, Color(1, 1, 1, 0.10))

func draw_desk() -> void:
	# desk surface + front
	rect(120, 505, 1032, 143, C_DESK)
	rect(120, 505, 1032, 12, C_DESK_EDGE)
	# monitor
	rect(285, 318, 245, 176, C_BLACK)
	rect(297, 330, 221, 140, Color("#0a0f1c"))
	if power_on and wifi_on:
		# in-game sky with a little depth, mountains, ground
		rect(297, 330, 221, 30, Color("#5f8fe8"))
		rect(297, 360, 221, 30, Color("#79a6ff"))
		rect(297, 390, 221, 24, Color("#a8c8f0"))
		circ(Vector2(492, 348), 9, Color("#ffe9a3"))
		draw_colored_polygon(PackedVector2Array([Vector2(297, 414), Vector2(352, 380), Vector2(404, 414)]), Color("#6a8f6e"))
		draw_colored_polygon(PackedVector2Array([Vector2(380, 414), Vector2(452, 372), Vector2(518, 414)]), Color("#4e9b47"))
		draw_colored_polygon(PackedVector2Array([Vector2(297, 414), Vector2(518, 414), Vector2(518, 470), Vector2(297, 470)]), Color("#3c7f3a"))
		draw_colored_polygon(PackedVector2Array([Vector2(330, 470), Vector2(392, 436), Vector2(420, 436), Vector2(380, 470)]), Color("#8a734f"))
		# tiny hero, forever mid-quest, now with a cape and a minimap to ignore
		var hx := 330.0 + fmod(t * 26.0, 130.0)
		draw_colored_polygon(PackedVector2Array([Vector2(hx - 3, 426), Vector2(hx + 2, 424), Vector2(hx - 5, 442)]), Color("#5e2f85"))
		rect(hx, 424, 10, 16, Color("#8e44ad"))
		circ(Vector2(hx + 5, 420), 5, C_SKIN)
		line(Vector2(hx + 10, 430), Vector2(hx + 20, 422), Color("#d7dde3"), 3)
		circ(Vector2(492, 436), 7, Color("#e64545"))
		draw_colored_polygon(PackedVector2Array([Vector2(486, 424), Vector2(490, 416), Vector2(494, 424)]), Color("#e64545"))
		draw_colored_polygon(PackedVector2Array([Vector2(494, 424), Vector2(498, 416), Vector2(502, 424)]), Color("#e64545"))
		# party frames + minimap: the full MMO HUD experience
		for p in range(3):
			rect(301, 336 + p * 17, 34, 14, Color(0.05, 0.06, 0.1, 0.75))
			rect(303, 339 + p * 17, 30, 4, C_GREEN if p < 2 else Color("#e8b13c"))
			rect(303, 345 + p * 17, 22, 3, Color("#3f7fe0"))
		circ(Vector2(498, 350), 15, Color(0.05, 0.08, 0.05, 0.8))
		draw_arc(Vector2(498, 350), 15, 0, TAU, 24, Color("#c9a227"), 2.0)
		circ(Vector2(503, 345), 2.5, Color("#e64545"))
		circ(Vector2(492, 356), 2, Color("#7ed957"))
		rect(305, 396, 92, 8, C_RED)
		rect(305, 407, 72, 7, Color("#3f7fe0"))
		rect(hx - 6, 446, 34, 4, Color(0, 0, 0, 0.55))
		rect(hx - 6, 446, 34.0 * (0.5 + 0.5 * sin(t * 0.9)), 4, Color("#c9a227"))
		for i in range(8):
			rect(305 + i * 26, 446, 22, 20, Color(0.12, 0.13, 0.18))
			circ(Vector2(316 + i * 26, 456), 3, C_GOLD if i % 3 == 0 else Color("#7fb2ff"))
		rect(297, 330, 221, 140, Color(1, 1, 1, 0.03 + 0.02 * sin(t * 7.0)))
	elif power_on and not wifi_on:
		rect(297, 330, 221, 140, Color("#2a0606"))
		line(Vector2(360, 360), Vector2(455, 440), C_RED, 7)
		line(Vector2(455, 360), Vector2(360, 440), C_RED, 7)
	else:
		line(Vector2(310, 460), Vector2(420, 344), Color(1, 1, 1, 0.05), 10)
	rect(392, 494, 30, 14, Color("#23252b"))
	rect(362, 506, 92, 8, Color("#23252b"))
	shadow(Vector2(407, 516), 150, 10, 0.16)
	if power_on and wifi_on:
		draw_colored_polygon(PackedVector2Array([Vector2(310, 514), Vector2(500, 514), Vector2(560, 570), Vector2(250, 570)]), Color(0.55, 0.7, 1.0, 0.05))
	# keyboard + keys
	rect(548, 522, 282, 38, Color("#1d1f26"))
	for r in range(3):
		for i in range(16):
			rect(556 + i * 17, 528 + r * 11, 13, 8, Color("#3a3f4a"))
	# mouse on its pad + cord
	rect(836, 516, 62, 54, Color("#2c2f38"))
	rect(839, 519, 56, 48, Color("#343945"))
	circ(Vector2(866, 542), 13, Color("#23252b"))
	circ(Vector2(866, 537), 6, Color("#3a3f4a"))
	line(Vector2(866, 530), Vector2(900, 512), Color("#101216"), 2)
	# snack zone: cans multiply with feeding
	var cans := mini(3 + snacks, 9)
	for i in range(cans):
		var cx := 946.0 + (i % 3) * 34.0
		var cy := 520.0 + (i / 3) * 40.0
		rect(cx, cy, 24, 34, C_DEW.darkened(0.15))
		rect(cx, cy, 24, 7, Color("#c9f2b0"))
		rect(cx + 4, cy + 12, 16, 4, Color(0, 0, 0, 0.25))
	# chip bag + bowl
	draw_colored_polygon(PackedVector2Array([Vector2(196, 540), Vector2(238, 540), Vector2(230, 506), Vector2(204, 506)]), Color("#c9a227"))
	rect(196, 540, 42, 6, Color("#8a6d1c"))
	circ(Vector2(452, 540), 20, Color("#54606e"))
	circ(Vector2(452, 536), 15, Color("#e8a13c"))
	# loose discs + papers on desk
	var disc_spots: Array[Vector2] = [Vector2(250, 586), Vector2(520, 596), Vector2(700, 592), Vector2(1080, 600)]
	for i in range(4):
		var dp: Vector2 = disc_spots[i]
		circ(dp, 13, Color("#cfd4d8"))
		circ(dp, 4, Color("#8f979e"))
	rect(150, 566, 66, 20, Color("#e8e6df"))
	rect(880, 578, 58, 18, Color("#d5d2c8"))

func draw_router_and_strip() -> void:
	# router on desk, right side
	rect(958, 448, 96, 26, C_BLACK)
	line(Vector2(972, 448), Vector2(962, 404), Color("#0c0d10"), 5)
	line(Vector2(1040, 448), Vector2(1052, 404), Color("#0c0d10"), 5)
	circ(Vector2(962, 402), 4, Color("#0c0d10"))
	circ(Vector2(1052, 402), 4, Color("#0c0d10"))
	for i in range(3):
		var c := Color("#394048")
		if power_on:
			c = C_GREEN if wifi_on else C_RED
			if wifi_on and i == 2 and fmod(t, 1.0) > 0.5:
				c = Color("#1d5c36")
		circ(Vector2(974 + i * 18, 461), 4, c)
	rect(958, 474, 96, 4, Color(0, 0, 0, 0.3))
	# power strip on the floor + cord to the rig
	rect(946, 600, 168, 24, Color("#d8d5cc"))
	for i in range(3):
		rect(962 + i * 44, 607, 18, 10, Color("#8f8b80"))
	var switch_c := C_RED if power_on else Color("#5c5648")
	rect(1088, 606, 16, 12, switch_c)
	if power_on:
		line(Vector2(946, 612), Vector2(880, 630), Color("#17181c"), 5)
		line(Vector2(880, 630), Vector2(700, 640), Color("#17181c"), 5)
	else:
		line(Vector2(946, 612), Vector2(906, 636), Color("#17181c"), 5)
		circ(Vector2(900, 638), 6, Color("#17181c"))
		if fmod(t, 0.9) < 0.12:
			circ(Vector2(894, 632), 4, Color("#ffe27a"))

func draw_trash_item(i: int, p: Vector2) -> void:
	match i % 5:
		0: # crushed can
			rect(p.x, p.y, 20, 13, C_DEW.darkened(0.3))
			rect(p.x + 3, p.y + 4, 14, 3, Color(0, 0, 0, 0.3))
		1: # pizza box
			rect(p.x - 6, p.y, 34, 12, Color("#c9a06a"))
			circ(p + Vector2(11, 6), 4, Color("#a8793f"))
		2: # dew bottle
			rect(p.x + 4, p.y - 8, 10, 20, Color(0.35, 0.75, 0.3, 0.85))
			rect(p.x + 7, p.y - 13, 4, 6, Color(0.35, 0.75, 0.3, 0.85))
		3: # wrapper
			draw_colored_polygon(PackedVector2Array([p, p + Vector2(18, 3), p + Vector2(12, 12), p + Vector2(2, 9)]), Color("#c7ccd1"))
		_: # cup
			draw_colored_polygon(PackedVector2Array([p, p + Vector2(16, 0), p + Vector2(13, 15), p + Vector2(3, 15)]), Color("#e8e6df"))

func draw_trash_pile() -> void:
	var n := mini(trash, 46)
	for i in range(n):
		var p: Vector2 = trash_spots[i % trash_spots.size()]
		if i >= 30: # overflow pile by the tower
			p = Vector2(180.0 + (i * 37) % 90, 586.0 + (i * 13) % 30)
		draw_trash_item(i, p)
	# a few permanent desk crumbs of civilization
	draw_trash_item(1, Vector2(1010, 566))
	draw_trash_item(3, Vector2(300, 612))
