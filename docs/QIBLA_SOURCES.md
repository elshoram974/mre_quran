# Qibla sources and how to change the data

The Qibla page (`/qibla`, in `lib/features/prayer`) works two things out on the phone: the bearing of the Kaaba
from true north, and how far magnetic north is from true north where the person is, so that the compass can be read
from true north too. Nothing is downloaded and nothing leaves the phone.

## Files

| File | What it is | SHA-256 |
|---|---|---|
| `lib/features/prayer/domain/wmm2025_coefficients.dart` | The 90 coefficient lines of the World Magnetic Model 2025: `WMM.COF` (the same bytes as `WMM2025.COF`) in [`WMM2025COF.zip`](https://www.ncei.noaa.gov/sites/default/files/2024-12/WMM2025COF.zip), fetched 2026-11-27, as a Dart `const` table. Transcribed by a script, token for token. Never edit by hand | `WMM.COF`: `dfa8597825af4e0b87ff4198a5b4fb661b3c49f4cd090cd0164e0259b075582f`. The archive: `2e76569370d081f2cd7919490218bd094ca9afde347b198eff5621e0af460d03` |
| `test/fixtures/wmm/WMM2025_TestValues.txt` | The 100 test values that ship in the same archive, **unmodified** | `e6975b093dddeb6153e0b23cc418425c438167e7c5b1dd795da379cb654f5819` |
| `test/fixtures/wmm/WMM2025_TEST_VALUES.txt` | The 12 test values [linked from the model's page](https://www.ncei.noaa.gov/sites/default/files/2025-02/WMM2025_TEST_VALUES.txt) (six on the ground, six at 100 km), **unmodified** | `ae289c94e2200e4deeae2dfdedf543a8a0e93096512b30d6a754199731f570d0` |

The checksums are those of the published files, whose lines end with a line feed. Git may check the fixtures out
with carriage returns on Windows; the test drops them before it checks.

## Where it comes from

- **The model:** the [World Magnetic Model](https://www.ncei.noaa.gov/products/world-magnetic-model) for 2025 to
  2030. Its page says: "The model is produced by the United States' National Geospatial-Intelligence Agency (NGA) and
  the United Kingdom's Defence Geographic Centre (DGC). NCEI and the British Geological Survey (BGS) jointly developed
  the WMM." The coefficient file's own first line is `    2025.0            WMM-2025     11/13/2024`.
- **Licence:** public domain. The same page says: "The WMM source code is in the public domain and not licensed or
  under copyright. The information and software may be used freely by the public. As required by 17 U.S.C. 403, third
  parties producing copyrighted works consisting predominantly of the material produced by U.S. government agencies
  must provide notice with such work(s) identifying the U.S. Government material incorporated and stating that such
  material is not subject to copyright protection." The app says so on its licences page.
- **The Kaaba and the bearing:** the `adhan` package (MIT): the Kaaba at 21.4225241° N, 39.8261818° E, and the
  bearing along the great circle on a sphere. Against the shortest path on the WGS-84 ellipsoid that is within a
  quarter of a degree up to 15,000 km from the Kaaba, and over one degree only in French Polynesia, next to the
  point of the Earth opposite the Kaaba. Almost every Qibla table is worked out this way, so it is kept.

## How it is used

- `magneticField` (`lib/features/prayer/domain/magnetic_field.dart`) works the model out in Dart: from the WGS-84
  ellipsoid to the sphere, Schmidt semi-normalised Legendre functions by recursion to degree 12, and back. Its
  `declination` is how far magnetic north is east of true north.
- The compass sensors give a heading from magnetic north. The heading the page uses is that plus the declination at
  the saved place on today's date, so the dial's north is the north of maps and of the bearing (D-078).
- A phone with no compass sensor shows the bearing from true north and, for a person holding a real compass, the
  bearing from magnetic north as well.
- The model also says where a compass cannot be trusted, by the strength of the horizontal field (`CompassZone`).
  The limits are [NOAA's](https://www.ncei.noaa.gov/products/world-magnetic-model/accuracy-limitations-error-model):
  under 6000 nT is its "caution zone", where the page warns; under 2000 nT its "blackout zone", where "compasses
  are not accurate and should not be relied on", and the page says so and never claims to face the Qibla (D-079).

## What the tests check

`test/features/prayer/magnetic_field_test.dart`:

- **The table is the official file.** Written back out in the layout of `WMM.COF`, the table has the published
  file's SHA-256: no number is mistyped, missing, or out of order.
- **The model gives the official values.** All 100 values of `WMM2025_TestValues.txt` (2025.0 to 2029.5, up to 98 km
  high) and all 12 of `WMM2025_TEST_VALUES.txt`: the declination and the inclination to the hundredth of a degree
  the files print; the east and down parts to the millionth of a nanotesla the first file prints; the north part to
  under a thousandth of a nanotesla (the file's own north column is that far from two independent evaluations in
  double precision; the reason is not known, and it moves the declination by less than 0.000002°).
- Declinations of the right sign and size in ten cities, no jump at the date line, a finite field at the geographic
  poles, a vertical field at the magnetic poles, and a steady change before 2025 and after 2030.

## Limits

- **The model runs out.** It is made for 2025.0 to 2030.0. After that the app goes on with each coefficient's yearly
  rate, which is far nearer the truth than no correction, and the error grows by the year. A new model comes out
  every five years; WMM2030 is due at the end of 2029.
- **It is the field of the Earth's core only.** NOAA puts the error of its declination at √(0.26² + (5417/H)²)
  degrees, H being the horizontal field in nanotesla: about 0.3° in Cairo, 0.6° in the far north of Canada. Rock
  under the ground can add three or four degrees in places, and steel, speakers and magnets near the phone far more.

## How to change the data

When WMM2030 is published:

1. Download its coefficient archive from the model's page into an empty folder. Record the address, the date, and
   the SHA-256 of the archive and of `WMM.COF`.
2. Write the 90 lines of `WMM.COF` into the table by a script, never by hand: degree, order, then the four numbers
   exactly as the file prints them. Update the header comment, the epoch, and the names that say 2025.
3. In the test, set the new checksum of `WMM.COF` and the new first line of the file. Replace the two files in
   `test/fixtures/wmm` with the new test values, unmodified, and set their checksums.
4. Run `flutter test test/features/prayer/magnetic_field_test.dart`. It fails until the table is the file, byte
   for byte, and the model gives the new test values.
5. Update this file and the entry on the licences page.
