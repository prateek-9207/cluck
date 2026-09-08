extends Node3D

const Progress = preload("res://scripts/progress.gd")
const Stick = preload("res://scripts/joystick.gd")
const LEVELS = [
	{"name":"THE FARMYARD", "sub":"A small bird. A very big problem.", "time":240.0, "boss":"THE RAT KING", "kind":0},
	{"name":"CORNFIELD CHAOS", "sub":"Something is moving in the corn.", "time":300.0, "boss":"OLD TUSK", "kind":2},
	{"name":"THE LAST BARN", "sub":"Make your final stand.", "time":360.0, "boss":"THE MOODON", "kind":3}]
const TYPES = ["rat", "fox", "boar", "cow"]
const ATTACKS = ["Egg Shot", "Feather Ring", "Peck Sweep", "Eggsplosion"]
const INK = Color("233b32")
const CREAM = Color("fff0ce")
const GOLD = Color("efb84f")
const RED = Color("d65a42")
var progress = Progress.new()
var world: Node3D
var actors: Node3D
var hero: Node3D
var hero_model: Node3D
var cam: Camera3D
var ui: Control
var overlay: Control
var hud: Control
var stick: Control
var title_label: Label
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var info_label: Label
var weapon_label: Label
var boss_bar: ProgressBar
var boss_label: Label
var notice: Label
var music: AudioStreamPlayer
var sounds: Array = []
var models: Dictionary = {}
var pools: Dictionary = {}
var enemies: Array = []
var shots: Array = []
var gems: Array = []
var effects: Array = []
var rng = RandomNumberGenerator.new()
var mode = "menu"
var level = 0
var elapsed = 0.0
var hp = 100.0
var max_hp = 100.0
var xp = 0
var rank = 1
var xp_need = 7
var kills = 0
var run_coins = 0
var damage_scale = 1.0
var speed = 5.0
var pickup = 2.0
var cooldown_scale = 1.0
var invuln = 0.0
var spawn_cd = 0.0
var weapon_cd = [0.0,0.0,0.0,0.0]
var weapons = [0,0,0,0]
var passives = {"power":0,"speed":0,"health":0,"magnet":0,"haste":0}
var facing = Vector3.FORWARD
var boss_spawned = false
var boss_defeated = false
var wave = 0
var shake = 0.0
var notice_time = 0.0
var bank_cd = 0.0
var saved_run_coins = 0
var autofarm = false
var test_mode = false
var test_completed = false
var test_level = 0
var test_file = ""
var sphere_mesh: SphereMesh
var gem_mesh: PrismMesh
var materials: Dictionary = {}

func _ready():
	rng.randomize()
	test_mode = "--smoke" in OS.get_cmdline_user_args() or "--campaign-test" in OS.get_cmdline_user_args()
	if test_mode: progress = Progress.new("user://cluck_test_save.json"); progress.reset()
	autofarm = "--campaign-test" in OS.get_cmdline_user_args()
	for name in TYPES + ["chicken","barn","hay","tree","fence","corn"]:
		models[name] = load("res://assets/models/" + name + ".glb")
	sphere_mesh = SphereMesh.new(); sphere_mesh.radius = .16; sphere_mesh.height = .32; sphere_mesh.radial_segments = 10; sphere_mesh.rings = 5
	gem_mesh = PrismMesh.new(); gem_mesh.size = Vector3(.19,.32,.19)
	make_world()
	make_ui()
	make_audio()
	show_home()
	if test_mode:
		start_run(0)
		if not autofarm: run_smoke.call_deferred()

func mat(color: Color, glow = false) -> StandardMaterial3D:
	var key = str(color) + str(glow)
	if materials.has(key): return materials[key]
	var m = StandardMaterial3D.new(); m.albedo_color = color; m.roughness = .85
	if glow: m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	materials[key] = m; return m

func cube(parent, pos, dims, color):
	var n = MeshInstance3D.new(); var mesh = BoxMesh.new(); mesh.size = dims; n.mesh = mesh
	n.material_override = mat(color); parent.add_child(n); n.position = pos; return n

func model(name: String, parent: Node3D, pos: Vector3, scale_value = 1.0) -> Node3D:
	var n = models[name].instantiate(); parent.add_child(n); n.position = pos; n.scale = Vector3.ONE * scale_value
	# Ignore any unselected object included by Blender's cross-scene export context.
	for child in n.get_children():
		if child.name == "Cube": child.visible = false
	return n

