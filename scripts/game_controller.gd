extends Control
const EngineClass = preload("res://scripts/slot_machine.gd")
const SaveClass = preload("res://scripts/save_manager.gd")
const Progression = preload("res://scripts/progression.gd")
const BoardClass = preload("res://scripts/reel_board.gd")
const AudioClass = preload("res://scripts/audio_manager.gd")
var engine := EngineClass.new()
var saver := SaveClass.new()
var progression := Progression.new()
var state: Dictionary
var board: Control
var audio: Node
var balance: Label
var jackpot_label: Label
var message: Label
var detail: Label
var free_label: Label
var spin_button: Button
var auto_button: Button
var speed_button: Button
var bet_buttons: Array[Button] = []
var refill_button: Button
var modal: Control
var modal_body: VBoxContainer
var busy := false
var auto_left := 0
var run_free := true
var epoch := 0
var displayed_credits := 100.0
var session_wagered := 0.0
var session_won := 0.0
var forced: Dictionary = {}
var developer := false
var time := 0.0
var companion: Texture2D
var hud_buttons: Array[Button] = []
var result: Dictionary = {}
var celebration: Control
var compact_touch := false
var keyboard_hint: Label

func _ready():
	developer = OS.is_debug_build() and "--developer" in OS.get_cmdline_user_args()
	if developer: saver.path = "user://puppy-debug-save.json"
	state = saver.load_state()
	displayed_credits = state.credits
	developer = OS.is_debug_build() and "--developer" in OS.get_cmdline_user_args()
	audio = AudioClass.new()
	add_child(audio)
	build_ui()
	celebration = preload("res://scripts/celebration.gd").new()
	add_child(celebration)
	refresh()
	get_tree().auto_accept_quit = false

func panel(rect: Rect2, color: Color, radius: int = 24) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	node.add_theme_stylebox_override("panel",style)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func text_label(value: String, rect: Rect2, font_size: int = 24, color: Color = Color("f9f3dd")) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func style_button(b: Button, gold: bool = false):
	b.add_theme_font_size_override("font_size",22)
	b.add_theme_color_override("font_color",Color("263d46"))
	b.add_theme_color_override("font_hover_color",Color("263d46"))
	b.add_theme_color_override("font_focus_color",Color("263d46"))
	b.add_theme_color_override("font_pressed_color",Color("263d46"))
	for type in ["normal","hover","pressed","disabled","focus"]:
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(14)
		style.content_margin_left = 15
		style.content_margin_right = 15
		style.bg_color = Color("eac46c") if gold else Color("e5eee2")
		if type == "hover": style.bg_color = style.bg_color.lightened(.13)
		if type == "pressed": style.bg_color = Color("9fc9b9")
		if type == "disabled": style.bg_color = Color("7f9690")
		if type == "focus":
			style.bg_color = Color(0,0,0,0)
			style.border_color = Color("fff4b4")
			style.set_border_width_all(4)
		b.add_theme_stylebox_override(type,style)
	b.custom_minimum_size.y = 88 if get_window().size.y < 600 else 50

func button(value: String, rect: Rect2, action: Callable, gold: bool = false) -> Button:
	var b := Button.new()
	b.text = value
	b.position = rect.position
	b.size = rect.size
	style_button(b,gold)
	b.pressed.connect(func():
		audio.interact(state)
		audio.play_sound("click")
		action.call())
	add_child(b)
	return b

