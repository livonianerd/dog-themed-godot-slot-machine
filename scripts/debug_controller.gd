extends RefCounted
## UI instantiates only in a debug build AND with --developer.
func grid_for(kind: String) -> Array:
	var grid: Array = [[1,2,3],[2,3,1],[3,1,2],[1,2,3],[2,3,1]]
	match kind:
		"Three":
			for col in 3: grid[col][1] = 4
		"Five":
			for col in 5: grid[col][1] = 4
		"Down":
			for col in 5: grid[col][[0,0,1,2,2][col]] = 5
		"Up":
			for col in 5: grid[col][[2,2,1,0,0][col]] = 5
		"Multiple":
			for col in 5: grid[col] = [4,5,4]
		"Wild":
			for col in 5: grid[col][1] = 8 if col % 2 else 4
		"Free":
			for col in 3: grid[col][0] = 10
	return grid