func make_world():
	world = Node3D.new(); add_child(world)
	actors = Node3D.new(); add_child(actors)
	var env = WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color("728c76")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color("ffe7b0"); env.environment.ambient_light_energy = .65
	add_child(env)
	var sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-53,-25,0); sun.light_color = Color("ffe2ad"); sun.light_energy = 1.25; sun.shadow_enabled = true; sun.directional_shadow_max_distance = 60; add_child(sun)
	cube(world,Vector3(0,-.2,0),Vector3(70,.35,70),Color("788a4b"))
	# Softly varied tiles make the farm floor legible without noisy textures.
	for x in range(-14,15,2):
		for z in range(-17,18,2):
			var c = Color("b59b66") if abs(x)<5 or abs(z)<3 else Color("839353")
			c = c.lightened(rng.randf_range(-.07,.05))
			cube(world,Vector3(x,-.02,z),Vector3(2,.025,2),c)
	for side in [-1,1]:
		for z in range(-17,18,2): model("fence",world,Vector3(side*13.8,0,z)).rotation.y = PI/2
		for x in range(-12,13,2): model("fence",world,Vector3(x,0,side*18.5))
	model("barn",world,Vector3(0,0,-22),1.8)
	for side in [-1,1]:
		for z in range(-23,25,5):
			model("tree",world,Vector3(side*rng.randf_range(16,19),0,z),rng.randf_range(1,1.7))
		for z in [-13,-6,8,15]:
			model("hay",world,Vector3(side*12.3,0,z),1.0)
		for x in range(8,13):
			for z in range(-16,18,3): model("corn",world,Vector3(side*x,0,z),rng.randf_range(.65,.9))
	for i in range(80):
		var p = Vector3(rng.randf_range(-13,13),.025,rng.randf_range(-18,18))
		if abs(p.x) > 5: cube(world,p,Vector3(.12,.09,.2),Color("afad61"))
	hero = Node3D.new(); actors.add_child(hero); hero_model = model("chicken",hero,Vector3.ZERO,.8)
	cam = Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.size = 20; cam.near = .1; cam.far = 100; add_child(cam); cam.current = true
	update_camera(1.0)

func update_camera(dt):
	var target = hero.position + Vector3(0,19,14)
	cam.position = cam.position.lerp(target, minf(1,dt*7))
	cam.look_at(cam.position - Vector3(0,19,14),Vector3.UP)
	if shake > 0 and not test_mode: cam.h_offset = rng.randf_range(-shake,shake); cam.v_offset = rng.randf_range(-shake,shake)
	else: cam.h_offset = 0; cam.v_offset = 0

func style(bg: Color, border = Color.TRANSPARENT, radius = 16) -> StyleBoxFlat:
	var s = StyleBoxFlat.new(); s.bg_color = bg; s.set_corner_radius_all(radius); s.set_border_width_all(2); s.border_color = border; s.content_margin_left = 18; s.content_margin_right = 18; s.content_margin_top = 12; s.content_margin_bottom = 12; return s

func text_label(parent, text: String, font_size = 20, color = CREAM) -> Label:
	var n = Label.new(); n.text = text; n.add_theme_font_size_override("font_size",font_size); n.add_theme_color_override("font_color",color); parent.add_child(n); return n

func button(parent, text: String, fn: Callable, primary = false, disabled = false) -> Button:
	var b = Button.new(); b.text = text; b.custom_minimum_size.y = 60; b.add_theme_font_size_override("font_size",20)
	b.add_theme_stylebox_override("normal",style(GOLD if primary else Color("355346"),Color("e5b951") if primary else Color("597161")))
	b.add_theme_stylebox_override("hover",style(Color("fbd27c") if primary else Color("466955")))
	b.add_theme_stylebox_override("pressed",style(Color("d69d38") if primary else Color("233b32")))
	b.add_theme_stylebox_override("disabled",style(Color("293e35")))
	b.add_theme_color_override("font_color",INK if primary else CREAM); b.add_theme_color_override("font_hover_color",INK if primary else CREAM)
	b.add_theme_color_override("font_pressed_color",INK if primary else CREAM); b.add_theme_color_override("font_disabled_color",Color("819180")); b.disabled = disabled
	b.pressed.connect(func(): sfx("tap"); fn.call()); parent.add_child(b); return b

