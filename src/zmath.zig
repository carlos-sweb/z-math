const std = @import("std");

// Constants (ECMA-262 Math.* value properties).
pub const PI: f64 = std.math.pi;
pub const E: f64 = std.math.e;
pub const LN10: f64 = std.math.ln10;
pub const LN2: f64 = std.math.ln2;
pub const LOG10E: f64 = std.math.log10e;
pub const LOG2E: f64 = std.math.log2e;
pub const SQRT1_2: f64 = std.math.sqrt1_2;
pub const SQRT2: f64 = std.math.sqrt2;

/// Mirrors spec IsIntegralNumber: finite AND trunc(x) == x. `@trunc` alone
/// isn't enough -- `@trunc(Infinity) == Infinity` holds in IEEE754, so a
/// bare truncation check wrongly calls +-Infinity "integral" (spec
/// explicitly excludes it). Caught via pow()'s isOddInteger(exponent)
/// call misfiring when BOTH base and exponent are infinite (e.g.
/// pow(-Infinity, +Infinity) took the odd-integer branch and returned
/// -Infinity instead of the correct +Infinity) -- confirmed against real
/// Node before fixing.
fn isInteger(x: f64) bool {
    return std.math.isFinite(x) and @trunc(x) == x;
}

fn isOddInteger(x: f64) bool {
    if (!isInteger(x)) return false;
    return @mod(x, 2.0) != 0;
}

/// Math.round() - rounds half toward +Infinity, unlike @round()/std.math.round
/// which round half away from zero (round(-0.5) === -1 in Zig, but JS's
/// Math.round(-0.5) === -0). Verified the divergence by compiling a probe
/// before writing this.
///
/// Deliberately NOT `@floor(x + 0.5)`: that naive form loses precision near
/// a .5 boundary -- `x + 0.5` can itself round up to the next representable
/// double before `@floor` ever runs (e.g. `x = 0.5 - Number.EPSILON/4`
/// computes `x + 0.5` as exactly `1.0`, giving round(x) == 1 instead of the
/// correct 0; confirmed against real Node, and test262 catches exactly
/// this). Comparing `x - floor(x)` against 0.5 instead avoids adding two
/// close-in-magnitude values, so it doesn't manufacture that extra ULP.
pub fn round(x: f64) f64 {
    if (std.math.isNan(x) or std.math.isInf(x) or x == 0) return x;
    if (x < 0 and x >= -0.5) return -0.0;
    const f = @floor(x);
    const diff = x - f;
    return if (diff >= 0.5) f + 1 else f;
}

/// Math.trunc() - truncate toward zero. Matches @trunc() bit-for-bit
/// (including sign of a zero result), no spec divergence here.
pub fn trunc(x: f64) f64 {
    return @trunc(x);
}

pub fn floor(x: f64) f64 {
    return @floor(x);
}

pub fn ceil(x: f64) f64 {
    return @ceil(x);
}

pub fn abs(x: f64) f64 {
    return @abs(x);
}

/// Math.sign() - preserves the sign of zero (sign(-0) === -0) and propagates
/// NaN; @max/@min-based tricks would not preserve this, so it's written
/// directly.
pub fn sign(x: f64) f64 {
    if (std.math.isNan(x)) return x;
    if (x > 0) return 1.0;
    if (x < 0) return -1.0;
    return x;
}

fn numGreater(a: f64, b: f64) bool {
    if (a > b) return true;
    if (a == b and a == 0) return !std.math.signbit(a) and std.math.signbit(b);
    return false;
}

fn numLess(a: f64, b: f64) bool {
    if (a < b) return true;
    if (a == b and a == 0) return std.math.signbit(a) and !std.math.signbit(b);
    return false;
}

/// Math.max() - NaN-poisoning variadic reduce. @max()/std.math.max() ignore
/// NaN operands (matching Zig's own semantics, not JS's); Math.max(NaN, 1)
/// must be NaN. Also chooses +0 over -0, per spec.
pub fn max(values: []const f64) f64 {
    if (values.len == 0) return -std.math.inf(f64);
    var result = values[0];
    for (values[1..]) |v| {
        if (std.math.isNan(v) or std.math.isNan(result)) return std.math.nan(f64);
        if (numGreater(v, result)) result = v;
    }
    return result;
}

