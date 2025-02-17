use dep::protocol_types::{
    constants::GENERATOR_INDEX__SYMMETRIC_KEY, grumpkin_private_key::GrumpkinPrivateKey,
    grumpkin_point::GrumpkinPoint, utils::arr_copy_slice
};
use dep::std::{hash::sha256, embedded_curve_ops::{EmbeddedCurvePoint, EmbeddedCurveScalar, multi_scalar_mul}};

// TODO(#5726): This function is called deriveAESSecret in TS. I don't like point_to_symmetric_key name much since
// point is not the only input of the function. Unify naming with TS once we have a better name.
pub fn point_to_symmetric_key(secret: GrumpkinPrivateKey, point: GrumpkinPoint) -> [u8; 32] {
    let shared_secret_fields = multi_scalar_mul(
        [EmbeddedCurvePoint { x: point.x, y: point.y, is_infinite: false }],
        [EmbeddedCurveScalar { lo: secret.low, hi: secret.high }]
    );
    // TODO(https://github.com/AztecProtocol/aztec-packages/issues/6061): make the func return Point struct directly
    let shared_secret = GrumpkinPoint::new(shared_secret_fields[0], shared_secret_fields[1]);
    let mut shared_secret_bytes_with_separator = [0 as u8; 65];
    shared_secret_bytes_with_separator = arr_copy_slice(shared_secret.to_be_bytes(), shared_secret_bytes_with_separator, 0);
    shared_secret_bytes_with_separator[64] = GENERATOR_INDEX__SYMMETRIC_KEY;
    sha256(shared_secret_bytes_with_separator)
}

#[test]
fn check_point_to_symmetric_key() {
    // Value taken from "derive shared secret" test in encrypt_buffer.test.ts
    let secret = GrumpkinPrivateKey::new(
        0x0000000000000000000000000000000023b3127c127b1f29a7adff5cccf8fb06,
        0x00000000000000000000000000000000649e7ca01d9de27b21624098b897babd
    );
    let point = GrumpkinPoint::new(
        0x2688431c705a5ff3e6c6f2573c9e3ba1c1026d2251d0dbbf2d810aa53fd1d186,
        0x1e96887b117afca01c00468264f4f80b5bb16d94c1808a448595f115556e5c8e
    );

    let key = point_to_symmetric_key(secret, point);
    // The following value gets updated when running encrypt_buffer.test.ts with AZTEC_GENERATE_TEST_DATA=1
    let expected_key = [
        198, 74, 242, 51, 177, 36, 183, 8, 2, 246, 197, 138, 59, 166, 86, 96, 155, 50, 186, 34, 242, 3, 208, 144, 161, 64, 69, 165, 70, 57, 226, 139
    ];
    assert_eq(key, expected_key);
}
