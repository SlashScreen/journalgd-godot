extends GutTest


var quest_engine:QuestEngine


func before_each() -> void:
	quest_engine = autofree(QuestEngine.new())
	add_child(quest_engine)
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


func test_quest_event_path() -> void:
	watch_signals(quest_engine)
	assert_eq(quest_engine.get_child(0)._active_step.name, &"s1")
	quest_engine.register_quest_event("testing_quest/s1g1")
	assert_eq(quest_engine.get_child(0)._active_step.name, &"s2")
	assert_signal_emitted(quest_engine, "goal_updated")
	assert_signal_emitted(quest_engine, "step_updated")


func test_quest_event_no_path() -> void:
	assert_eq(quest_engine.get_child(0)._active_step.name, &"s1")
	quest_engine.register_quest_event("s1g1")
	assert_eq(quest_engine.get_child(0)._active_step.name, &"s2")


func test_quest_branch() -> void:
	assert_eq(quest_engine.get_child(0)._active_step.name, &"s1")
	quest_engine.register_quest_event("testing_quest/s1g1")
	assert_eq(quest_engine.get_child(0)._active_step.name, &"s2")
	quest_engine.register_quest_event("testing_quest/s2g2") # deliberately go to the other branch to avoid false positives due to ordering
	assert_eq(quest_engine.get_child(0)._active_step.name, &"s4")


func test_quest_all() -> void:
	pending()


func test_quest_any() -> void:
	pending()


func test_quest_active() -> void:
	watch_signals(quest_engine)
	quest_engine.start_quest("testing_quest")
	assert_true(quest_engine.is_member_active("testing_quest"))
	assert_signal_emitted(quest_engine, "quest_started")


func test_quest_completion() -> void:
	watch_signals(quest_engine)
	quest_engine.start_quest("testing_quest")
	quest_engine.register_quest_event("testing_quest/s1g1")
	quest_engine.register_quest_event("testing_quest/s2g1")
	assert_false(quest_engine.is_member_complete("testing_quest"))
	quest_engine.register_quest_event("testing_quest/s3g1")
	assert_true(quest_engine.is_member_complete("testing_quest"))
	assert_signal_emitted(quest_engine, "quest_complete")


func test_step_active() -> void:
	quest_engine.start_quest("testing_quest")
	quest_engine.register_quest_event("testing_quest/s1g1")
	assert_true(quest_engine.is_member_active("testing_quest/s2"), "Step s2 should be active.")
	assert_true(quest_engine.is_member_complete("testing_quest/s1"), "Step s1 should be complete.")
