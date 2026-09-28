extends SceneTree
var failures := 0
func check(value: bool, name: String):
	if not value:
		failures += 1
		push_error(name)
func _initialize():
	call_deferred("run")
func run():
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.saver.path="user://ui-test-save.json"
	game.state=game.engine.new_state()
	game.state.fast=true
	game.state.counting=0
	game.state.mute=true
	game.refresh()
	check(not game.audio.started and not game.audio.music.playing,"audio waits for interaction")
	game.select_bet(4)
	check(game.board.lines.size()==5,"UI wager mapping")
	game.forced={"grid":preload("res://scripts/debug_controller.gd").new().grid_for("Multiple"),"bonus":false,"jackpot":false}
	game.developer=true
	game.spin()
	check(game.busy and game.spin_button.disabled,"lock during spin")
	await create_timer(1.2).timeout
	check(not game.busy and game.board.wins.size()==3,"visible multiline result")
	game.auto_left=-1
	game.forced={"bonus":true,"jackpot":false}
	game.spin()
	await create_timer(1.2).timeout
	check(game.auto_left==0 and is_instance_valid(game.modal),"bonus stops auto and opens choice")
	game.close_modal()
	game.auto_left=-1
	game.forced={"bonus":false,"jackpot":true}
	game.spin()
	await create_timer(1.2).timeout
	check(game.auto_left==0 and not game.run_free,"jackpot stops auto")
	game.state.queue=[]
	game.state.credits=0
	game.refresh()
	check(game.refill_button.visible,"out of biscuits button")
	game.refill()
	check(game.state.credits==100 and not game.refill_button.visible,"refill UI")
	game.state.credits=55
	game.refill()
	check(game.state.credits==100,"permanent refill")
	game.auto_left=50
	game.stop_auto()
	check(game.auto_left==0 and not game.run_free,"immediate stop")
	game.show_settings()
	check(is_instance_valid(game.modal),"settings")
	game.close_modal()
	game.show_odds();game.close_modal()
	game.show_stats();game.close_modal()
	game.show_collection();game.close_modal()
	check(game.state.cosmetics.size()>2,"collection unlocks")
	game.close_modal()
	game.queue_free()
	await process_frame
	await create_timer(.2).timeout
	print("UI integration failures: ",failures)
	quit(1 if failures else 0)
