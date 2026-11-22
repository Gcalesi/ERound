extends Node

const DATA = preload("res://scripts/roster.gd")
const CAREER = preload("res://scripts/career.gd")
const MATCH = preload("res://scripts/match.gd")
const ARENA = preload("res://scripts/arena.gd")

const INK := Color("#111827")
const PANEL := Color("#161f31")
const PANEL_LIGHT := Color("#202d43")
const BORDER := Color("#374761")
const PAPER := Color("#faf2d8")
const MUTED := Color("#afbed2")
const GOLD := Color("#ffc462")
const GREEN := Color("#75dfbc")
const RED := Color("#ff827e")

var career = CAREER.new()
var fight: RefCounted
var arena: Node3D
var ui: Control
var theme := Theme.new()
var title_font := SystemFont.new()
var screen := ""
var last_phase := ""
var hud: VBoxContainer
var interaction: VBoxContainer
var clock_label: Label
var round_label: Label
var feed_label: Label
var score_label: Label
var read_button: Button
var time_button: Button
var stamina_bar: ProgressBar
var focus_bar: ProgressBar
var stress_bar: ProgressBar
var rival_bar: ProgressBar
var bell: AudioStreamPlayer
var towel_prompt := false

func _ready() -> void:
	arena = ARENA.new()
	add_child(arena)
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	title_font.font_names = PackedStringArray(["DejaVu Sans", "Arial", "sans-serif"])
	title_font.font_weight = 800
	var body_font := SystemFont.new()
	body_font.font_names = PackedStringArray(["DejaVu Sans", "Arial", "sans-serif"])
	theme.default_font = body_font
	theme.default_font_size = 16
	ui.theme = theme
	if DisplayServer.get_name() != "headless":
		bell = AudioStreamPlayer.new()
		bell.stream = bell_stream()
		add_child(bell)
	career.load_progress()
	show_menu()

func _process(delta: float) -> void:
	arena.update_pose(delta, fight)
	if screen != "fight":
		return
	if not towel_prompt:
		fight.step(delta)
	if fight.phase != last_phase:
		phase_changed()
	if screen == "fight":
		update_hud()

func _input(event: InputEvent) -> void:
	if screen != "fight" or towel_prompt or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_SPACE and fight.can_read():
		fight.read_fight()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_T and fight.can_request_time():
		fight.request_time()
		get_viewport().set_input_as_handled()

func play_bell() -> void:
	if bell != null:
		bell.play()

func bell_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples := PackedByteArray()
	samples.resize(22050 * 2)
	for i in range(22050):
		var t := float(i) / 22050.0
		var wave := (sin(t * TAU * 720.0) + 0.48 * sin(t * TAU * 1098.0) + 0.20 * sin(t * TAU * 1476.0)) * exp(-t * 6.5)
		samples.encode_s16(i * 2, int(wave * minf(1.0, t * 530.0) * 4800.0))
	stream.data = samples
	return stream

