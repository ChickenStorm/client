extends Control

signal join(lobby, must_update)

var lobby = null
var nb_players = 0

func _ready():
	get_node("Body/Join").connect("pressed", self, "join_lobby")
	set_lobby_name()
	nb_players = lobby.nb_players if lobby.has("nb_players") else lobby.players.Size()
	set_nb_players()
	
func set_lobby_name():
	get_node('Body/Name').set_text(Store.get_lobby_name(lobby))

func set_nb_players():
	get_node("Body/Section/Players").set_text(str(nb_players) + "/12")

func increment_nb_players():
	nb_players = nb_players + 1
	set_nb_players()
	
func decrement_nb_players():
	nb_players = nb_players - 1
	set_nb_players()

func join_lobby():
	emit_signal("join", lobby, true)

func update_name(name):
	lobby.creator = {
		"id": lobby.creator if typeof(lobby.creator) == TYPE_STRING else lobby.creator.id,
		"username": name
	}
	set_lobby_name()
	
