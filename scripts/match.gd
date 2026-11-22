extends RefCounted

const DATA = preload("res://scripts/roster.gd")
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
var exchange_delay := 0.7
var exchange_interval := 1.3
var exchange_serial := 0
var momentum := 0.0
var animation := "idle"
var punch_side := 0
var action_left := 0
var reads_left := 2
var timeout_left := true
var timeout_pending := false
var read_window := 0.0
var read_preview := 0.0
var clue_saved := false
var street_clue := ""
var adjustment := ""
var adjustment_exchanges := 0
var trust_delta := 0.0
var round_hits := Vector2i.ZERO
var score := Vector2i.ZERO
var scorecard: Array[Vector2i] = []
var line := "O gongo toca. Observe como os dois disputam o espaço."
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
			street_clue = "Repare nos dois passos para trás depois que o rival avança e erra."
		"exhaust":
			street_clue = "As investidas são fortes, mas o rival demora a recuperar a guarda depois delas."
		"chase":
			street_clue = "Quando encontra distância, o rival espera que alguém vá atrás. Veja o que faz quando precisa tomar a iniciativa."

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
	if not can_read():
		return
	reads_left -= 1
	read_window = 0.0
	read_preview = 1.35
	phase = "slow"
	animation = str(away["pattern"])
	line = "Observe como %s reage após a troca." % away["name"]

func step(delta: float) -> void:
	if phase == "slow":
		read_preview -= delta
		if read_preview <= 0.0:
			phase = "read"
		return
	if phase != "fight":
		return
	time_left = maxf(0.0, time_left - delta)
	read_window = maxf(0.0, read_window - delta)
	if time_left <= 0.0:
		end_round()
		return
	exchange_delay -= delta
	if exchange_delay > 0.0:
		return
	if timeout_pending:
		interrupt()
		return
	exchange()

func interrupt() -> void:
	timeout_pending = false
	timeout_left = false
	action_left = 1
	phase = "timeout"
	stamina = minf(100.0, stamina + 5.0)
	rival_stamina = minf(100.0, rival_stamina + 8.0)
	line = "O árbitro concedeu o tempo. Os dois atletas recuperaram um pouco de fôlego."

func exchange() -> void:
	exchange_serial += 1
	exchange_interval = rng.randf_range(0.93, 1.48)
	exchange_delay = exchange_interval
	var rival_pattern: String = away["pattern"]
	var matched: bool = plan == DATA.ANSWERS[rival_pattern]
	var using_training := training == plan
	var coached := adjustment_exchanges > 0 and adjustment == plan
	var base := 0.26 + (stamina - rival_stamina) * 0.004
	base += (focus - float(away["focus"])) * 0.002
	base += (trust - 55.0) * 0.001
	base -= stress * 0.0013
	base += 0.08 if matched else 0.0
	base += 0.04 + minf(level * 0.012, 0.06) if using_training else 0.0
	base += 0.13 if coached and matched else 0.035 if coached else 0.0
	var player_chance := clampf(base, 0.08, 0.66)
	var rival_chance := clampf(0.28 + (rival_stamina - stamina) * 0.003 + stress * 0.001 + round_number * 0.012, 0.13, 0.57)
	var roll := rng.randf()
	punch_side = exchange_serial % 2
	if roll < player_chance:
		animation = "home"
		round_hits.x += 1
		momentum = lerpf(momentum, 1.0, 0.34)
		stress = maxf(0.0, stress - 1.7)
		if exchange_serial % 4 == 0:
			line = "%s encaixou uma boa troca." % home["name"]
	elif roll > 1.0 - rival_chance:
		animation = "away"
		round_hits.y += 1
		momentum = lerpf(momentum, -1.0, 0.34)
		stress = minf(100.0, stress + 4.6)
		focus = maxf(0.0, focus - 1.8)
		if exchange_serial % 4 == 0:
			line = "%s impôs o ritmo nesta troca." % away["name"]
	else:
		animation = "guard"
		momentum = lerpf(momentum, 0.0, 0.24)
		stress = maxf(0.0, stress - 0.3)
	if exchange_serial % 7 == 4:
		animation = rival_pattern
		read_window = 4.0
		match rival_pattern:
			"retreat":
				line = "%s avançou e recuou de novo." % away["name"]
			"exhaust":
				line = "%s está demorando mais para recuperar a guarda." % away["name"]
			"chase":
				line = "%s parou e está esperando seu atleta ir atrás." % away["name"]
	var spend := 0.60 + float(home["pace"]) * 1.15
	if plan == "pace":
		spend *= 0.68
	elif plan == "center":
		spend *= 1.21
	stamina = clampf(stamina - spend * 0.78 + (0.55 if animation == "guard" else 0.0), 4.0, 100.0)
	var rival_spend := 0.64 + float(away["pace"]) * 1.12
	if rival_pattern == "exhaust":
		rival_spend += 0.52
	rival_stamina = clampf(rival_stamina - rival_spend * 0.78 + (0.55 if animation == "guard" else 0.0), 4.0, 100.0)
	adjustment_exchanges = maxi(0, adjustment_exchanges - 1)

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
	exchange_delay = exchange_interval
	animation = "idle"

func orient(choice: String, live: bool) -> void:
	var clarity: float = focus - stress * 0.48 + trust * 0.23
	if choice == training:
		clarity += 18.0
	if stamina < 24.0:
		clarity -= 14.0
	if live:
		clarity -= 14.0
	if clarity < 40.0:
		line = "%s ouviu a orientação e acabou voltando ao seu plano anterior." % home["name"]
		trust_delta -= 3.0 if live else 0.0
		return
	plan = choice
	clue_saved = false
	adjustment = choice
	adjustment_exchanges = 11 if live else 18
	if plan == DATA.ANSWERS[away["pattern"]]:
		focus = minf(100.0, focus + 8.0)
		trust_delta += 4.0
		line = "%s entendeu a leitura e mudou de plano." % home["name"]
	else:
		line = "%s aceitou o ajuste e vai experimentar a orientação." % home["name"]

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
		momentum = 0.0
	elif phase != "timeout":
		return
	phase = "fight"
	read_window = 0.0
	exchange_delay = 1.0
	animation = "idle"

func end_round() -> void:
	var points := Vector2i(10, 10)
	if round_hits.x > round_hits.y:
		points.y = 9 if round_hits.x - round_hits.y < 10 else 8
	elif round_hits.y > round_hits.x:
		points.x = 9 if round_hits.y - round_hits.x < 10 else 8
	scorecard.append(points)
	score += points
	timeout_pending = false
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
