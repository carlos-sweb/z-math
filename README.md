# Z-Math

[![Zig Version](https://img.shields.io/badge/zig-0.17.0-orange.svg)](https://ziglang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

ECMAScript-oriented **Math** namespace in Zig 0.17.0, part of the [z-*](https://github.com/carlos-sweb) micro-library ecosystem. Provides all 37 numerical functions and 8 constants from ECMAScript 2026's `Math` API; full semantic conformance is not yet established.

Requires **Zig 0.17.0**. The package's minimum compiler version and the development toolchain are pinned to 0.17.0.

## Why a separate library

`Math` isn't an instantiable JS type — there's no "a Math value," just a namespace of static functions over `f64`. So unlike z-array/z-object/z-map/z-set/z-symbol/z-error, this library has **no `JSValue` variant to wire into z-value**: it's meant to be called directly wherever an interpreter evaluates a `Math.foo(...)` call.

## Design

Most functions are thin wraps over `std.math` or Zig float builtins (`@sin`, `@sqrt`, etc.), with selected ECMA-262 edge cases covered by tests. A few genuinely diverge from their `std.math`/libm counterparts and are implemented directly:

- **`round(x)`** — rounds half toward **+Infinity** (`round(-0.5) === -0`, `round(-1.5) === -1`). `@round()`/`std.math.round()` round half **away from zero** instead (`round(-0.5) == -1`), which is wrong for JS.
- **`max(values)` / `min(values)`** — NaN-poisoning variadic reduce (`Math.max(NaN, 1) === NaN`). `@max`/`@min`/`std.math.max` silently drop NaN operands instead. Also resolve `+0`/`-0` ties per spec (`max` prefers `+0`, `min` prefers `-0`).
- **`pow(base, exponent)`** — implements ECMA-262's `Number::exponentiate` directly rather than wrapping `std.math.pow` (C99/IEEE754-2008 semantics). They disagree on several edge cases, most notably: `Math.pow(1, Infinity)` is `NaN` in JS, but `1` under C99 pow — the exponent's NaN/Infinity is checked *before* the base in the JS algorithm.
- **`sign(x)`** — preserves the sign of a zero result (`sign(-0) === -0`) and propagates NaN.
- **`imul(a, b)`** — `ToInt32` both operands (wrapping to the 32-bit signed range), then a wrapping 32-bit multiply.
- **`clz32(x)`** — `ToUint32`, then count leading zero bits (`clz32(0) === 32`).
- **`hypot(values)`** — variadic; an `Infinity` argument anywhere in the list wins over a `NaN` argument anywhere else, per spec ordering.
- **`random(rand: std.Random)`** — takes an injected RNG, same convention as `ZArray.shuffle(random)` elsewhere in the ecosystem: no hidden global RNG state.

Everything else (`abs`, `floor`, `ceil`, `trunc`, `sqrt`, `cbrt`, `exp`, `expm1`, `log`, `log2`, `log10`, `log1p`, `sin`/`cos`/`tan` and their inverse/hyperbolic variants, `atan2`, `fround`) is a direct wrap, using Zig's corresponding numerical implementation.

## Usage

```zig
const zmath = @import("zmath");
const std = @import("std");

pub fn main() void {
    std.debug.print("round: {d}\n", .{zmath.round(-0.5)}); // -0
    std.debug.print("max: {d}\n", .{zmath.max(&.{ 1.0, std.math.nan(f64) })}); // NaN
    std.debug.print("pow: {d}\n", .{zmath.pow(1.0, std.math.inf(f64))}); // NaN

    var prng = std.Random.DefaultPrng.init(42);
    const r = zmath.random(prng.random()); // [0, 1)
    std.debug.print("random: {d}\n", .{r});
}
```

## Testing

```bash
zig build test
zig build test -Doptimize=ReleaseSafe
```

## API documentation

[Browse the native Zig API documentation](https://carlos-sweb.github.io/z-math/).

Generate the same documentation locally with Zig 0.17.0:

```bash
zig build docs
python3 -m http.server 8000 --directory zig-out/docs
```

Open `http://localhost:8000/`. GitHub Actions builds and publishes the generated API documentation to GitHub Pages on each push to `master`.

## License

MIT
