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

export type Test = {
	labels: {string},
	run: () -> ()
}

export type RunResult = {
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
	message: string,
	trace: string
}

export type PrettyOptions = {
	disable_emoji: boolean?,
	disable_unicode: boolean?,
	disable_colour: boolean?
}

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
		inner(root_context)
		current_context = nil
	end

	function with_inner_context(
		make_context: (Context) -> Context,
		inner: (Context) -> ()
	): ()
		local outer_context = get_context()
		local inner_context = make_context(outer_context)
		current_context = inner_context
		inner(inner_context)
		current_context = outer_context
	end
end

local tiniest = {}

function tiniest.describe(
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

function tiniest.test(
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

function tiniest.collect_tests(
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

function tiniest.run_tests(
	tests: {Test},
	environment: {
		get_time: () -> number
	}
): RunResult
	local context: Context = {
		type = "run"
	}
	
	local individual = {}
	for _, test in tests do
		local _, run_result = xpcall(
			function()
				local start_time = environment.get_time()
				with_root_context(context, test.run)
				local end_time = environment.get_time()
				local pass: TestRunResult = {
					status = "pass",
					duration = end_time - start_time
				}
				return pass
			end,
			function(message)
				local trace = debug.traceback(nil, 2)
				local fail: TestRunResult = {
					status = "fail",
					message = message,
					trace = trace
				}
				return fail
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
		status_tally = status_tally,
		total_duration = total_duration,
		individual = individual
	}
	return result
end

function tiniest.pretty_report(
	run_result: RunResult,
	declared_options: PrettyOptions?
): string
	local options: PrettyOptions = declared_options or {}
	local lines = {}

	local function string_len(text: string)
		if options.disable_unicode then
			return string.len(text)
		else
			return utf8.len(text) or string.len(text)
		end
	end
	local status_icons = {
		pass = if options.disable_emoji then "[PASS]" else "✅",
		fail = if options.disable_emoji then "[FAIL]" else "❌"
	}
	local crumb_trail = if options.disable_unicode then " > " else " ▸ "
	local divider = if options.disable_unicode then "=" else "═"
	local suffix = {
		micro = if options.disable_unicode then "u" else "µ",
		milli = "m",
	}
	local paint = {}
	do
		local function ansi_mode(...)
			if options.disable_colour then
				return ""
			else
				return `{string.char(27)}[{table.concat({...}, ";")}m`
			end
		end
		local DIM = ansi_mode("2")
		local PASS = ansi_mode("1", "32")
		local PASS_DIM = ansi_mode("2", "32")
		local FAIL = ansi_mode("1", "31")
		local FAIL_DIM = ansi_mode("2", "31")
		local TRACE = ansi_mode("34")
		local TRACE_DIM = ansi_mode("2", "34")
		local RESET = ansi_mode("0")

		function paint.dim(
			text: string
		): string
			return DIM .. text .. RESET
		end

		function paint.pass(
			text: string
		): string
			return PASS .. text .. RESET
		end

		function paint.pass_dim(
			text: string
		): string
			return PASS_DIM .. text .. RESET
		end

		function paint.fail(
			text: string
		): string
			return FAIL .. text .. RESET
		end

		function paint.fail_dim(
			text: string
		): string
			return FAIL_DIM .. text .. RESET
		end

		function paint.trace(
			text: string
		): string
			return TRACE .. text .. RESET
		end

		function paint.trace_dim(
			text: string
		): string
			return TRACE_DIM .. text .. RESET
		end
	end
	local LINE_LENGTH = 80
	local function title(
		text: string
	): string
		local no_ansi = text:gsub(`{string.char(27)}.-m`, "")
		local divider_count = (LINE_LENGTH - string_len(no_ansi) - 2) / 2
		local divider_lhs = string.rep(divider, math.ceil(divider_count))
		local divider_rhs = string.rep(divider, math.floor(divider_count))
		return paint.dim(divider_lhs) .. " " .. text .. " " .. paint.dim(divider_rhs)
	end

	local function duration(
		seconds: number
	): string
		local SECOND = 1
		local MILLISECOND = SECOND / 1000
		local MICROSECOND = MILLISECOND / 1000
		if seconds < 100 * MICROSECOND then
			return `{math.ceil(seconds / MICROSECOND * 100) / 100}{suffix.micro}s`
		elseif seconds < 100 * MILLISECOND then
			return `{math.ceil(seconds / MICROSECOND * 100) / 100}{suffix.milli}s`
		else
			return `{math.ceil(seconds * 100) / 100}s`
		end
	end

	local ordered_pretty_results = {}
	for test, result in run_result.individual do
		local painted_labels = table.clone(test.labels)
		for index, label in painted_labels do
			local style = result.status .. if index < #painted_labels then "_dim" else ""
			painted_labels[index] = paint[style](label)
		end
		local pretty = {
			test = test,
			result = result,
			crumbs = table.concat(painted_labels, paint[result.status .. "_dim"](crumb_trail)),
			icon = status_icons[result.status]
		}
		table.insert(ordered_pretty_results, pretty)
	end
	table.sort(ordered_pretty_results, function(a, b)
		local A_THEN_B = true
		local B_THEN_A = false
		for index = 1, math.max(#a.test.labels, #b.test.labels) do
			local a_label = a.test.labels[index]
			local b_label = b.test.labels[index]
			if a_label == nil then
				return A_THEN_B
			elseif b_label == nil then
				return B_THEN_A
			elseif a_label ~= b_label then
				return a_label < b_label
			end
		end
		-- default case - a < b == false
		return B_THEN_A
	end)

	if run_result.status_tally.fail > 0 then
		table.insert(lines, title(`Errors from {run_result.status_tally.fail} test(s)`))
		table.insert(lines, "")
		for _, pretty in ordered_pretty_results do
			if pretty.result.status == "pass" then continue end
			table.insert(lines, `{pretty.icon} {pretty.crumbs}`)
			table.insert(lines, paint.trace(pretty.result.message))
			table.insert(lines, paint.trace_dim(pretty.result.trace))
		end
		table.insert(lines, "")
	end
	
	table.insert(lines, title(`Status of {#ordered_pretty_results} test(s)`))
	table.insert(lines, "")
	for _, pretty in ordered_pretty_results do
		table.insert(lines, `{pretty.icon} {pretty.crumbs}`)
	end
	table.insert(lines, "")
	table.insert(lines, title(`{paint.pass(`{run_result.status_tally.pass} passed in {duration(run_result.total_duration)}`)}, {paint.fail(`{run_result.status_tally.fail} failed`)}`))

	return table.concat(lines, "\n")
end

return tiniest