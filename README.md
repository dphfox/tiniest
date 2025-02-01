<h1>
	<img src="github/logo.svg" alt="tiniest">
</h1>

`tiniest` is a collection of minimal, portable testing libraries for Luau,
built on a few principles:

- Simple, idiomatic Luau throughout.
- Zero external dependencies.
- Small core, extend with plugins.
- Runtime independence.
- No opinions about project structure.

`tiniest` comes with a batteries-included setup for Lune, or pick and mix your
own modules and plugins!

## Features

- `test()` and `describe()` callbacks
- Clean, correctly-cropped stack traces
- Declarative `expect()` API with line numbers and code visualisation
- Pretty-formatted summaries of reports with emoji, Unicode, and colour
- Benchmark how long tests run for
- Extensible, lightweight plugin system
- Snapshot testing for all quotable data types

### Planned

- Test discovery for Lune

## Installation

No installation needed!

`tiniest` is distributed as a set of portable Luau files that sit next to each
other. Drop them into your `lib` folder, keep the ones you need, and start using
`tiniest` right away :)


## Usage

> *🎨 The printed reports come with colour - try it in your terminal!*

Here's an example file written with `tiniest_for_lune`:

```Lua
--!strict

local tiniest = require("@tiniest_for_lune").configure({
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
			expect(2 + 2).is(5)
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
```

The above example generates a report like this and prints it to stdout:

```
══════════════════════════════ Status of 2 test(s) ═════════════════════════════

✅ some cool features ▸ it works - 74.9µs
✅ some cool features ▸ snapshots - 137.71ms

══════════════════════════════ 2 passed, 0 failed ══════════════════════════════

Time to run: 217.9ms

════════════════════════════════════════════════════════════════════════════════
```

Failures look like this:

```
═════════════════════════════ Errors from 2 test(s) ════════════════════════════

❌ some cool features ▸ it works
Expectation not met
   │ 
16 │ expect(4).is(5)
   │ 
[string "test/test_main"]:16

❌ some cool features ▸ snapshots
Snapshot does not match
   │ 
78 │ snapshot({
   │   ["bar"] = 2;
   │   ["foo"] = true;
   │   ["hello"] = "world";
   │ })
   │ 
   │ -- snapshot on disk:
   │ snapshot({
   │   ["bar"] = 5;
   │   ["foo"] = false;
   │   ["hello"] = "earth";
   │ })
   │ 
[string "test/test_main"]:20

══════════════════════════════ Status of 2 test(s) ═════════════════════════════

❌ some cool features ▸ it works - 111.6ms
❌ some cool features ▸ snapshots - 174.9ms

══════════════════════════════ 0 passed, 2 failed ══════════════════════════════

Time to run: 292.81ms

════════════════════════════════════════════════════════════════════════════════
```

## Contributions and maintenance

This is [a certified Daniel P H Fox Side Project™](https://fluff.blog/2024/04/10/i-dont-want-to-be-a-maintainer.html), which I am sharing because I personally wanted it to exist in the world. I might maintain it. I might not.
Contributions are welcome, but I do not make guarantees about those either.

Feel free to use `tiniest`, but if you're about to depend on it big time, the security audit's on you. If, for whatever reason, you end up in a spot of bother, you should probably not have used a random project from someone's GitHub without inspecting what it does properly. I take no responsibility for that.
