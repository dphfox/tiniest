<h1>
	<img src="github/logo.svg" alt="tiniest">
</h1>

`tiniest` is a minimal, portable testing library for Luau. It's one file with
everything you need in it.

`tiniest` is built on a few principles:

- Simple, idiomatic Luau throughout.
- Zero dependencies.
- Zero standard library extensions.
- Zero opinions about project structure.
- Just the core features to write simple, good tests.

## Features

- `test()` and `describe()` callbacks
- Full stack trace capture for errors
- Pretty-formatted summaries of reports with emoji, Unicode, and colour
- Benchmark how long tests run for with your own time source

## Usage

Require `tiniest` in any runtime you like, then use its functions:

```Lua
local tiniest = require("@lib/tiniest")

local function my_test_suite()
	local describe = tiniest.describe
	local test = tiniest.test

	describe("some cool features", function()
		test("it works", function()
			assert(2 + 2 == 4)
		end)
	end)
end

local tests = tiniest.collect_tests(my_test_suite)
local results = tiniest.run_tests(tests, { get_time = os.clock })
print(tiniest.pretty_report(results))
```

## Output

> *🎨 These examples come with colour - try it in your terminal!*

The above example generates a report like this and prints it to stdout:

```
══════════════════════════════ Status of 1 test(s) ═════════════════════════════

✅ some cool features ▸ it works

═════════════════════════ 1 passed in 0.31µs, 0 failed ═════════════════════════
```

Failures look like this:

```
═════════════════════════════ Errors from 1 test(s) ════════════════════════════

❌ some cool features ▸ it works
[string "test/test_main"]:9: assertion failed!
[string "test/test_main"]:9
[string "tiniest.luau"]:64 function with_root_context
[string "tiniest.luau"]:140
[string "tiniest.luau"]:137 function run_tests
[string "test/test_main"]:15


══════════════════════════════ Status of 1 test(s) ═════════════════════════════     

❌ some cool features ▸ it works

═══════════════════════════ 0 passed in 0µs, 1 failed ══════════════════════════
```

## Contributions and maintenance

This is [a certified Daniel P H Fox Side Project™](https://fluff.blog/2024/04/10/i-dont-want-to-be-a-maintainer.html), which I am sharing because I personally wanted it to exist in the world. I might maintain it. I might not.
Contributions are welcome, but I do not make guarantees about those either.

Feel free to use `tiniest`, but if you're about to depend on it big time, the security audit's on you. If, for whatever reason, you end up in a spot of bother, you should probably not have used a random project from someone's GitHub without inspecting what it does properly. I take no responsibility for that.
