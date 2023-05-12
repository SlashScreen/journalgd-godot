class_name SavedStep
extends Resource


@export var step_name:StringName
@export var step_type:QuestStep.StepType = QuestStep.StepType.ALL
@export var connections:Dictionary = {}
@export var goals:Array[SavedGoal] = []


func add_goal(goal:SavedGoal) -> SavedGoal:
	goals.append(goal)
	return goal
