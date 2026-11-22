extends Node3D

var camera: Camera3D
var home: Dictionary
var away: Dictionary
var elapsed := 0.0
var mode := "menu"
var home_key := ""
var away_key := ""
var motion := 0.0

func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#101729")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#afbdda")
	environment.ambient_light_energy = 0.58
	world.environment = environment
	add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-54.0, -24.0, 0.0)
	key.light_color = Color("#ffe1ad")
	key.light_energy = 0.94
	key.shadow_enabled = true
	add_child(key)
	light(Vector3(-4, 4, -3), Color("#577fff"), 6.0, 13.0)
	light(Vector3(4, 3, 4), Color("#ff8b50"), 4.0, 10.0)
	build_gym()
	camera = Camera3D.new()
	camera.fov = 40.0
	camera.position = Vector3(3.4, 3.0, 8.2)
	add_child(camera)
	camera.look_at(Vector3(-1.05, 1.12, 0.0))
	camera.current = true

func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.93
	return mat

func mesh(parent: Node3D, model: PrimitiveMesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = model
	node.position = pos
	node.material_override = material(color)
	parent.add_child(node)
	return node

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var model := BoxMesh.new()
	model.size = size
	return mesh(parent, model, pos, color)

func ellipsoid(parent: Node3D, pos: Vector3, size: Vector3, color: Color, sectors: int = 12) -> MeshInstance3D:
	var model := SphereMesh.new()
	model.radius = 0.5
	model.height = 1.0
	model.radial_segments = sectors
	model.rings = 6
	var node := mesh(parent, model, pos, color)
	node.scale = size
	return node

func pole(parent: Node3D, pos: Vector3, length: float, radius: float, color: Color) -> MeshInstance3D:
	var model := CylinderMesh.new()
	model.height = length
	model.top_radius = radius
	model.bottom_radius = radius
	model.radial_segments = 8
	return mesh(parent, model, pos, color)

func light(pos: Vector3, color: Color, energy: float, reach: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = pos
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = reach
	add_child(lamp)

func sign_text(words: String, pos: Vector3, size: int, pixel: float, color: Color) -> Label3D:
	var sign := Label3D.new()
	sign.text = words
	sign.font_size = size
	sign.outline_size = 0
	sign.pixel_size = pixel
	sign.modulate = color
	sign.position = pos
	add_child(sign)
	return sign

func build_gym() -> void:
	box(self, Vector3(0, -0.82, -1), Vector3(38, 0.12, 29), Color("#20243b"))
	box(self, Vector3(0, 3.3, -8.6), Vector3(36, 8, 0.35), Color("#252c43"))
	box(self, Vector3(0, 0.15, -8.38), Vector3(36, 1.55, 0.12), Color("#552a43"))
	box(self, Vector3(0, 1.0, -8.36), Vector3(36, 0.11, 0.12), Color("#ad6547"))
	for i in range(-5, 6):
		box(self, Vector3(i * 3.0, 3.8, -8.22), Vector3(0.17, 7.5, 0.28), Color("#171d34"))
	for i in range(-4, 5, 2):
		box(self, Vector3(i * 3, 4.5, -8.31), Vector3(2.2, 1.16, 0.09), Color("#141b32"))
		box(self, Vector3(i * 3, 4.5, -8.24), Vector3(1.95, 0.86, 0.08), Color("#5d7191"))
		box(self, Vector3(i * 3, 4.5, -8.17), Vector3(0.10, 0.82, 0.07), Color("#262f48"))
	for i in range(-2, 3):
		box(self, Vector3(i * 3.5, 5.4, -2.4), Vector3(2.5, 0.17, 0.28), Color("#12182b"))
		box(self, Vector3(i * 3.5, 5.29, -2.4), Vector3(2.12, 0.06, 0.17), Color("#f2bc83"))
		box(self, Vector3(i * 4.0, 5.83, -2.4), Vector3(0.09, 0.75, 0.09), Color("#182032"))
	box(self, Vector3(0.0, -0.42, 0.0), Vector3(7.95, 0.62, 7.95), Color("#1a2544"))
	box(self, Vector3(0.0, -0.16, 0.0), Vector3(7.88, 0.28, 7.88), Color("#323d5f"))
	box(self, Vector3(0.0, -0.025, 0.0), Vector3(7.65, 0.05, 7.65), Color("#647a9b"))
	box(self, Vector3(0.0, -0.34, 3.99), Vector3(7.90, 0.07, 0.04), Color("#dd9c58"))
	var ink := Color("#526888")
	for edge in [-3.45, 3.45]:
		box(self, Vector3(edge, 0.002, 0), Vector3(0.032, 0.006, 6.91), ink)
		box(self, Vector3(0, 0.002, edge), Vector3(6.91, 0.006, 0.032), ink)
	var floor_mark := sign_text("E R O U N D S", Vector3(0, 0.009, -1.53), 92, 0.008, Color("#98abc3"))
	floor_mark.rotation_degrees.x = -90.0
	sign_text("ER  /  ACADEMIA DE BOXE", Vector3(0, 3.17, -8.04), 64, 0.0076, Color("#eac591"))
	for x in [-3.7, 3.7]:
		for z in [-3.7, 3.7]:
			var accent := Color("#df4c53") if x < 0 else Color("#5b82f3")
			box(self, Vector3(x, 0.73, z), Vector3(0.16, 1.65, 0.16), Color("#252d44"))
			box(self, Vector3(x, 0.91, z), Vector3(0.25, 0.97, 0.25), accent)
			box(self, Vector3(x, 1.46, z), Vector3(0.25, 0.13, 0.25), Color("#e8ded1"))
	for h in [0.51, 0.86, 1.20]:
		var rope_color := Color("#eee0c2") if is_equal_approx(h, 0.86) else Color("#b54a5e")
		box(self, Vector3(0, h, -3.7), Vector3(7.37, 0.055, 0.055), rope_color)
		box(self, Vector3(-3.7, h, 0), Vector3(0.055, 0.055, 7.37), rope_color)
		box(self, Vector3(3.7, h, 0), Vector3(0.055, 0.055, 7.37), rope_color)
		var near_rope := Color("#b87674") if is_equal_approx(h, 0.86) else Color("#783c59")
		box(self, Vector3(0, h, 3.7), Vector3(7.37, 0.042, 0.042), near_rope)
	for x in [-2.95, 2.95]:
		var stool_color := Color("#c8484e") if x < 0 else Color("#4265d0")
		pole(self, Vector3(x, 0.22, -2.96), 0.43, 0.075, Color("#272e43"))
		pole(self, Vector3(x, 0.44, -2.96), 0.12, 0.23, stool_color)
	var palette := [Color("#3c4663"), Color("#4e495d"), Color("#363b54"), Color("#566278")]
	for i in range(23):
		var x := (i - 11) * 0.65
		var z := -5.5 - (i % 3) * 0.68
		var height := float(i % 5) * 0.11
		ellipsoid(self, Vector3(x, 0.64 + height, z), Vector3(0.37, 0.42, 0.33), palette[i % 4], 8)
		ellipsoid(self, Vector3(x, 0.14 + height, z), Vector3(0.59, 0.76, 0.45), palette[(i + 2) % 4], 8)

func cast(left: Dictionary, right: Dictionary) -> void:
	if home_key == left["id"] and away_key == right["id"]:
		return
	if not home.is_empty():
		home["root"].queue_free()
		away["root"].queue_free()
	home_key = left["id"]
	away_key = right["id"]
	home = figure(left)
	away = figure(right)

func joint(parent: Node3D, at: Vector3) -> Node3D:
	var part := Node3D.new()
	part.position = at
	parent.add_child(part)
	return part

func figure(data: Dictionary) -> Dictionary:
	var root := joint(self, Vector3.ZERO)
	root.scale = data["shape"]
	var body := joint(root, Vector3(0, 0.92, 0))
	var skin: Color = data["skin"]
	var shade := skin.darkened(0.20)
	var shorts: Color = data["shorts"]
	var glove: Color = data["gloves"]
	var hair: Color = data["hair"]
	ellipsoid(body, Vector3(0, 0.29, 0.0), Vector3(0.67, 0.73, 0.42), skin)
	ellipsoid(body, Vector3(0, 0.01, 0.0), Vector3(0.49, 0.38, 0.39), shade)
	box(body, Vector3(0.0, -0.09, 0.012), Vector3(0.52, 0.16, 0.40), shorts)
	box(body, Vector3(0.0, -0.02, 0.018), Vector3(0.53, 0.085, 0.42), Color("#f5ebcf"))
	ellipsoid(body, Vector3(0, 0.61, 0.018), Vector3(0.22, 0.23, 0.22), shade)
	var head := joint(body, Vector3(0, 0.77, 0.043))
	ellipsoid(head, Vector3(0, 0.0, 0.0), Vector3(0.38, 0.48, 0.37), skin)
	var features := Color("#282334")
	for s in [-1, 1]:
		ellipsoid(head, Vector3(s * 0.166, -0.015, -0.001), Vector3(0.09, 0.115, 0.085), shade)
		var eye := box(head, Vector3(s * 0.075, 0.012, 0.174), Vector3(0.091, 0.030, 0.027), features)
		eye.rotation.z = s * 0.16
		box(head, Vector3(s * 0.073, 0.014, 0.189), Vector3(0.029, 0.011, 0.009), Color("#fbdfbf"))
	ellipsoid(head, Vector3(0.0, -0.052, 0.178), Vector3(0.076, 0.075, 0.08), skin.lightened(0.08), 8)
	box(head, Vector3(0.0, -0.11, 0.149), Vector3(0.083, 0.014, 0.025), shade.darkened(0.43))
	ellipsoid(head, Vector3(0, 0.14, -0.042), Vector3(0.40, 0.28, 0.37), hair, 9)
	if data["id"] in ["lia", "mara"]:
		ellipsoid(head, Vector3(0, 0.24, -0.14), Vector3(0.24, 0.23, 0.25), hair, 9)
	else:
		for i in range(4):
			var lock := ellipsoid(head, Vector3(-0.15 + i * 0.077, 0.16 + (i % 2) * 0.046, 0.102), Vector3(0.14, 0.24, 0.22), hair, 8)
			lock.rotation.z = -0.45
	var arms: Array[Node3D] = []
	var forearms: Array[Node3D] = []
	var legs: Array[Node3D] = []
	for side in [-1, 1]:
		var thigh := joint(body, Vector3(side * 0.151, -0.13, 0.01))
		ellipsoid(thigh, Vector3(0, -0.12, 0), Vector3(0.285, 0.40, 0.35), shorts)
		ellipsoid(thigh, Vector3(0, -0.43, -0.02), Vector3(0.205, 0.52, 0.23), skin)
		ellipsoid(thigh, Vector3(0, -0.64, 0.066), Vector3(0.22, 0.29, 0.33), Color("#282e45"))
		box(thigh, Vector3(0, -0.735, 0.093), Vector3(0.21, 0.055, 0.31), Color("#e5dfd1"))
		legs.append(thigh)
		var arm := joint(body, Vector3(side * 0.29, 0.47, 0.0))
		ellipsoid(arm, Vector3(0, -0.146, 0), Vector3(0.239, 0.42, 0.237), skin)
		var elbow := joint(arm, Vector3(0, -0.30, 0.025))
		ellipsoid(elbow, Vector3(0, -0.12, 0.0), Vector3(0.176, 0.35, 0.188), shade)
		box(elbow, Vector3(0, -0.236, 0), Vector3(0.206, 0.11, 0.215), Color("#efe4d0"))
		ellipsoid(elbow, Vector3(0, -0.35, 0.0), Vector3(0.29, 0.34, 0.31), glove)
		ellipsoid(elbow, Vector3(-side * 0.102, -0.316, 0.08), Vector3(0.12, 0.19, 0.14), glove.darkened(0.12))
		arms.append(arm)
		forearms.append(elbow)
	return {"root": root, "body": body, "head": head, "arms": arms, "forearms": forearms, "legs": legs}

func update_pose(delta: float, fight: RefCounted) -> void:
	if home.is_empty():
		return
	var phase: String = fight.phase if fight != null else ""
	var slow := phase == "slow" or phase == "read"
	elapsed += delta * (0.23 if slow else 1.0)
	var viewing_match := mode == "fight"
	var target := Vector3(1.9, 2.7, 6.8) if viewing_match else Vector3(3.4, 3.0, 8.2)
	var look := Vector3(0.0, 1.04, 0.0) if viewing_match else Vector3(-1.05, 1.12, 0.0)
	if slow:
		target = Vector3(1.48, 2.15, 4.77)
		look = Vector3(0.18, 1.11, 0.0)
	camera.position = camera.position.lerp(target, 1.0 - exp(-delta * 3.7))
	camera.look_at(look)
	var time_in_exchange := 0.0
	var event := "idle"
	var active_side := 0
	if fight != null:
		time_in_exchange = clampf(1.0 - fight.exchange_delay / fight.exchange_interval, 0.0, 1.0)
		event = fight.animation
		active_side = fight.punch_side
	motion = lerpf(motion, 1.0 if slow else 0.0, 1.0 - exp(-delta * 4.0))
	if slow:
		time_in_exchange = 0.24 + motion * 0.57
	var envelope := sin(PI * time_in_exchange)
	var pattern := sin(TAU * time_in_exchange)
	var retreat := 0.0
	match event:
		"retreat":
			retreat = -0.28 * maxf(0.0, pattern) + 0.52 * maxf(0.0, -pattern)
		"exhaust":
			retreat = -0.39 * envelope
		"chase":
			retreat = 0.22 * envelope
	var corner := phase in ["corner", "timeout"]
	var spacing := 0.82 + sin(elapsed * 1.18) * 0.10
	if corner:
		spacing = 2.72
	var shift := 0.11 * sin(elapsed * 1.7)
	var home_dist := -spacing + (0.33 * envelope if event == "home" else 0.0)
	var away_dist := spacing + retreat - (0.33 * envelope if event == "away" else 0.0)
	if not viewing_match:
		home_dist += 0.75
		away_dist += 0.75
	pose(home, delta, Vector3(home_dist, 0, shift), 1.0, elapsed, active_side if event == "home" else -1, envelope, corner, fight != null and fight.stamina < 29.0)
	pose(away, delta, Vector3(away_dist, 0, -shift), -1.0, elapsed + 0.55, active_side if event in ["away", "exhaust", "retreat"] else -1, envelope, corner, event == "exhaust" or (fight != null and fight.rival_stamina < 29.0))
	home["root"].position.z = lerpf(home["root"].position.z, -2.65 if corner else shift, clampf(delta * 4.8, 0.0, 1.0))
	away["root"].position.z = lerpf(away["root"].position.z, -2.65 if corner else -shift, clampf(delta * 4.8, 0.0, 1.0))

func pose(pawn: Dictionary, delta: float, pos: Vector3, direction: float, clock: float, hit_side: int, strength: float, corner: bool, tired: bool) -> void:
	var root: Node3D = pawn["root"]
	root.position.x = lerpf(root.position.x, pos.x, clampf(delta * 12.0, 0.0, 1.0))
	var yaw := direction * (PI * 0.5 - 0.42)
	root.rotation.y = lerp_angle(root.rotation.y, yaw if not corner else direction * 0.35, clampf(delta * 7.0, 0.0, 1.0))
	var body: Node3D = pawn["body"]
	var hit := strength if hit_side >= 0 and not corner else 0.0
	body.position.y = 0.88 + 0.034 * sin(clock * 9.0) - (0.20 if corner else 0.0)
	body.rotation.x = -0.04 + hit * 0.14 + (0.20 * strength if tired else 0.0)
	body.rotation.y = sin(clock * 4.5) * 0.11 + hit * (0.35 if hit_side == 0 else -0.35)
	for i in range(2):
		var arm: Node3D = pawn["arms"][i]
		var elbow: Node3D = pawn["forearms"][i]
		var leg: Node3D = pawn["legs"][i]
		var strike := hit if hit_side == i else 0.0
		var side := -1.0 if i == 0 else 1.0
		arm.rotation.x = -0.48 - strike * 0.91 + (0.28 if corner else 0.0)
		arm.rotation.z = side * (0.14 + 0.025 * sin(clock * 8.0))
		elbow.rotation.x = -1.58 + strike * 1.54 + (0.66 if corner else 0.0) + (0.32 * strength if tired else 0.0)
		leg.rotation.x = side * (0.17 + 0.06 * sin(clock * 6.0 + i)) - (0.30 if corner else 0.0)
		leg.rotation.z = side * 0.17
