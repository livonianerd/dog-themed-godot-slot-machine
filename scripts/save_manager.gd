extends RefCounted
const EngineClass = preload("res://scripts/slot_machine.gd")
var path := "user://puppy-save.json"

func save_state(state: Dictionary) -> bool:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"version": 1, "state": state}))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

func load_state() -> Dictionary:
	var engine := EngineClass.new()
	var defaults := engine.new_state()
	if not FileAccess.file_exists(path): return defaults
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return defaults
	var raw = parser.data
	if not raw is Dictionary or raw.get("version") != 1 or not raw.get("state") is Dictionary: return defaults
	var s: Dictionary = raw.state
	for key in defaults:
		if not s.has(key): s[key] = defaults[key]
		if typeof(s[key]) != typeof(defaults[key]) and not (s[key] is float and defaults[key] is int) and not (s[key] is int and defaults[key] is float): return defaults
	for key in defaults.stats:
		if not s.stats.has(key) or not (s.stats[key] is float or s.stats[key] is int): return defaults
		if not is_finite(float(s.stats[key])) or s.stats[key] < 0: return defaults
	if not is_finite(s.credits) or s.credits < 0 or not is_finite(s.jackpot) or s.jackpot < engine.config.jackpot_base: return defaults
	if s.bet < 1 or s.bet > 4 or s.theme < 0 or s.theme > 1: return defaults
	if s.queue.size() > 1000000: return defaults
	for ticket in s.queue:
		if not ticket is Array or ticket.size() != 2: return defaults
		if not (ticket[0] is float or ticket[0] is int) or not (ticket[1] is float or ticket[1] is int): return defaults
		if ticket[0] < 1 or ticket[0] > 4 or ticket[1] < 1 or ticket[1] > engine.config.max_generation: return defaults
	for key in ["bet","theme","counting"]:
		if not is_finite(float(s[key])) or s[key] != floor(s[key]): return defaults
	if s.counting < 0 or s.counting > 2: return defaults
	for key in ["music", "sfx"]:
		if not is_finite(float(s[key])): return defaults
		s[key] = clampf(s[key], 0, 1)
	return s