func make_ui():
	var layer = CanvasLayer.new(); add_child(layer)
	ui = Control.new(); ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layer.add_child(ui); ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme = Theme.new(); theme.default_font_size = 20; ui.theme = theme
	stick = Stick.new(); ui.add_child(stick)
	hud = Control.new(); ui.add_child(hud); hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top = PanelContainer.new(); hud.add_child(top); top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); top.offset_left = 16; top.offset_right = -16; top.offset_top = 26; top.offset_bottom = 153; top.add_theme_stylebox_override("panel",style(Color(.1,.18,.14,.92)))
	var col = VBoxContainer.new(); top.add_child(col)
	var row = HBoxContainer.new(); col.add_child(row)
	title_label = text_label(row,"",22); title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(row,"Ⅱ",show_pause).custom_minimum_size = Vector2(54,48)
	hp_bar = ProgressBar.new(); hp_bar.custom_minimum_size.y = 16; hp_bar.show_percentage = false; hp_bar.add_theme_stylebox_override("background",style(Color("182c25"),Color.TRANSPARENT,6)); hp_bar.add_theme_stylebox_override("fill",style(RED,Color.TRANSPARENT,6)); col.add_child(hp_bar)
	xp_bar = ProgressBar.new(); xp_bar.custom_minimum_size.y = 8; xp_bar.show_percentage = false; xp_bar.add_theme_stylebox_override("background",style(Color("182c25"),Color.TRANSPARENT,3)); xp_bar.add_theme_stylebox_override("fill",style(Color("6cd7ce"),Color.TRANSPARENT,3)); col.add_child(xp_bar)
	info_label = text_label(col,"",16)
	weapon_label = text_label(hud,"",17); weapon_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); weapon_label.offset_top = -46; weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bc = VBoxContainer.new(); hud.add_child(bc); bc.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); bc.offset_top = 173; bc.offset_left = 40; bc.offset_right = -40
	boss_label = text_label(bc,"",20,GOLD); boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar = ProgressBar.new(); bc.add_child(boss_bar); boss_bar.show_percentage = false; boss_bar.custom_minimum_size.y = 12; boss_bar.add_theme_stylebox_override("fill",style(RED)); boss_bar.visible = false
	notice = text_label(hud,"",24,GOLD); notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER); notice.offset_left = -245; notice.offset_right = 245; notice.offset_top = -190; notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay = Control.new(); ui.add_child(overlay); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func clear_overlay():
	for c in overlay.get_children(): overlay.remove_child(c); c.queue_free()
	overlay.visible = true; stick.enabled = false; stick.release()

func panel(title: String, subtitle: String) -> VBoxContainer:
	clear_overlay()
	var shade = ColorRect.new(); shade.color = Color(.04,.10,.08,.74); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.add_child(shade)
	var margin = MarginContainer.new(); overlay.add_child(margin); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",28); margin.add_theme_constant_override("margin_right",28); margin.add_theme_constant_override("margin_top",48); margin.add_theme_constant_override("margin_bottom",34)
	var scroll = ScrollContainer.new(); margin.add_child(scroll); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col = VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; col.add_theme_constant_override("separation",12); scroll.add_child(col)
	text_label(col,"CLUCK  /  FARM SWEET SURVIVAL",14,GOLD)
	var t = text_label(col,title,38); t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var sub = text_label(col,subtitle,18,Color("c6d0b7")); sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var spacer = Control.new(); spacer.custom_minimum_size.y = 8; col.add_child(spacer)
	return col

func show_home():
	mode = "menu"; hud.visible = false; hero.position = Vector3.ZERO; hero_model.rotation.y = -.3
	var col = panel("SMALL BIRD.\nBIG PROBLEMS.","Your farm. Your fight. One more run.")
	text_label(col,"◈  %d COINS" % progress.data.coins,26,GOLD)
	text_label(col,"CHOOSE YOUR PATCH",15,Color("b3c3a4"))
	for i in range(3):
		var locked = i >= progress.data.unlocked
		var label = "%02d   %s   ·   %d MIN" % [i+1,LEVELS[i].name,int(LEVELS[i].time/60)]
		if locked: label += "  [LOCKED]"
		button(col,label,func(): start_run(i),not locked,locked).add_theme_font_size_override("font_size",17)
	text_label(col,"EQUIPPED  /  " + ATTACKS[int(progress.data.equipped)],18)
	button(col,"THE COOP   /   Upgrades & weapons",show_shop)
	button(col,"HOW TO PLAY",show_help)
	button(col,"SOUND & SETTINGS",show_settings)
	text_label(col,"Coins and purchases save automatically.\nNo ads. No purchases. Just poultry.",15,Color("a8b99b"))

func show_help():
	var col = panel("RULE THE ROOST","Move with one thumb. Let the eggs do the talking.")
	for msg in ["DRAG TO MOVE\nTouch anywhere below the top bar. On desktop, use WASD, arrow keys, or drag the mouse.","GROW DURING A RUN\nCollect blue gems. Each level gives three choices: add an attack or strengthen your build.","READ THE HERD\nRed circles warn of charges. Keep moving and collect hearts to heal. Gold magnets pull in every gem.","BRING HOME THE COINS\nEvery enemy earns coins. Spend them at the coop on lasting upgrades and starting weapons. Temporary run upgrades reset.","BEAT THE BOSS\nA boss arrives near the end of each level. Defeat it to unlock the next patch. Losing keeps your earned coins."]:
		var l = text_label(col,msg,19); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(col,"BACK TO THE FARM",show_home,true)

