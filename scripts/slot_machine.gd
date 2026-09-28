extends RefCounted
## Authoritative engine shared verbatim by UI, tests and simulator.
const CONFIG_PATH = "res://data/probability.json"
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
var rng := RandomNumberGenerator.new()
var cumulative: Array[int] = []
var total_weight := 0

func _init(seed_value: int = -1):
	for line in config.lines:
		for i in line.size(): line[i] = int(line[i])
	if seed_value < 0: rng.randomize()
	else: rng.seed = seed_value
	for weight in config.weights:
		total_weight += int(weight)
		cumulative.append(total_weight)

func active_lines(bet: int) -> Array:
	return config.lines.slice(0, 5 if bet == 4 else bet)

func symbol() -> int:
	var roll := rng.randi_range(1, total_weight)
	for i in cumulative.size():
		if roll <= cumulative[i]: return i
	return 0

func generate_result() -> Array:
	var grid: Array = []
	for col in 5:
		grid.append([symbol(), symbol(), symbol()])
	return grid

func evaluate_line(values: Array) -> Dictionary:
	var best := {"symbol": -1, "count": 0, "multiplier": 0.0}
	for candidate in 9:
		var count := 0
		for value in values:
			if value == candidate or value == 8: count += 1
			else: break
		if count >= 3:
			var amount: float = config.payouts[candidate][count - 3] * config.line_scale
			if amount > best.multiplier:
				best = {"symbol": candidate, "count": count, "multiplier": amount}
	return best

func evaluate(grid: Array, bet: int) -> Array:
	var wins: Array = []
	var lines := active_lines(bet)
	for index in lines.size():
		var values: Array = []
		for col in 5: values.append(grid[col][int(lines[index][col])])
		var win := evaluate_line(values)
		if win.count >= 3:
			win["line"] = index
			win["amount"] = win.multiplier * bet / lines.size() * (config.max_bet_multiplier if bet == 4 else 1.0)
			wins.append(win)
	return wins

func free_award(grid: Array, generation: int) -> int:
	if generation >= int(config.max_generation): return 0
	var bones := 0
	for col in grid:
		for item in col:
			if item == 10: bones += 1
	return int(config.free_rewards[mini(bones - 3, 2)]) if bones >= 3 else 0

func new_state() -> Dictionary:
	return {"credits": 100.0, "jackpot": config.jackpot_base, "queue": [], "bet": 1,
		"theme": 0, "dog": "Husky", "cosmetics": ["Dachshund", "Husky"], "achievements": [],
		"music": 0.3, "sfx": 0.65, "mute": false, "reduced_sound": false,
		"reduce_motion": false, "reduce_particles": false, "shake": false, "counting": 1,
		"fast": false, "stats": fresh_stats()}

func fresh_stats() -> Dictionary:
	return {"spins": 0, "paid": 0, "free": 0, "wagered": 0.0, "won": 0.0, "largest": 0.0,
		"jackpots": 0, "bonuses": 0, "free_rounds": 0, "hits": 0, "refills": 0}

func refill(state: Dictionary) -> bool:
	if state.credits >= 100.0: return false
	state.credits = 100.0
	state.stats.refills += 1
	return true

func spin(state: Dictionary, requested_bet: int, forced: Dictionary = {}) -> Dictionary:
	var is_free: bool = not state.queue.is_empty()
	var bet := clampi(requested_bet, 1, 4)
	var generation := 0
	if is_free:
		var ticket: Array = state.queue.pop_front()
		bet = int(ticket[0])
		generation = int(ticket[1])
	elif state.credits + 0.0000001 < bet: return {"error": "Out of biscuits!"}
	if not is_free:
		state.credits -= bet
		state.jackpot += config.contribution_per_credit * bet
		state.stats.wagered += bet
		state.stats.paid += 1
	else: state.stats.free += 1
	# All randomness resolves before presentation, even bonus choice prizes.
	var grid: Array = forced.get("grid", generate_result())
	var wins := evaluate(grid, bet)
	var award := 0.0
	for win in wins: award += win.amount
	var free_count := free_award(grid, generation)
	for i in free_count: state.queue.append([bet, generation + 1])
	var bonus: bool = forced.get("bonus", rng.randf() < config.bonus_probability)
	var bonus_prizes: Array = []
	for i in 3: bonus_prizes.append(float(config.bonus_rewards[rng.randi_range(0, 3)]) * bet)
	# Selected house is cosmetic: each reveals the same already-drawn reward.
	var bonus_award: float = bonus_prizes[0] if bonus else 0.0
	award += bonus_award
	var jackpot: bool = forced.get("jackpot", rng.randf() < config.jackpot_probability)
	var jackpot_award := 0.0
	if jackpot:
		jackpot_award = state.jackpot
		award += jackpot_award
		state.jackpot = config.jackpot_base
		state.stats.jackpots += 1
	state.credits += award
	state.stats.spins += 1
	state.stats.won += award
	state.stats.largest = maxf(state.stats.largest, award)
	if award > 0: state.stats.hits += 1
	if bonus: state.stats.bonuses += 1
	if free_count > 0: state.stats.free_rounds += 1
	return {"grid": grid, "wins": wins, "award": award, "free_count": free_count, "free": is_free,
		"generation": generation, "bet": bet, "bonus": bonus, "bonus_award": bonus_award,
		"jackpot": jackpot, "jackpot_award": jackpot_award}