func build_ui():
	text_label("THE GOOD DOG SOCIAL CLUB",Rect2(290,15,700,30),17,Color("d8dab2"))
	text_label("Dachshunds & Huskies",Rect2(230,48,820,60),44)
	text_label("S L O T S   •   A LITTLE LUCK, A LOT OF LOVE",Rect2(300,105,680,26),16,Color("ccd9c7"))
	button("Settings",Rect2(1080,36,155,52),show_settings)
	button("Free Biscuits",Rect2(32,36,185,52),refill)
	panel(Rect2(400,145,480,66),Color("2a4648"),20)
	jackpot_label = text_label("",Rect2(400,150,480,52),26,Color("f2d58b"))
	panel(Rect2(207,226,866,350),Color("172e36"),25)
	board = BoardClass.new()
	board.position = Vector2(220,239)
	board.size = Vector2(840,324)
	add_child(board)
	board.reel_stopped.connect(func(): audio.play_sound("stop"))
	text_label("YOUR BISCUITS",Rect2(18,178,180,26),15,Color("d4dec4"))
	balance = text_label("100.00",Rect2(8,205,200,56),34)
	text_label("Always free.\nAlways yours.",Rect2(27,477,160,65),18,Color("dce6d8"))
	text_label("YOUR COMPANION",Rect2(1084,180,180,30),14,Color("d4dec4"))
	button("Collection",Rect2(1084,475,166,52),show_collection)
	free_label = text_label("",Rect2(255,574,770,36),21,Color("f4da8e"))
	message = text_label("A little luck. A lot of tail wags.",Rect2(200,610,880,38),27)
	detail = text_label("Fictional credits • no ads • no purchases • no waiting",Rect2(170,651,940,28),17,Color("d4dec4"))
	text_label("WAGER",Rect2(28,678,385,20),17)
	for bet in range(1,5):
		var b := button(str(bet),Rect2(28+(bet-1)*99,701,88,62),func(): select_bet(bet))
		bet_buttons.append(b)
	spin_button = button("SPIN  •  SPACE",Rect2(466,694,335,62),spin,true)
	auto_button = button("AUTO",Rect2(818,697,135,55),show_auto)
	button("STOP",Rect2(968,697,125,55),stop_auto)
	speed_button = button("Fast",Rect2(1108,697,130,55),func():
		state.fast = not state.fast
		refresh();saver.save_state(state))
	button("Odds & Math",Rect2(29,580,175,52),show_odds)
	button("Statistics",Rect2(1084,580,166,52),show_stats)
	keyboard_hint = text_label("1–4 wager   /   A auto   /   S stop   /   P odds   /   C collection   /   ESC settings",Rect2(200,761,880,25),15,Color("cfdbc9"))
	if developer: button("DEV",Rect2(1115,105,100,50),show_debug)
	refill_button = button("Out of biscuits!  Refill to 100",Rect2(365,610,550,65),refill,true)
	refill_button.visible = false
	spin_button.grab_focus()

func _process(delta: float):
	time += delta
	var small := get_window().size.y < 600
	if small != compact_touch:
		compact_touch = small
		for child in get_children():
			if child is Button:
				if not child.has_meta("original_height"): child.set_meta("original_height",child.size.y)
				child.size.y = maxf(88,child.get_meta("original_height")) if small else child.get_meta("original_height")
		keyboard_hint.visible = not small
	queue_redraw()

func _draw():
	var snow: bool = state.get("theme",0) == 1
	draw_rect(Rect2(Vector2.ZERO,Vector2(1280,800)),Color("1b3549") if snow else Color("254c43"))
	if snow:
		for i in 5:
			var x: float = i*300-100
			draw_colored_polygon(PackedVector2Array([Vector2(x,520),Vector2(x+190,100+i%2*90),Vector2(x+410,520)]),Color("375568"))
			draw_colored_polygon(PackedVector2Array([Vector2(x+132,228+i%2*60),Vector2(x+190,100+i%2*90),Vector2(x+257,238+i%2*60)]),Color("b8d7dd"))
		for i in 3:
			var points := PackedVector2Array()
			for x in range(0,1281,30): points.append(Vector2(x,130+i*22+sin(x*.005+time*.15+i)*60))
			draw_polyline(points,Color(.35,.8,.72,.08),26,true)
	else:
		draw_circle(Vector2(1100,102),65,Color("e3c880"))
		for i in 7: draw_circle(Vector2(i*230,690+i%2*55),220,Color("39604b"))
	draw_rect(Rect2(0,683,1280,117),Color("183a3a") if not snow else Color("172e42"))
	if not state.get("reduce_particles",false):
		for i in 28:
			var x: float = fmod(i*197.0+sin(time*.4+i)*8,1280)
			var y: float = fmod(i*113.0+(time*12 if snow else 0),680)
			if snow: draw_circle(Vector2(x,y),2,Color(.85,.95,1,.5))
			elif y > 450:
				draw_circle(Vector2(x,y),5,Color("d4ab82"))
				draw_circle(Vector2(x,y),2,Color("f7e3a6"))
	var bounce := 0.0 if state.get("reduce_motion",false) else sin(time*2)*4
	var dach: Texture2D = load("res://assets/symbols/4.svg")
	var husky: Texture2D = load("res://assets/symbols/5.svg")
	draw_texture_rect(dach,Rect2(4,285+bounce,200,170),false)
	if not state.get("reduce_motion",false):
		draw_line(Vector2(44,395+bounce),Vector2(19+sin(time*9)*9,362+bounce),Color("b87040"),9,true)
	draw_texture_rect(companion if companion else husky,Rect2(1078,285-bounce,200,170),false)
	draw_accessory(state.get("dog",""),bounce)
	if state.get("dog","") in Progression.DOGS.slice(8):
		draw_string(ThemeDB.fallback_font,Vector2(1090,463),state.dog,HORIZONTAL_ALIGNMENT_CENTER,175,18,Color("f5d992"))

