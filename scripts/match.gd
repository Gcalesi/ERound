extends RefCounted

signal strike_resolved(hit: Dictionary)

const DATA = preload("res://scripts/roster.gd")
const EXCHANGE = preload("res://scripts/exchange.gd")
const ROUND_SECONDS := 45.0
const ROUND_COUNT := 3

var rng := RandomNumberGenerator.new()
var home: Dictionary
var away: Dictionary
var training: String
var level: int
var trust: float
var stress := 18.0
var stamina: float
var rival_stamina: float
var focus: float
var plan: String
var phase := "fight"
var round_number := 1
var time_left := ROUND_SECONDS
var exchange_delay := 0.8
var exchange_serial := 0
var current: RefCounted
var footage: RefCounted
var playhead := 0.0
var replay_position := 0.0
var impact: Dictionary = {}
var impact_age := 1.0
var resolved := 0
const COMMANDS := {
	"low_hook": "Baixou a guarda? Dá um gancho!",
	"rhythm": "Foca no ritmo: dois jabs e sai!",
	"on_entry": "Ele entrou? Recebe com um jab!",
}
const COMMAND_PLANS := {"low_hook": "center", "rhythm": "pace", "on_entry": "distance"}
var motion_center := Vector2.ZERO
var resting_offset := Vector2.ZERO
var command := ""
var command_status := ""
var command_exchange := ""
var action_left := 0
var reads_left := 2
var timeout_left := true
var timeout_pending := false
var read_window := 0.0
var clue_saved := false
var street_clue := ""
var adjustment := ""
var adjustment_exchanges := 0
var trust_delta := 0.0
var round_hits := Vector2i.ZERO
var score := Vector2i.ZERO
var scorecard: Array[Vector2i] = []
var line := "Seu atleta está à esquerda. Observe o adversário à direita."
var result: Dictionary = {}

func setup(career: RefCounted) -> void:
	rng.randomize()
	home = career.athlete()
	away = career.opponent()
	training = career.trained_plan
	level = career.level
	trust = career.trust
	plan = home["plan"]
	stamina = float(home["stamina"]) + minf(level * 2.0, 8.0)
	focus = home["focus"]
	rival_stamina = away["stamina"]
	match career.recovery:
		"load":
			stamina -= 11.0
		"balanced":
			stamina += 2.0
		"rest":
			stamina += 12.0
			stress -= 5.0
	match career.meals:
		"regular":
			focus += 10.0
		"energy":
			stamina += 10.0
		"routine":
			trust_delta += 6.0
			stress -= 5.0
	stamina = minf(100.0, stamina)
	var reading: String = away["pattern"]
	match reading:
		"retreat":
			street_clue = "Depois de errar, o rival dá dois passos para trás e entrega o centro."
		"exhaust":
			street_clue = "Depois de dois golpes seguidos, o rival fica parado com as luvas baixas."
		"chase":
			street_clue = "O rival abre espaço de propósito. Se alguém vai atrás dele, ele responde no avanço. Se ninguém persegue, ele precisa sair primeiro."

func can_read() -> bool:
	return phase == "fight" and read_window > 0.0 and reads_left > 0 and not timeout_pending

func can_request_time() -> bool:
	return phase == "fight" and timeout_left and not timeout_pending and time_left > 3.0

func request_time() -> void:
	if not can_request_time():
		return
	timeout_pending = true
	line = "Tempo pedido. O árbitro vai esperar os boxeadores se separarem."

func read_fight() -> void:
	if not can_read() or footage == null:
		return
	reads_left -= 1
	read_window = 0.0
	replay()

func replay() -> void:
	if footage == null:
		return
	replay_position = 0.0
	phase = "slow"
	line = "A mesma troca, em câmera lenta. O rival está à direita."