func show_shop():
	mode = "shop"
	var col = panel("THE COOP","Permanent improvements. A tougher bird every time.")
	text_label(col,"◈  %d COINS" % progress.data.coins,28,GOLD)
	for entry in [["health","HEARTY HEN","+20 maximum health"],["power","HARD BOILED","+10% weapon damage"],["magnet","FORAGER","+0.4m pickup range"]]:
		var key = entry[0]; var lv = int(progress.data[key]); var price = progress.cost(key)
		text_label(col,"%s  %d/5 · %s" % [entry[1],lv,entry[2]],17)
		button(col,"MAXED" if lv == 5 else "UPGRADE   ·   %d COINS" % price,func(): progress.buy_stat(key); show_shop(),false,lv==5 or progress.data.coins<price)
	text_label(col,"STARTING WEAPON",17,GOLD)
	for i in range(3):
		var owned = i in progress.data.owned; var equipped = int(progress.data.equipped)==i
		var suffix = "EQUIPPED" if equipped else ("EQUIP" if owned else "%d COINS" % Progress.PRICES[i])
		button(col,ATTACKS[i]+"   /   "+suffix,func(): progress.buy_weapon(i); show_shop(),equipped, equipped or (not owned and progress.data.coins<Progress.PRICES[i]))
	button(col,"BACK TO THE FARM",show_home,true)

func show_settings():
	var col = panel("SOUND & SETTINGS","Make yourself at home.")
	button(col,"MUSIC   " + ("ON" if progress.data.music else "OFF"),func(): progress.data.music = not progress.data.music; progress.save(); update_audio(); show_settings())
	button(col,"SOUND EFFECTS   " + ("ON" if progress.data.sound else "OFF"),func(): progress.data.sound = not progress.data.sound; progress.save(); show_settings())
	button(col,"BACK TO THE FARM",show_home,true)

func start_run(index: int):
	clear_combat(); level = index; elapsed = 0; hp = 100 + int(progress.data.health)*20; max_hp = hp
	damage_scale = 1 + int(progress.data.power)*.1; pickup = 2 + int(progress.data.magnet)*.4; speed = 5; cooldown_scale = 1
	xp = 0; rank = 1; xp_need = 7; kills = 0; run_coins = 0; saved_run_coins = 0; bank_cd = 0
	weapons = [0,0,0,0]; weapons[int(progress.data.equipped)] = 1; weapon_cd = [0.0,0.0,0.0,0.0]
	passives = {"power":0,"speed":0,"health":0,"magnet":0,"haste":0}
	invuln = 1; spawn_cd = .6; wave = 0; boss_spawned = false; boss_defeated = false
	hero.position = Vector3.ZERO; hero_model.visible = true; mode = "playing"; hud.visible = true; overlay.visible = false; stick.enabled = true
	boss_bar.visible = false; boss_label.text = ""; announce("%s\nDrag to move · attacks are automatic" % LEVELS[level].name,4)
	update_hud()

func clear_combat():
	for list in [enemies,shots,gems,effects]:
		for e in list: recycle(e.node)
		list.clear()

func acquire(kind: String) -> Node3D:
	if not pools.has(kind): pools[kind] = []
	var n: Node3D
	if pools[kind].size() > 0: n = pools[kind].pop_back()
	elif kind in TYPES: n = model(kind,actors,Vector3.ZERO)
	else:
		n = MeshInstance3D.new(); n.mesh = gem_mesh if kind == "gem" else sphere_mesh; actors.add_child(n)
	n.set_meta("pool",kind); n.visible = true; n.scale = Vector3.ONE; n.rotation = Vector3.ZERO; return n

func recycle(n: Node3D):
	n.visible = false; pools[n.get_meta("pool")].append(n)

func spawn_enemy(kind: int, boss = false):
	if enemies.size() >= 110 and not boss: return
	var n = acquire(TYPES[kind]); var angle = rng.randf()*TAU
	n.position = hero.position + Vector3(sin(angle),0,cos(angle))*rng.randf_range(12,16)
	n.position.x = clampf(n.position.x,-13,13); n.position.z = clampf(n.position.z,-18,18)
	if n.position.distance_to(hero.position)<7: n.position = Vector3(-10 if hero.position.x>0 else 10,0,-14 if hero.position.z>0 else 14)
	var health = [10.0,18.0,48.0,80.0][kind] * (1 + level*.25 + elapsed/900)
	if boss: health = [750.0,1200.0,1800.0][level]; n.scale *= 2.1
	enemies.append({"node":n,"kind":kind,"hp":health,"max":health,"speed":[1.6,2.7,1.8,1.2][kind]+level*.13,"radius":1.2 if boss else .45,"boss":boss,"attack":rng.randf_range(2,5),"warn":0.0,"charge":0.0,"dir":Vector3.ZERO,"flash":0.0,"phase":rng.randf()*TAU})
	if boss: boss_bar.max_value = health; boss_bar.value = health; boss_bar.visible = true; boss_label.text = LEVELS[level].boss; announce("%s\nINCOMING!" % LEVELS[level].boss,3); sfx("boss")