func draw_accessory(item: String, bounce: float):
	var p:=Vector2(1222,378-bounce)
	match item:
		"Red collar", "Blue collar", "Winter scarf", "Bandana":
			var c:=Color("e87c79") if item=="Red collar" else Color("71bdde")
			draw_line(p+Vector2(-24,20),p+Vector2(0,25),c,12)
			if item in ["Winter scarf","Bandana"]: draw_colored_polygon(PackedVector2Array([p+Vector2(-10,20),p+Vector2(15,22),p+Vector2(4,58)]),c)
		"Bow tie":
			draw_colored_polygon(PackedVector2Array([p+Vector2(-25,15),p+Vector2(10,36),p+Vector2(10,15),p+Vector2(-25,36)]),Color("edb2c7"))
		"Sunglasses":
			draw_rect(Rect2(p+Vector2(-13,-27),Vector2(15,12)),Color("253444"))
			draw_rect(Rect2(p+Vector2(8,-27),Vector2(15,12)),Color("253444"))
			draw_line(p+Vector2(-8,-24),p+Vector2(19,-24),Color("253444"),4)
		"Cowboy hat":
			draw_rect(Rect2(p+Vector2(-25,-60),Vector2(45,30)),Color("c5995f"))
			draw_line(p+Vector2(-42,-32),p+Vector2(33,-32),Color("e0b571"),10)
		"Flower crown":
			for i in 5:
				var f:=p+Vector2(-23+i*10,-43+abs(i-2)*2)
				draw_circle(f,7,Color("f1aac3"));draw_circle(f,3,Color("f9db7b"))

func refresh():
	balance.text = "%.2f" % displayed_credits
	jackpot_label.text = "COLLAR JACKPOT   •   %.2f" % state.jackpot
	board.lines = engine.active_lines(int(state.bet))
	board.reduced = state.reduce_motion
	for i in 4:
		bet_buttons[i].text = ("[%d]" if state.bet == i+1 else "%d") % (i+1)
		bet_buttons[i].disabled = busy or not state.queue.is_empty()
	spin_button.disabled = busy
	spin_button.text = "FREE SPIN" if not state.queue.is_empty() else "SPIN  •  SPACE"
	free_label.text = "FREE SPINS: %d REMAINING" % state.queue.size() if not state.queue.is_empty() else ("MAX BET • 5 lines + 1.5% line payout bonus" if state.bet == 4 else "%d ACTIVE PAYLINE%s" % [state.bet,"" if state.bet==1 else "S"])
	speed_button.text = "Fast" if state.fast else "Normal"
	auto_button.text = "AUTO: ∞" if auto_left < 0 else ("AUTO: %d" % auto_left if auto_left > 0 else "AUTO")
	refill_button.visible = not busy and state.queue.is_empty() and state.credits < state.bet
	var index: int = Progression.DOGS.find(state.dog)
	companion = load("res://assets/symbols/%s.svg" % ("dog%d" % index if index >= 2 and index < 8 else ("4" if index == 0 else "5")))
	audio.apply(state,not state.queue.is_empty())

