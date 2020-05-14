extends Control

var player_info_scene = load("res://matchmaking/player/player_info.tscn")

signal scene_requested(scene)

func _ready():
	get_node("GUI/Body/Header/Name").set_text("Votre Partie")
	get_node("GUI/Body/Footer/LeaveButton").connect("pressed", self, "leave_lobby")
	$HTTPRequest.connect("request_completed", self, "load_lobby")
	Network.connect("PlayerJoined", self, "_on_player_joined")
	Network.connect("PlayerUpdate", self, "_on_player_update")
	Network.connect("PlayerLeft", self, "_on_player_disconnected")
	Network.connect("LobbyLaunched", self, "_on_lobby_launched")
	$HTTPRequest.request(Network.api_url + "/api/lobbies/" + Store._state.lobby.id, [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_GET)

func load_lobby(err, response_code, headers, body):
	if err:
		ErrorHandler.network_response_error(err)
		return
	$HTTPRequest.disconnect("request_completed", self, "load_lobby")
	var lobby = JSON.parse(body.get_string_from_utf8()).result
	Store._state.lobby = lobby
	get_node("GUI/Body/Header/Name").set_text(Store.get_lobby_name(lobby))
	add_players_info(lobby.players)
	if lobby.creator.id == Store._state.player.id:
		var launch_button = get_node("GUI/Body/Footer/LaunchButton")
		launch_button.visible = true
		launch_button.connect("pressed", self, "launch_game")
	
func add_players_info(players):
	var list = get_node("GUI/Body/Section/PlayersContainer/Players")
	for player in players:
		add_player_info(list, player)

func add_player_info(list, player):
	var player_info = player_info_scene.instance()
	player_info.set_name(player.id)
	player_info.player = player
	
	if player.id == Store._state.player.id:
		player_info.connect("player_updated", self, "_on_player_update")
	list.add_child(player_info)

func leave_lobby():
	$HTTPRequest.connect("request_completed", self, "_on_lobby_left")
	$HTTPRequest.request(Network.api_url + "/api/lobbies/" + Store._state.lobby.id + "/players/", [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_DELETE)
	
func launch_game():
	$HTTPRequest.connect("request_completed", self, "_on_launch_response")
	$HTTPRequest.request(Network.api_url + "/api/lobbies/" + Store._state.lobby.id + "/launch/", [
		"Authorization: Bearer " + Network.token
	], false, HTTPClient.METHOD_POST)

func check_ready_state():
	get_node("GUI/Body/Footer/LaunchButton").disabled = not get_ready_state()

func get_ready_state():
	if Store._state.lobby.creator.id != Store._state.player.id || Store._state.lobby.players.size() < 2:
		return false
	var factionInLoby = []
	for player in Store._state.lobby.players:
		if player.ready == false:
			return false
		if player.faction != null:
			var isTheFactionInArray = false
			for faction in factionInLoby: # I have trouble using .has() and .count()
				if faction == player.faction:
					isTheFactionInArray = true
					break
			if not isTheFactionInArray:
				factionInLoby.push_back(player.faction)
	if factionInLoby.size() < 2:
		return false
	return true

func _on_player_joined(player):
	Store._state.lobby.players.push_back(player)
	add_player_info(get_node("GUI/Body/Section/PlayersContainer/Players"), player)
	check_ready_state()

func _on_player_update(player):
	for i in range(Store._state.lobby.players.size()):
		if Store._state.lobby.players[i].id == player.id:
			Store._state.lobby.players[i] = player
	get_node("GUI/Body/Section/PlayersContainer/Players/" + player.id).update_data(player)
	check_ready_state()

func _on_player_disconnected(player):
	get_node("GUI/Body/Section/PlayersContainer/Players/" + player.id).queue_free()
	check_ready_state()

func _on_lobby_launched(game):
	Store.reset_player_lobby_data()
	Store._state.game = game
	emit_signal("scene_requested", "game_loading")
	
func _on_launch_response(err, response_code, headers, body):
	$HTTPRequest.disconnect("request_completed", self, "_on_launch_response")
	if err:
		ErrorHandler.network_response_error(err)

func _on_lobby_left(err, response_code, headers, body):
	$HTTPRequest.disconnect("request_completed", self, "_on_lobby_left")
	if err:
		ErrorHandler.network_response_error(err)
		return
	Store.reset_player_lobby_data()
	emit_signal("scene_requested", "menu")
	