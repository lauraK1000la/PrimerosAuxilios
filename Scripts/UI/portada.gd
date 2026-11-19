class_name Portada
extends Node2D
# Pantalla de portada (titulo) del juego.
# Igual que ui_juego.gd, todo se arma por codigo para que sea facil de cambiar.
# Resolucion 256x176. Al pulsar ESPACIO / E / clic / ENTER pasa a scene_game.

const ANCHO := 256
const ALTO := 176
const TILE := 16
const ESCENA_JUEGO := "res://Scenes/World/scene_game.tscn"

# Indices de colegio_tiles.png (fila unica de 7 tiles de 16x16)
const T_PASTO := 0
const T_FLORES := 1
const T_ARBOL := 2
const T_TIERRA := 3
const T_ANDEN := 4
const T_LADRILLO := 5

const TEX_TILES := preload("res://Assets/Tiles/colegio_tiles.png")
const TEX_TITULO := preload("res://Assets/UI/portada_titulo.png")
const TEX_BRIGADISTA := preload("res://Assets/Characters/brigadista.png")
const TEX_EFECTOS := preload("res://Assets/Effects/efectos.png")
const PACIENTES := [
	preload("res://Assets/Pacientes/ciclista.png"),
	preload("res://Assets/Pacientes/corte.png"),
	preload("res://Assets/Pacientes/quemadura.png"),
	preload("res://Assets/Pacientes/atragantado.png"),
]
const SFX_INICIO := preload("res://Assets/Audio/sfx_correcto.wav")
const MUSICA := preload("res://Assets/Audio/musica_exploracion.wav")

# Mapa del fondo: 16 columnas x 11 filas
#  L = ladrillo (colegio), A = anden, . = pasto, f = flores, T = arbol, = = camino
const MAPA := [
	"LLLLLLLLLLLLLLLL",
	"LLLLLLLLLLLLLLLL",
	"AAAAAAAAAAAAAAAA",
	"T.f..........f.T",
	"T..............T",
	".f............f.",
	"T..............T",
	"..f..........f..",
	"================",
	".f...f....f...f.",
	"T.....f..f.....T",
]

var iniciando: bool = false
var tiempo: float = 0.0

var brigadista: Sprite2D
var pacientes: Array[Sprite2D] = []
var iconos: Array[Sprite2D] = []
var lbl_presiona: Label
var cortina: ColorRect
var musica: AudioStreamPlayer
var sfx: AudioStreamPlayer


func _ready() -> void:
	_crear_titulo()
	_crear_personajes()
	_crear_textos()
	_crear_audio()

	# Entrada con fundido desde negro
	cortina = ColorRect.new()
	cortina.color = Color.BLACK
	cortina.size = Vector2(ANCHO, ALTO)
	cortina.z_index = 100
	add_child(cortina)
	create_tween().tween_property(cortina, "modulate:a", 0.0, 0.6)


# ---------- Fondo (patio del colegio) ----------
func _draw() -> void:
	var codigos := {"L": T_LADRILLO, "A": T_ANDEN, ".": T_PASTO, "f": T_FLORES, "T": T_ARBOL, "=": T_TIERRA}
	for fila in MAPA.size():
		var linea: String = MAPA[fila]
		for col in linea.length():
			var id: int = codigos[linea[col]]
			# Los arboles se dibujan sobre pasto
			if id == T_ARBOL:
				_tile(T_PASTO, col, fila)
			_tile(id, col, fila)

	# Puerta del colegio con cruz roja (enfermeria)
	draw_rect(Rect2(116, 6, 24, 26), Color(0.08, 0.07, 0.13))
	draw_rect(Rect2(118, 8, 20, 24), Color(0.93, 0.9, 0.82))
	draw_rect(Rect2(126, 11, 4, 12), Color(0.84, 0.16, 0.19))
	draw_rect(Rect2(122, 15, 12, 4), Color(0.84, 0.16, 0.19))

	# Panel oscuro detras del titulo
	var panel := Rect2(46, 34, 164, 74)
	draw_rect(panel.grow(1), Color(0.08, 0.07, 0.13))
	draw_rect(panel, Color(0.05, 0.08, 0.18, 0.92))
	draw_rect(panel.grow(-2), Color(1.0, 0.85, 0.3), false, 1.0)

	# Franja inferior para el texto "Presiona..."
	draw_rect(Rect2(0, 150, ANCHO, 18), Color(0, 0, 0, 0.55))


