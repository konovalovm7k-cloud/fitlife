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
