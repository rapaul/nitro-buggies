extends Node3D
## Top-level scene controller: pause toggle and controller hotplug handling.
## Runs with PROCESS_MODE_ALWAYS so the pause action keeps working while paused.


func _ready() -> void:
	# Wire the follow camera to the car. Done in code because node-reference
	# exports don't resolve reliably from a hand-authored .tscn NodePath.
	$Camera3D.target = $Car
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	# Input still flows through the InputMap regardless; this just surfaces the
	# connect/disconnect so a controller plugged in after launch is recognized.
	if connected:
		print("Gamepad connected: ", Input.get_joy_name(device))
	else:
		print("Gamepad disconnected: device ", device)
