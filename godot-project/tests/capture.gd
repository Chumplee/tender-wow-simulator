extends SceneTree
# Visual capture: renders the real game under Xvfb and saves PNGs of
# the start screen, gameplay, Wi-Fi rage, and the unplugged meltdown.
# Run: xvfb-run -a godot --path . --script tests/capture.gd

func snap(game: Node, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://tests/shots")
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir + "/" + name + ".png")
	print("SHOT ", name, " size=", img.get_size(), " mood=", game.mood)

func wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame

func _init() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await wait_frames(40)
	await snap(game, "01_start_screen")
	game.start_game()
	await wait_frames(60)
	await snap(game, "02_playing")
	game.toggle_wifi()
	await wait_frames(40)
	await snap(game, "03_wifi_rage")
	game.toggle_plug()
	game._process(1.6) # burn through the shock beat into the breakdown
	game._process(0.1)
	await wait_frames(30)
	print("MOOD AT CRY CAPTURE: ", game.mood)
	await snap(game, "04_unplugged_cry")
	print("CAPTURE DONE")
	quit(0)
