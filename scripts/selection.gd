extends Node
## Autoload holding the player's chosen vehicle across the scene change from the
## landing screen into the race. Defaults to the original car so Main.tscn (and
## the headless drive test) work when launched directly with no selection made.

var selected_model_path := "res://assets/race.glb"

## How many players race. 1 keeps the original single-player, full-screen setup
## (and the headless tests, which launch Main.tscn directly with this default).
## 2 enables the horizontal split-screen race.
var player_count := 1

## Player 2's chosen vehicle (used only when player_count == 2). Player 1 uses
## selected_model_path above.
var player2_model_path := "res://assets/race.glb"
