extends Control
var age := 10.0
var tier := 0
var reduced := false
var particles := true
var dach: Texture2D = preload("res://assets/symbols/4.svg")
var husky: Texture2D = preload("res://assets/symbols/5.svg")
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	z_index=5
func celebrate(ratio: float, jackpot: bool, reduce_motion: bool, reduce_particles: bool):
	age=0
	tier=4 if jackpot else (3 if ratio>=50 else (2 if ratio>=15 else (1 if ratio>=5 else 0)))
	reduced=reduce_motion
	particles=not reduce_particles
func _process(delta: float):
	age+=delta
	queue_redraw()
func _draw():
	if age>2.0 or tier==0 or reduced: return
	var alpha:=clampf(2.0-age,0,1)
	if tier>=2:
		var x:=lerpf(-260,1280,age/2.0)
		draw_texture_rect(dach,Rect2(x,526+sin(age*20)*6,240+sin(age*4)*30,130),false,Color(1,1,1,alpha))
	if tier>=3: draw_texture_rect(husky,Rect2(1015,420+sin(age*10)*7,220,180),false,Color(1,1,1,alpha))
	if particles:
		for i in 22+tier*6:
			var p:=Vector2(240+fmod(i*91.0,800),230+fmod(age*100+i*37,350))
			var color:=Color(.85,.93,1,alpha*.8) if i%2 else Color(1,.83,.40,alpha*.8)
			draw_line(p-Vector2(4,0),p+Vector2(4,0),color,2)
			draw_line(p-Vector2(0,4),p+Vector2(0,4),color,2)
