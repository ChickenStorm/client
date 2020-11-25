extends MenuContainer

const ASSETS = preload("res://resources/assets.tres")

var fleet : Fleet = null setget set_fleet
var ship_group_hangar = [] setget set_ship_group_hangar
var system_id = null
var selected_formation = "" setget set_selected_formation
var _game_data : GameData = Store.game_data

onready var menu_fleet_details = $MenuBody/MarginContainer/Body/Details
onready var grid_formation_container = $MenuBody/MarginContainer/Body/LeftColomn/Formation/GridContainer


func _ready():
	if fleet != null and not fleet.is_connected("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships"):
		fleet.connect("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships")
	for node in grid_formation_container.get_children():
		if node is ShipGroupCard:
			node.connect("pressed", self, "_on_ship_group_pressed", [node.formation_position])
	menu_fleet_details.connect("request_assignation", self, "_on_request_assignation")
	_game_data.selected_state.connect("hangar_updated", self, "_on_hangar_updated")
	_game_data.selected_state.connect("system_selected", self, "_on_system_selected")
	update_hangar()
	update_element_fleet()
	# it is possible that we would call _refresh_hangar_elements multiple time
	# it is however necessary to call it as it is possible that the elments are not updated before
	# (as ship_group_element_container is null before ready) but that ship_group_hangar are already in memory
	_refresh_hangar_elements()
	_update_details_view()


func _on_system_selected(_old_system):
	if fleet.system != _game_data.selected_state.selected_system.id:
		emit_signal("close_requested")
	else:
		set_ship_group_hangar(_game_data.selected_state.selected_system.hangar)


func _on_hangar_updated(ship_groups):
	set_ship_group_hangar(ship_groups)


func update_hangar():
	# NOTE : ship_groupe
	if fleet == null or system_id == fleet.system:
		return
	system_id = fleet.system
	if _game_data.selected_state.selected_system.hangar != null: # todo always true
		set_ship_group_hangar(_game_data.selected_state.selected_system.hangar)
	else:
		set_ship_group_hangar([])
		_game_data.request_hangar(_game_data.get_system(fleet.system))


func update_element_fleet():
	var node_update_formation = []
	if menu_fleet_details == null:
		return
	menu_fleet_details.fleet = fleet
	if fleet != null and fleet.squadrons != null:
		for i in fleet.squadrons:
			var node_formation = grid_formation_container.get_node(i.formation)
			node_update_formation.push_back(i.formation)
			node_formation.ship_group = i
	for node in grid_formation_container.get_children():
		if node is ShipGroupCard and not node_update_formation.has(node.name):
			node.ship_group = null


func set_fleet(new_fleet):
	if fleet != null and fleet.is_connected("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships"):
		fleet.disconnect("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships")
	fleet = new_fleet
	if fleet != null and not fleet.is_connected("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships"):
		fleet.connect("fleet_update_nb_ships", self, "_on_fleet_update_nb_ships")
	if fleet.system != system_id:
		update_hangar()
	update_element_fleet()
	_update_details_view()


func set_ship_group_hangar(array):
	ship_group_hangar = array
	_refresh_hangar_elements()


func _refresh_hangar_elements():
	# NOTE : ship_groupe
	if menu_fleet_details == null:
		return
	menu_fleet_details.hangar = ship_group_hangar


func _on_fleet_update_nb_ships():
	update_element_fleet()


func _on_ship_group_pressed(formation_param):
	for node in grid_formation_container.get_children():
		if node is ShipGroupCard: 
			if node.formation_position != formation_param:
				node.is_selected = false
			else:
				if node.is_selected:
					show_details(formation_param)
				else:
					hide_details()


func show_details(formation_param):
	self.selected_formation = formation_param


func hide_details():
	self.selected_formation = ""


func set_selected_formation(new_formation):
	selected_formation = new_formation
	_update_details_view()


func _update_details_view():
	if menu_fleet_details == null:
		return
	menu_fleet_details.visible = selected_formation != ""
	menu_fleet_details.formation = selected_formation


func _on_request_assignation(ship_category, quantity):
	if selected_formation == "":
		return
	# there is no implementation of a lock here
	# the reason is that I do not want to block multiple assignation request
	# for multiple formation. 
	# Anyway the request should be extecuter in order and all info are passed to
	# _on_ship_assigned (apart from _game_data)
	Network.req(self, "_on_ship_assigned",
			"/api/games/" + _game_data.id +
				"/systems/" + _game_data.selected_state.selected_system.id +
				"/fleets/" + fleet.id +
				"/ship-groups/",
			HTTPClient.METHOD_POST,
			[ "Content-Type: application/json" ],
			JSON.print({
				"category" : ship_category.category,
				"quantity" : quantity,
				"formation" : selected_formation,
			}),
			[quantity, fleet, ship_category, selected_formation]
	)


func _on_ship_assigned(err, response_code, _headers, _body,\
		quantity, fleet_param : Fleet, ship_category : ShipModel, formation):
	if err:
		ErrorHandler.network_response_error(err)
	if response_code == HTTPClient.RESPONSE_NO_CONTENT:
		var previous_squadron = fleet_param.get_squadron(formation)
		var previous_quantity = previous_squadron.quantity if previous_squadron != null else 0
		fleet_param.update_fleet_nb_ships(ship_category, quantity, formation)  
		# this trigger the event to refresh the data so no need to do it here
		var system = _game_data.get_system(fleet_param.system)
		system.add_quantity_hangar(ship_category, previous_quantity - quantity) 
		# this trigger the event to refresh the data