func select_bet(bet: int):
	if busy or not state.queue.is_empty(): return
	state.bet = bet
	refresh();saver.save_state(state)

func refill():
	if busy: return
	stop_auto()
	if engine.refill(state):
		displayed_credits = state.credits
		message.text = "Fresh biscuits! Your bowl is back to 100."
	else: message.text = "Your bowl already has 100 biscuits or more."
	saver.save_state(state);refresh()

func spin():
	if busy or is_instance_valid(modal): return
	audio.interact(state)
	result = engine.spin(state,int(state.bet),forced if developer else {})
	forced = {}
	if result.has("error"):
		stop_auto();refresh();return
	busy = true
	run_free = true
	if not result.free:
		session_wagered += result.bet
		if auto_left > 0: auto_left -= 1
	session_won += result.award
	var earned := progression.update(state,result)
	# Commit immediately: closing a tab cannot refund a losing spin or replay a jackpot.
	saver.save_state(state)
	displayed_credits = state.credits-result.award
	message.text = "The dogs are fetching your result…"
	detail.text = "Result drawn before animation • every spin uses the same symbol odds"
	refresh()
	board.lines = engine.active_lines(int(result.bet))
	if not result.free and not state.reduce_motion:
		var growth := create_tween()
		jackpot_label.pivot_offset = jackpot_label.size/2
		growth.tween_property(jackpot_label,"scale",Vector2(1.02,1.02),.15)
		growth.tween_property(jackpot_label,"scale",Vector2.ONE,.2)
	audio.play_sound("spin")
	board.start(result.grid,state.fast,state.reduce_motion)
	await board.finished
	board.wins = result.wins
	var ratio: float = result.award/result.bet
	celebration.celebrate(ratio,result.jackpot,state.reduce_motion,state.reduce_particles)
	var tier := "Good dogs!"
	if ratio >= 50: tier = "PUPPY PARTY!"
	elif ratio >= 15: tier = "HUGE WIN!"
	elif ratio >= 5: tier = "BIG WIN!"
	if result.jackpot: tier = "JACKPOT! Both dogs celebrate!"
	message.text = "%s  +%.2f biscuits" % [tier,result.award] if result.award>0 else "A tail wag for the next spin."
	if result.award>0:
		audio.play_sound("jackpot" if result.jackpot else ("big" if ratio>=15 else ("medium" if ratio>=5 else "small")))
		for w in result.wins:
			if w.symbol == 4: audio.play_sound("bark")
			if w.symbol == 5: audio.play_sound("howl")
		if result.jackpot:
			audio.play_sound("howl");audio.play_sound("bark")
		if not state.reduce_motion:
			var pop := create_tween()
			jackpot_label.pivot_offset = jackpot_label.size/2
			pop.tween_property(jackpot_label,"scale",Vector2(1.035,1.035),.12)
			pop.tween_property(jackpot_label,"scale",Vector2.ONE,.2)
		if state.shake and not state.reduce_motion and ratio>=15:
			var shake := create_tween()
			shake.tween_property(board,"position:x",224.0,.06)
			shake.tween_property(board,"position:x",216.0,.06)
			shake.tween_property(board,"position:x",220.0,.06)
	var count_time := 0.2 if state.fast else 0.45
	if state.counting == 0 or state.reduce_motion: count_time = 0.01
	if state.counting == 2: count_time = 1.3
	var tween := create_tween()
	tween.tween_method(func(v: float):
		displayed_credits=v
		balance.text="%.2f" % v,displayed_credits,float(state.credits),count_time)
	await tween.finished
	detail.text = " • ".join(earned) if not earned.is_empty() else ("Lines won: " + ", ".join(result.wins.map(func(w): return str(w.line+1))) if not result.wins.is_empty() else "Free Biscuits is always here when you need it.")
	busy = false
	if result.jackpot or result.bonus or result.free_count>0 or ratio>=50:
		auto_left = 0
	refresh()
	if result.bonus:
		show_bonus(result.bonus_award)
		return
	if result.jackpot:
		run_free=false
		return
	schedule_next()

