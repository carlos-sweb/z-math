const std = @import("std");
const testing = std.testing;
const zmath = @import("zmath");

test "abs/floor/ceil/trunc basic sanity" {
    try testing.expectEqual(@as(f64, 3.0), zmath.abs(-3.0));
    try testing.expectEqual(@as(f64, -2.0), zmath.floor(-1.5));
    try testing.expectEqual(@as(f64, -1.0), zmath.ceil(-1.5));
    try testing.expectEqual(@as(f64, -1.0), zmath.trunc(-1.5));
}

test "sqrt/cbrt/exp/log inverse relationships" {
    try testing.expectApproxEqAbs(@as(f64, 3.0), zmath.sqrt(9.0), 1e-12);
    try testing.expectApproxEqAbs(@as(f64, 2.0), zmath.cbrt(8.0), 1e-12);
    try testing.expectApproxEqAbs(@as(f64, 1.0), zmath.log(zmath.E), 1e-12);
}

test "atan2 matches quadrant expectations" {
    try testing.expectApproxEqAbs(zmath.PI / 2.0, zmath.atan2(1.0, 0.0), 1e-12);
}

test "sign/round/max/min end-to-end through the public API" {
    try testing.expectEqual(@as(f64, 1.0), zmath.sign(42.0));
    try testing.expectEqual(@as(f64, 4.0), zmath.max(&.{ 1.0, 4.0, -9.0 }));
    try testing.expectEqual(@as(f64, -9.0), zmath.min(&.{ 1.0, 4.0, -9.0 }));
    try testing.expectEqual(@as(f64, 2.0), zmath.round(1.5));
}
