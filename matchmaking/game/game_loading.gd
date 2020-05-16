extends Control

signal scene_requested(scene)

func _ready():
	Network.connect("GameStarted", self, "_on_game_started")
	$HTTPRequest.connect("request_completed", self, "_on_factions_loaded")
	$HTTPRequest.request(Network.api_url + "/api/factions/", [
		"Authorization: Bearer " + Network.token
	])

func _on_game_started(game):
	Store._state.game.systems = game.systems
	emit_signal("scene_requested", "game")

func _on_factions_loaded(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	$HTTPRequest.disconnect("request_completed", self, "_on_factions_loaded")
	Store.set_factions(JSON.parse(body.get_string_from_utf8()).result)
	load_players()
	
func load_players():
	$HTTPRequest.connect("request_completed", self, "_on_players_loaded")
	$HTTPRequest.request(Network.api_url + "/api/games/" + Store._state.game.id + "/players/", [
		"Authorization: Bearer " + Network.token
	])

func _on_players_loaded(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
	Store.set_game_players(JSON.parse(body.get_string_from_utf8()).result)
	$NbPlayers.set_text(str(Store._state.game.players.size()) + " joueurs")
