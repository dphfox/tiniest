--!strict

local tiniest = require("../src/tiniest_for_lune").configure({
	snapshot_path = "./test/__snapshots__",
	save_snapshots = true
}) 

local function my_test_suite()
	local describe = tiniest.describe
	local test = tiniest.test
	local expect = tiniest.expect
	local snapshot = tiniest.snapshot

	describe("some cool features", function()
		test("it works", function()
			expect(2 + 2).is(4)
		end)

		test("snapshots", function()
			snapshot({
				hello = "world",
				foo = true,
				bar = 2
			})
		end)
	end)
end

local tests = tiniest.collect_tests(my_test_suite)
tiniest.run_tests(tests, {})