extends RefCounted

const WEAPONS = ["Egg Shot", "Feather Ring", "Peck Sweep"]
const PRICES = [0, 65, 110]
var path = "user://cluck_save.json"
var data: Dictionary

func _init(save_path: String = "user://cluck_save.json"):
	path = save_path
	reset()
	load_save()

func reset():
	data = {"version": 1, "coins": 0, "unlocked": 1, "equipped": 0, "owned": [0], "health": 0, "power": 0, "magnet": 0, "best": [0, 0, 0], "music": true, "sound": true}

func load_save():
	if not FileAccess.file_exists(path): return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary: return
	for key in data:
		if parsed.has(key): data[key] = parsed[key]
	data.coins = maxi(0, int(data.coins))
	data.unlocked = clampi(int(data.unlocked), 1, 3)
	for key in ["health", "power", "magnet"]: data[key] = clampi(int(data[key]), 0, 5)
	if not data.owned is Array: data.owned = [0]
	data.owned = data.owned.map(func(v): return int(v)).filter(func(v): return v >= 0 and v < 3)
	if not 0 in data.owned: data.owned.append(0)
	data.equipped = int(data.equipped)
	if not data.equipped in data.owned: data.equipped = 0
	if not data.best is Array or data.best.size() != 3: data.best = [0, 0, 0]

func save():
	var f = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(data)); f.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

func cost(stat: String) -> int:
	return 30 + int(data[stat]) * 35

func buy_stat(stat: String) -> bool:
	if not stat in ["health", "power", "magnet"] or int(data[stat]) >= 5: return false
	var price = cost(stat)
	if data.coins < price: return false
	data.coins -= price; data[stat] += 1; save(); return true

func buy_weapon(index: int) -> bool:
	if index < 0 or index >= WEAPONS.size(): return false
	if not index in data.owned:
		if data.coins < PRICES[index]: return false
		data.coins -= PRICES[index]; data.owned.append(index)
	data.equipped = index; save(); return true

func award(level: int, coins: int, seconds: float, won: bool) -> int:
	var reward = coins + (35 + level * 15 if won else 0)
	data.coins += reward
	data.best[level] = maxi(int(data.best[level]), int(seconds))
	if won: data.unlocked = mini(3, maxi(data.unlocked, level + 2))
	save(); return reward
