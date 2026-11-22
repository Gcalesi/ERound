extends Node3D

var camera: Camera3D
var home: Dictionary
var away: Dictionary
var elapsed := 0.0
var mode := "menu"
var home_key := ""
var away_key := ""
var look_at_point := Vector3(0, 1.0, 0)
var fight_deck: Node3D

func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#171a24")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d0d6ed")
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-54.0, -24.0, 0.0)
	key.light_color = Color("#ffeacb")
	key.light_energy = 0.86
	key.shadow_enabled = false
	add_child(key)
	light(Vector3(-4, 4, -3), Color("#5e89fa"), 2.3, 12.0)
	light(Vector3(4, 3, 4), Color("#ffad77"), 1.8, 10.0)
	build_gym()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.7
	camera.position = Vector3(0, 2.45, 6.8)
	add_child(camera)
	camera.look_at(look_at_point)
	camera.current = true

func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.roughness = 0.82
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
	var cream := Color("#e6d9bb")
	var deep := Color("#1d2230")
	var rail := Color("#373d4b")
	box(self, Vector3(0, -0.82, -1), Vector3(28, 0.12, 23), deep)
	box(self, Vector3(0, 2.9, -6.8), Vector3(23, 7, 0.3), Color("#292735"))
	box(self, Vector3(0, 1.0, -6.61), Vector3(23, 1.70, 0.09), Color("#413039"))
	for i in range(-5, 6):
		box(self, Vector3(i * 2.2, 2.8, -6.57), Vector3(0.09, 6, 0.08), Color("#4b3940"))
	for x in [-5.6, 5.6]:
		box(self, Vector3(x, 2.73, -6.55), Vector3(2.1, 1.4, 0.09), rail)
		for i in range(3):
			box(self, Vector3(x - 0.64 + i * 0.65, 2.73, -6.48), Vector3(0.55, 1.14, 0.08), Color("#75645b"))
	var placard := box(self, Vector3(0, 2.51, -6.54), Vector3(3.8, 0.89, 0.12), Color("#211e2b"))
	sign_text("ENTRE ROUNDS", placard.position + Vector3(0, 0.03, 0.07), 88, 0.0045, Color("#eac5a0"))
	box(self, Vector3(0, 2.02, -6.45), Vector3(3.8, 0.028, 0.04), Color("#af6a43"))
	box(self, Vector3(0, -0.35, 0), Vector3(7.8, 0.65, 7.5), Color("#24364c"))
	box(self, Vector3(0, -0.028, 0), Vector3(7.65, 0.055, 7.35), Color("#7c9aaf"))
	box(self, Vector3(0, -0.24, 3.77), Vector3(7.76, 0.085, 0.018), Color("#b99458"))
	var marking := Color("#90a7b6")
	for edge in [-3.35, 3.35]:
		box(self, Vector3(edge, 0.002, 0), Vector3(0.05, 0.005, 6.72), marking)
		box(self, Vector3(0, 0.002, edge), Vector3(6.72, 0.005, 0.05), marking)
	for i in range(20):
		var angle := TAU * float(i) / 20.0
		var point := Vector3(cos(angle) * 1.32, 0.006, sin(angle) * 1.32)
		var tick := box(self, point, Vector3(0.17, 0.008, 0.028), marking)
		tick.rotation.y = -angle - PI * 0.5
	fight_deck = joint(self, Vector3.ZERO)
	for x in [-3.7, 3.7]:
		for z in [-3.53, 3.53]:
			var accent := Color("#3979a4") if x < 0 else Color("#c86046")
			var poles := self if z < 0.0 else fight_deck
			box(poles, Vector3(x, 0.72, z), Vector3(0.18, 1.55, 0.18), deep)
			box(poles, Vector3(x, 0.85, z), Vector3(0.28, 0.89, 0.26), accent)
			box(poles, Vector3(x, 1.35, z), Vector3(0.30, 0.16, 0.30), cream)
	for height in [0.51, 0.82, 1.12]:
		var rope_color := Color("#c2b39b") if is_equal_approx(height, 0.82) else Color("#805853")
		box(self, Vector3(0, height, -3.53), Vector3(7.36, 0.037, 0.047), rope_color)
		box(self, Vector3(-3.7, height, 0), Vector3(0.048, 0.048, 7.06), rope_color)
		box(self, Vector3(3.7, height, 0), Vector3(0.048, 0.048, 7.06), rope_color)
		box(fight_deck, Vector3(0, height, 3.53), Vector3(7.36, 0.046, 0.045), rope_color.darkened(0.25))
	for i in range(18):
		var x := (i - 8.5) * 0.63
		var z := -4.45 - (i % 2) * 0.45
		var height := 0.35 + (i % 4) * 0.095
		var tone := Color("#34343e").lightened((i % 5) * 0.024)
		ellipsoid(self, Vector3(x, height + 0.40, z), Vector3(0.33, 0.39, 0.32), tone, 8)
		ellipsoid(self, Vector3(x, height - 0.08, z), Vector3(0.53, 0.64, 0.40), tone.darkened(0.17), 8)

