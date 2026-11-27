// The Gauss coefficients of the World Magnetic Model 2025 (WMM2025).
//
// Transcribed by a script from the official coefficient file, token for
// token. Do not edit a number by hand: `magnetic_field_test.dart` writes the
// table back out in the file's own layout and checks its SHA-256.
//
// Source file: WMM.COF (the same bytes as WMM2025.COF) in WMM2025COF.zip,
//   https://www.ncei.noaa.gov/sites/default/files/2024-12/WMM2025COF.zip
//   linked from https://www.ncei.noaa.gov/products/world-magnetic-model
// Fetched: 2026-11-27
// Header line: "    2025.0            WMM-2025     11/13/2024"
// Epoch: 2025.0. Valid from 2025.0 to 2030.0.
// SHA-256 of WMM.COF:
//   dfa8597825af4e0b87ff4198a5b4fb661b3c49f4cd090cd0164e0259b075582f
// SHA-256 of WMM2025COF.zip:
//   2e76569370d081f2cd7919490218bd094ca9afde347b198eff5621e0af460d03
// Made by NOAA's National Centers for Environmental Information (NCEI) and
// the British Geological Survey (BGS) for the US National
// Geospatial-Intelligence Agency and the UK Defence Geographic Centre.
// Licence: public domain. NCEI says: "The WMM source code is in the public
// domain and not licensed or under copyright. The information and software
// may be used freely by the public." The numbers below are material produced
// by US Government agencies, which is not subject to copyright protection
// (17 U.S.C. 403).
//
// Provenance, and how to replace this table with the next model:
// `docs/QIBLA_SOURCES.md`.

/// One line of the coefficient file: the Gauss coefficients of degree [n] and
/// order [m] at the model's epoch, in nanotesla, and how much each changes in
/// a year.
class GaussCoefficient {
  /// Creates a line, in the order the file prints it.
  const GaussCoefficient(this.n, this.m, this.g, this.h, this.gDot, this.hDot);

  /// The degree, 1 to 12.
  final int n;

  /// The order, 0 to [n].
  final int m;

  /// The cosine coefficient at the epoch, in nanotesla.
  final double g;

  /// The sine coefficient at the epoch, in nanotesla.
  final double h;

  /// The yearly change of [g], in nanotesla a year.
  final double gDot;

  /// The yearly change of [h], in nanotesla a year.
  final double hDot;
}

/// The year the coefficients are given for, as a decimal year.
///
/// WMM2025 is made for 2025.0 to 2030.0. A new model comes out every five
/// years; its successor (WMM2030) is due at the end of 2029: replace this
/// table then.
const double wmm2025Epoch = 2025.0;

/// The highest degree in [wmm2025Coefficients].
const int wmm2025Degree = 12;

