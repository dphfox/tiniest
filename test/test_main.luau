local tiniest = require("../tiniest")

local function my_test_suite()
	local describe = tiniest.describe
	local test = tiniest.test

	describe("some cool features", function()
		test("it works", function()
			assert(2 + 2 == 5)
		end)
	end)
end

local tests = tiniest.collect_tests(my_test_suite)
local results = tiniest.run_tests(tests, { get_time = os.clock })
print(tiniest.pretty_report(results))