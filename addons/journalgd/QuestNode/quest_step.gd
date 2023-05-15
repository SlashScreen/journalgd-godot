@tool

class_name QuestStep
extends Node

var type:StepType = StepType.ALL
var is_final_step:bool = false
var is_already_complete:bool
var next_steps:Array = []
var goal_order:Array = []
var next_step:QuestStep:
	get:
		if not type == StepType.BRANCH:
			return next_steps[0]
		for g in get_children().map(func(x): x as QuestGoal):
			if(g.evaluate(false)):
				return next_steps[goal_order.find(g.key)]
		return null


func _init(eqs:SavedStep = null) -> void:
	if not eqs:
		return
	type = eqs.step_type
	is_final_step = eqs.is_final_step
	name = eqs.step_name
	# TODO: set up connections
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
		var check = results.any(func(x): x)
		if check:
			is_already_complete = true
		return check


## Register a goal event.
func register_event(key:String, args:Dictionary):
	for g in get_children():
		g.attempt_register(key, args)


enum StepType {
	ALL,
	ANY,
	BRANCH,
}