func cast(left: Dictionary, right: Dictionary) -> void:
	if home_key == left["id"] and away_key == right["id"]:
		return
	if not home.is_empty():
		home["root"].queue_free()
		away["root"].queue_free()
		home["shadow"].queue_free()
		away["shadow"].queue_free()
	home_key = left["id"]
	away_key = right["id"]
	home = figure(left, Color("#2999c9"))
	away = figure(right, Color("#d35c45"))
	update_pose(1.0, null)

func joint(parent: Node3D, at: Vector3) -> Node3D:
	var part := Node3D.new()
	part.position = at
	parent.add_child(part)
	return part

func figure(data: Dictionary, team: Color) -> Dictionary:
	var shadow := ellipsoid(self, Vector3(0, 0.009, 0), Vector3(0.78, 0.006, 0.51), Color("#455c70"), 16)
	var root := joint(self, Vector3.ZERO)
	root.scale = data["shape"]
	var body := joint(root, Vector3(0, 0.91, 0))
	var skin: Color = data["skin"]
	var shade := skin.darkened(0.18)
	var shorts: Color = data["shorts"]
	var hair: Color = data["hair"]
	var dark := Color("#202633")
	var trim := Color("#f0dbc1")
	var torso := CylinderMesh.new()
	torso.height = 0.54
	torso.top_radius = 0.37
	torso.bottom_radius = 0.23
	torso.radial_segments = 8
	mesh(body, torso, Vector3(0, 0.24, 0), team.darkened(0.29) if data["id"] in ["lia", "mara"] else skin).scale.z = 0.67
	ellipsoid(body, Vector3(0.0, 0.47, 0.012), Vector3(0.77, 0.32, 0.43), skin, 10)
	ellipsoid(body, Vector3(0.0, 0.22, 0.018), Vector3(0.54, 0.41, 0.40), skin, 10)
	box(body, Vector3(0.0, -0.034, 0.012), Vector3(0.55, 0.15, 0.39), shorts)
	box(body, Vector3(0.0, 0.059, 0.015), Vector3(0.56, 0.095, 0.405), trim)
	box(body, Vector3(0.0, 0.06, 0.226), Vector3(0.16, 0.055, 0.023), team)
	if data["id"] in ["lia", "mara"]:
		ellipsoid(body, Vector3(0.0, 0.36, 0.041), Vector3(0.66, 0.34, 0.43), team.darkened(0.3), 10)
		box(body, Vector3(0.0, 0.23, 0.24), Vector3(0.38, 0.055, 0.022), team.lightened(0.16))
	ellipsoid(body, Vector3(0, 0.63, 0.035), Vector3(0.25, 0.30, 0.24), shade)
	var head := joint(body, Vector3(0, 0.80, 0.057))
	ellipsoid(head, Vector3(0, -0.07, 0.042), Vector3(0.36, 0.36, 0.34), skin, 10)
	ellipsoid(head, Vector3(0, 0.045, -0.016), Vector3(0.43, 0.46, 0.40), skin, 10)
	for side in [-1, 1]:
		ellipsoid(head, Vector3(side * 0.195, -0.016, -0.009), Vector3(0.10, 0.14, 0.076), shade, 8)
		var brow := box(head, Vector3(side * 0.091, 0.043, 0.163), Vector3(0.118, 0.031, 0.044), hair)
		brow.rotation.z = side * 0.21
		box(head, Vector3(side * 0.085, 0.011, 0.173), Vector3(0.076, 0.023, 0.023), trim)
		box(head, Vector3(side * 0.073, 0.011, 0.185), Vector3(0.029, 0.024, 0.008), dark)
	ellipsoid(head, Vector3(0.0, -0.049, 0.177), Vector3(0.092, 0.088, 0.105), skin.lightened(0.05), 8)
	box(head, Vector3(0.0, -0.108, 0.185), Vector3(0.097, 0.016, 0.029), dark)
	ellipsoid(head, Vector3(0, 0.156, -0.043), Vector3(0.43, 0.29, 0.41), hair, 9)
	match data["id"]:
		"lia", "mara":
			ellipsoid(head, Vector3(0, 0.27, -0.15), Vector3(0.21, 0.22, 0.26), hair, 8)
			box(head, Vector3(0, 0.118, 0.16), Vector3(0.35, 0.041, 0.084), team)
		"nico", "davi":
			ellipsoid(head, Vector3(0, 0.205, -0.015), Vector3(0.36, 0.19, 0.35), hair.lightened(0.08), 8)
			if data["id"] == "nico":
				box(head, Vector3(0, 0.131, 0.162), Vector3(0.35, 0.043, 0.081), team)
		_:
			for i in range(4):
				var lock := ellipsoid(head, Vector3(-0.14 + i * 0.082, 0.18 + (i % 2) * 0.035, 0.112), Vector3(0.12, 0.20, 0.23), hair, 8)
				lock.rotation.z = -0.40
	var arms: Array[Dictionary] = []
	var legs: Array[Dictionary] = []
	for side in [-1, 1]:
		var upper := ellipsoid(body, Vector3.ZERO, Vector3(0.26, 1, 0.26), skin, 9)
		var fore := ellipsoid(body, Vector3.ZERO, Vector3(0.19, 1, 0.20), shade, 9)
		var hand := joint(body, Vector3.ZERO)
		ellipsoid(hand, Vector3(0, 0.01, 0.024), Vector3(0.32, 0.32, 0.38), team, 10)
		ellipsoid(hand, Vector3(-side * 0.104, -0.06, 0.00), Vector3(0.147, 0.19, 0.21), team.darkened(0.21), 8)
		box(hand, Vector3(0, -0.076, -0.117), Vector3(0.217, 0.18, 0.125), team.darkened(0.28))
		box(hand, Vector3(0, -0.056, -0.18), Vector3(0.193, 0.16, 0.055), trim)
		arms.append({"upper": upper, "fore": fore, "hand": hand})
		var thigh := ellipsoid(root, Vector3.ZERO, Vector3(0.31, 1, 0.30), shorts, 9)
		var calf := ellipsoid(root, Vector3.ZERO, Vector3(0.192, 1, 0.213), shade, 9)
		var boot := joint(root, Vector3.ZERO)
		ellipsoid(boot, Vector3(0, 0.125, -0.024), Vector3(0.23, 0.25, 0.23), dark, 9)
		box(boot, Vector3(0, 0.071, 0.068), Vector3(0.23, 0.115, 0.345), dark)
		box(boot, Vector3(0, 0.021, 0.074), Vector3(0.235, 0.043, 0.35), trim)
		for i in range(3):
			box(boot, Vector3(0, 0.137 + i * 0.023, 0.139 - i * 0.032), Vector3(0.128, 0.014, 0.035), team.lightened(0.25))
		legs.append({"thigh": thigh, "calf": calf, "boot": boot})
	return {"root": root, "shadow": shadow, "body": body, "head": head, "arms": arms, "legs": legs}

