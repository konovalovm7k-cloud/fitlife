# Local search for a confirmed nutrition source

The source editor and full catalogue now share NutritionCatalog.search.
Previously the editor required one literal name substring; for example
`рис вареный` did not find `Рис басмати белый, варёный без соли (CoFID)`.
Search now ignores case, treats е/ё alike and requires all query words,
independent of order. Whitespace and common separators are accepted. Words
can match the displayed name, attributed source/original English name or ID.
No synonyms, inferred cooking state, fuzzy matching or external API is used.
`рис сухой` and `рис вареный` remain distinct; unmatched state words are never
discarded. The original catalogue order is retained.

If a recognized name has no match, Show full catalogue clears only the query.
It does not select a source or save a meal. Explicit selection, portion review
and confirmation are still required; nutrition facts and existing diary data
are unchanged. The source-search semantics identifier enables real Android
acceptance without relying on a visible field label omitted by accessibility.

Regression coverage uses the actual bundled CoFID records: reordered Russian
words, е/ё, multiple spaces, English attribution, exact source code, dry/cooked
separation, unknown words, unchanged ordering and explicit source selection.
The no-match widget test checks that clearing the query creates no save and
leaves confirmation disabled. Android catalogue acceptance now exercises the
no-match escape and reordered English source search before its existing
150.5 g banana -> 122 kcal -> cold-launch source checks. No AI call is made.

2026-10-28: analyze, all 236 Flutter tests, 23 Python harness tests and actionlint
passed. Signed release 4.6.12+26 built with the existing applicationId/certificate.
APK SHA256: 7e90f348e2ea50698ec39cd82449048ea39213953148b393041b31c7d30712de.
Final native acceptance and GitHub status are reported in the pull request;
this document does not infer their success from unit tests or build success.
