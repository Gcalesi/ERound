extends RefCounted

const DATA = preload("res://scripts/roster.gd")
const SAVE_PATH := "user://erounds-carreira.json"
const MAX_BOUTS := 3

var athlete_index := -1
var bouts: Array = []
var former_index := -1
var former_plan := ""
var unavailable: Array = []
var trust := 58.0
var level := 0
var reputation := 0
var trained_plan := "center"
var recovery := "balanced"
var meals := "regular"
var status := ""

func athlete() -> Dictionary:
	return DATA.ATHLETES[athlete_index]

func opponent() -> Dictionary:
	if bouts.size() >= 2 and former_index >= 0:
		var rival: Dictionary = DATA.ATHLETES[former_index].duplicate()
		var patterns := {"center": "exhaust", "pace": "chase", "distance": "retreat"}
		rival["style"] = "Ex-aluno • " + DATA.PLANS.get(former_plan, "Plano próprio")
		rival["pattern"] = patterns.get(former_plan, "chase")
		rival["clue"] = "%s mudou o jeito de lutar desde que saiu da sua academia. Leia o ritmo atual antes de orientar." % rival["name"]
		rival["stamina"] = 100.0
		rival["focus"] = 91.0
		return rival
	return DATA.RIVALS[mini(bouts.size(), DATA.RIVALS.size() - 1)]

func recruit(index: int) -> void:
	if unavailable.has(index):
		return
	athlete_index = index
	trust = 58.0
	level = 0
	trained_plan = athlete()["plan"]
	recovery = "balanced"
	meals = "regular"
	status = ""
	save_progress()

func record(result: Dictionary, response: String) -> void:
	var current: Dictionary = athlete()
	bouts.append({
		"athlete": current["name"], "opponent": result["opponent"],
		"outcome": result["title"], "score": result["score"],
	})
	trust = clampf(trust + float(result["trust_delta"]), 0.0, 100.0)
	level += 2 if recovery == "load" else 1
	reputation += 2 if result["win"] else 1
	match response:
		"escuta":
			trust = minf(100.0, trust + 10.0)
			status = "Vocês conversaram sobre a luta antes de planejar a próxima."
		"resumo":
			trust = minf(100.0, trust + 4.0)
			status = "Vocês saíram com um ponto concreto para treinar."
		"cobrança":
			trust = clampf(trust + (6.0 if current["tone"] == "desafio" and result["stress"] < 55 else -14.0), 0.0, 100.0)
			status = "Você cobrou uma resposta para a próxima luta."
	if trust < 40.0 and bouts.size() < MAX_BOUTS:
		if not result["win"] and trust < 26.0:
			status = "%s decidiu dar uma pausa na carreira. A academia precisa de outro atleta." % current["name"]
		else:
			former_index = athlete_index
			former_plan = trained_plan
			status = "%s decidiu treinar em outra academia. Vocês ainda podem se reencontrar." % current["name"]
		unavailable.append(athlete_index)
		athlete_index = -1
	elif trust < 52.0:
		status = "%s quer conversar sobre como vocês estão trabalhando juntos." % current["name"]
	save_progress()

func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"athlete": athlete_index, "bouts": bouts, "former": former_index,
		"former_plan": former_plan, "trust": trust, "level": level,
		"reputation": reputation, "training": trained_plan, "recovery": recovery,
		"meals": meals, "status": status, "unavailable": unavailable
	}))

func load_progress() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or not data.get("bouts") is Array:
		return false
	athlete_index = clampi(int(data.get("athlete", -1)), -1, DATA.ATHLETES.size() - 1)
	bouts = data["bouts"]
	former_index = clampi(int(data.get("former", -1)), -1, DATA.ATHLETES.size() - 1)
	former_plan = str(data.get("former_plan", ""))
	unavailable.clear()
	for index in data.get("unavailable", []):
		unavailable.append(int(index))
	trust = clampf(float(data.get("trust", 58)), 0.0, 100.0)
	level = maxi(int(data.get("level", 0)), 0)
	reputation = maxi(int(data.get("reputation", 0)), 0)
	trained_plan = str(data.get("training", "center"))
	recovery = str(data.get("recovery", "balanced"))
	meals = str(data.get("meals", "regular"))
	status = str(data.get("status", ""))
	return true

func reset() -> void:
	athlete_index = -1
	bouts.clear()
	former_index = -1
	former_plan = ""
	unavailable.clear()
	trust = 58.0
	level = 0
	reputation = 0
	status = ""
	save_progress()
