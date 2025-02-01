--!strict

local tiniest = require("../src/tiniest").configure({
	external = {
		get_timestamp = os.clock
	}
}) 
local tiniest_pretty = require("../src/tiniest_pretty").configure({})
local tiniest_expect = require("../src/tiniest_expect")

local function my_test_suite()
	local describe = tiniest.describe
	local test = tiniest.test
	local expect = tiniest_expect.expect

	describe("some cool features", function()
		test("it works", function()
			expect(2 + 2).is({
				foo = 2,
				bar = true
			})
		end)
	end)
end

local tests = tiniest.collect_tests(my_test_suite)
local results = tiniest.run_tests(tests)
print(tiniest_pretty.format(results))