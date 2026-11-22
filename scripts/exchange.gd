extends RefCounted

const CONTACT := 0.53
const REPLAY_SECONDS := 4.8

var strikes: Array[Dictionary]
var pattern: String
var length: float
var number: int
var center: float
var spaced: bool

func _init(serial: int, motif: String, hits: Array[Dictionary], seconds: float, midpoint: float, keep_distance: bool) -> void:
	number = serial
	pattern = motif
	strikes = hits
	length = seconds
	center = midpoint
	spaced = keep_distance

static func strike(actor: int, style: String, outcome: String, start: float, end: float) -> Dictionary:
	return {"actor": actor, "style": style, "outcome": outcome, "start": start, "end": end,
		"contact": lerpf(start, end, CONTACT)}

static func smooth_span(t: float, start: float, end: float) -> float:
	return smoothstep(start, end, t)

func progress(t: float, hit: Dictionary) -> float:
	return clampf(inverse_lerp(hit["start"], hit["end"], t), 0.0, 1.0)

func extension(p: float) -> float:
	return smooth_span(p, 0.25, CONTACT) * (1.0 - smooth_span(p, CONTACT + 0.035, 0.93))

func cue(t: float) -> int:
	match pattern:
		"retreat":
			return 0 if t < 0.31 else 1 if t < 0.53 else 2
		"exhaust":
			return 0 if t < 0.34 else 1 if t < 0.58 else 2
		"chase":
			return 0 if t < 0.23 else 1 if t < 0.53 else 2
	return 0

func stage_names() -> PackedStringArray:
	match pattern:
		"retreat":
			return ["Entrada", "Golpe no vazio", "Dois passos atrás"]
		"exhaust":
			return ["Primeira investida", "Segunda investida", "Guarda baixa"]
		"chase":
			return ["Abre espaço", "Distância mantida" if spaced else "Seu atleta avança", "Rival parte primeiro" if spaced else "Contra-ataque"]
	return []

func pose_at(t: float, side: int) -> Dictionary:
	var state := {
		"move": 0.0, "duck": 0.0, "recoil": 0.0, "drop": 0.0,
		"guard": 0.0, "windup": 0.0, "strike": 0.0, "arm": 0,
		"style": "jab", "outcome": "", "step": 0.0,
	}
	for hit in strikes:
		var p := progress(t, hit)
		if p <= 0.0 or p >= 1.0:
			continue
		var reach := extension(p)
		if int(hit["actor"]) == side:
			state["strike"] = reach
			state["windup"] = sin(PI * smooth_span(p, 0.0, 0.27)) if p < 0.27 else 0.0
			state["arm"] = 0 if hit["style"] == "jab" else 1
			state["style"] = hit["style"]
			state["outcome"] = hit["outcome"]
			state["move"] = 0.30 * smooth_span(p, 0.04, 0.47) * (1.0 - smooth_span(p, 0.63, 1.0))
			state["step"] = p
		else:
			match hit["outcome"]:
				"land":
					state["recoil"] = smooth_span(p, CONTACT - 0.04, 0.62) * (1.0 - smooth_span(p, 0.65, 1.0))
					state["move"] -= float(state["recoil"]) * 0.17
				"block":
					state["guard"] = smooth_span(p, 0.22, 0.48) * (1.0 - smooth_span(p, 0.73, 0.98))
				"miss":
					state["duck"] = smooth_span(p, 0.24, 0.50) * (1.0 - smooth_span(p, 0.64, 1.0))
					state["move"] = -0.20 * reach
	if pattern == "retreat" and side == 1:
		var first := smooth_span(t, 0.53, 0.68)
		var second := smooth_span(t, 0.70, 0.87)
		state["move"] -= 0.43 * first + 0.48 * second
		if t >= 0.53:
			state["step"] = 1.0 - first * 0.5 - second * 0.5
	elif pattern == "exhaust" and side == 1:
		state["drop"] = smooth_span(t, 0.55, 0.72)
	elif pattern == "chase":
		var gap := smooth_span(t, 0.04, 0.31) * (1.0 - smooth_span(t, 0.53, 0.76))
		state["move"] += -0.48 * gap if side == 1 else (0.37 * gap if not spaced else -0.13 * gap)
	return state