/// Math.min() - see max(). Chooses -0 over +0, per spec.
pub fn min(values: []const f64) f64 {
    if (values.len == 0) return std.math.inf(f64);
    var result = values[0];
    for (values[1..]) |v| {
        if (std.math.isNan(v) or std.math.isNan(result)) return std.math.nan(f64);
        if (numLess(v, result)) result = v;
    }
    return result;
}

fn toUint32(x: f64) u32 {
    if (std.math.isNan(x) or std.math.isInf(x) or x == 0) return 0;
    const t = @trunc(x);
    // @mod's result takes the sign of the (positive) divisor, i.e. lands in
    // [0, 2^32) even for negative t -- exactly ToUint32's "modulo 2^32" step.
    const m = @mod(t, 4294967296.0);
    return @intFromFloat(m);
}

fn toInt32(x: f64) i32 {
    return @bitCast(toUint32(x));
}

/// Math.imul() - ToInt32 both operands, 32-bit wrapping signed multiply.
pub fn imul(a: f64, b: f64) f64 {
    const ia = toInt32(a);
    const ib = toInt32(b);
    const result = ia *% ib;
    return @floatFromInt(result);
}

/// Math.clz32() - ToUint32, then count leading zero bits (clz32(0) === 32).
pub fn clz32(x: f64) f64 {
    const u = toUint32(x);
    return @floatFromInt(@clz(u));
}

pub fn sqrt(x: f64) f64 {
    return @sqrt(x);
}

pub fn cbrt(x: f64) f64 {
    return std.math.cbrt(x);
}

pub fn exp(x: f64) f64 {
    return @exp(x);
}

pub fn expm1(x: f64) f64 {
    return std.math.expm1(x);
}

pub fn log(x: f64) f64 {
    return @log(x);
}

pub fn log2(x: f64) f64 {
    return std.math.log2(x);
}

pub fn log10(x: f64) f64 {
    return std.math.log10(x);
}

pub fn log1p(x: f64) f64 {
    return std.math.log1p(x);
}

pub fn sin(x: f64) f64 {
    return @sin(x);
}

pub fn cos(x: f64) f64 {
    return @cos(x);
}

pub fn tan(x: f64) f64 {
    return @tan(x);
}

pub fn asin(x: f64) f64 {
    return std.math.asin(x);
}

pub fn acos(x: f64) f64 {
    return std.math.acos(x);
}

pub fn atan(x: f64) f64 {
    return std.math.atan(x);
}

pub fn atan2(y: f64, x: f64) f64 {
    return std.math.atan2(y, x);
}

pub fn sinh(x: f64) f64 {
    return std.math.sinh(x);
}

pub fn cosh(x: f64) f64 {
    return std.math.cosh(x);
}

pub fn tanh(x: f64) f64 {
    return std.math.tanh(x);
}

pub fn asinh(x: f64) f64 {
    return std.math.asinh(x);
}

pub fn acosh(x: f64) f64 {
    return std.math.acosh(x);
}

pub fn atanh(x: f64) f64 {
    return std.math.atanh(x);
}

/// Math.hypot() - variadic; ECMA order of special cases matters: an
/// Infinity argument wins over a NaN argument anywhere else in the list.
pub fn hypot(values: []const f64) f64 {
    for (values) |v| {
        if (std.math.isInf(v)) return std.math.inf(f64);
    }
    for (values) |v| {
        if (std.math.isNan(v)) return std.math.nan(f64);
    }
    var sum: f64 = 0;
    for (values) |v| sum += v * v;
    return @sqrt(sum);
}

/// Math.fround() - round-trip through f32 to snap to the nearest
/// single-precision value.
pub fn fround(x: f64) f64 {
    const f: f32 = @floatCast(x);
    return @floatCast(f);
}

