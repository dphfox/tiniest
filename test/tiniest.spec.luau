-- From dphfox/tiniest, licensed under BSD3
--!strict

type tiniest_actual = typeof(require("../src/tiniest_for_lune").configure({}))
local tiniest = require("../src/tiniest")

return function(tiniest_actual: tiniest_actual)
	local describe = tiniest_actual.describe
	local test = tiniest_actual.test
	local expect = tiniest_actual.expect
	local snapshot = tiniest_actual.snapshot

	local tiniest = tiniest.configure({})
	local t_describe = tiniest.describe
	local t_test = tiniest.test

	local function pass()
		-- noop
	end

	local function fail()
		error("This should not run")
	end

	describe("test collection", function()
		test("flat test suite", function()
			snapshot(tiniest.collect_tests(function()
				t_test("this is the first test", fail)
				t_test("this is the second test", fail)
				t_test("this is the third test", fail)
			end))
		end)

		test("singly nested test suites", function()
			snapshot(tiniest.collect_tests(function()
				t_describe("group one", function()
					t_test("this is the first test", fail)
					t_test("this is the second test", fail)
					t_test("this is the third test", fail)
				end)
				t_describe("group two", function()
					t_test("this is the first test", fail)
					t_test("this is the second test", fail)
					t_test("this is the third test", fail)
				end)
				t_describe("group three", function()
					t_test("this is the first test", fail)
					t_test("this is the second test", fail)
					t_test("this is the third test", fail)
				end)
			end))
		end)

		test("multiply nested test suites", function()
			snapshot(tiniest.collect_tests(function()
				t_describe("group one", function()
					t_describe("group one one", function()
						t_test("this is the first test", fail)
						t_test("this is the second test", fail)
						t_test("this is the third test", fail)
					end)
					t_describe("group one two", function()
						t_test("this is the first test", fail)
						t_test("this is the second test", fail)
						t_test("this is the third test", fail)
					end)
				end)
				t_describe("group two", function()
					t_describe("group two one", function()
						t_test("this is the first test", fail)
						t_test("this is the second test", fail)
						t_test("this is the third test", fail)
					end)
					t_describe("group two two", function()
						t_test("this is the first test", fail)
						t_test("this is the second test", fail)
						t_test("this is the third test", fail)
					end)
				end)
			end))
		end)

		test("duplicate names at the same level", function()
			expect(function()
				tiniest.collect_tests(function()
					t_test("this is the first level", fail)
					t_test("this is the first level", fail)
				end)
			end).fails_with("duplicate")
			expect(function()
				tiniest.collect_tests(function()
					t_test("this is the first level", fail)
					t_describe("this is the first level", function()
						t_test("this is the second level", fail)
					end)
				end)
			end).fails_with("duplicate")
		end)
	end)
	
	describe("test running", function()
		local results
		local pass_test, fail_test

		test("running the suite", function()
			results = tiniest.run_tests(
				tiniest.collect_tests(function()
					t_test("passes", pass)
					t_test("fails", fail)
				end),
				{}
			)
		end)

		test("tallies", function()
			expect(results.status_tally.pass).is(1)
			expect(results.status_tally.fail).is(1)
		end)

		test("find individual tests", function()
			for _, test in results.tests do
				expect(results.individual).has_key(test)
				if results.individual[test].status == "pass" then
					pass_test = test
				else
					fail_test = test
				end
			end
			expect(pass_test).exists()
			expect(fail_test).exists()
		end)
	end)
end