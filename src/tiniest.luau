-- From dphfox/tiniest, licenced under MIT
--!strict

type Context = DescribeContext | RunContext

type DescribeContext = {
	type: "describe",
	labels: {string},
	add_test: (Test) -> ()
}

type RunContext = {
	type: "run"
}

export type ErrorReport = {
	type: "tiniest.ErrorReport",
	message: string,
	trace: string,
	code: {
		snippet: string,
		line: string
	}?
}

export type Test = {
	labels: {string},
	run: () -> ()
}

export type RunResult = {
	tests: {Test},
	status_tally: {
		pass: number,
		fail: number
	},
	total_duration: number,
	individual: {[Test]: TestRunResult}
}

export type TestRunResult = PassTestRunResult | FailTestRunResult

export type PassTestRunResult = {
	status: "pass",
	duration: number
}

export type FailTestRunResult = {
	status: "fail",
	error: ErrorReport
}

export type Options = {
	external: {
		get_timestamp: () -> number
	}
}

local function catch_errors(func: any, ...)
	local outer_trace
	local function handler(message)
		local report: ErrorReport
		if typeof(message) == "table" and message.type == "tiniest.ErrorReport" then
			report = message :: ErrorReport
		else
			report = {
				type = "tiniest.ErrorReport",
				message = tostring(message),
				trace = debug.traceback(nil, 2)
			}
		end
		local from, to = string.find(report.trace, outer_trace, 1, true)
		if from ~= nil and to ~= nil then
			report.trace = report.trace:sub(1, from - 1) .. report.trace:sub(to + 1)
		end
		return report
	end
	outer_trace = debug.traceback(); return xpcall(func, handler, ...)
end

local tiniest = {}

function tiniest.configure(
	options: Options
)
	local get_context, with_root_context, with_inner_context
	do
		local current_context: Context? = nil

		function get_context(): Context
			assert(current_context ~= nil, "This function can only be called from inside of a test suite")
			return current_context
		end

		function with_root_context(
			root_context: Context,
			inner: (Context) -> ()
		): ()
			assert(current_context == nil, "This function can't be called from inside of a test suite")
			current_context = root_context
			local ok, err = catch_errors(inner :: any, root_context)
			current_context = nil
			if not ok then
				error(err)
			end
		end

		function with_inner_context(
			make_context: (Context) -> Context,
			inner: (Context) -> ()
		): ()
			local outer_context = get_context()
			local inner_context = make_context(outer_context)
			current_context = inner_context
			local ok, err = catch_errors(inner :: any, inner_context)
			current_context = outer_context
			if not ok then
				error(err)
			end
		end
	end

	local self = {}

	function self.describe(
		label: string,
		inner: () -> ()
	): ()
		with_inner_context(function(outer_context: Context): Context
			assert(outer_context.type == "describe", "This function can only be called outside of tests")
			local context = table.clone(outer_context)
			context.labels = table.clone(context.labels)
			table.insert(context.labels, label)
			return context
		end, inner)
	end

	function self.test(
		label: string,
		run: () -> ()
	): ()
		local context = get_context()
		assert(context.type == "describe", "This function can only be called outside of tests")
		local labels = table.clone(context.labels)
		table.insert(labels, label)
		local test: Test = {
			labels = labels,
			run = run
		}
		context.add_test(test)
	end

	function self.collect_tests(
		inner: () -> ()
	): {Test}
		local tests = {}
		local context: Context = {
			type = "describe",
			labels = {},
			add_test = function(test)
				table.insert(tests, test)
			end
		}
		with_root_context(context, inner)
		return tests
	end

	function self.run_tests(
		tests: {Test}
	): RunResult
		local context: Context = {
			type = "run"
		}
		
		local individual = {}
		for _, test in tests do
			local _, run_result = xpcall(
				function()
					local start_time = options.external.get_timestamp()
					with_root_context(context, test.run)
					local end_time = options.external.get_timestamp()
					local pass: TestRunResult = {
						status = "pass",
						duration = end_time - start_time
					}
					return pass
				end,
				function(message)
					if typeof(message) == "table" and message.type == "tiniest.ErrorReport" then
						local fail: TestRunResult = {
							status = "fail",
							error = message :: ErrorReport
						}
						return fail
					else
						local error: ErrorReport = {
							type = "tiniest.ErrorReport",
							message = tostring(message),
							trace = debug.traceback()
						}
						local fail: TestRunResult = {
							status = "fail",
							error = error
						}
						return fail
					end
				end
			)
			individual[test] = run_result
		end

		local status_tally = {
			pass = 0,
			fail = 0
		}
		local total_duration = 0

		for _, result in individual do
			status_tally[result.status] += 1
			if result.status == "pass" then
				total_duration += result.duration
			end
		end

		local result: RunResult = {
			tests = tests,
			status_tally = status_tally,
			total_duration = total_duration,
			individual = individual
		}
		return result
	end

	return self
end

return tiniest