/// Math.f16round() -- rounds to the nearest f64 representable exactly as
/// IEEE 754 binary16, same shape as fround()'s f32 rounding. Verified
/// value-by-value against real Node (v26, the first version available
/// here with Math.f16round -- v22 doesn't have it yet) across normal,
/// subnormal, boundary (65504 max finite, 65520 rounds to Infinity),
/// signed-zero, and NaN/Infinity inputs before trusting @floatCast alone:
/// every case matched bit-for-bit, including -0 staying -0.
pub fn f16round(x: f64) f64 {
    const h: f16 = @floatCast(x);
    return @floatCast(h);
}

/// Math.pow() / the `**` operator's Number::exponentiate algorithm.
/// Deliberately NOT a thin wrap over std.math.pow(): that function follows
/// C99/IEEE754-2008 special cases (e.g. pow(1, Infinity) == 1), but
/// ECMA-262 Number::exponentiate checks the exponent for NaN/Infinity
/// *before* looking at the base, giving different results for several
/// edge cases -- most notably pow(1, Infinity) must be NaN in JS, not 1.
pub fn pow(base: f64, exponent: f64) f64 {
    if (std.math.isNan(exponent)) return std.math.nan(f64);
    if (exponent == 0) return 1.0;
    if (std.math.isNan(base)) return std.math.nan(f64);

    if (std.math.isInf(base)) {
        const positive_base = base > 0;
        if (positive_base) {
            return if (exponent > 0) std.math.inf(f64) else 0.0;
        }
        const exponent_is_odd_integer = isOddInteger(exponent);
        if (exponent > 0) {
            return if (exponent_is_odd_integer) -std.math.inf(f64) else std.math.inf(f64);
        }
        return if (exponent_is_odd_integer) -0.0 else 0.0;
    }

    if (base == 0) {
        const positive_zero_base = !std.math.signbit(base);
        if (positive_zero_base) {
            return if (exponent > 0) 0.0 else std.math.inf(f64);
        }
        const exponent_is_odd_integer = isOddInteger(exponent);
        if (exponent > 0) {
            return if (exponent_is_odd_integer) -0.0 else 0.0;
        }
        return if (exponent_is_odd_integer) -std.math.inf(f64) else std.math.inf(f64);
    }

    if (std.math.isInf(exponent)) {
        const abs_base = @abs(base);
        if (abs_base == 1.0) return std.math.nan(f64);
        if (exponent > 0) {
            return if (abs_base > 1.0) std.math.inf(f64) else 0.0;
        }
        return if (abs_base > 1.0) 0.0 else std.math.inf(f64);
    }

    if (base < 0 and !isInteger(exponent)) return std.math.nan(f64);

    return std.math.pow(f64, base, exponent);
}

/// Math.random() - takes an injected std.Random, same convention as
/// ZArray.shuffle(random): no hidden global RNG state anywhere in the
/// z-* ecosystem. Range [0, 1).
pub fn random(rand: std.Random) f64 {
    return rand.float(f64);
}

/// Math.sumPrecise(values) -- ES2025's correctly-rounded summation:
/// the result must be the f64 nearest the EXACT mathematical sum of
/// `values` (finite ones only -- NaN/+-Infinity/all-minus-zero are
/// each their own special case, handled by the caller via `state`
/// tracking before any of these finite values reach this function;
/// see math_builtins.zig's mathSumPrecise).
///
/// A faithful, structure-preserving port of the official TC39
/// reference polyfill (Shewchuk's exact-floating-point-summation
/// algorithm, extended to survive intermediate overflow via a
/// "biased partial" representing 2**1024 times its value):
/// https://github.com/tc39/proposal-math-sum/blob/main/polyfill/polyfill.mjs
/// No live Node in this environment ships Math.sumPrecise yet
/// (Stage 3, confirmed absent from the newest available build) to
/// verify against directly -- instead verified against test262's own
/// `test/built-ins/Math/sumPrecise/sum.js`, whose assertions are
/// "chosen for having exercised bugs in real implementations": all
/// pass bit-for-bit, including every overflow/cancellation case.
const MAX_DOUBLE: f64 = 1.79769313486231570815e+308;
const PENULTIMATE_DOUBLE: f64 = 1.79769313486231550856e+308;
const MAX_ULP: f64 = MAX_DOUBLE - PENULTIMATE_DOUBLE;
const TWO_POW_1023: f64 = 8.98846567431158e+307;

