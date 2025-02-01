--!strict

local tiniest_expect = require("../src/tiniest_expect")
local tiniest_time = require("../src/tiniest_time").configure({
	get_timestamp = os.clock
})
local tiniest_pretty = require("../src/tiniest_pretty").configure({
	plugins = { tiniest_time :: any }
})
local tiniest = require("../src/tiniest").configure({
	plugins = { tiniest_time :: any, tiniest_pretty }
}) 

local function my_test_suite()
	local describe = tiniest.describe
	local test = tiniest.test
	local expect = tiniest_expect.expect

	describe("some cool features", function()
		test("it works", function()
			local start = os.clock()
			repeat until os.clock() - start > 0.1
			expect(2 + 2).is({
				foo = 2,
				bar = true
			})
		end)
	end)
end

local tests = tiniest.collect_tests(my_test_suite)
tiniest.run_tests(tests, {})