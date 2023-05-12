@tool

class_name QuestEditor
extends GraphEdit


var STEP_PREFAB = preload("res://addons/journalgd/Editor/step_prefab.tscn")

var q_name_input:LineEdit


func _ready():
	q_name_input = $"../HBoxContainer/QName"
	connection_request.connect(make_connection.bind())
	disconnection_request.connect(make_disconnection.bind())


func _on_add_new_button_down() -> EditorQuestStep:
	var n = STEP_PREFAB.instantiate()
	add_child(n)
	return n


func _on_save_button_up():
	save()


func make_connection(from_node, from_port, to_node, to_port):
	print("Made connection request: from %s port %s to %s port %s" % [from_node, from_port, to_node, to_port])
	connect_node(from_node, from_port, to_node, to_port)


func make_disconnection(from_node, from_port, to_node, to_port):
	print("Made disconnection request: from %s port %s to %s port %s" % [from_node, from_port, to_node, to_port])
	disconnect_node(from_node, from_port, to_node, to_port)


func delete_node(n:String):
	# { from_port: 0, from: "GraphNode name 0", to_port: 1, to: "GraphNode name 1" }.
	var connections_for_n:Array[Dictionary] = get_connection_list().filter(func(x): return x.from == n || x.to == n) # get all connections with this involved
	for node in connections_for_n: # for each in connections
		disconnect_node(node.from, node.from_port, node.to, node.to_port) # disconnect
	print("Deleting node $s", n)
	get_node(n).queue_free()


func find_step(sname:StringName) -> EditorQuestGoal:
	for c in get_children():
		if c.name == sname:
			return c
	return null


func save() -> void:
	if q_name_input.text == "":
		print("Write a quest name to save.")
		return
	
	print("Start save")
	var q_root:QuestNode = QuestNode.new()
	q_root.name = q_name_input.text
	
	var owned_nodes = []
	# Get steps
	for s in get_children():
		var q_step = QuestStep.new(s)
		q_step.goal_order = s.mapped_goals
		q_root.add_child(q_step)
		
		var cns = get_connection_list().filter(func(x): return x["from"])
		cns.sort_custom(func(a,b): return a["from_port"] < b["from_port"])
		print("Connections found:")
		print(cns)
		q_step.next_steps = cns.map(func(x): return x["to"])
		
		owned_nodes.append(q_step)
		for g in q_step.get_children():
			owned_nodes.append(g)
	
	for n in owned_nodes:
		n.owner = q_root
	
	print("Packed quest %s with %s children" % [q_root.name, q_root.get_child_count()])
	# Pack and save
	var result = Quest.new()
	var scene = PackedScene.new()
	q_root.print_tree_pretty()
	scene.pack(q_root)
	result.quest_id = q_root.name
	result.quest_scene = scene
	ResourceSaver.save(result, (ProjectSettings.get_setting("journalgd/quests_directory") + "/%s.tres" % q_root.name))


func open(q:Quest) -> void:
	# Get rid of all children
	for s in get_children():
		delete_node(s.name)
	# Create steps
	q_name_input.text = q.quest_id # set quest ID
	var quest_scene = q.quest_scene.instantiate() # unpack scene to analyze
	var to_connect:Array[Dictionary] = []
	quest_scene.print_tree_pretty()
	# Iterate through steps, create new
	for step in quest_scene.get_children():
		var e_q = STEP_PREFAB.instantiate()
		e_q.setup(step)
		for i in (step as QuestStep).goal_order.size():
			to_connect.append({"from": step.name, "to": (step as QuestStep).next_steps[i], "from_port": i})
		add_child(e_q)
	# Connect all
	print("to connect: %s" % to_connect)
	#for conn in to_connect:
	#	print("Connecting %s to %s from port %s" % [conn["from"], conn["to"], conn["from_port"]] )
	#	make_connection(conn["from"], conn["from_port"], conn["to"], 0)


func _on_clear_pressed() -> void:
	q_name_input.text = ""
	for s in get_children():
		delete_node(s.name)
