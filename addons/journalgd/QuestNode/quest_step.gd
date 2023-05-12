@tool

class_name QuestStep
extends Node

var type:StepType = StepType.ALL
var is_final_step:bool = false
var is_already_complete:bool
@export var next_steps:Array = []
@export var goal_order:Array = []
@export var editor_coordinates:Vector2
var next_step:QuestStep:
	get:
		if type == StepType.ALL:
			return next_steps[0]
		for g in get_children().map(func(x): x as QuestGoal):
			if(g.evaluate(false)):
				return next_steps[goal_order.find(g.key)]
		return null


func _init(eqs:EditorQuestStep = null) -> void:
	if not eqs:
		return
	type = eqs.step_type
	is_final_step = eqs.is_exit
	name = eqs.step_name
	editor_coordinates = eqs.position
	for g in eqs.get_goals():
		add_child(QuestGoal.new(g))


func evaluate(is_active_step:bool) -> bool:
	if is_already_complete:
		return true
	var results:Array[bool] = []
	for g in get_children().map(func(x): x as QuestGoal):
		results.append(g.evaluate() || g.optional) # if evaluate or optional
	if type == StepType.ALL:
		var check = results.all(func(x): x)
		if check:
			is_already_complete = true
		return check
	else:
		var check = results.any(func(x): x)
		if check:
			is_already_complete = true
		return check


## Register a goal event.
func register_event(key:String):
	for g in get_children().map(func(x): x as QuestGoal):
		g.attempt_register(key)


enum StepType {
	ALL,
	ANY,
	BRANCH,
}