func step(delta: float) -> void:
	if phase == "slow":
		replay_position = minf(1.0, replay_position + delta / EXCHANGE.REPLAY_SECONDS)
		if replay_position >= 1.0:
			phase = "read"
		return
	if phase != "fight":
		return
	impact_age += delta
	time_left = maxf(0.0, time_left - delta)
	read_window = maxf(0.0, read_window - delta)
	if time_left <= 0.0:
		end_round()
		return
	if current != null:
		playhead = minf(1.0, playhead + delta / current.length)
		while resolved < current.strikes.size() and playhead >= float(current.strikes[resolved]["contact"]):
			resolve_strike(current.strikes[resolved])
			resolved += 1
		if playhead < 1.0:
			return
		if not current.pattern.is_empty():
			footage = current
			read_window = 8.0
		resting_offset = Vector2(current.pose_at(1.0, 0)["move"], current.pose_at(1.0, 1)["move"])
		if not command_exchange.is_empty() and command.is_empty():
			command_status = ""
		current = null
		exchange_delay = 0.21
		if timeout_pending:
			interrupt()
		return
	if timeout_pending:
		interrupt()
		return
	exchange_delay -= delta
	if exchange_delay <= 0.0 and time_left > 0.9:
		exchange()

func interrupt() -> void:
	timeout_pending = false
	timeout_left = false
	action_left = 1
	phase = "timeout"
	stamina = minf(100.0, stamina + 5.0)
	rival_stamina = minf(100.0, rival_stamina + 8.0)
	line = "O árbitro concedeu o tempo. Os dois atletas recuperaram um pouco de fôlego."

func round_chance() -> Vector2:
	var matched: bool = plan == DATA.ANSWERS[away["pattern"]]
	var using_training := training == plan
	var coached := adjustment_exchanges > 0 and adjustment == plan
	var base := 0.28 + (stamina - rival_stamina) * 0.004
	base += (focus - float(away["focus"])) * 0.002
	base += (trust - 55.0) * 0.001
	base -= stress * 0.0013
	base += 0.10 if matched else 0.0
	base += 0.04 + minf(level * 0.012, 0.06) if using_training else 0.0
	base += 0.13 if coached and matched else 0.035 if coached else 0.0
	var rival := 0.29 + (rival_stamina - stamina) * 0.003 + stress * 0.001 + round_number * 0.012
	return Vector2(clampf(base, 0.09, 0.67), clampf(rival, 0.13, 0.58))

func exchange() -> void:
	exchange_serial += 1
	var chances := round_chance()
	var roll := rng.randf()
	var hit_home := roll < chances.x
	var hit_away := not hit_home and roll > 1.0 - chances.y
	var start_center := motion_center
	var route := (exchange_serial - 1) % 12
	var direction := TAU * float(route) / 12.0
	var desired := Vector2(sin(direction) * 2.15, sin(direction * 2.0 + 0.35) * 0.94)
	var pressure := 0.25 if hit_home else -0.25 if hit_away else 0.0
	motion_center = motion_center.move_toward(desired + Vector2(pressure, 0), 1.16)
	var motif: String = away["pattern"] if exchange_serial % 6 == 3 else ""
	var hits: Array[Dictionary] = []
	var duration := rng.randf_range(1.34, 1.68)
	var spaced := plan == "distance"
	var opening := motif == "exhaust" or (motif.is_empty() and exchange_serial % 5 == 0)
	command_exchange = ""
	match motif:
		"retreat":
			hits.append(EXCHANGE.strike(1, "cross", "miss", 0.06, 0.54))
			duration = 2.05
		"exhaust":
			hits.append(EXCHANGE.strike(1, "jab", "block", 0.03, 0.35))
			hits.append(EXCHANGE.strike(1, "hook", "land" if hit_away else "block", 0.34, 0.65))
			duration = 2.15
		"chase":
			if not spaced:
				hits.append(EXCHANGE.strike(0, "cross", "miss", 0.13, 0.50))
			hits.append(EXCHANGE.strike(1, "jab", "land" if hit_away and not spaced else "block", 0.51, 0.89))
			duration = 2.10
		_:
			var first := 0 if hit_home else 1 if hit_away else rng.randi_range(0, 1)
			var style: String = ["jab", "cross", "hook"][exchange_serial % 3]
			var outcome := "land" if hit_home or hit_away else "block"
			hits.append(EXCHANGE.strike(first, style, outcome, 0.07, 0.64 if exchange_serial % 3 == 0 else 0.91))
			if exchange_serial % 3 == 0:
				hits.append(EXCHANGE.strike(1 - first, "jab", "block", 0.59, 0.95))
				duration = 1.85
	if command == "low_hook" and opening:
		if motif.is_empty():
			hits.clear()
		var hook_outcome := "land" if rng.randf() < clampf(chances.x + 0.39, 0.32, 0.91) else "miss"
		hits.append(EXCHANGE.strike(0, "hook", hook_outcome, 0.70, 0.97))
		duration = 2.28
		command_exchange = command
	elif command == "rhythm" and motif.is_empty():
		hits.assign([
			EXCHANGE.strike(0, "jab", "block", 0.18, 0.43),
			EXCHANGE.strike(0, "jab", "land" if rng.randf() < chances.x + 0.14 else "block", 0.47, 0.77),
		])
		duration = 1.98
		command_exchange = command
	elif command == "on_entry" and (motif == "retreat" or (motif.is_empty() and hits[0]["actor"] == 1)):
		hits.clear()
		hits.append(EXCHANGE.strike(0, "jab", "land" if rng.randf() < chances.x + 0.26 else "block", 0.21, 0.51))
		command_exchange = command
	if not command_exchange.is_empty():
		command = ""
		command_status = "Executando: " + COMMANDS[command_exchange]
	current = EXCHANGE.new(exchange_serial, motif, hits, duration, start_center, spaced, motion_center, opening, command_exchange, resting_offset)
	playhead = 0.0
	resolved = 0
	var spend := 0.60 + float(home["pace"]) * 1.15
	if plan == "pace":
		spend *= 0.68
	elif plan == "center":
		spend *= 1.21
	stamina = clampf(stamina - spend, 4.0, 100.0)
	var rival_spend := 0.68 + float(away["pace"]) * 1.25
	if away["pattern"] == "exhaust":
		rival_spend += 0.58
	rival_stamina = clampf(rival_stamina - rival_spend, 4.0, 100.0)
	adjustment_exchanges = maxi(0, adjustment_exchanges - 1)

