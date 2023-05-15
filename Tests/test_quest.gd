extends GutTest


const EXAMPLE_QUEST = preload("res://Quests/54745.tres")

var quest_engine:QuestEngine

func before_each() -> void:
	quest_engine = autofree(QuestEngine.new())
	quest_engine.add_quest_from_path("res://Quests/testing_quest.tres")


func test_quest_load() -> void:
	quest_engine.print_tree_pretty()
	# check name
	assert_eq(quest_engine.get_child(0).name, &"testing_quest")
	# check steps
	var q = quest_engine.get_child(0) as QuestNode
	for i in range(1, q.get_child_count() + 1):
		assert_eq(q.get_child(i-1).name, &"s%s" % i)
		# check goals
		for g in range(1, q.get_child(i-1).get_child_count() + 1):
			assert_eq(q.get_child(i-1).get_child(g-1).name, &"s%sg%s" % [i,g])


func test_quest_events() -> void:
	pass_test("Not complete")
