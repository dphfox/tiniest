-- From dphfox/tiniest, licenced under MIT
--!strict

local tiniest = require("../src/tiniest_for_lune").configure({
	snapshot_path = "./test/__snapshots__",
	save_snapshots = true
})

local require: any = require

local tests = tiniest.collect_tests(function()
	local describe = tiniest.describe

	local function describe_from_file(name: string)
		describe(name, function()
			require(`./{name}.spec`)(tiniest)
		end)
	end

	-- describe_from_file("tiniest_expect")
	-- describe_from_file("tiniest_plugin")
	-- describe_from_file("tiniest_pretty")
	-- describe_from_file("tiniest_quote")
	-- describe_from_file("tiniest_snapshot")
	-- describe_from_file("tiniest_time")
	describe_from_file("tiniest")
end)
tiniest.run_tests(tests, {})