func resolve_strike(hit: Dictionary) -> void:
	impact = hit
	impact_age = 0.0
	strike_resolved.emit(hit)
	var actor: Dictionary = home if hit["actor"] == 0 else away
	var other: Dictionary = away if hit["actor"] == 0 else home
	match hit["outcome"]:
		"land":
			line = "%s acertou em cheio." % actor["name"]
			if hit["actor"] == 0:
				round_hits.x += 1
				stress = maxf(0.0, stress - 2.3)
			else:
				round_hits.y += 1
				stress = minf(100.0, stress + 5.2)
				focus = maxf(0.0, focus - 2.0)
		"block":
			line = "%s bloqueou." % other["name"]
		"miss":
			line = "%s bateu no vazio." % actor["name"]
	if command_exchange == "low_hook" and hit["actor"] == 0:
		line = "%s aproveitou a guarda baixa com um gancho." % actor["name"] if hit["outcome"] == "land" else "%s viu a guarda baixar, mas o gancho passou no vazio." % actor["name"]
	elif command_exchange == "rhythm" and hit["start"] > 0.4:
		line = "%s completou os dois jabs e saiu da troca." % actor["name"]

func review_clue() -> String:
	if footage != null and footage.pattern == "chase" and footage.spaced:
		return "Seu atleta manteve a distância. Sem ninguém para atrair, o rival precisou sair primeiro."
	return street_clue

func read_choice(choice: String) -> void:
	if phase != "read":
		return
	if choice == "save":
		clue_saved = true
		line = "Você guardou a leitura para conversar no córner."
	elif choice == "wait":
		line = "Você esperou outra troca antes de opinar."
	else:
		orient(choice, true)
	phase = "fight"

func orient(choice: String, live: bool) -> void:
	var tactic: String = COMMAND_PLANS.get(choice, choice)
	var clarity: float = focus - stress * 0.48 + trust * 0.23
	if tactic == training:
		clarity += 18.0
	if stamina < 24.0:
		clarity -= 14.0
	if live:
		clarity -= 14.0
	if clarity < 40.0 and not COMMANDS.has(choice):
		line = "%s ouviu a orientação e acabou voltando ao seu plano anterior." % home["name"]
		trust_delta -= 3.0 if live else 0.0
		return
	plan = tactic
	clue_saved = false
	adjustment = tactic
	adjustment_exchanges = 11 if live else 18
	if plan == DATA.ANSWERS[away["pattern"]]:
		focus = minf(100.0, focus + 8.0)
		trust_delta += 4.0
		line = "%s entendeu a leitura e mudou de plano." % home["name"]
	else:
		line = "%s aceitou o ajuste e vai experimentar a orientação." % home["name"]
	if COMMANDS.has(choice):
		command = choice
		command_status = "Preparando: " + COMMANDS[choice]
		line = "“%s”" % COMMANDS[choice]

