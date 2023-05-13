class_name SavedStep
extends Resource


@export var step_name:StringName
@export var step_type:QuestStep.StepType = QuestStep.StepType.ALL
@export var connections:Dictionary = {}
@export var goals:Array[SavedGoal] = []


func _init(eqs:EditorQuestStep = null) -> void:
	if not eqs:
		return
	step_name = eqs.step_name
	step_type = eqs.step_type
	for g in eqs.get_goals():
		add_goal(SavedGoal.new(g))


func add_goal(goal:SavedGoal) -> SavedGoal:
	goals.append(goal)
	return goal


func add_named_connection(port:int, to:StringName) -> void:
	if not step_type == QuestStep.StepType.BRANCH:
		set_default_connection(to)
		return
	connections[goals[port]] = to


func set_default_connection(to:StringName) -> void:
	connections["default"] = to