func idle_state() -> Dictionary:
	return {"move": 0.0, "duck": 0.0, "recoil": 0.0, "drop": 0.0, "guard": 0.0,
		"strike": 0.0, "arm": 0, "windup": 0.0, "style": "", "outcome": "", "step": 0.0, "swing": 0.0}

func update_pose(delta: float, fight: RefCounted) -> void:
	if home.is_empty():
		return
	var phase: String = fight.phase if fight != null else ""
	var replay := phase in ["slow", "read"]
	var corner := phase in ["corner", "timeout"]
	elapsed += delta * (0.17 if replay else 1.0)
	var viewing_match := mode == "fight"
	fight_deck.visible = not viewing_match
	var event: RefCounted
	var time := 0.0
	if fight != null:
		event = fight.footage if replay else fight.current
		time = fight.replay_position if replay else fight.playhead
	var left: Dictionary = event.pose_at(time, 0) if event != null else idle_state()
	var right: Dictionary = event.pose_at(time, 1) if event != null else idle_state()
	var center: Vector2 = event.travel(time) if event != null else fight.motion_center if fight != null else Vector2.ZERO
	if event == null and viewing_match and not corner and fight != null:
		left["move"] = fight.resting_offset.x
		right["move"] = fight.resting_offset.y
	var spacing := 0.78
	var depth := 0.09 + center.x * 0.16
	if not viewing_match:
		center = Vector2(1.73, 0.0)
		spacing = 0.83
	elif corner:
		spacing = 2.46
	var left_pos := Vector3(center.x - spacing + float(left["move"]), 0, center.y + depth)
	var right_pos := Vector3(center.x + spacing - float(right["move"]), 0, center.y - depth)
	if corner:
		left_pos.z = -0.7
		right_pos.z = -0.7
	left_pos.x = clampf(left_pos.x, -3.19, 3.19)
	right_pos.x = clampf(right_pos.x, -3.19, 3.19)
	var heading := atan2(right_pos.x - left_pos.x, right_pos.z - left_pos.z)
	var alignment := 1.0 - exp(-delta * (24.0 if replay else 27.0))
	place(home, left, left_pos, 1.0, elapsed, corner, alignment, heading - 0.28)
	place(away, right, right_pos, -1.0, elapsed + 0.49, corner, alignment, heading - PI + 0.28)
	limbs(home, away, left, elapsed, corner, event, time, 0)
	limbs(away, home, right, elapsed + 0.49, corner, event, time, 1)
	var desired_camera := Vector3(0.0, 2.38, 6.7)
	var desired_look := Vector3(0.0, 1.10, 0.0)
	var zoom := 3.68
	if not viewing_match:
		desired_camera = Vector3(0, 2.70, 7.5)
		desired_look = Vector3(-0.35, 1.01, 0)
		zoom = 4.04
	elif replay:
		desired_camera.x = 0.20
		desired_look.x = center.x + 0.24
		zoom = 3.42
	elif corner:
		zoom = 4.15
	else:
		desired_look.x = center.x * 0.63
	var camera_blend := 1.0 - exp(-delta * 6.0)
	camera.position = camera.position.lerp(desired_camera, camera_blend)
	look_at_point = look_at_point.lerp(desired_look, camera_blend)
	camera.size = lerpf(camera.size, zoom, camera_blend)
	camera.look_at(look_at_point)