func corner_action(action: String) -> void:
	if action_left <= 0 or phase not in ["corner", "timeout"]:
		return
	action_left -= 1
	match action:
		"water":
			stamina = minf(100.0, stamina + 14.0)
			line = "%s recuperou um pouco de fôlego." % home["name"]
		"breathe":
			stress = maxf(0.0, stress - 24.0)
			focus = minf(100.0, focus + 4.0)
			line = "%s desacelerou a respiração e voltou a prestar atenção." % home["name"]
		"direto", "escuta", "desafio":
			talk(action)
		_:
			orient(action, false)

func talk(tone: String) -> void:
	var match_tone: bool = tone == home["tone"] and (tone != "desafio" or stress < 55.0)
	if tone == "escuta":
		clue_saved = true
		line = "“Eu reparei nisso também.” " + street_clue
		trust_delta += 3.0 if not match_tone else 7.0
		focus = minf(100.0, focus + (12.0 if match_tone else 5.0))
	elif match_tone:
		focus = minf(100.0, focus + 15.0)
		stress = maxf(0.0, stress - 9.0)
		trust_delta += 6.0
		line = "%s olhou para você e confirmou o que vai tentar." % home["name"]
	else:
		stress = minf(100.0, stress + (19.0 if tone == "desafio" else 8.0))
		trust_delta -= 15.0 if tone == "desafio" else 6.0
		line = "%s ficou mais tenso com a conversa." % home["name"]

func resume() -> void:
	if phase == "corner":
		round_number += 1
		time_left = ROUND_SECONDS
		round_hits = Vector2i.ZERO
		motion_center = Vector2.ZERO
		resting_offset = Vector2.ZERO
	elif phase != "timeout":
		return
	phase = "fight"
	read_window = 0.0
	exchange_delay = 1.0
	current = null
	impact.clear()

func end_round() -> void:
	var points := Vector2i(10, 10)
	if round_hits.x > round_hits.y:
		points.y = 9 if round_hits.x - round_hits.y < 10 else 8
	elif round_hits.y > round_hits.x:
		points.x = 9 if round_hits.y - round_hits.x < 10 else 8
	scorecard.append(points)
	score += points
	timeout_pending = false
	current = null
	impact.clear()
	if round_number >= ROUND_COUNT:
		finish(false)
		return
	stamina = minf(100.0, stamina + 13.0)
	rival_stamina = minf(100.0, rival_stamina + 16.0)
	line = "Round %d • %d a %d nas trocas. %s chegou ao córner." % [round_number, round_hits.x, round_hits.y, home["name"]]
	phase = "corner"
	action_left = 2

func finish(towel: bool) -> void:
	if phase == "result":
		return
	phase = "result"
	var win := not towel and score.x > score.y
	var title := "Vitória por pontos" if win else "Derrota por pontos" if score.x != score.y else "Empate"
	var remark := "“Vamos lembrar do que funcionou quando voltarmos à academia.”"
	if towel:
		title = "Luta encerrada pelo córner"
		trust_delta += 4.0
		remark = "“A gente conversa na academia. Hoje eu precisava que você decidisse.”"
	elif trust_delta <= -8.0:
		remark = "“Eu ouvi você. Só precisava que você me ouvisse também.”"
	elif win and trust_delta >= 8.0:
		remark = "“Funcionou. Eu reconheci na luta o que a gente treinou.”"
	result = {
		"title": title, "win": win, "towel": towel, "opponent": away["name"],
		"stress": stress, "trust_delta": trust_delta,
		"score": "%d–%d" % [score.x, score.y] if not towel else "Córner",
		"remark": remark,
	}
