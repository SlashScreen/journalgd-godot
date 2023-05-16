class_name QuestEngine
extends Node
## This keeps track of all of the quests.
## Quests will be instantiated as [QuestObject]s underneath this node.
## Registering a quest event will update the tree downwards. What does this mean? I don't know, I'm tired.
## When functions ask for a "Quest path", they are referring to a string in the format of [code]quest_name/step_name/goal_name[/code].


## Array of IDs of all the quests that are currently active.
var active_quests: Array[String]
## Array of IDs of all the quests the player has completed.
var complete_quests:Array[String]

## Emitted when a quest has started.
signal quest_started(q_id:String)
## Emitted when a quest is complete.
signal quest_complete(q_id:String)
## Emitted when a quest goal has been updated - the amount has been increased, or it is marked as complete.
signal goal_updated(quest_path:String) # TODO
## Emitted when a step is updated - when a step is marked as complete.
signal step_updated(quest_path:String) # TODO


## Loads all quests from the [code]biznasty/quests_directory[/code] project setting, and then instantiates them as child [QuestObject]s.
func load_quest_objects():
	_load_dir(ProjectSettings.get_setting("journalgd/quests_path"))


func _load_dir(path:String):
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			_load_dir(file_name)
		else:
			add_quest_from_path("%s/%s" % [path, file_name])
		file_name = dir.get_next()


## Load a quest resource at a path, and load it into the system.
func add_quest_from_path(path:String):
	var q = load(path) as SavedQuest
	add_node_from_saved(q)


## Mark a quest as started.
func start_quest(q_id:String) -> bool:
	if get_node_or_null(q_id):
		active_quests.append(q_id)
		quest_started.emit(q_id)
		return true
	return false


## Add a quest from a [SavedQuest] resource.
func add_node_from_saved(q:SavedQuest) -> void:
	var q_node = QuestNode.new()
	q_node.qID = q.quest_id
	q_node.name = q.quest_id
	
	# Create steps
	for s in q.steps:
		var s_node = QuestStep.new(q.steps[s])
		if q.steps[s].is_entry_step:
			q_node._active_step = s_node 
		q_node.add_child(s_node)
	
	add_child(q_node)
	if q.entry_point == &"":
		q_node._active_step = q_node.get_child(0)
		print(q_node._active_step)
	else:
		q_node = q.entry_point


func is_member_active(q_path) -> bool:
	var path_info = _parse_quest_path(q_path) if q_path is String else q_path
	# step 1: quest
	if path_info["quest"]:
		if not active_quests.has(path_info["quest"]):
			return false
	if path_info["step"]:
		# by the time we get here, we know the step is active.
		var quest:QuestNode = get_member(path_info["quest"])
		if not quest._active_step.name == path_info["step"]: # if step is not the active step, false
			return false
	if path_info["goal"]:
		var goal:QuestGoal = get_member(path_info)
		return not goal.already_satisfied # only active if not yet done
	return false


func is_member_complete(q_path) -> bool:
	var path_info = _parse_quest_path(q_path) if q_path is String else q_path
	# step 1: quest
	if path_info["quest"]:
		if not complete_quests.has(path_info["quest"]):
			return false
	if path_info["step"]:
		# by the time we get here, we know the step is active.
		var step:QuestStep = get_member(path_info["quest"] + "/" + path_info["step"])
		if not step.is_already_complete: # if step is not the active step, false
			return false
	if path_info["goal"]:
		var goal:QuestGoal = get_member(path_info)
		return goal.already_satisfied
	return false


func has_member_been_started(q_path) -> bool:
	var path_info = _parse_quest_path(q_path) if q_path is String else q_path
	return is_member_active(path_info) or is_member_complete(path_info)


func get_member(q_path) -> Variant:
	var path_info = _parse_quest_path(q_path) if q_path is String else q_path
	
	var q_node:QuestNode
	var q_step:QuestStep
	var q_goal:QuestGoal
	
	# step 1: quest
	if path_info["quest"]:
		# try to get quest, if fail return null
		q_node = get_node_or_null(path_info["quest"])
		if not q_node:
			return null
	else:
		return null
	# step 2: step
	if path_info["step"]:
		q_step = q_node.get_node_or_null(path_info["step"])
		if not q_step:
			return null
	else:
		return q_node # return node because we only wanted it
	# step 3: goal
	if path_info["step"]:
		q_goal = q_step.get_node_or_null(path_info["step"])
		if not q_goal:
			return null
	else:
		return q_step # return step because we only wanted it
	
	return q_goal


# TODO: Use propogate_call instead.
# TODO: Use consistent quest string format.
## Register a quest event. 
## You can either pass in a path formatted like [Code]MyQuest/MyEvent[/code] to send an event to a specific quest,
## or simply pass in the event key to send an event to all quests.
func register_quest_event(path:String):
	if path.contains("/"): # if the key is a path
		var chunks = path.split("/")
		var qnode = get_node_or_null(chunks[0]) as QuestNode
		if qnode == null:
			return
		qnode.register_step_event(chunks[1])
	else: # if just the key
		for q in get_children().map(func(x): return x as QuestNode):
			q.register_step_event(path)
	_update_all_quests()


func _update_all_quests():
	for q in get_children():
		q.update()
		if q.complete and not complete_quests.has(q.name):
			complete_quests.append(q.name)
			quest_complete.emit(q.name)


func _parse_quest_path(path:String) -> Dictionary:
	var chunks = path.split("/")
	return {
		"quest" = chunks[0],
		"step" = chunks[1] if chunks.size() > 1 else null,
		"goal" = chunks[2] if chunks.size() > 2 else null
	}
