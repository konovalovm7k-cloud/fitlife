# Public Android photo-picker fixture

`apple-public.jpg` is the 74,593-byte, metadata-stripped JPEG previously prepared
by FitLife's image pipeline for acceptance testing. It is not a personal photo.

Source: [Apple (1), Renee Comet / NIH, via Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Apple_(1).jpg).
The page identifies the photograph as public domain and credits Renee Comet.
Attribution/licensing was checked on 2026-10-28. The original image was released
by the National Cancer Institute, image ID 2632. This fixture is confined to
`tool/fixtures` and is not bundled in the application assets.

SHA256: `d2d272766c08cffc97784d3c0e6d60f813c9b783af76fd282f17b7f1c5d7ff52`.
Original source JPEG SHA256 is not asserted to match this prepared derivative.

The offline Android smoke only selects/prepares the image and declines the AI
consent dialog. It does not call Google. `android_photo_live.py` is separate,
requires explicit --allow-live-request plus a private config and consumes quota.

## Additional pinned public cases (2026-10-29)

Both 960 px Wikimedia previews below were processed by the unchanged FitLife
`preparePhotoBytes` implementation (JPEG quality 82, stripped EXIF and ICC).
They are developer fixtures only, not APK assets. Names/categories were selected
after visual inspection, before any live recognition request. None has a known
measured portion weight or a verified nutrient/recipe reference.

| Fixture | Source / author / page licence | Prepared SHA256 / bytes |
| --- | --- | --- |
| `banana-public.jpg` | [Banana (1)](https://commons.wikimedia.org/wiki/File:Banana_(1).jpg), Renee Comet / NCI 2693, public domain | `927fcf129b0dfc1e5925d861b9c5a60f99af86c274792c489dde5e76a66c4bd9` / 36,961 |
| `rice-beans-public.jpg` | [Limón — Rice and Beans](https://commons.wikimedia.org/wiki/File:Lim%C3%B3n_-_Rice_and_Beans.jpg), AndSalx95, CC0 1.0 | `e9de7646d63bd15d1172005400bf679478622ae601b95e697542c5ae59154878` / 99,205 |

The banana preview is 960×640, source preview SHA256
`c27bde3a8f5646fc75cbe7ea5894fd9274cc06e210aa1ff3fa3934361400fdfc`.
The mixed plate preview is 960×540, source preview SHA256
`04a397a9f35f862186ea14c732faf9387692268249f06506011db1345ea149ac`.
These hashes describe downloaded previews, not the larger Wikimedia originals.
Source pages and licences checked 2026-10-29. The mixed plate also contains other
foods and a drink; rice and beans are only two coarse visible-category checks.

`python3 tool/check_photo_cases.py` verifies all three locally, never reads
credentials and sends zero requests. The separate opt-in live mode has a hard
two-request cap and stops on any failure without retrying. See
[PHOTO_CASE_ACCEPTANCE.md](../../PHOTO_CASE_ACCEPTANCE.md) for scope and limits.
