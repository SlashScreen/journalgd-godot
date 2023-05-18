@tool

class_name QuestStep
extends Node

var type:StepType = StepType.ALL
var is_final_step:bool = false
var is_already_complete:bool
var next_steps:Dictionary = {}
var next_step:QuestStep:
	get:
		if not type == StepType.BRANCH:
			return get_parent().get_node_or_null(next_steps.values()[0] as String) 
		for g in get_children():
			if(g.evaluate(false)):
				return get_parent().get_node_or_null(next_steps[g.name] as String)
		return null


func _init(eqs:SavedStep = null) -> void:
	if not eqs:
		return
	type = eqs.step_type
	is_final_step = eqs.is_final_step
	name = eqs.step_name
	next_steps = eqs.connections
	for g in eqs.goals:
		add_child(QuestGoal.new(g))


func evaluate(is_active_step:bool) -> bool:
	if is_already_complete:
		return true
	var results:Array[bool] = []
	for g in get_children():
		results.append(g.evaluate(is_active_step) || g.optional) # if evaluate or optional
	if type == StepType.ALL:
		var check = results.all(func(x): return x)
		if check:
			is_already_complete = true
		return check
	else:
		var check = results.any(func(x): return x)
		if check:
			is_already_complete = true
		return check


## Register a goal event.
func register_event(key:String, args:Dictionary, undo:bool):
	for g in get_children():
		g.attempt_register(key, args, undo)


func save() -> Dictionary:
	var goal_data = {}
	for g in get_children():
		goal_data[g.name] = g.save()
	return {
		"is_already_complete": is_already_complete,
		"goal_data" : goal_data
	}


func load_data(data:Dictionary) -> void:
	is_already_complete = data.is_already_complete
	for g_key in data.goal_data:
		get_node(g_key).load_data(data.goal_data[g_key])


enum StepType {
	ALL,
	ANY,
	BRANCH,
}
