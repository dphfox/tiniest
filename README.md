<h1>
	<img src="github/logo.svg" alt="tiniest">
</h1>

`tiniest` is a collection of minimal, portable testing libraries for Luau,
built on a few principles:

- Simple, idiomatic Luau throughout.
- Zero external dependencies.
- Minimal internal dependencies.
- Runtime independence.
- No opinions about project structure.

## Features

- `test()` and `describe()` callbacks
- Clean, correctly-cropped stack traces
- Declarative `expect()` API with line numbers and code visualisation
- Pretty-formatted summaries of reports with emoji, Unicode, and colour
- Benchmark how long tests run for

### Planned

- Snapshots with your own serialiser
- Test discovery with your own IO system

## Usage

Require `tiniest` in any runtime you like, then use its functions:

```Lua
--!strict

local tiniest = require("@tiniest").configure({
	external = {
		get_timestamp = os.clock
	}
}) 
local tiniest_pretty = require("@tiniest_pretty").configure({})
local tiniest_expect = require("@tiniest_expect")

local function my_test_suite()
	local describe = tiniest.describe
	local test = tiniest.test
	local expect = tiniest_expect.expect

	describe("some cool features", function()
		test("it works", function()
			expect(2 + 2).is(4)
		end)
	end)
end

local tests = tiniest.collect_tests(my_test_suite)
local results = tiniest.run_tests(tests)
print(tiniest_pretty.format(results))
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
Expectation not met
   │
18 │ expect(4).is(5)
   │
[string "test/test_main"]:18

══════════════════════════════ Status of 1 test(s) ═════════════════════════════

❌ some cool features ▸ it works

═══════════════════════════ 0 passed in 0µs, 1 failed ══════════════════════════
```

## Contributions and maintenance

This is [a certified Daniel P H Fox Side Project™](https://fluff.blog/2024/04/10/i-dont-want-to-be-a-maintainer.html), which I am sharing because I personally wanted it to exist in the world. I might maintain it. I might not.
Contributions are welcome, but I do not make guarantees about those either.

Feel free to use `tiniest`, but if you're about to depend on it big time, the security audit's on you. If, for whatever reason, you end up in a spot of bother, you should probably not have used a random project from someone's GitHub without inspecting what it does properly. I take no responsibility for that.
