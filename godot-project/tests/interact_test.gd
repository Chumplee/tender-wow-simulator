extends SceneTree
# Automated interaction test: boots the real game, presses start,
# kills Wi-Fi, yanks the plug, and reports state at each step.
# Run: godot --headless --path . --script tests/interact_test.gd

func wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame

func _init() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null:
		print("TEST FAIL: main scene failed to load")
		quit(1)
		return
	var game = packed.instantiate()
	root.add_child(game)
	await wait_frames(20)
	print("TEST boot ok, started=", game.started)
	game.start_game()
	await wait_frames(40)
	print("TEST after start: started=", game.started, " mood=", game.mood, " day=", game.day)
	game.toggle_wifi()
	await wait_frames(30)
	print("TEST after kill wifi: wifi_on=", game.wifi_on, " mood=", game.mood, " meltdowns=", game.meltdowns)
	game.toggle_wifi()
	await wait_frames(20)
	print("TEST after restore wifi: wifi_on=", game.wifi_on, " mood=", game.mood)
	game.give_snack()
	game.give_snack()
	await wait_frames(10)
	print("TEST after snacks: snacks=", game.snacks, " trash=", game.trash)
	game.toggle_curtains()
	await wait_frames(20)
	print("TEST after curtains: blinds_open=", game.blinds_open, " mood=", game.mood, " sunlight=", game.sunlight_avoided)
	game.suggest_bed()
	game.poke()
	await wait_frames(10)
	game.toggle_plug()
	await wait_frames(30)
	print("TEST after yank plug: power_on=", game.power_on, " mood=", game.mood, " rages=", game.rages)
	await wait_frames(150) # shock should decay into bloodrage
	print("TEST after waiting unplugged: mood=", game.mood)
	game.toggle_plug()
	await wait_frames(20)
	print("TEST after plug back in: power_on=", game.power_on, " mood=", game.mood)
	# fast-forward: simulate two full days of process time
	for i in range(80):
		game._process(1.0)
	print("TEST after 80 simulated seconds: day=", game.day, " trash=", game.trash, " played=", int(game.played_hours))
	print("TEST LOG SAMPLE: ", game.log_lines)
	print("TEST ALL OK")
	quit(0)
