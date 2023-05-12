class_name SavedQuest
extends Resource


@export var quest_id:StringName
@export var steps:Dictionary = {}


func add_step(step:SavedStep) -> SavedStep:
	steps[step.step_name] = step
	return step