const TwoSum = struct { hi: f64, lo: f64 };

/// Error-free transform of x+y into an exact (hi, lo) pair: hi is the
/// rounded sum, lo is the exact rounding error (hi+lo == x+y exactly,
/// as real numbers). Precondition: abs(x) >= abs(y).
fn twosum(x: f64, y: f64) TwoSum {
    const hi = x + y;
    const lo = y - (hi - x);
    return .{ .hi = hi, .lo = lo };
}

pub const SumPreciseError = error{ Overflow, OutOfMemory };

/// `values` must contain ONLY finite f64s (no NaN/+-Infinity -- the
/// caller has already special-cased those). Real -0 entries are
/// harmless (a no-op in exact summation) but the caller may filter
/// them; either way this returns +0/-0 correctly per the exact sum's
/// own sign.
pub fn sumPrecise(allocator: std.mem.Allocator, values: []const f64) SumPreciseError!f64 {
    if (values.len == 0) return 0.0;
    var partials: std.ArrayList(f64) = .empty;
    defer partials.deinit(allocator);
    var overflow: f64 = 0;

    try partials.append(allocator, values[0]);
    for (values[1..]) |value| {
        var x = value;
        var i: usize = 0;
        for (partials.items) |y_in| {
            var y = y_in;
            if (@abs(x) < @abs(y)) {
                const t = x;
                x = y;
                y = t;
            }
            var r = twosum(x, y);
            if (@abs(r.hi) == std.math.inf(f64)) {
                const hi_sign: f64 = if (r.hi == std.math.inf(f64)) 1 else -1;
                overflow += hi_sign;
                if (@abs(overflow) >= 9007199254740992.0) return error.Overflow;
                x = (x - hi_sign * TWO_POW_1023) - hi_sign * TWO_POW_1023;
                if (@abs(x) < @abs(y)) {
                    const t = x;
                    x = y;
                    y = t;
                }
                r = twosum(x, y);
            }
            if (r.lo != 0) {
                partials.items[i] = r.lo;
                i += 1;
            }
            x = r.hi;
        }
        partials.items.len = i;
        if (x != 0) try partials.append(allocator, x);
    }

    // Compute the exact sum of partials, stopping once precision is lost.
    var n: isize = @as(isize, @intCast(partials.items.len)) - 1;
    var hi: f64 = 0;
    var lo: f64 = 0;

    if (overflow != 0) {
        const next: f64 = if (n >= 0) partials.items[@intCast(n)] else 0;
        n -= 1;
        if (@abs(overflow) > 1 or (overflow > 0 and next > 0) or (overflow < 0 and next < 0)) {
            return if (overflow > 0) std.math.inf(f64) else -std.math.inf(f64);
        }
        const r = twosum(overflow * TWO_POW_1023, next / 2);
        hi = r.hi;
        lo = r.lo * 2;
        if (@abs(2 * hi) == std.math.inf(f64)) {
            // MAX_DOUBLE has a 1 in its last significand bit, so
            // subtracting exactly half a ULP from 2**1024 rounds AWAY
            // from it (to Infinity) under ties-to-even -- unless the
            // next partial's sign says round toward MAX_DOUBLE instead.
            if (hi > 0) {
                if (hi == TWO_POW_1023 and lo == -(MAX_ULP / 2) and n >= 0 and partials.items[@intCast(n)] < 0) return MAX_DOUBLE;
                return std.math.inf(f64);
            } else {
                if (hi == -TWO_POW_1023 and lo == (MAX_ULP / 2) and n >= 0 and partials.items[@intCast(n)] > 0) return -MAX_DOUBLE;
                return -std.math.inf(f64);
            }
        }
        if (lo != 0) {
            n += 1;
            if (n >= 0 and @as(usize, @intCast(n)) < partials.items.len) {
                partials.items[@intCast(n)] = lo;
            } else {
                try partials.append(allocator, lo);
            }
            lo = 0;
        }
        hi *= 2;
    }

    while (n >= 0) {
        const x = hi;
        const y = partials.items[@intCast(n)];
        n -= 1;
        const r = twosum(x, y);
        hi = r.hi;
        lo = r.lo;
        if (lo != 0) break;
    }

    // Half-even rounding needs one more partial to break a tie: e.g.
    // sum([1e-16, 1, 1e16]) must round the last digit up to 2, not
    // down to 0, because the 1e-16 nudges 1 slightly closer to 2.
    if (n >= 0 and ((lo < 0.0 and partials.items[@intCast(n)] < 0.0) or (lo > 0.0 and partials.items[@intCast(n)] > 0.0))) {
        const y2 = lo * 2.0;
        const x2 = hi + y2;
        const yr2 = x2 - hi;
        if (y2 == yr2) hi = x2;
    }

    return hi;
}

