# Z-Math

[![Zig Version](https://img.shields.io/badge/zig-0.16-orange.svg)](https://ziglang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

ECMAScript-compatible **Math** namespace in Zig 0.16, part of the [z-*](https://github.com/carlos-sweb) micro-library ecosystem.

## Why a separate library

`Math` isn't an instantiable JS type — there's no "a Math value," just a namespace of static functions over `f64`. So unlike z-array/z-object/z-map/z-set/z-symbol/z-error, this library has **no `JSValue` variant to wire into z-value**: it's meant to be called directly wherever an interpreter evaluates a `Math.foo(...)` call.

## Design

Most functions are thin wraps over `std.math` or Zig float builtins (`@sin`, `@sqrt`, etc.), verified one-by-one against their ECMA-262 spec algorithm rather than assumed identical. A few genuinely diverge from their `std.math`/libm counterparts and are implemented directly:

- **`round(x)`** — rounds half toward **+Infinity** (`round(-0.5) === -0`, `round(-1.5) === -1`). `@round()`/`std.math.round()` round half **away from zero** instead (`round(-0.5) == -1`), which is wrong for JS.
- **`max(values)` / `min(values)`** — NaN-poisoning variadic reduce (`Math.max(NaN, 1) === NaN`). `@max`/`@min`/`std.math.max` silently drop NaN operands instead. Also resolve `+0`/`-0` ties per spec (`max` prefers `+0`, `min` prefers `-0`).
- **`pow(base, exponent)`** — implements ECMA-262's `Number::exponentiate` directly rather than wrapping `std.math.pow` (C99/IEEE754-2008 semantics). They disagree on several edge cases, most notably: `Math.pow(1, Infinity)` is `NaN` in JS, but `1` under C99 pow — the exponent's NaN/Infinity is checked *before* the base in the JS algorithm.
- **`sign(x)`** — preserves the sign of a zero result (`sign(-0) === -0`) and propagates NaN.
- **`imul(a, b)`** — `ToInt32` both operands (wrapping to the 32-bit signed range), then a wrapping 32-bit multiply.
- **`clz32(x)`** — `ToUint32`, then count leading zero bits (`clz32(0) === 32`).
- **`hypot(values)`** — variadic; an `Infinity` argument anywhere in the list wins over a `NaN` argument anywhere else, per spec ordering.
- **`random(rand: std.Random)`** — takes an injected RNG, same convention as `ZArray.shuffle(random)` elsewhere in the ecosystem: no hidden global RNG state.

Everything else (`abs`, `floor`, `ceil`, `trunc`, `sqrt`, `cbrt`, `exp`, `expm1`, `log`, `log2`, `log10`, `log1p`, `sin`/`cos`/`tan` and their inverse/hyperbolic variants, `atan2`, `fround`) is a direct wrap, confirmed to already agree with the corresponding `std.math`/builtin behavior for NaN/Infinity edge cases.

## Usage

```zig
const zmath = @import("zmath");

zmath.round(-0.5);              // -0
zmath.max(&.{ 1.0, std.math.nan(f64) }); // NaN
zmath.pow(1.0, std.math.inf(f64));       // NaN, not 1

var prng = std.Random.DefaultPrng.init(seed);
const r = zmath.random(prng.random()); // [0, 1)
```

## Testing

```bash
zig build test
```

## License

MIT
