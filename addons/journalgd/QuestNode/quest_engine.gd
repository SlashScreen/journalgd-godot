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


## Checks whether a quest is currently active.
func is_quest_active(qID:String) -> bool:
	return active_quests.has(qID)


## Checks whether a quest has been complete.
func is_quest_complete(qID:String) -> bool:
	return complete_quests.has(qID)


## Checks whether a quest has been started, meaning it is either currently in progress, or already complete.
## Inverting this can check if the quest hasn't been started by the player.
func has_quest_been_started(qID:String) -> bool:
	return is_quest_active(qID) or is_quest_complete(qID)


## Gets a quest's node by name.
func get_quest(q_id:String) -> QuestNode:
	return get_node_or_null(q_id)


## Determines whether a step is active or not, meaning that it is the current step of an active quest.
func is_step_active(path:String) -> bool:
	var chunks = path.split("/")
	if not is_quest_active(chunks[0]):
		return false
	var qnode = get_quest(chunks[0])
	if not qnode:
		return false
	return qnode._active_step.name == chunks[1]


## Determines whether a step is complete or not.
func is_step_complete(path:String) -> bool:
	var chunks = path.split("/")
	var qnode = get_quest(chunks[0])
	if not qnode:
		return false
	return qnode.is_step_complete(chunks[1])


## Checks whether a step has been started, meaning it is either currently in progress, or already complete.
## Inverting this can check if the quest hasn't been started by the player.
func has_step_been_started(path:String) -> bool:
	return is_quest_active(path) or is_step_complete(path)


## Get a step object at a given path.
func get_step(path:String) -> QuestStep:
	var chunks = path.split("/")
	var qnode = get_node_or_null(chunks[0]) as QuestNode
	if qnode == null:
		return null
	return qnode.get_node_or_null(chunks[1]) as QuestStep


## Returns whether the goal is incomplete in an active quest and step - if the player is currently doing it.
func is_goal_active(path:String) -> bool:
	var chunks = path.rsplit("/", true, 1) # we only want to pop off the last part of the path
	if not is_step_active(chunks[0]):
		return false
	var g = get_goal(path)
	return not g.already_satisfied


## Ignoring whether the goal's step and quest are complete, returns whether the goal is complete or not.
func is_goal_complete(path:String) -> bool:
	var g = get_goal(path)
	if not g:
		return false
	return g.already_satisfied


## Checks whether a goal has been started, meaning it is either currently in progress, or already complete.
## Inverting this can check if the quest hasn't been started by the player.
func has_goal_been_started(path:String) -> bool:
	return is_goal_active(path) or is_goal_complete(path)


## Get a goal object at the given path.
func get_goal(path:String) -> QuestGoal:
	var chunks = path.rsplit("/", true, 1) # we only want to pop off the last part of the path
	var q_step = get_step(chunks[0]) # DRY!
	if not q_step:
		return null
	var q_goal = q_step.get_node_or_null(chunks[1])
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
		"step" = chunks[1] if chunks.size() > 0 else "",
		"goal" = chunks[2] if chunks.size() > 1 else ""
	}