func place(pawn: Dictionary, state: Dictionary, target: Vector3, direction: float, clock: float, corner: bool, blend: float, heading: float) -> void:
	var root: Node3D = pawn["root"]
	root.position = root.position.lerp(target, blend)
	var shadow: Node3D = pawn["shadow"]
	shadow.position.x = root.position.x
	shadow.position.z = root.position.z
	var yaw := heading if mode == "fight" and not corner else direction * 0.62
	var strike_t: float = state["strike"]
	var twist := 0.24 if state["style"] == "hook" else 0.15 if state["style"] == "cross" else 0.035
	yaw += (-1.0 if state["arm"] == 1 else 1.0) * strike_t * twist
	root.rotation.y = lerp_angle(root.rotation.y, yaw, blend)
	var body: Node3D = pawn["body"]
	var head: Node3D = pawn["head"]
	var spring := sin(clock * 8.0) * 0.022
	var twitch := float(state["recoil"])
	var lower := float(state["duck"])
	var strike := float(state["strike"])
	var low_guard := float(state["drop"])
	var lead := -1.0 if state["arm"] == 0 else 1.0
	body.position = Vector3(-lower * 0.14, 0.91 + spring - lower * 0.34 - low_guard * 0.14, strike * 0.055 - twitch * 0.14)
	if corner:
		body.position.y = 0.82 + spring
	body.rotation = Vector3(0.10 + lower * 0.25 + low_guard * 0.34 - twitch * 0.47,
		lead * (strike * (-0.88 if state["style"] == "hook" else -0.52 if state["style"] == "cross" else 0.22) - float(state["windup"]) * 0.32), lower * 0.17 - twitch * 0.12)
	head.rotation = Vector3(twitch * -0.28 + low_guard * 0.22, twitch * 0.52, twitch * -0.26)

func stretch(segment: Node3D, a: Vector3, b: Vector3, overlap: float) -> void:
	segment.position = (a + b) * 0.5
	var extent := b - a
	segment.quaternion = Quaternion(Vector3.UP, extent.normalized())
	segment.scale.y = extent.length() + overlap

