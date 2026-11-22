extends RefCounted

const ATHLETES := [
	{
		"id": "caio", "name": "Caio", "age": 19, "shape": Vector3(0.86, 1.10, 0.91),
		"shorts": Color("#365cff"), "gloves": Color("#fc6245"), "skin": Color("#cc8d65"), "hair": Color("#211a27"),
		"style": "Alcance longo", "profile": "Controla a distância. Sob pressão, tende a ceder espaço.",
		"personality": "Prefere instruções curtas e claras.", "tone": "direto",
		"pace": 0.53, "stamina": 88.0, "focus": 80.0, "plan": "distance",
	},
	{
		"id": "lia", "name": "Lia", "age": 20, "shape": Vector3(1.03, 0.90, 1.00),
		"shorts": Color("#ffb939"), "gloves": Color("#d63260"), "skin": Color("#97573e"), "hair": Color("#261823"),
		"style": "Pressão explosiva", "profile": "Toma a iniciativa cedo. Pode gastar o fôlego antes da hora.",
		"personality": "Gosta de desafios quando ainda está confiante.", "tone": "desafio",
		"pace": 0.80, "stamina": 80.0, "focus": 78.0, "plan": "center",
	},
	{
		"id": "bento", "name": "Bento", "age": 18, "shape": Vector3(0.90, 1.00, 0.84),
		"shorts": Color("#39c19b"), "gloves": Color("#d252f4"), "skin": Color("#dfab86"), "hair": Color("#48302a"),
		"style": "Mobilidade", "profile": "Tem boa resistência. Demora a tomar a iniciativa.",
		"personality": "Se envolve mais quando ajuda a escolher o plano.", "tone": "escuta",
		"pace": 0.47, "stamina": 96.0, "focus": 75.0, "plan": "pace",
	},
]

const RIVALS := [
	{
		"id": "nico", "name": "Nico", "shape": Vector3(1.03, 0.98, 1.00),
		"shorts": Color("#bb3151"), "gloves": Color("#f6edcc"), "skin": Color("#c7815d"), "hair": Color("#2c1c34"),
		"style": "Pressão frontal", "stamina": 94.0, "focus": 80.0, "pace": 0.73,
		"pattern": "retreat", "clue": "Quando erra um avanço, Nico dá dois passos para trás e cede o centro.",
	},
	{
		"id": "mara", "name": "Mara", "shape": Vector3(0.82, 1.10, 0.93),
		"shorts": Color("#9144bc"), "gloves": Color("#ffc351"), "skin": Color("#a87556"), "hair": Color("#24282e"),
		"style": "Ritmo forte", "stamina": 82.0, "focus": 91.0, "pace": 0.91,
		"pattern": "exhaust", "clue": "Mara volta a avançar antes de recuperar o fôlego. Os intervalos entre as investidas estão aumentando.",
	},
	{
		"id": "davi", "name": "Davi", "shape": Vector3(1.13, 1.05, 1.06),
		"shorts": Color("#e76f38"), "gloves": Color("#171b2a"), "skin": Color("#83523a"), "hair": Color("#1b2027"),
		"style": "Espera e reage", "stamina": 100.0, "focus": 88.0, "pace": 0.65,
		"pattern": "chase", "clue": "Davi atrai quem vai atrás dele. Quando seu atleta mantém a distância, Davi precisa tomar a iniciativa.",
	},
]

const PLANS := {
	"center": "Segurar o centro",
	"pace": "Dosar o ritmo",
	"distance": "Manter a distância",
}

const ANSWERS := {"retreat": "center", "exhaust": "pace", "chase": "distance"}

const TRAINING := [
	["center", "Controle do ringue", "Pratica disputar o centro."],
	["pace", "Mudanças de ritmo", "Pratica alternar intensidade e recuperação."],
	["distance", "Movimentação", "Pratica manter a distância."],
]

const RECOVERY := [
	["load", "Semana intensa", "Melhora a técnica, com mais cansaço no início da luta."],
	["balanced", "Semana equilibrada", "Distribui treino, refeições e descanso."],
	["rest", "Priorizar recuperação", "Mais fôlego inicial e menos ganho técnico."],
]

const MEALS := [
	["regular", "Rotina regular", "Ajuda a começar focado."],
	["energy", "Energia para a luta", "Aumenta o fôlego inicial."],
	["routine", "Refeições com o atleta", "Abre espaço para conversar e fortalece o vínculo."],
]