test "sumPrecise matches test262's own bug-triggering assertions" {
    const a = std.testing.allocator;
    const eq = std.testing.expectEqual;
    try eq(@as(f64, 6), try sumPrecise(a, &.{ 1, 2, 3 }));
    try eq(@as(f64, 1e308), try sumPrecise(a, &.{1e308}));
    try eq(@as(f64, 0), try sumPrecise(a, &.{ 1e308, -1e308 }));
    try eq(@as(f64, 0.30000000000000004), try sumPrecise(a, &.{ 1e308, 1e308, 0.1, 0.1, 1e30, 0.1, -1e30, -1e308, -1e308 }));
    try eq(@as(f64, 9.9792015476736e+291), try sumPrecise(a, &.{ 8.98846567431158e+307, 8.988465674311579e+307, -1.7976931348623157e+308 }));
    try eq(-std.math.inf(f64), try sumPrecise(a, &.{ 0.31150493246968836, -8.988465674311582e+307, 1.8315037361673755e-270, -15.999999999999996, 2.9999999999999996, 7.345200721499384e+164, -2.033582473639399, -8.98846567431158e+307, -3.5737295155405993e+292, 4.13894772383715e-124, -3.6111186457260667e-35, 2.387234887098013e+180, 7.645295562778372e-298, 3.395189016861822e-103, -2.6331611115768973e-149 }));
    try eq(std.math.inf(f64), try sumPrecise(a, &.{ 8.98846567431158e+307, 8.98846567431158e+307 }));
    try eq(@as(f64, -0.0), try sumPrecise(a, &.{ -0.0, -0.0 }));
    try eq(@as(f64, 0), try sumPrecise(a, &.{}));
}

test "round matches JS Math.round, not std.math.round" {
    try std.testing.expectEqual(@as(f64, -0.0), round(-0.5));
    try std.testing.expect(std.math.signbit(round(-0.5)));
    try std.testing.expectEqual(@as(f64, 1.0), round(0.5));
    try std.testing.expectEqual(@as(f64, 3.0), round(2.5));
    try std.testing.expectEqual(@as(f64, -2.0), round(-2.5));
    try std.testing.expectEqual(@as(f64, -1.0), round(-1.5));
    try std.testing.expect(std.math.isNan(round(std.math.nan(f64))));
    try std.testing.expectEqual(std.math.inf(f64), round(std.math.inf(f64)));
}

test "max/min propagate NaN and prefer +0/-0 correctly" {
    try std.testing.expect(std.math.isNan(max(&.{ std.math.nan(f64), 1.0 })));
    try std.testing.expect(std.math.isNan(min(&.{ 1.0, std.math.nan(f64) })));
    try std.testing.expectEqual(@as(f64, -std.math.inf(f64)), max(&.{}));
    try std.testing.expectEqual(@as(f64, std.math.inf(f64)), min(&.{}));

    const maxed = max(&.{ -0.0, 0.0 });
    try std.testing.expect(!std.math.signbit(maxed));
    const mined = min(&.{ -0.0, 0.0 });
    try std.testing.expect(std.math.signbit(mined));
}

