# Readable portion fields — 4.6.19+33

The add-food sheet placed grams and meal in two narrow columns. A real Android
320x700 dp / 1.8 font-scale screenshot showed the meal label/value shortened.
The selected meal's RenderParagraph also exceeded its available line width in
widget tests, including 390x844 at default scale.

LayoutBuilder now uses full-width stacked fields when the sheet content width
is below 400 dp or the scaled 16-point text exceeds 24 points. Wider layouts
retain the row. The same grams controller, selected meal and existing callbacks
are used; changing width while editing does not reset the draft. No models,
calculations, stored keys, API calls, validation or write behavior change.

Four scenarios check the actual selected text is not ellipsized and then save
one 150.5 g snack: 320x700/1.8, 390x844/1.0, 600x800/1.8 and a 600x800/1.0
draft resized to 320x700 before saving. The first two fail before the fix.

Local analysis, all 256 Flutter-/43 Python-tests and actionlint pass. Signed APK
4.6.19+33 passes the actual applicationId/version/existing release-certificate
verifier. SHA256:
890b5e0798dcc69f1591890ebbbbb67de5e51cbce3d05edf1bb05b5c356590b8.

Actual Android 15 update 4.6.18+32 -> 4.6.19+33, filters/search/precise draft,
cancel and cold launch preserve every serialized preference entry in four
ordinary/encrypted files. At actual 320x700 dp and font scale 1.8, recent egg
selection, 150.5 g input, reachable enabled Add and cancel pass. The captured
screen shows the full meal label and full selected snack instead of ellipses.
Every preference entry and original emulator size/density/font is restored.
No AI calls were made.

Full CI including all 12 Android cases remains a merge gate. Physical phone
and native iOS are not tested.
