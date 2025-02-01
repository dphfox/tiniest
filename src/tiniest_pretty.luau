-- From dphfox/tiniest, licenced under MIT
--!strict

local tiniest = require("tiniest")
type RunResult = tiniest.RunResult

export type Options = {
	disable_emoji: boolean?,
	disable_unicode: boolean?,
	disable_colour: boolean?
}

local tiniest_pretty = {}

function tiniest_pretty.configure(
	options: Options
)
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
	local margin_line = if options.disable_unicode then "|" else "│"
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
		local TRACE = ansi_mode("1", "34")
		local TRACE_DIM = ansi_mode("2", "34")
		local NUMBER = ansi_mode("1", "36")
		local STRING = ansi_mode("1", "33")
		local KEYWORD = ansi_mode("1", "35")
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

		function paint.number(
			text: string
		): string
			return NUMBER .. text .. RESET
		end

		function paint.string(
			text: string
		): string
			return STRING .. text .. RESET
		end

		function paint.keyword(
			text: string
		): string
			return KEYWORD .. text .. RESET
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
	local function syntax(
		snippet: string
	): string
		return snippet
			:gsub("0?[xXbB]?%d*%.?%d*[eE]?%-?%d+", paint.number)
			:gsub("\".-\"", paint.string)
			:gsub("\'.-\'", paint.string)
			:gsub("function", paint.keyword)
			:gsub("end", paint.keyword)
			:gsub("true", paint.keyword)
			:gsub("false", paint.keyword)
			:gsub("nil", paint.keyword)
	end

	local self = {}

	function self.format(
		run_result: RunResult
	): string
		local lines = {}

		local pretty_results = {}
		for _, test in run_result.tests do
			local result = run_result.individual[test]
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
			table.insert(pretty_results, pretty)
		end

		if run_result.status_tally.fail > 0 then
			table.insert(lines, title(`Errors from {run_result.status_tally.fail} test(s)`))
			table.insert(lines, "")
			for _, pretty in pretty_results do
				if pretty.result.status == "pass" then continue end
				table.insert(lines, `{pretty.icon} {pretty.crumbs}`)
				table.insert(lines, paint.trace(pretty.result.error.message))
				local code = pretty.result.error.code
				if code ~= nil then
					local num_length = string_len(code.line)
					local empty_margin = string.rep(" ", num_length + 1) .. paint.dim(margin_line)
					table.insert(lines, empty_margin)
					table.insert(lines, `{paint.dim(`{code.line} {margin_line}`)} {syntax(code.snippet)}`)
					table.insert(lines, empty_margin)
				end
				local trace = pretty.result.error.trace:gsub("\n+$", "")
				table.insert(lines, paint.trace_dim(trace))
				table.insert(lines, "")
			end
		end
		
		table.insert(lines, title(`Status of {#pretty_results} test(s)`))
		table.insert(lines, "")
		for _, pretty in pretty_results do
			table.insert(lines, `{pretty.icon} {pretty.crumbs}`)
		end
		table.insert(lines, "")
		table.insert(lines, title(`{paint.pass(`{run_result.status_tally.pass} passed in {duration(run_result.total_duration)}`)}, {paint.fail(`{run_result.status_tally.fail} failed`)}`))

		return table.concat(lines, "\n")
	end

	return self
end

return tiniest_pretty