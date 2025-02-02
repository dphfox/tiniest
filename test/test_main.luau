-- From dphfox/tiniest, licensed under BSD3
--!strict

local SAVE_SNAPSHOTS = true

local tiniest = require("../src/tiniest_for_lune").configure({
	snapshot_path = "./test/__snapshots__",
	save_snapshots = SAVE_SNAPSHOTS
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

if SAVE_SNAPSHOTS then
	print()
	print(string.rep("💾 🛠️  ", 12))
	print()
	print("Warning! Snapshots are being saved.")
	print("Unless you're in a local dev environment, turn this off.")
	print()
	print(string.rep("💾 🛠️  ", 12))
	print()
end