test "sign preserves signed zero and propagates NaN" {
    try std.testing.expect(std.math.isNan(sign(std.math.nan(f64))));
    try std.testing.expectEqual(@as(f64, 1.0), sign(5.0));
    try std.testing.expectEqual(@as(f64, -1.0), sign(-5.0));
    try std.testing.expect(std.math.signbit(sign(-0.0)));
    try std.testing.expect(!std.math.signbit(sign(0.0)));
}

test "imul wraps like 32-bit signed multiplication" {
    try std.testing.expectEqual(@as(f64, -15.0), imul(3, -5));
    try std.testing.expectEqual(@as(f64, -8.0), imul(0xffffffff, 8)); // 0xffffffff as int32 is -1
}

test "clz32 counts leading zero bits, clz32(0) === 32" {
    try std.testing.expectEqual(@as(f64, 32.0), clz32(0));
    try std.testing.expectEqual(@as(f64, 1.0), clz32(1 << 30));
    try std.testing.expectEqual(@as(f64, 0.0), clz32(0xffffffff));
}

test "pow follows ECMA Number::exponentiate, not C99 pow" {
    // The classic divergence: C99 pow(1, Infinity) == 1, JS Math.pow(1, Infinity) is NaN.
    try std.testing.expect(std.math.isNan(pow(1.0, std.math.inf(f64))));
    try std.testing.expect(std.math.isNan(pow(-1.0, std.math.inf(f64))));
    try std.testing.expect(std.math.isNan(pow(1.0, std.math.nan(f64))));
    try std.testing.expectEqual(@as(f64, 1.0), pow(std.math.nan(f64), 0.0));
    try std.testing.expectEqual(@as(f64, 1.0), pow(std.math.nan(f64), -0.0));
    try std.testing.expect(std.math.isNan(pow(-2.0, 0.5)));
    try std.testing.expectEqual(@as(f64, 8.0), pow(2.0, 3.0));
    try std.testing.expectEqual(@as(f64, 0.25), pow(2.0, -2.0));
    try std.testing.expectEqual(std.math.inf(f64), pow(2.0, std.math.inf(f64)));
    try std.testing.expectEqual(@as(f64, 0.0), pow(0.5, std.math.inf(f64)));
}

test "hypot: an Infinity argument wins over a NaN argument" {
    try std.testing.expectEqual(std.math.inf(f64), hypot(&.{ std.math.inf(f64), std.math.nan(f64) }));
    try std.testing.expect(std.math.isNan(hypot(&.{ 1.0, std.math.nan(f64) })));
    try std.testing.expectEqual(@as(f64, 5.0), hypot(&.{ 3.0, 4.0 }));
}

test "fround snaps to nearest f32 value" {
    const x: f64 = 1.1;
    const rounded = fround(x);
    try std.testing.expect(rounded != x);
    try std.testing.expectEqual(@as(f32, 1.1), @as(f32, @floatCast(rounded)));
}

test "trig/log/hyperbolic functions propagate NaN" {
    const nan = std.math.nan(f64);
    try std.testing.expect(std.math.isNan(sin(nan)));
    try std.testing.expect(std.math.isNan(log(-1.0)));
    try std.testing.expect(std.math.isNan(asin(2.0)));
    try std.testing.expect(std.math.isNan(acosh(0.0)));
}

test "random(rand) stays within [0, 1)" {
    var prng = std.Random.DefaultPrng.init(42);
    const rand = prng.random();
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const r = random(rand);
        try std.testing.expect(r >= 0.0 and r < 1.0);
    }
}

test "constants match std.math" {
    try std.testing.expectEqual(std.math.pi, PI);
    try std.testing.expectEqual(std.math.e, E);
}
