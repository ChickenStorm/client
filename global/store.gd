extends Node

var _state = {
	"factions": {},
	"game": {},
	"lobby": null,
	"player": null,
	"selected_system": null
}

signal notification_added(notification)
signal system_selected(system, old_system)
signal wallet_updated(amount)

func _ready():
	pass

func get_lobby_name():
	return 'Partie de ' + _state.lobby.creator.username if typeof(_state.lobby.creator) == TYPE_DICTIONARY && _state.lobby.creator.username != '' else 'Nouvelle Partie'

func reset_player_lobby_data():
	_state.player.username = ''
	_state.player.faction = null
	_state.player.ready = false

func notify(title, content):
	emit_signal("notification_added", {
		"title": title,
		"content": content
	})

func set_factions(factions):
	_state.factions = {}
	for faction in factions:
		_state.factions[faction.id] = faction
		
func get_faction(id):
	return _state.factions[id]
	
func set_game_players(players):
	_state.game.players = {}
	for player in players:
		_state.game.players[player.id] = player
		
func get_game_player(id):
	return _state.game.players[id]
	
func update_wallet(new_amount):
	_state.player.wallet += new_amount
	emit_signal("wallet_updated", _state.player.wallet)
	
func select_system(system):
	emit_signal("system_selected", system, _state.selected_system)
	_state.selected_system = system
	
func add_fleet(system_id, fleet):
	_state.game.systems[system_id].fleets[fleet.id] = fleet
	
func remove_player_lobby(player):
	for i in range(Store._state.lobby.players.size()):
		if Store._state.lobby.players[i].id == player.id:
			Store._state.lobby.players.remove(i)
			break
			
