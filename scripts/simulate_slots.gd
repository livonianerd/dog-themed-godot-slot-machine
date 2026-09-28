extends SceneTree
const EngineClass = preload("res://scripts/slot_machine.gd")

func _initialize():
	var count := 1000000
	var seed_value := 20260927
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: count = maxi(1, int(args[0]))
	if args.size() > 1: seed_value = int(args[1])
	var reports: Array = []
	for bet in range(1, 5):
		var engine := EngineClass.new(seed_value + bet)
		var state := engine.new_state()
		var hist := {}
		var rewards: Array[float] = []
		var squares := 0.0
		var session_spins := 0
		var ended_sessions: Array[int] = []
		var combinations := {}
		while state.stats.paid < count or not state.queue.is_empty():
			if state.queue.is_empty() and state.credits < bet:
				ended_sessions.append(session_spins)
				session_spins = 0
				engine.refill(state)
			var r := engine.spin(state, bet)
			session_spins += 1
			squares += r.award * r.award
			if r.award > 0: rewards.append(r.award)
			for w in r.wins:
				var key := "%s × %d" % [engine.config.names[w.symbol], w.count]
				combinations[key] = combinations.get(key, 0) + 1
			if int(state.stats.paid) % 100000 == 0 and state.queue.is_empty():
				print("Bet %d: %d paid spins" % [bet, state.stats.paid])
		rewards.sort()
		var spins: float = state.stats.spins
		var won: float = state.stats.won
		var mean: float = won / spins
		var session_total := 0
		for length in ended_sessions: session_total += length
		var report := {"bet": bet, "seed": seed_value + bet, "stats": state.stats,
			"rtp": won / state.stats.wagered, "theoretical_rtp": engine.config.theoretical_rtp[bet-1],
			"hit_rate": state.stats.hits / spins, "no_payout_rate": 1.0 - state.stats.hits / spins,
			"average_win": won / maxf(1, rewards.size()), "median_win": rewards[int(rewards.size()/2)] if not rewards.is_empty() else 0,
			"mean_return_per_spin": mean, "standard_deviation": sqrt(maxf(0, squares/spins - mean*mean)),
			"jackpot_frequency": state.stats.jackpots/spins, "bonus_frequency": state.stats.bonuses/spins,
			"free_trigger_frequency": state.stats.free_rounds/spins, "combinations": combinations,
			"completed_sessions": ended_sessions.size(), "mean_completed_session_length": float(session_total)/maxi(1, ended_sessions.size()),
			"last_censored_session_length": session_spins, "unpaid_progressive_growth": state.jackpot-engine.config.jackpot_base}
		reports.append(report)
		print(JSON.stringify(report, "  "))
	var output := "res://docs/simulation-results.json"
	if args.size() > 2: output = args[2]
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify({"paid_spins_per_wager": count, "seed": seed_value, "results": reports}, "  "))
	quit()