func sheet(color: Color, edge: Color, radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func clear_screen(next: String) -> void:
	clear_children(ui)
	screen = next
	arena.mode = "fight" if next == "fight" else "menu"
	if next != "fight":
		fight = null

func panel(parent: Node, color: Color = PANEL) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", sheet(color, BORDER))
	parent.add_child(frame)
	return frame

func box(parent: Node, spacing: int = 10) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", spacing)
	parent.add_child(container)
	return container

func row(parent: Node, spacing: int = 10) -> HBoxContainer:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", spacing)
	parent.add_child(container)
	return container

func label(parent: Node, words: String, size: int = 16, color: Color = PAPER, strong: bool = false) -> Label:
	var node := Label.new()
	node.text = words
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	if strong:
		node.add_theme_font_override("font", title_font)
	parent.add_child(node)
	return node

func paragraph(parent: Node, words: String, size: int = 16, color: Color = MUTED) -> Label:
	var node := label(parent, words, size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node

func button(parent: Node, words: String, callback: Callable, accent: bool = false) -> Button:
	var node := Button.new()
	node.text = words
	node.custom_minimum_size.y = 39
	node.add_theme_font_override("font", title_font)
	node.add_theme_font_size_override("font_size", 14)
	var normal := GOLD if accent else PANEL_LIGHT
	var foreground := INK if accent else PAPER
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(state, foreground)
	node.add_theme_color_override("font_disabled_color", Color("#8895a9"))
	node.add_theme_stylebox_override("normal", sheet(normal, GOLD if accent else BORDER, 7))
	node.add_theme_stylebox_override("hover", sheet(normal.lightened(0.14), GOLD if accent else MUTED, 7))
	node.add_theme_stylebox_override("pressed", sheet(normal.darkened(0.12), GOLD, 7))
	node.add_theme_stylebox_override("focus", sheet(Color.TRANSPARENT, PAPER, 7))
	node.add_theme_stylebox_override("disabled", sheet(INK, BORDER, 7))
	parent.add_child(node)
	node.pressed.connect(callback)
	return node

func tint(color: Color) -> void:
	var background := ColorRect.new()
	background.color = color
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(background)

func side_content(height_top: float = 46.0, width: float = 520.0) -> VBoxContainer:
	tint(Color(0.025, 0.04, 0.08, 0.26))
	var scroll := ScrollContainer.new()
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 30.0
	scroll.offset_right = 30.0 + width
	scroll.offset_top = height_top
	scroll.offset_bottom = -26.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(scroll)
	var frame := panel(scroll, Color(0.065, 0.094, 0.153, 0.97))
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return box(frame, 12)

func show_menu() -> void:
	clear_screen("menu")
	arena.cast(DATA.ATHLETES[0], DATA.RIVALS[0])
	var content := side_content(112, 475)
	label(content, "ACADEMIA  /  CARREIRA", 14, GOLD, true)
	label(content, "ERounds", 70, PAPER, true)
	label(content, "ENTRE ROUNDS", 22, GOLD, true)
	paragraph(content, "Treine um jovem boxeador e acompanhe sua carreira do lado de fora das cordas.", 19)
	if career.athlete_index >= 0 or not career.bouts.is_empty():
		button(content, "Continuar carreira", continue_career, true)
		button(content, "Começar outra carreira", show_restart)
	else:
		button(content, "Escolher boxeador", show_roster, true)

func show_restart() -> void:
	clear_screen("restart")
	var content := side_content(140, 475)
	label(content, "Outra carreira", 36, PAPER, true)
	paragraph(content, "Começar de novo substitui o progresso salvo neste computador.")
	button(content, "Começar do zero", reset_career, true)
	button(content, "Voltar", show_menu)

func reset_career() -> void:
	career.reset()
	show_roster()

func continue_career() -> void:
	if career.bouts.size() >= CAREER.MAX_BOUTS:
		show_final()
	elif career.athlete_index < 0:
		show_roster()
	else:
		show_camp()

func show_roster() -> void:
	clear_screen("roster")
	arena.cast(DATA.ATHLETES[0], DATA.ATHLETES[1])
	var content := side_content(26, 550)
	label(content, "ACADEMIA  /  RECRUTAMENTO", 13, GOLD, true)
	label(content, "Escolha seu atleta", 39, PAPER, true)
	if not career.status.is_empty():
		paragraph(content, career.status, 15, GOLD)
	for i in range(DATA.ATHLETES.size()):
		if career.unavailable.has(i):
			continue
		var athlete: Dictionary = DATA.ATHLETES[i]
		var card := box(panel(content, PANEL), 4)
		label(card, "%s  /  %d anos" % [athlete["name"], athlete["age"]], 20, athlete["shorts"].lightened(0.38), true)
		paragraph(card, athlete["profile"], 14, PAPER)
		paragraph(card, athlete["personality"], 13)
		var select := button(card, "Treinar " + athlete["name"], choose_athlete.bind(i))
		select.mouse_entered.connect(preview_athlete.bind(i))
		select.focus_entered.connect(preview_athlete.bind(i))
	button(content, "Menu inicial", show_menu)

func preview_athlete(index: int) -> void:
	arena.cast(DATA.ATHLETES[index], career.opponent())

func choose_athlete(index: int) -> void:
	career.recruit(index)
	show_camp()

func show_camp() -> void:
	clear_screen("camp")
	var athlete: Dictionary = career.athlete()
	var rival: Dictionary = career.opponent()
	arena.cast(athlete, rival)
	var content := side_content(23, 558)
	label(content, "ACADEMIA  /  LUTA %d DE %d" % [career.bouts.size() + 1, CAREER.MAX_BOUTS], 13, GOLD, true)
	label(content, "Preparar a semana", 37, PAPER, true)
	paragraph(content, "%s  ×  %s    •    %s" % [athlete["name"], rival["name"], rival["style"]], 17, PAPER)
	paragraph(content, "Vínculo %d   /   Técnica %d   /   Reputação %d" % [roundi(career.trust), career.level, career.reputation], 14, GOLD)
	paragraph(content, athlete["personality"], 14)
	if career.reputation >= 2:
		paragraph(content, "Olheiro • " + rival["clue"], 14, MUTED)
	if not career.status.is_empty():
		paragraph(content, career.status, 14, GREEN)
	option(content, "Treino da semana", DATA.TRAINING, career.trained_plan, "trained_plan")
	option(content, "Carga e descanso", DATA.RECOVERY, career.recovery, "recovery")
	option(content, "Alimentação", DATA.MEALS, career.meals, "meals")
	var controls := row(content)
	button(controls, "Entrar no ringue", start_fight, true)
	button(controls, "Menu", show_menu)

func option(parent: Node, heading: String, entries: Array, selected: String, property: String) -> void:
	var section := box(panel(parent, PANEL), 4)
	label(section, heading, 15, PAPER, true)
	var options := OptionButton.new()
	options.add_theme_stylebox_override("normal", sheet(PANEL_LIGHT, BORDER, 6))
	options.custom_minimum_size.y = 34
	var description := paragraph(section, "", 13)
	section.add_child(options)
	section.move_child(options, 1)
	for i in range(entries.size()):
		options.add_item(entries[i][1])
		if entries[i][0] == selected:
			options.select(i)
	description.text = entries[options.selected][2]
	options.item_selected.connect(func(index: int) -> void:
		career.set(property, entries[index][0])
		description.text = entries[index][2]
		career.save_progress()
	)

func start_fight() -> void:
	clear_screen("fight")
	fight = MATCH.new()
	fight.setup(career)
	towel_prompt = false
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(overlay)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header.anchor_right = 1.0
	header.offset_left = 22
	header.offset_right = -22
	header.offset_top = 18
	overlay.add_child(header)
	var home_card := panel(header, Color(0.07, 0.10, 0.16, 0.95))
	home_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var home_stats := box(home_card, 3)
	label(home_stats, fight.home["name"].to_upper(), 23, GOLD, true)
	stamina_bar = bar(home_stats, "Fôlego", GREEN)
	focus_bar = bar(home_stats, "Foco", GOLD)
	stress_bar = bar(home_stats, "Estresse", RED)
	var center := box(panel(header, Color(0.07, 0.10, 0.16, 0.95)), 3)
	center.custom_minimum_size.x = 164
	round_label = label(center, "", 13, GOLD, true)
	clock_label = label(center, "", 38, PAPER, true)
	score_label = label(center, "", 12, MUTED)
	for text_node in [round_label, clock_label, score_label]:
		text_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var away_card := panel(header, Color(0.07, 0.10, 0.16, 0.95))
	away_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var away_stats := box(away_card, 3)
	label(away_stats, fight.away["name"].to_upper(), 23, RED, true)
	rival_bar = bar(away_stats, "Fôlego", GREEN)
	label(away_stats, fight.away["style"], 13, MUTED)
	hud = VBoxContainer.new()
	hud.anchor_top = 1.0
	hud.anchor_bottom = 1.0
	hud.anchor_right = 1.0
	hud.offset_left = 22
	hud.offset_right = -22
	hud.offset_bottom = -18
	hud.offset_top = -114
	overlay.add_child(hud)
	var calls := box(panel(hud, Color(0.065, 0.094, 0.153, 0.98)), 6)
	feed_label = paragraph(calls, "", 16, PAPER)
	var tools := row(calls)
	read_button = button(tools, "Analisar [Espaço]", fight.read_fight, true)
	time_button = button(tools, "Pedir tempo [T]", fight.request_time)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools.add_child(spacer)
	button(tools, "Jogar a toalha", open_towel_prompt)
	var interaction_frame := PanelContainer.new()
	interaction_frame.add_theme_stylebox_override("panel", sheet(Color(0.065, 0.094, 0.153, 0.98), BORDER))
	interaction_frame.anchor_top = 1.0
	interaction_frame.anchor_bottom = 1.0
	interaction_frame.anchor_left = 0.5
	interaction_frame.anchor_right = 0.5
	interaction_frame.grow_horizontal = Control.GROW_DIRECTION_BOTH
	interaction_frame.grow_vertical = Control.GROW_DIRECTION_BEGIN
	interaction_frame.offset_left = -410
	interaction_frame.offset_right = 410
	interaction_frame.offset_top = -124
	interaction_frame.offset_bottom = -124
	overlay.add_child(interaction_frame)
	interaction = box(interaction_frame, 7)
	last_phase = "fight"
	refresh_interaction()
	update_hud()
	play_bell()

func bar(parent: Node, words: String, color: Color) -> ProgressBar:
	var line := row(parent, 8)
	var title := label(line, words, 12, MUTED)
	title.custom_minimum_size.x = 59
	var meter := ProgressBar.new()
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.custom_minimum_size = Vector2(70, 13)
	meter.show_percentage = false
	var track := sheet(Color("#303d54"), Color.TRANSPARENT, 4)
	var fill := sheet(color, Color.TRANSPARENT, 4)
	track.content_margin_top = 0
	track.content_margin_bottom = 0
	fill.content_margin_left = 0
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	meter.add_theme_stylebox_override("background", track)
	meter.add_theme_stylebox_override("fill", fill)
	line.add_child(meter)
	return meter

func update_hud() -> void:
	stamina_bar.value = fight.stamina
	focus_bar.value = fight.focus
	stress_bar.value = fight.stress
	rival_bar.value = fight.rival_stamina
	var seconds := ceili(fight.time_left)
	clock_label.text = "%d:%02d" % [seconds / 60, seconds % 60]
	round_label.text = "ROUND %d / %d" % [fight.round_number, MATCH.ROUND_COUNT]
	score_label.text = "PLACAR  %d–%d" % [fight.score.x, fight.score.y]
	feed_label.text = fight.line
	read_button.disabled = not fight.can_read() or towel_prompt
	time_button.disabled = not fight.can_request_time() or towel_prompt
	read_button.text = ("Analisar agora  ·  %d" if fight.can_read() else "Analisar [Espaço]  ·  %d") % fight.reads_left
	time_button.text = "Tempo solicitado" if fight.timeout_pending else "Pedir tempo [T]" if fight.timeout_left else "Tempo usado"

func phase_changed() -> void:
	var was := last_phase
	last_phase = fight.phase
	if last_phase == "result":
		play_bell()
		show_result()
		return
	if last_phase == "corner" or (last_phase == "fight" and was in ["corner", "timeout"]):
		play_bell()
	refresh_interaction()

func refresh_interaction() -> void:
	clear_children(interaction)
	var frame: PanelContainer = interaction.get_parent()
	frame.visible = fight.phase != "fight" or towel_prompt
	hud.visible = true
	if not frame.visible:
		return
	if towel_prompt:
		label(interaction, "Encerrar a luta?", 24, GOLD, true)
		paragraph(interaction, "Ao jogar a toalha, você aceita a derrota do seu córner.")
		var buttons := row(interaction)
		button(buttons, "Confirmar", func() -> void:
			towel_prompt = false
			fight.finish(true)
		, true)
		button(buttons, "Continuar assistindo", func() -> void:
			towel_prompt = false
			refresh_interaction()
		)
		return
	match fight.phase:
		"slow":
			label(interaction, "CÂMERA LENTA", 21, GOLD, true)
			paragraph(interaction, "Observe os passos e a guarda do adversário.")
		"read":
			label(interaction, "O que você viu?", 23, GOLD, true)
			paragraph(interaction, fight.street_clue, 15)
			var plans := row(interaction)
			for plan_key in DATA.PLANS:
				button(plans, DATA.PLANS[plan_key], fight.read_choice.bind(plan_key), plan_key == career.trained_plan)
			var alternatives := row(interaction)
			button(alternatives, "Guardar para o intervalo", fight.read_choice.bind("save"))
			button(alternatives, "Esperar outra troca", fight.read_choice.bind("wait"))
		"corner", "timeout":
			var title := "Intervalo entre rounds" if fight.phase == "corner" else "Tempo de córner"
			label(interaction, "%s  /  %d ações" % [title, fight.action_left], 23, GOLD, true)
			if fight.clue_saved:
				paragraph(interaction, fight.street_clue, 14)
			var care := row(interaction)
			corner_button(care, "Dar água", "water")
			corner_button(care, "Sentar e respirar", "breathe")
			corner_button(care, "Perguntar o que viu", "escuta")
			var plans := row(interaction)
			for plan_key in DATA.PLANS:
				corner_button(plans, DATA.PLANS[plan_key], plan_key)
			var talk := row(interaction)
			corner_button(talk, "Falar direto", "direto")
			corner_button(talk, "Lançar um desafio", "desafio")
			var other := row(interaction)
			button(other, "Voltar à luta", fight.resume, true)

func open_towel_prompt() -> void:
	if not towel_prompt:
		towel_prompt = true
		refresh_interaction()

func corner_button(parent: Node, words: String, action: String) -> void:
	var action_button := button(parent, words, func() -> void:
		fight.corner_action(action)
		refresh_interaction()
	)
	action_button.disabled = fight.action_left <= 0

func show_result() -> void:
	var result: Dictionary = fight.result
	var scorecard: Array[Vector2i] = fight.scorecard.duplicate()
	clear_screen("result")
	var content := side_content(51, 540)
	label(content, "SÚMULA  /  LUTA %d" % [career.bouts.size() + 1], 13, GOLD, true)
	label(content, result["title"], 30, PAPER, true)
	paragraph(content, "%s  ×  %s    /    %s" % [career.athlete()["name"], result["opponent"], result["score"]], 17, GOLD)
	for i in range(scorecard.size()):
		paragraph(content, "Round %d      %d–%d" % [i + 1, scorecard[i].x, scorecard[i].y], 14)
	paragraph(content, result["remark"], 17, PAPER)
	label(content, "O que você diz depois da luta?", 17, GOLD, true)
	button(content, "Quero ouvir como foi pra você", record_result.bind(result, "escuta"), true)
	button(content, "Vamos resumir o que aprendemos", record_result.bind(result, "resumo"))
	button(content, "Quero mais de você na próxima", record_result.bind(result, "cobrança"))

func record_result(result: Dictionary, tone: String) -> void:
	career.record(result, tone)
	continue_career()

func show_final() -> void:
	clear_screen("final")
	var leading: int = maxi(0, career.athlete_index)
	arena.cast(DATA.ATHLETES[leading], DATA.RIVALS[2])
	var content := side_content(95, 510)
	label(content, "ACADEMIA  /  BALANÇO", 13, GOLD, true)
	label(content, "Fim da temporada", 38, PAPER, true)
	paragraph(content, "Reputação da academia  %d" % career.reputation, 18, GOLD)
	for i in range(career.bouts.size()):
		var bout: Dictionary = career.bouts[i]
		var card := box(panel(content), 3)
		label(card, "%d   %s × %s" % [i + 1, bout["athlete"], bout["opponent"]], 17, PAPER, true)
		paragraph(card, "%s   /   %s" % [bout["outcome"], bout["score"]], 14)
	button(content, "Menu inicial", show_menu, true)
