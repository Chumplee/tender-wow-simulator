extends SceneTree
# Steps the blue-world stage through its 5.2s performance cycle and snaps a
# frame every half second, so the whole freak-out can be reviewed as a GIF.

func _init() -> void:
	var packed = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_game()
	game._process(0.1)
	game.toggle_wifi()
	for k in range(11):
		game._process(0.52)
		await process_frame
		await process_frame
		var img = root.get_texture().get_image()
		img.save_png("res://tests/stage_frames/s%02d.png" % k)
		print("STAGE SHOT ", k)
	quit()