func _process(dt):
	if mode == "menu" or mode == "shop": hero_model.rotation.y += dt*.18; update_camera(dt); return
	if mode != "playing": return
	elapsed += dt; invuln = maxf(0,invuln-dt); shake = maxf(0,shake-dt*2); notice_time -= dt
	if notice_time <= 0: notice.text = ""
	var movement: Vector2 = stick.value
	if movement.length() < .1:
		movement = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).normalized()
	if autofarm:
		movement = Vector2(cos(elapsed*.18),sin(elapsed*.18))
		hp = max_hp
	var move3 = Vector3(movement.x,0,movement.y)
	hero.position += move3*speed*dt; hero.position.x = clampf(hero.position.x,-13,13); hero.position.z = clampf(hero.position.z,-17.5,17.5)
	if move3.length()>.1: facing = move3.normalized(); hero_model.rotation.y = lerp_angle(hero_model.rotation.y,atan2(-facing.x,-facing.z),dt*14)
	hero_model.position.y = abs(sin(elapsed*14))*.12*movement.length()
	hero_model.rotation.z = sin(elapsed*14)*.065*movement.length()
	hero_model.visible = invuln<=0 or int(invuln*12)%2==0
	update_camera(dt)
	spawn_cd -= dt
	if spawn_cd <= 0 and not boss_defeated:
		spawn_cd = maxf(.30,1.25-elapsed/300-level*.14)
		for i in range(1 + int(elapsed/100)):
			var kind = 0
			var r = rng.randf()
			if elapsed>25 and r>.63: kind = 1
			if level>=1 and elapsed>40 and r>.8: kind = 2
			if level>=2 and elapsed>65 and r>.9: kind = 3
			spawn_enemy(kind)
	var current_wave = int(elapsed/30)+1
	if current_wave > wave:
		wave = current_wave
		if wave > 1: announce("WAVE %02d  /  KEEP CLUCKING" % wave,2)
	if elapsed >= LEVELS[level].time-30 and not boss_spawned: boss_spawned = true; spawn_enemy(LEVELS[level].kind,true)
	for i in range(4):
		weapon_cd[i] -= dt
		if weapons[i]>0 and weapon_cd[i]<=0: fire_weapon(i)
	update_enemies(dt)
	if mode != "playing": return
	update_shots(dt); update_gems(dt); update_effects(dt)
	bank_cd += dt
	if bank_cd>5: bank_coins(); bank_cd=0
	update_hud()
	if boss_defeated: finish_run(true)

func update_enemies(dt):
	for e in enemies:
		if e.hp<=0: continue
		var n: Node3D = e.node; var to_player = hero.position - n.position; to_player.y = 0
		var dir = to_player.normalized(); e.attack -= dt; e.flash = maxf(0,e.flash-dt)
		if (e.kind == 2 or e.boss) and e.attack<=0 and e.warn<=0 and e.charge<=0:
			e.warn = .9; e.dir = dir; e.attack = 5.5; ring(n.position,1.7,RED,.9)
		if e.warn>0:
			e.warn -= dt
			if e.warn<=0: e.charge = .65
		elif e.charge>0:
			e.charge-=dt; n.position += e.dir*10*dt
		else:
			# A stable lateral offset stops every enemy collapsing into one point.
			var lateral = Vector3(-dir.z,0,dir.x) * sin(e.phase+elapsed*.8)*.35
			n.position += (dir+lateral)*e.speed*dt
		n.position.x = clampf(n.position.x,-13.5,13.5); n.position.z = clampf(n.position.z,-18,18)
		n.rotation.y = atan2(-dir.x,-dir.z); n.position.y = abs(sin(elapsed*10+e.phase))*.065
		n.rotation.z = sin(elapsed*10+e.phase)*.035
		if to_player.length() < e.radius+.45 and invuln<=0:
			hp -= (20 if e.boss else [9,12,17,20][e.kind]); invuln = .75; shake=.18; sfx("hurt"); ring(hero.position,.7,RED,.3)
			if hp<=0: finish_run(false); return
		if e.boss: boss_bar.value = e.hp
	for i in range(enemies.size()-1,-1,-1):
		if enemies[i].hp<=0:
			recycle(enemies[i].node); enemies.remove_at(i)

