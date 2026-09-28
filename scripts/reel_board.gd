extends Control
var textures: Array[Texture2D] = []
var grid: Array = [[4,0,5],[1,5,4],[6,4,8],[5,3,0],[7,4,5]]
var target: Array = []
var spinning := false
var elapsed := 0.0
var duration := 2.0
var stopped := 0
var lines: Array = []
var wins: Array = []
var reduced := false
var pulse := 0.0
signal reel_stopped
signal finished
const LABELS = ["BONE", "BALL", "PAW", "BOWL", "DACHSHUND", "HUSKY", "GOLDEN", "DOGHOUSE", "WILD", "COLLAR", "BONUS"]
func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 11: textures.append(load("res://assets/symbols/%d.svg" % i))
func start(result: Array, fast: bool, reduce_motion: bool):
	target = result
	spinning = true
	elapsed = 0
	stopped = 0
	wins = []
	reduced = reduce_motion
	duration = 0.85 if fast or reduced else 1.9
func _process(delta: float):
	pulse += delta
	if spinning:
		elapsed += delta
		var count := clampi(int((elapsed / duration - 0.45) / 0.11), 0, 5)
		while stopped < count:
			grid[stopped] = target[stopped].duplicate()
			stopped += 1
			reel_stopped.emit()
		if elapsed >= duration:
			grid = target.duplicate(true)
			spinning = false
			finished.emit()
	queue_redraw()
func _draw():
	if textures.is_empty(): return
	var cw := size.x / 5.0
	var ch := size.y / 3.0
	for col in 5:
		for row in 3:
			var rect := Rect2(col*cw+5,row*ch+5,cw-10,ch-10)
			var style := StyleBoxFlat.new()
			style.bg_color = Color("fff7e3") if (col+row)%2==0 else Color("f3ecd8")
			style.set_corner_radius_all(14)
			draw_style_box(style,rect)
			var symbol: int = int(grid[col][row])
			var moving := spinning and col >= stopped
			if moving: symbol = (int(elapsed*18)+col*3+row*4)%11
			var offset := 0.0
			if moving and not reduced: offset = sin(elapsed*30+row)*12
			var highlight := false
			for win in wins:
				if col < win.count and int(lines[win.line][col]) == row: highlight = true
			if highlight:
				draw_rect(rect.grow(-2),Color("dd9c35"),false,4)
				if not reduced: offset = sin(pulse*8+col)*4
			draw_texture_rect(textures[symbol],Rect2(rect.position+Vector2(16,offset),Vector2(rect.size.x-32,rect.size.y-18)),false)
			draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+8,rect.end.y-6),LABELS[symbol],HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-16,14,Color("38515c"))
	var colors := [Color("eabd54"),Color("e59491"),Color("8ccccc"),Color("b7a6e5"),Color("f0b573")]
	for index in lines.size():
		var points := PackedVector2Array()
		for col in 5: points.append(Vector2((col+.5)*cw,(float(lines[index][col])+.5)*ch))
		var winning := false
		for w in wins:
			if w.line == index: winning = true
		var color: Color = colors[index]
		color.a = (0.65 + 0.25*sin(pulse*5)) if winning else 0.17
		draw_polyline(points,color,5 if winning else 2,true)
		draw_circle(Vector2(8,(float(lines[index][0])+.5)*ch+index*3),10,colors[index])
		draw_string(ThemeDB.fallback_font,Vector2(3,(float(lines[index][0])+.5)*ch+5+index*3),str(index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("263f47"))