func schedule_next():
	var token := epoch
	if auto_left != 0 or (run_free and not state.queue.is_empty()):
		await get_tree().create_timer(.3 if state.fast else .5).timeout
		if token == epoch and not busy and not is_instance_valid(modal): spin()

func stop_auto():
	auto_left = 0
	run_free = false
	epoch += 1
	if is_instance_valid(auto_button): refresh()

func close_modal():
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
		modal = null
	spin_button.grab_focus()

func open_modal(title: String):
	stop_auto()
	close_modal()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var shade := ColorRect.new()
	shade.color=Color(0.03,.10,.12,.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var bg := Panel.new()
	bg.position=Vector2(130,38);bg.size=Vector2(1020,725)
	var style := StyleBoxFlat.new()
	style.bg_color=Color("213f49");style.set_corner_radius_all(25)
	bg.add_theme_stylebox_override("panel",style)
	modal.add_child(bg)
	var heading := Label.new()
	heading.text=title;heading.position=Vector2(160,52);heading.size=Vector2(800,55)
	heading.add_theme_font_size_override("font_size",32)
	modal.add_child(heading)
	var close := Button.new()
	close.text="Close";close.position=Vector2(995,55);close.size=Vector2(130,52)
	style_button(close);close.pressed.connect(close_modal);modal.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.position=Vector2(165,124);scroll.size=Vector2(950,606)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	modal.add_child(scroll)
	modal_body=VBoxContainer.new()
	modal_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	modal_body.add_theme_constant_override("separation",15)
	scroll.add_child(modal_body)
	close.grab_focus()

func paragraph(value: String, font_size: int = 22):
	var l := Label.new()
	l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",Color("eff0db"))
	modal_body.add_child(l)

func choice(value: String, action: Callable):
	var b := Button.new()
	b.text=value;style_button(b)
	b.pressed.connect(func():
		audio.interact(state);audio.play_sound("click");action.call())
	modal_body.add_child(b)
	return b

func toggle(value: String, key: String):
	var b := CheckButton.new()
	b.text=value;b.button_pressed=state[key]
	b.custom_minimum_size.y=88 if compact_touch else 52;b.add_theme_font_size_override("font_size",22)
	b.toggled.connect(func(v): state[key]=v;saver.save_state(state);refresh())
	modal_body.add_child(b)

func show_auto():
	if busy:
		stop_auto();return
	open_modal("Auto Spin • settle in with the dogs")
	paragraph("Stops for a bonus, free-spin trigger, jackpot, Puppy Party, or an empty bowl. Stop always cancels the next spin; the current result finishes.")
	for count in [10,25,50,-1]:
		choice("Continuous" if count<0 else "%d spins" % count,func():
			close_modal();auto_left=count;run_free=true;spin())
	choice("Speed: " + ("Fast (about 1 second)" if state.fast else "Normal (about 2.5 seconds)"),func():
		state.fast=not state.fast;saver.save_state(state);show_auto())

func show_bonus(amount: float):
	open_modal("Dog Park Bonus")
	audio.play_sound("bonus")
	paragraph("Your dog found a surprise! Choose a doghouse to reveal the randomly drawn reward. Every house reveals your prize; there is no wrong choice.")
	for house in ["Meadow doghouse", "Snowy doghouse", "Cozy doghouse"]:
		choice(house,func():
			open_modal("Fetch complete!")
			paragraph("Your dog brought back %.2f biscuits! They have already been added to your bowl." % amount)
			choice("Lovely!",close_modal))

func show_settings():
	open_modal("Make yourself at home")
	paragraph("Theme changes scenery and sound only. Your odds always stay the same.")
	choice("Theme: " + ("Dachshund Meadow" if state.theme==0 else "Husky Snow"),func():
		state.theme=1-int(state.theme);saver.save_state(state);refresh();show_settings())
	toggle("Mute all audio","mute")
	toggle("Reduced sounds (no repetitive reel sounds or barks)","reduced_sound")
	for key in ["music","sfx"]:
		paragraph("Music volume" if key=="music" else "Sound effects volume")
		var slider := HSlider.new()
		slider.min_value=0;slider.max_value=1;slider.step=.05;slider.value=state[key]
		slider.custom_minimum_size.y=88 if compact_touch else 50
		slider.value_changed.connect(func(v): state[key]=v;audio.apply(state);saver.save_state(state))
		modal_body.add_child(slider)
	toggle("Reduce animation","reduce_motion")
	toggle("Reduce particles","reduce_particles")
	toggle("Allow gentle screen shake","shake")
	choice("Payout counting: " + ["Instant","Normal","Slow"][int(state.counting)],func():
		state.counting=(int(state.counting)+1)%3;saver.save_state(state);show_settings())
	choice("New Game / Reset everything",func():
		if busy: return
		open_modal("Start a fresh game?")
		paragraph("This resets credits to 100, jackpot to 500, statistics, cosmetics, achievements and settings on this device.")
		choice("Yes, reset my local game",func():
			state=engine.new_state();displayed_credits=100;session_won=0;session_wagered=0
			saver.save_state(state);close_modal();refresh();message.text="Welcome back to the dog park!")
		choice("Keep my dogs",close_modal))

func show_collection():
	open_modal("Your dog collection")
	paragraph("Unlock a companion or accessory for each achievement, every 50 spins, and every 3 bonuses. Pick any unlocked item to display beside the reels. Cosmetics never affect odds.")
	for dog in Progression.DOGS:
		if dog in state.cosmetics:
			choice(("✓ " if state.dog==dog else "Select: ")+dog,func():
				state.dog=dog;saver.save_state(state);refresh();show_collection())
		else: paragraph("○ " + dog + " — keep playing at your own pace",18)
	paragraph("Achievement badges",28)
	for badge in Progression.BADGES: paragraph(("★ " if badge in state.achievements else "○ ")+badge,21)

func show_stats():
	open_modal("Your local scrapbook")
	paragraph("Current credits: %.2f • Starting credits: 100\nCurrent jackpot: %.2f\nCosmetics: %d / %d • Achievements: %d / %d" % [state.credits,state.jackpot,state.cosmetics.size(),Progression.DOGS.size(),state.achievements.size(),Progression.BADGES.size()])
	for key in state.stats: paragraph("%s: %.2f" % [key.capitalize(),state.stats[key]],21)
	paragraph("Observed session RTP: " + ("%.2f%%" % (100*session_won/session_wagered) if session_wagered>0 else "No paid spins this session"))
	paragraph("Observed lifetime RTP: " + ("%.2f%%" % (100*state.stats.won/state.stats.wagered) if state.stats.wagered>0 else "No paid spins yet"))
	paragraph("Observed RTP is credits won ÷ credits wagered. Free-spin wins count as returns. Refills are excluded. Short sessions vary greatly; these are not the theoretical odds. Session means since this app was opened.")

func show_odds():
	open_modal("Odds & Math • nothing hidden")
	paragraph("All biscuits are fictional credits. No real money, purchases, advertisements, accounts, tracking, cash-out or server. Results are randomly generated before reels animate.")
	paragraph("Target long-term RTP: 103%. Theoretical RTP including free spins, bonuses and the progressive jackpot:")
	for i in 4: paragraph("Bet %d → %.3f%%" % [i+1,100*engine.config.theoretical_rtp[i]],23)
	paragraph("Bet 1: middle. Bet 2: middle + top. Bet 3: all horizontal rows. Bet 4: all horizontal rows + both diagonals (top-top-middle-bottom-bottom, and its mirror). Numbered lines show active paths. Matching symbols must start on the leftmost reel.")
	paragraph("Your wager is split equally over active lines: 1 credit per line at Bets 1–3, 0.8 at Bet 4. Max Bet adds a 1.5% bonus to line payouts. This keeps the five-line option generous without a 25% RTP jump. Symbol odds never change with your bet.")
	paragraph("Approximate paid-spin payout frequency: 6.5%, 11.8%, 16.7%, 23.2% for Bets 1–4 (see measured report). Independent Dog Park bonus: 1 in 100 per spin; mean prize 4× total wager. Independent jackpot: 1 in 40,000 per paid or free spin. The Collar symbol is decorative; it does not trigger the independent jackpot.")
	paragraph("Three Bonus Bones anywhere award 5 free spins; four award 8; five or more award 10. Chance: about 0.304% per eligible spin. Free spins use the triggering wager. Retriggers extend to six generations; generation six cannot retrigger. No credit charge for free spins.")
	paragraph("Jackpot starts at 500 and grows by 0.005 × paid wager. A hit pays the entire saved pot then resets it to 500. Theoretical RTP assumes long-run payout of contributions; an unclaimed pot explains a small finite-simulation difference.")
	paragraph("Paytable • 3 / 4 / 5 matches",28)
	paragraph("Multipliers below apply to the per-line stake. Wild Puppy substitutes for ordinary symbols, not Bonus Bone or Collar; each line pays only its highest matching award.")
	for i in 9:
		var p: Array = engine.config.payouts[i]
		paragraph("%s: %.3f× / %.3f× / %.3f×" % [engine.config.names[i],p[0]*engine.config.line_scale,p[1]*engine.config.line_scale,p[2]*engine.config.line_scale],21)
	paragraph("Symbol weights • each cell sampled independently",28)
	for i in 11: paragraph("%s: %s%%" % [engine.config.names[i],str(engine.config.weights[i])],20)
	paragraph("No outcomes are moved or replaced to manufacture near misses. Credits retain fractional precision internally; displays round to two decimals. The public repository includes the exact shared engine, mathematical derivation and reproducible million-spin reports.")

func show_debug():
	if not developer or busy: return
	open_modal("Development controls • DEBUG + --developer only")
	var seed_box := LineEdit.new()
	seed_box.placeholder_text="RNG seed (integer)";seed_box.custom_minimum_size.y=50;modal_body.add_child(seed_box)
	choice("Apply seed",func(): engine.rng.seed=int(seed_box.text))
	for kind in ["Three","Five","Down","Up","Multiple","Wild","Free"]:
		choice("Force " + kind,func():
			forced={"grid":preload("res://scripts/debug_controller.gd").new().grid_for(kind),"bonus":false,"jackpot":false}
			select_bet(4);close_modal())
	var grid_box := LineEdit.new()
	grid_box.placeholder_text="JSON grid: 5 columns, each with 3 IDs (0–10)";grid_box.custom_minimum_size.y=50;modal_body.add_child(grid_box)
	choice("Force JSON grid",func():
		var parser:=JSON.new()
		if parser.parse(grid_box.text)!=OK: return
		var g=parser.data
		if not g is Array or g.size()!=5: return
		for col in g:
			if not col is Array or col.size()!=3: return
			for s in col:
				if not s is float or s!=floor(s) or s<0 or s>10: return
		forced={"grid":g};close_modal())
	for event in ["bonus","jackpot"]:
		choice("Force " + event,func(): forced={event:true};close_modal())
	choice("Increase jackpot/bonus chance to 10% (until restart)",func():
		engine.config.jackpot_probability=.1;engine.config.bonus_probability=.1)
	for amount in [-100,100]:
		choice("Test credits: %+d" % amount,func(): state.credits=maxf(0,state.credits+amount);displayed_credits=state.credits;refresh())
	choice("Reset statistics",func(): state.stats=engine.fresh_stats();session_won=0;session_wagered=0)

func _unhandled_key_input(event: InputEvent):
	if not event is InputEventKey or not event.pressed or event.echo: return
	audio.interact(state)
	if event.keycode==KEY_S: stop_auto();return
	if is_instance_valid(modal):
		if event.keycode==KEY_ESCAPE: close_modal()
		return
	match event.keycode:
		KEY_SPACE: spin()
		KEY_1: select_bet(1)
		KEY_2: select_bet(2)
		KEY_3: select_bet(3)
		KEY_4: select_bet(4)
		KEY_A: show_auto()
		KEY_P: show_odds()
		KEY_C: show_collection()
		KEY_ESCAPE: show_settings()

func _notification(what: int):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		saver.save_state(state);get_tree().quit()
	if what == NOTIFICATION_APPLICATION_PAUSED and not state.is_empty(): saver.save_state(state)