func closest_enemy():
	var result = null; var distance = 200.0
	for e in enemies:
		if e.hp<=0: continue
		var d = e.node.position.distance_squared_to(hero.position)
		if d < distance: distance = d; result = e
	return result

func fire_weapon(kind: int):
	var lv = weapons[kind]; var target = closest_enemy()
	weapon_cd[kind] = [.85,.55,1.35,2.8][kind] * cooldown_scale / (1+lv*.09)
	if kind == 0:
		if target == null: weapon_cd[kind]=.1; return
		var dir = (target.node.position - hero.position).normalized(); dir.y=0
		for j in range(1 + int(lv/3)):
			var n = acquire("shot"); n.position = hero.position + Vector3(0,.7,0); n.scale = Vector3(.85,1.15,.85); n.material_override = mat(CREAM,true)
			shots.append({"node":n,"dir":dir.rotated(Vector3.UP,(j-float(int(lv/3))*.5)*.16),"life":1.8,"damage":(12+lv*5)*damage_scale,"pierce":1+int(lv/4),"hit":[]})
		sfx("egg",.25)
	elif kind == 1:
		var radius = 1.8+lv*.18
		for j in range(3+lv):
			var angle = elapsed*3+j*TAU/(3+lv)
			var pos = hero.position+Vector3(cos(angle)*radius,.55,sin(angle)*radius)
			particle(pos,CREAM,Vector3(.09,.3,.09),.5)
		for e in enemies:
			if e.node.position.distance_to(hero.position)<radius+e.radius: hit(e,(5+lv*3)*damage_scale)
	elif kind == 2:
		var radius = 2.1+lv*.25; ring(hero.position,radius,GOLD,.3)
		for e in enemies:
			if e.node.position.distance_to(hero.position)<radius+e.radius:
				hit(e,(17+lv*7)*damage_scale); e.node.position += (e.node.position-hero.position).normalized()*.55
		sfx("sweep",.35)
	else:
		if target == null: return
		var pos: Vector3 = target.node.position; var radius = 2.1+lv*.2; ring(pos,radius,Color("f39743"),.5); particle(pos,GOLD,Vector3.ONE*1.8,.35)
		for e in enemies:
			if e.node.position.distance_to(pos)<radius: hit(e,(28+lv*12)*damage_scale)
		sfx("boom",.5)

func hit(e, amount):
	if e.hp<=0: return
	e.hp -= amount; e.flash=.12
	particle(e.node.position+Vector3(0,.6,0),CREAM,Vector3.ONE*.28,.12)
	if e.hp>0: return
	kills += 1; run_coins += 1+int(e.kind/2)
	var pos: Vector3 = e.node.position
	drop(pos, "xp", 2 if e.kind>=2 else 1)
	if kills%28==0: drop(pos+Vector3(.35,0,0),"heart",25)
	if kills%65==0: drop(pos+Vector3(-.35,0,0),"magnet",1)
	if e.boss: run_coins += 25; boss_defeated = true

func update_shots(dt):
	for i in range(shots.size()-1,-1,-1):
		var s = shots[i]; s.life -= dt; s.node.position += s.dir*14*dt; s.node.rotation.x+=dt*12
		for e in enemies:
			if e.hp<=0 or e.node in s.hit: continue
			var a: Vector3 = s.node.position; a.y=0
			var b: Vector3 = e.node.position; b.y=0
			if a.distance_to(b)<e.radius+.3:
				hit(e,s.damage); s.hit.append(e.node); s.pierce-=1
				if s.pierce<=0: s.life=0; break
		if s.life<=0: recycle(s.node); shots.remove_at(i)

func drop(pos: Vector3, kind: String, value: int):
	if gems.size()>=240 and kind=="xp":
		# Merge value rather than lose experience when the pickup cap is reached.
		for g in gems:
			if g.kind=="xp": g.value+=value; return
	var n = acquire("gem"); n.position = pos+Vector3(0,.3,0)
	n.material_override = mat(Color("50dfec") if kind=="xp" else (RED if kind=="heart" else GOLD),true)
	n.scale = Vector3.ONE*(1 if kind=="xp" else 2)
	gems.append({"node":n,"kind":kind,"value":value,"pull":false})

