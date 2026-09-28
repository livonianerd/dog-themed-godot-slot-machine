extends SceneTree
const E = preload("res://scripts/slot_machine.gd")
const D = preload("res://scripts/debug_controller.gd")
const S = preload("res://scripts/save_manager.gd")
const P = preload("res://scripts/progression.gd")
var failures := 0
var checks := 0
func check(condition: bool, label: String):
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
func _initialize():
	var e := E.new(7)
	var d := D.new()
	check(e.active_lines(1) == [[1,1,1,1,1]], "middle")
	check(e.active_lines(2) == [[1,1,1,1,1],[0,0,0,0,0]], "middle and top")
	check(e.active_lines(3).size() == 3 and e.active_lines(4).size() == 5, "mapping")
	for name in ["Three", "Five", "Down", "Up", "Multiple", "Wild"]:
		check(not e.evaluate(d.grid_for(name),4).is_empty(), name)
	check(e.evaluate(d.grid_for("Down"),3).is_empty(), "inactive diagonal")
	check(e.evaluate_line([8,8,10,10,10]).count == 0, "wild excludes bonus")
	check(e.evaluate_line([8,9,9,9,9]).count == 0, "wild excludes collar")
	check(e.evaluate_line([1,0,0,0,0]).count == 0, "leftmost required")
	check(e.evaluate(d.grid_for("Multiple"),3).size() == 3, "three simultaneous wins")
	var s := e.new_state()
	var r := e.spin(s,4,{"grid":d.grid_for("Five"),"bonus":false,"jackpot":false})
	check(is_equal_approx(s.credits,96+r.award), "deduct then award")
	check(is_equal_approx(s.jackpot,500.02), "progressive growth")
	r = e.spin(s,1,{"grid":d.grid_for("Free"),"bonus":false,"jackpot":false})
	check(r.free_count == 5 and s.queue.size()==5, "free trigger")
	var paid_before: float = s.stats.wagered
	r = e.spin(s,4,{"grid":d.grid_for("Free"),"bonus":false,"jackpot":false})
	check(s.stats.wagered == paid_before and r.bet==1 and r.free and s.queue.size()==9, "free costs zero; locked wager; retrigger")
	check(e.free_award(d.grid_for("Free"),6)==0, "generation limit")
	r = e.spin(s,1,{"grid":d.grid_for("Five"),"bonus":true,"jackpot":true})
	check(r.bonus_award>0 and s.stats.bonuses==1, "bonus")
	check(r.jackpot_award>500 and s.jackpot==500 and s.stats.jackpots==1, "jackpot award/reset")
	var p := P.new()
	p.update(s,r)
	check("Top Dog" in s.achievements and "Long Dog" in s.achievements and s.cosmetics.size()>2, "achievements/cosmetics")
	s.theme=1
	var saver := S.new()
	saver.path="user://test-save.json"
	check(saver.save_state(s), "save")
	var loaded := saver.load_state()
	check(loaded.theme==1 and is_equal_approx(loaded.credits,s.credits) and loaded.jackpot==s.jackpot and loaded.cosmetics==s.cosmetics and loaded.achievements==s.achievements, "roundtrip")
	var file := FileAccess.open(saver.path,FileAccess.WRITE)
	file.store_string('{"broken":');file.close()
	check(saver.load_state().credits==100,"corruption fallback")
	s.credits=0
	check(e.refill(s) and s.credits==100,"free refill")
	check(not e.refill(s),"refill only below100")
	s.credits=0;s.queue=[]
	check(e.spin(s,1).has("error"),"insufficient funds")
	var a := E.new(123)
	var b := E.new(123)
	for i in 100: check(a.generate_result()==b.generate_result(),"seed reproducibility")
	print("CHECKS: %d; FAILURES: %d" % [checks,failures])
	quit(1 if failures else 0)