/// The lines of `WMM.COF`, in the file's order: degree 1 to
/// [wmm2025Degree], and within a degree order 0 to that degree. The line of
/// degree n and order m is at index n (n + 1) / 2 + m - 1.
const List<GaussCoefficient> wmm2025Coefficients = [
  GaussCoefficient(1, 0, -29351.8, 0.0, 12.0, 0.0),
  GaussCoefficient(1, 1, -1410.8, 4545.4, 9.7, -21.5),
  GaussCoefficient(2, 0, -2556.6, 0.0, -11.6, 0.0),
  GaussCoefficient(2, 1, 2951.1, -3133.6, -5.2, -27.7),
  GaussCoefficient(2, 2, 1649.3, -815.1, -8.0, -12.1),
  GaussCoefficient(3, 0, 1361.0, 0.0, -1.3, 0.0),
  GaussCoefficient(3, 1, -2404.1, -56.6, -4.2, 4.0),
  GaussCoefficient(3, 2, 1243.8, 237.5, 0.4, -0.3),
  GaussCoefficient(3, 3, 453.6, -549.5, -15.6, -4.1),
  GaussCoefficient(4, 0, 895.0, 0.0, -1.6, 0.0),
  GaussCoefficient(4, 1, 799.5, 278.6, -2.4, -1.1),
  GaussCoefficient(4, 2, 55.7, -133.9, -6.0, 4.1),
  GaussCoefficient(4, 3, -281.1, 212.0, 5.6, 1.6),
  GaussCoefficient(4, 4, 12.1, -375.6, -7.0, -4.4),
  GaussCoefficient(5, 0, -233.2, 0.0, 0.6, 0.0),
  GaussCoefficient(5, 1, 368.9, 45.4, 1.4, -0.5),
  GaussCoefficient(5, 2, 187.2, 220.2, 0.0, 2.2),
  GaussCoefficient(5, 3, -138.7, -122.9, 0.6, 0.4),
  GaussCoefficient(5, 4, -142.0, 43.0, 2.2, 1.7),
  GaussCoefficient(5, 5, 20.9, 106.1, 0.9, 1.9),
  GaussCoefficient(6, 0, 64.4, 0.0, -0.2, 0.0),
  GaussCoefficient(6, 1, 63.8, -18.4, -0.4, 0.3),
  GaussCoefficient(6, 2, 76.9, 16.8, 0.9, -1.6),
  GaussCoefficient(6, 3, -115.7, 48.8, 1.2, -0.4),
  GaussCoefficient(6, 4, -40.9, -59.8, -0.9, 0.9),
  GaussCoefficient(6, 5, 14.9, 10.9, 0.3, 0.7),
  GaussCoefficient(6, 6, -60.7, 72.7, 0.9, 0.9),
  GaussCoefficient(7, 0, 79.5, 0.0, -0.0, 0.0),
  GaussCoefficient(7, 1, -77.0, -48.9, -0.1, 0.6),
  GaussCoefficient(7, 2, -8.8, -14.4, -0.1, 0.5),
  GaussCoefficient(7, 3, 59.3, -1.0, 0.5, -0.8),
  GaussCoefficient(7, 4, 15.8, 23.4, -0.1, 0.0),
  GaussCoefficient(7, 5, 2.5, -7.4, -0.8, -1.0),
  GaussCoefficient(7, 6, -11.1, -25.1, -0.8, 0.6),
  GaussCoefficient(7, 7, 14.2, -2.3, 0.8, -0.2),
  GaussCoefficient(8, 0, 23.2, 0.0, -0.1, 0.0),
  GaussCoefficient(8, 1, 10.8, 7.1, 0.2, -0.2),
  GaussCoefficient(8, 2, -17.5, -12.6, 0.0, 0.5),
  GaussCoefficient(8, 3, 2.0, 11.4, 0.5, -0.4),
  GaussCoefficient(8, 4, -21.7, -9.7, -0.1, 0.4),
  GaussCoefficient(8, 5, 16.9, 12.7, 0.3, -0.5),
  GaussCoefficient(8, 6, 15.0, 0.7, 0.2, -0.6),
  GaussCoefficient(8, 7, -16.8, -5.2, -0.0, 0.3),
  GaussCoefficient(8, 8, 0.9, 3.9, 0.2, 0.2),
  GaussCoefficient(9, 0, 4.6, 0.0, -0.0, 0.0),
  GaussCoefficient(9, 1, 7.8, -24.8, -0.1, -0.3),
  GaussCoefficient(9, 2, 3.0, 12.2, 0.1, 0.3),
  GaussCoefficient(9, 3, -0.2, 8.3, 0.3, -0.3),
  GaussCoefficient(9, 4, -2.5, -3.3, -0.3, 0.3),
  GaussCoefficient(9, 5, -13.1, -5.2, 0.0, 0.2),
  GaussCoefficient(9, 6, 2.4, 7.2, 0.3, -0.1),
  GaussCoefficient(9, 7, 8.6, -0.6, -0.1, -0.2),
  GaussCoefficient(9, 8, -8.7, 0.8, 0.1, 0.4),
  GaussCoefficient(9, 9, -12.9, 10.0, -0.1, 0.1),
  GaussCoefficient(10, 0, -1.3, 0.0, 0.1, 0.0),
  GaussCoefficient(10, 1, -6.4, 3.3, 0.0, 0.0),
  GaussCoefficient(10, 2, 0.2, 0.0, 0.1, -0.0),
  GaussCoefficient(10, 3, 2.0, 2.4, 0.1, -0.2),
  GaussCoefficient(10, 4, -1.0, 5.3, -0.0, 0.1),
  GaussCoefficient(10, 5, -0.6, -9.1, -0.3, -0.1),
  GaussCoefficient(10, 6, -0.9, 0.4, 0.0, 0.1),
  GaussCoefficient(10, 7, 1.5, -4.2, -0.1, 0.0),
  GaussCoefficient(10, 8, 0.9, -3.8, -0.1, -0.1),
  GaussCoefficient(10, 9, -2.7, 0.9, -0.0, 0.2),
  GaussCoefficient(10, 10, -3.9, -9.1, -0.0, -0.0),
  GaussCoefficient(11, 0, 2.9, 0.0, 0.0, 0.0),
  GaussCoefficient(11, 1, -1.5, 0.0, -0.0, -0.0),
  GaussCoefficient(11, 2, -2.5, 2.9, 0.0, 0.1),
  GaussCoefficient(11, 3, 2.4, -0.6, 0.0, -0.0),
  GaussCoefficient(11, 4, -0.6, 0.2, 0.0, 0.1),
  GaussCoefficient(11, 5, -0.1, 0.5, -0.1, -0.0),
  GaussCoefficient(11, 6, -0.6, -0.3, 0.0, -0.0),
  GaussCoefficient(11, 7, -0.1, -1.2, -0.0, 0.1),
  GaussCoefficient(11, 8, 1.1, -1.7, -0.1, -0.0),
  GaussCoefficient(11, 9, -1.0, -2.9, -0.1, 0.0),
  GaussCoefficient(11, 10, -0.2, -1.8, -0.1, 0.0),
  GaussCoefficient(11, 11, 2.6, -2.3, -0.1, 0.0),
  GaussCoefficient(12, 0, -2.0, 0.0, 0.0, 0.0),
  GaussCoefficient(12, 1, -0.2, -1.3, 0.0, -0.0),
  GaussCoefficient(12, 2, 0.3, 0.7, -0.0, 0.0),
  GaussCoefficient(12, 3, 1.2, 1.0, -0.0, -0.1),
  GaussCoefficient(12, 4, -1.3, -1.4, -0.0, 0.1),
  GaussCoefficient(12, 5, 0.6, -0.0, -0.0, -0.0),
  GaussCoefficient(12, 6, 0.6, 0.6, 0.1, -0.0),
  GaussCoefficient(12, 7, 0.5, -0.1, -0.0, -0.0),
  GaussCoefficient(12, 8, -0.1, 0.8, 0.0, 0.0),
  GaussCoefficient(12, 9, -0.4, 0.1, 0.0, -0.0),
  GaussCoefficient(12, 10, -0.2, -1.0, -0.1, -0.0),
  GaussCoefficient(12, 11, -1.3, 0.1, -0.0, 0.0),
  GaussCoefficient(12, 12, -0.7, 0.2, -0.1, -0.1),
];
