extends GutTest

func test_arithmetic():
	assert_eq(2 + 2, 4, "Basic arithmetic should work")

func test_string_concat():
	assert_eq("dead" + "hand", "deadhand")