func update_gems(dt):
	for i in range(gems.size()-1,-1,-1):
		var g = gems[i]; var dest = hero.position+Vector3(0,.4,0); var d = g.node.position.distance_to(dest)
		g.node.rotation.y += dt*2
		if d<pickup or g.pull or autofarm:
			g.pull=true; g.node.position = g.node.position.move_toward(dest,dt*12)
		if d<.65:
			if g.kind=="xp": xp += g.value; sfx("gem",.12)
			elif g.kind=="heart": hp=minf(max_hp,hp+g.value); announce("+25 HEALTH",1.2); sfx("heal")
			else:
				for other in gems: other.pull=true
				announce("MAGNET!",1.2); sfx("heal")
			recycle(g.node); gems.remove_at(i)
	if xp>=xp_need:
		xp-=xp_need; rank+=1; xp_need = 7+rank*4
		show_upgrades()

func particle(pos: Vector3, color: Color, dims: Vector3, life: float):
	if effects.size()>70: return
	var n = acquire("effect"); n.position=pos; n.scale=dims*3; n.material_override=mat(color,true)
	effects.append({"node":n,"life":life,"max":life,"size":n.scale,"ring":false})

func ring(pos: Vector3, radius: float, color: Color, life: float):
	if effects.size()>70: return
	var n = acquire("ring")
	if not n.mesh is TorusMesh:
		var mesh = TorusMesh.new(); mesh.inner_radius=.92; mesh.outer_radius=1; mesh.rings=24; mesh.ring_segments=6; n.mesh=mesh
	n.position = Vector3(pos.x,.12,pos.z); n.scale=Vector3(radius,.12,radius); n.material_override=mat(color,true)
	effects.append({"node":n,"life":life,"max":life,"size":n.scale,"ring":true})

func update_effects(dt):
	for i in range(effects.size()-1,-1,-1):
		var e = effects[i]; e.life-=dt
		if e.life<=0: recycle(e.node); effects.remove_at(i)
		else: e.node.scale=e.size*(.6+.4*e.life/e.max)

func upgrade_options() -> Array:
	var options: Array = []
	for i in range(4):
		if weapons[i]<5: options.append({"type":"weapon","id":i,"title":ATTACKS[i],"desc":["Auto-fired eggs. More damage and extra shots.","Orbiting feathers damage nearby enemies.","A wide sweep pushes back the crowd.","Exploding eggs blast a cluster of enemies."][i],"level":weapons[i]+1})
	for key in passives:
		if passives[key]<4:
			var details = {"power":["FIGHTING SPIRIT","+15% damage for all weapons."],"speed":["QUICK FEET","Move 8% faster."],"health":["SECOND WIND","+20 max health. Heal 35 health."],"magnet":["FEED FINDER","Collect gems from farther away."],"haste":["EARLY BIRD","All weapons attack 8% faster."]}[key]
			options.append({"type":"passive","id":key,"title":details[0],"desc":details[1],"level":passives[key]+1})
	if options.is_empty(): options.append({"type":"heal","id":0,"title":"FRESH START","desc":"Recover 40 health.","level":1})
	options.shuffle(); return options.slice(0,3)

func show_upgrades():
	var options = upgrade_options()
	if autofarm: apply_upgrade(options[0]); return
	mode="upgrade"; sfx("level")
	var col = panel("LOOK WHO'S\nGROWING.","LEVEL %d  /  Choose one upgrade for this run." % rank)
	for option in options:
		var card = PanelContainer.new(); card.add_theme_stylebox_override("panel",style(Color("2b483b"),Color("647750"))); col.add_child(card)
		var box = VBoxContainer.new(); box.add_theme_constant_override("separation",8); card.add_child(box)
		text_label(box,("NEW WEAPON" if option.type=="weapon" and option.level==1 else "UPGRADE %d" % option.level),14,GOLD)
		text_label(box,option.title,26)
		var desc = text_label(box,option.desc,18); desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button(box,"PICK THIS",func(): apply_upgrade(option); resume_run(),true)

func apply_upgrade(option):
	if option.type=="weapon": weapons[option.id]+=1
	elif option.type=="heal": hp=minf(max_hp,hp+40)
	else:
		passives[option.id]+=1
		match option.id:
			"power": damage_scale+=.15
			"speed": speed+=.4
			"health": max_hp+=20; hp=minf(max_hp,hp+35)
			"magnet": pickup+=.6
			"haste": cooldown_scale*=.92

func resume_run():
	mode="playing"; overlay.visible=false; stick.enabled=true; stick.release()

func show_pause():
	if mode!="playing": return
	mode="pause"
	var col=panel("TAKE A BREATHER.","Your chicken is safe while paused.")
	button(col,"BACK TO THE FIGHT",resume_run,true)
	button(col,"RETURN TO FARM · KEEP COINS",func(): finish_run(false))

func bank_coins():
	var fresh = run_coins-saved_run_coins
	if fresh>0: progress.data.coins+=fresh; progress.save(); saved_run_coins=run_coins

