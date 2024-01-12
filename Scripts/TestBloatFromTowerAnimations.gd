extends MainLoop

# Run the script with godot's command line executable:
# "C:\Program Files\Godot\Godot_v4.1.1-stable_win64_console.exe" -s "C:/Users/kvely/youtd2/Scripts/TestBloatFromTowerAnimations.gd"

const DUPLICATE_COUNT: int = 500
const FILENAME: String = "Assets/bloat-test/frames.png"


func _initialize():
	print("Begin")
	run()
	print("End")


# NOTE: returning true from _process() is the only way to
# quit from MainLoop.
func _process(_delta: float):
	var end_main_loop: bool = true
	return end_main_loop


func run():
	process()


func process():
	var original_image: Image = Image.load_from_file(FILENAME)

	for i in range(0, DUPLICATE_COUNT):
		var duplicate_filename: String = "Assets/bloat-test/duplicate-%d.png" % i
		original_image.save_png(duplicate_filename)
