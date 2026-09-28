extends SceneTree
## Exact enumeration using the production evaluator, not a second payout implementation.
func _initialize():
	var e := preload("res://scripts/slot_machine.gd").new(0)
	var c: Dictionary = e.config
	var expectation := 0.0
	var hit := 0.0
	for index in 161051: # 11^5 possible lines
		var cursor := index
		var line: Array = []
		var p := 1.0
		for col in 5:
			var symbol := cursor % 11
			cursor = int(cursor/11)
			line.append(symbol)
			p *= float(c.weights[symbol])/e.total_weight
		var win := e.evaluate_line(line)
		expectation += p*win.multiplier
		if win.count>=3: hit += p
	var m := 0.0
	var trigger := 0.0
	var bone_p := float(c.weights[10])/e.total_weight
	for k in range(3,16):
		var choose := 1.0
		for j in k: choose *= float(15-j)/(j+1)
		var p: float = choose*pow(bone_p,k)*pow(1-bone_p,15-k)
		trigger += p
		m += p*c.free_rewards[mini(k-3,2)]
	var f := 0.0
	for g in range(int(c.max_generation)+1): f += pow(m,g)
	var bonus_mean := 0.0
	for reward in c.bonus_rewards: bonus_mean += reward/c.bonus_rewards.size()
	var output := {"line_ev":expectation,"single_line_hit_rate":hit,"free_trigger":trigger,"mean_children":m,"spins_per_paid":f,"rtp":[]}
	var valid := true
	for bet in range(1,5):
		var rtp: float = f*(expectation*(c.max_bet_multiplier if bet==4 else 1.0)+c.bonus_probability*bonus_mean+c.jackpot_probability*c.jackpot_base/bet)+c.contribution_per_credit
		output.rtp.append(rtp)
		valid = valid and absf(rtp-c.theoretical_rtp[bet-1]) < 0.00000001 and rtp>=1.02 and rtp<=1.04
	print(JSON.stringify(output,"  "))
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var file := FileAccess.open(args[0],FileAccess.WRITE)
		if file: file.store_string(JSON.stringify(output,"  "))
	quit(0 if valid else 1)