func finish_run(won: bool):
	if mode=="results": return
	mode="results"; stick.enabled=false; hero_model.visible=true; bank_coins()
	var bonus = progress.award(level,0,elapsed,won)
	if autofarm:
		print("CAMPAIGN_LEVEL_PASS ",level," time=",elapsed," kills=",kills," earned=",run_coins+bonus," nodes=",actors.get_child_count())
		if level<2: start_run(level+1)
		else: print("CAMPAIGN_TEST_PASS"); get_tree().quit()
		return
	var col=panel("PATCH PROTECTED!" if won else "DOWN. NOT OUT.","%s  /  %s" % [LEVELS[level].name,"Victory!" if won else "Your earned coins are safe."])
	text_label(col,"%02d:%02d SURVIVED\n%d ENEMIES DEFEATED\nLEVEL %d REACHED" % [int(elapsed)/60,int(elapsed)%60,kills,rank],27)
	text_label(col,"+%d COINS" % (run_coins+bonus),42,GOLD)
	text_label(col,"%d earned in combat + %d completion bonus" % [run_coins,bonus],17)
	if won and level==2:
		var done=text_label(col,"THE FARM IS YOURS.\nAll three patches protected. Replay with a new weapon build!",23); done.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if won and level<2: button(col,"NEXT PATCH",func(): start_run(level+1),true)
	button(col,"VISIT THE COOP",func(): clear_combat(); hud.visible=false; show_shop(),true)
	button(col,"TRY AGAIN",func(): start_run(level))
	button(col,"BACK TO THE FARM",func(): clear_combat(); show_home())
	sfx("win" if won else "lose")

func announce(message: String, seconds: float):
	notice.text=message; notice_time=seconds

func update_hud():
	var remaining = maxi(0,int(LEVELS[level].time-elapsed))
	title_label.text = "%02d:%02d   /   WAVE %02d" % [remaining/60,remaining%60,maxi(1,wave)]
	hp_bar.max_value=max_hp; hp_bar.value=hp; xp_bar.max_value=xp_need; xp_bar.value=xp
	info_label.text="HP %d/%d    LV %d    ◈ %d    KILLS %d" % [maxi(0,int(hp)),int(max_hp),rank,run_coins,kills]
	var equipped: Array[String]=[]
	for i in range(4):
		if weapons[i]>0: equipped.append(ATTACKS[i]+" "+str(weapons[i]))
	weapon_label.text="  ·  ".join(equipped)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if mode=="playing": show_pause()
		elif mode=="pause": resume_run()

func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		if mode=="playing": show_pause()
		if is_instance_valid(hero): bank_coins()
	if what==NOTIFICATION_WM_CLOSE_REQUEST: bank_coins()

func make_audio():
	music=AudioStreamPlayer.new(); add_child(music); music.stream=load("res://assets/audio/farm_loop.wav"); music.volume_db=-21; update_audio()
	for i in range(10):
		var p=AudioStreamPlayer.new(); add_child(p); sounds.append(p)

func update_audio():
	if not is_instance_valid(music): return
	if progress.data.music and not test_mode: music.play()
	else: music.stop()

func sfx(name: String, volume=1.0):
	if not progress.data.sound or test_mode: return
	for p in sounds:
		if not p.playing:
			p.stream=load("res://assets/audio/"+name+".wav"); p.volume_db=linear_to_db(volume*.45); p.pitch_scale=rng.randf_range(.94,1.06); p.play(); return

func run_smoke():
	await get_tree().process_frame
	# Exercise the real run lifecycle, purchases, save roundtrip, and all attacks.
	for i in range(4): spawn_enemy(i)
	weapons=[3,3,3,3]
	for e in enemies: e.node.position=hero.position+Vector3(1,0,0)
	for i in range(4): fire_weapon(i)
	await get_tree().process_frame
	assert(kills>0,"Weapons should defeat enemies")
	run_coins=200; finish_run(false)
	assert(progress.data.coins==200,"Failed attempts retain coins once")
	finish_run(false); assert(progress.data.coins==200,"Duplicate result does not duplicate reward")
	assert(progress.buy_weapon(1)); assert(progress.buy_stat("health"))
	var loaded=Progress.new(progress.path)
	assert(loaded.data.equipped==1 and loaded.data.health==1 and loaded.data.coins==105)
	start_run(0); assert(max_hp==120 and weapons[1]==1)
	finish_run(true); assert(progress.data.unlocked==2)
	start_run(1); finish_run(true); assert(progress.data.unlocked==3)
	start_run(2); finish_run(true)
	print("SMOKE_TEST_PASS: combat, defeat rewards, duplicate guard, purchases, save reload, equipment, permanent stats, unlocks, campaign completion")
	get_tree().quit()