func _tile(id: int, col: int, fila: int) -> void:
	draw_texture_rect_region(TEX_TILES, Rect2(col * TILE, fila * TILE, TILE, TILE), Rect2(id * TILE, 0, TILE, TILE))


# ---------- Logo ----------
func _crear_titulo() -> void:
	var titulo := Sprite2D.new()
	titulo.texture = TEX_TITULO
	titulo.centered = false
	titulo.position = Vector2(roundi((ANCHO - TEX_TITULO.get_width()) / 2.0), 39)
	add_child(titulo)


# ---------- Brigadista, pacientes e iconos ----------
func _crear_personajes() -> void:
	# Brigadista al centro, el doble de grande
	brigadista = Sprite2D.new()
	brigadista.texture = TEX_BRIGADISTA
	brigadista.hframes = 3
	brigadista.vframes = 4
	brigadista.frame = 0
	brigadista.scale = Vector2(2, 2)
	brigadista.position = Vector2(128, 128)
	add_child(brigadista)

	# Pacientes a los lados del camino
	var xs := [28, 60, 196, 228]
	for i in PACIENTES.size():
		var p := Sprite2D.new()
		p.texture = PACIENTES[i]
		p.hframes = 4
		p.frame = 0
		p.position = Vector2(xs[i], 136)
		p.flip_h = xs[i] > 128 # miran hacia el brigadista
		add_child(p)
		pacientes.append(p)

	# Iconos flotando: botiquin, telefono (avisar) y cono (proteger)
	var datos := [[2, Vector2(96, 124)], [1, Vector2(160, 124)], [0, Vector2(12, 120)], [0, Vector2(244, 120)]]
	for d in datos:
		var ic := Sprite2D.new()
		ic.texture = TEX_EFECTOS
		ic.hframes = 7
		ic.frame = d[0]
		ic.position = d[1]
		add_child(ic)
		iconos.append(ic)


# ---------- Textos ----------
func _crear_textos() -> void:
	var lema := _label("Proteger · Avisar · Socorrer", 8, Color(1.0, 0.85, 0.3))
	lema.position = Vector2(46, 93)
	lema.size = Vector2(164, 12)
	add_child(lema)

	lbl_presiona = _label("Presiona ESPACIO para comenzar", 8, Color.WHITE)
	lbl_presiona.position = Vector2(0, 152)
	lbl_presiona.size = Vector2(ANCHO, 14)
	add_child(lbl_presiona)

	var nota := _label("Juego educativo de primeros auxilios", 6, Color(0.85, 0.95, 1.0))
	nota.position = Vector2(0, 166)
	nota.size = Vector2(ANCHO, 10)
	add_child(nota)


func _label(texto: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.13))
	l.add_theme_constant_override("outline_size", 3)
	return l


func _crear_audio() -> void:
	musica = AudioStreamPlayer.new()
	musica.stream = MUSICA
	musica.volume_db = -6.0
	add_child(musica)
	musica.finished.connect(musica.play)
	musica.play()

	sfx = AudioStreamPlayer.new()
	sfx.stream = SFX_INICIO
	add_child(sfx)


# ---------- Animacion ----------
func _process(delta: float) -> void:
	tiempo += delta

	# El brigadista "camina" en su lugar y salta un poquito
	brigadista.frame = int(tiempo * 4.0) % 2
	brigadista.position.y = 128 - absf(sin(tiempo * 4.0)) * 2.0

	# Los pacientes alternan sus dos primeros cuadros
	for i in pacientes.size():
		pacientes[i].frame = int(tiempo * 2.0 + i) % 2

	# Iconos flotando
	for i in iconos.size():
		iconos[i].offset.y = roundf(sin(tiempo * 3.0 + i * 1.3) * 2.0)

	# Texto parpadeante (mas rapido al iniciar)
	var vel := 12.0 if iniciando else 3.0
	lbl_presiona.visible = sin(tiempo * vel) > -0.3


# ---------- Entrada ----------
func _unhandled_input(event: InputEvent) -> void:
	if iniciando:
		return
	var tecla := event as InputEventKey
	var es_enter := tecla != null and tecla.pressed and not tecla.echo and (tecla.keycode == KEY_ENTER or tecla.keycode == KEY_KP_ENTER)
	if event.is_action_pressed("AYUDAR") or es_enter:
		_comenzar()


func _comenzar() -> void:
	iniciando = true
	sfx.play()
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(cortina, "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(musica, "volume_db", -40.0, 0.5)
	await tw.finished
	get_tree().change_scene_to_file(ESCENA_JUEGO)
