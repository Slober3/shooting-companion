# Appearance and PDF reports

## Appearance

Mode (`system`, `light`, `dark`) and palette (`rangeOrange`, `steelBlue`,
`forestGreen`, `highContrast`) are independent preferences. Missing or unknown
values fall back to System and Range Orange. Changes stream into the app theme
immediately and existing backup v2 preference records include them automatically.

The high-contrast palette uses black/white surfaces, `#FFD400` primary actions
and shape, border and text cues in addition to colour. Android status/navigation
icons follow the resolved brightness while edge-to-edge remains enabled.

## PDF

`PdfReportData` contains immutable report rows and derived totals.
`PdfFontBundle` injects locally bundled Noto Sans Regular/Bold.
`PdfReportBuilder` owns pagination and table layout. Only sessions represented by
confirmed report rows count in the summary. Table headers repeat, target names
wrap, and every page has a number and training disclaimer.

CI generates a multi-page fixture containing `•`, accents, a smart apostrophe,
and en/em dashes. Poppler extracts and renders it; the check rejects U+FFFD.
