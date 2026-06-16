extends Node
## Autoload holding the player's chosen vehicle across the scene change from the
## landing screen into the race. Defaults to the original car so Main.tscn (and
## the headless drive test) work when launched directly with no selection made.

var selected_model_path := "res://assets/race.glb"