func limbs(pawn: Dictionary, target: Dictionary, state: Dictionary, clock: float, corner: bool, event: RefCounted, time: float, fighter: int) -> void:
	var body: Node3D = pawn["body"]
	var enemy_head: Node3D = target["head"]
	var root: Node3D = pawn["root"]
	var enemy_body: Node3D = target["body"]
	for i in range(2):
		var side := -1.0 if i == 0 else 1.0
		var arm: Dictionary = pawn["arms"][i]
		var leg: Dictionary = pawn["legs"][i]
		var guard: float = state["guard"]
		var drop: float = state["drop"]
		var recoil: float = state["recoil"]
		var shoulder := Vector3(side * 0.30, 0.47, 0.012)
		var glove := Vector3(side * (0.22 - guard * 0.09 + recoil * 0.14),
			0.69 + guard * 0.10 - drop * 0.53 - recoil * 0.21, 0.33 + guard * 0.045 - drop * 0.08)
		var reach: float = state["strike"] if state["arm"] == i else 0.0
		if reach > 0.0:
			var contact := body.to_local(enemy_head.global_position)
			match state["outcome"]:
				"land":
					contact += Vector3(0, -0.055, -0.11)
				"block":
					contact += Vector3(0, -0.12, -0.28)
				"miss":
					contact.y = body.to_local(enemy_body.global_position).y + 1.23
			if state["style"] == "hook":
				var chamber := Vector3(side * 0.62, 0.47, 0.16)
				var sweep := Vector3(side * 0.90, 0.61, 0.52)
				contact.x -= side * float(state["swing"]) * (1.0 - reach) * 0.25
				var end := shoulder + (contact - shoulder).limit_length(0.82)
				var arc: float = state["swing"]
				glove = glove.lerp(chamber.lerp(sweep, arc).lerp(sweep.lerp(end, arc), arc), reach)
			else:
				var reach_limit := 0.97 if state["style"] == "cross" else 0.91
				glove = glove.lerp(shoulder + (contact - shoulder).limit_length(reach_limit), reach)
		elif state["arm"] == i:
			glove.z -= float(state["windup"]) * 0.13
		if corner:
			glove = Vector3(side * 0.29, 0.05, 0.10)
		var elbow := shoulder.lerp(glove, 0.49) + Vector3(side * (0.10 - reach * 0.06), -0.32 * (1.0 - reach * 0.86), -0.016)
		if state["style"] == "hook" and reach > 0.0:
			elbow = elbow.lerp(Vector3(side * 0.64, glove.y - 0.04, 0.31), reach)
		var hand: Node3D = arm["hand"]
		hand.position = glove
		hand.rotation = Vector3(-0.35 + reach * 0.62, -side * (0.21 + reach * 0.25), side * (0.23 - reach * 0.19))
		stretch(arm["upper"], shoulder, elbow, 0.15)
		stretch(arm["fore"], elbow, glove, 0.095)
		var boot := Vector3(side * 0.20, 0.0, -side * 0.27)
		var rear_pivot := reach if i == 1 and state["style"] in ["hook", "cross"] else 0.0
		if event != null and not corner:
			var stepping: float = time * 4.0 + float((i + fighter) % 2) * 0.5
			var part := fposmod(stepping, 1.0)
			var touchdown := time - part * 0.25
			var swing := smoothstep(0.36, 0.90, part)
			var foot_time := clampf(touchdown + 0.25 * swing, 0.0, 1.0)
			var trail: Vector2 = event.travel(foot_time) - event.travel(time)
			var foot_pose: Dictionary = event.pose_at(foot_time, fighter)
			trail.x += (float(foot_pose["move"]) - float(state["move"])) * (1.0 if fighter == 0 else -1.0)
			var step_delta := root.basis.inverse() * Vector3(trail.x, 0, trail.y)
			boot += step_delta.limit_length(0.38)
			if part >= 0.36 and part <= 0.9:
				boot.y += 0.105 * sin(PI * (part - 0.36) / 0.54)
		boot.y += rear_pivot * 0.075
		var hip := Vector3(side * 0.164, body.position.y - 0.078, 0)
		var knee := hip.lerp(boot + Vector3(0, 0.14, 0), 0.49) + Vector3(side * 0.023, 0, 0.09)
		leg["boot"].position = boot
		leg["boot"].rotation.y = side * 0.15 + sin(clock * 3.3) * 0.045 + rear_pivot * 0.48
		stretch(leg["thigh"], hip, knee, 0.15)
		stretch(leg["calf"], knee, boot + Vector3(0, 0.14, 0), 0.11)

func screen_anchor(side: int) -> Vector2:
	var pawn := home if side == 0 else away
	var head: Node3D = pawn["head"]
	return camera.unproject_position(head.global_position)
