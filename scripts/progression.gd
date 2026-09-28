extends RefCounted
const DOGS = ["Dachshund", "Husky", "Golden Retriever", "Beagle", "Corgi", "Labrador", "German Shepherd", "Poodle", "Red collar", "Blue collar", "Bow tie", "Bandana", "Sunglasses", "Winter scarf", "Cowboy hat", "Flower crown"]
const BADGES = ["First Fetch", "Long Dog", "Snow Dog", "Double Trouble", "Paw-some", "Free Treats", "Dog Park Regular", "Top Dog", "1000 Spins"]

func update(state: Dictionary, result: Dictionary) -> Array:
	var earned: Array = []
	var conditions := [not result.wins.is_empty(), false, false, result.wins.size() >= 2,
		result.wins.size() >= 3, result.free_count > 0, state.stats.bonuses >= 10,
		result.jackpot, state.stats.spins >= 1000]
	for win in result.wins:
		if win.count == 5 and win.symbol == 4: conditions[1] = true
		if win.count == 5 and win.symbol == 5: conditions[2] = true
	for i in BADGES.size():
		if conditions[i] and not BADGES[i] in state.achievements:
			state.achievements.append(BADGES[i])
			earned.append(BADGES[i])
	var unlock_count := mini(DOGS.size(), 2 + state.achievements.size() + int(state.stats.spins / 50) + int(state.stats.bonuses / 3))
	for i in unlock_count:
		if not DOGS[i] in state.cosmetics:
			state.cosmetics.append(DOGS[i])
			earned.append("Unlocked: " + DOGS[i])
	return earned
