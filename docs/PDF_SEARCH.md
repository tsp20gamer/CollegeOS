# PDF search

Search answers questions like "where did the lectures cover diodes?" from the
text of the student's **own PDFs**. Everything runs on the device: there is no
key, no request, and no service that ever sees a document. Search is an addition
to reading a file directly, never a replacement for it.

```text
PDF stored in a subject
   ↓
embedded text extraction (Syncfusion, background isolate)
   ↓ pages with no text
local page rendering + on-device OCR (Android, Latin and Devanagari)
   ↓
pdf_page_fts (FTS5, porter unicode61) + pdf_search_metadata (status, page count, resume cursor)
   ↓
sanitized prefix query
   ↓
snippet() + ORDER BY rank                             ← matched words marked in the result
   ↓
result rows (file, page) → the viewer opens that page
```

## Index

Schema versions 11–13 added the index and its resumable cursor:

| Object | Purpose |
| --- | --- |
| `pdf_search_metadata` | One row per file: `status`, `page_count`, `last_indexed_page`, `indexed_at`. `file_id` cascades from `subject_files`. |
| `pdf_page_fts` | FTS5 virtual table (`file_id`, `page_number` UNINDEXED, `page_text`), tokenized `porter unicode61`. |

Pages with embedded text are indexed directly. Only pages with no text layer
are rendered and passed to the bundled on-device OCR models. Recognized text is
stored in the same per-page FTS index. Library-wide search reconciles existing
PDFs sequentially too, so an index built by an older text-only release is
upgraded the first time the library is searched. A failed OCR pass remains
retryable.

## Resumable extraction

`LocalPdfExtractionService` (`lib/features/notes/domain/pdf_extraction_service.dart`)
drives the run; `PdfSearchDao` owns every write.

- Pages are written in batches of `kPagesPerDatabaseBatch` (20) inside one
  transaction together with the progress cursor, so the status can never claim
  pages that were not stored.
- `last_indexed_page` is the resume point. A retry after a failure, a process
  kill, or a missing index continues at `last_indexed_page + 1` instead of
  extracting the whole document again.
- A recorded `page_count` that no longer matches the document (the file was
  replaced) clears the stored pages and starts over.
- The open document is recycled only when resident memory grows past
  `kDocumentMemoryBudgetBytes` (128 MiB): Syncfusion retains parsed pages for as
  long as a `PdfDocument` is alive, and disposing it is the only way to return
  that memory.
- Outcomes are `indexed`, `skipped` (already complete), `unsupported` and
  `failed`; `failed` keeps the pages already stored.
- OCR is performed on the foreground service isolate after each text-extraction
  batch. Page images are capped at 2200 pixels on the longest side, processed
  one at a time, and deleted immediately after recognition. `indexed_ocr` marks
  an OCR-complete index; `ocr_error` keeps missing pages retryable.

On Android the run is hosted by the data-sync foreground service
(`flutter_foreground_task`, `FOREGROUND_SERVICE_DATA_SYNC`) so a long document
survives the app leaving the foreground. PDFs in the search scope are
processed one at a time.
After a restart, `PdfIndexCommandController.indexMissingPdfs` restarts files
that were never indexed and files left mid-run by an earlier session.

## Querying

`PdfSearchDao.search` is the only query path:

- The text the student typed is reduced to letters and numbers, so FTS5 syntax
  (`"`, `*`, `-`, `:` …) can never reach the index and no query can fail with a
  syntax error.
- Every term becomes a prefix search (`term*`), which is what makes part-typed
  topics useful.
- `snippet(pdf_page_fts, 2, '<b>', '</b>', '...', 64)` returns the matched text
  with markers around every hit, and `ORDER BY rank` puts the best pages first.
- Each query returns at most 200 ranked pages so a broad term cannot flood the
  results screen. Subject-scoped searches apply their subject filter in SQLite,
  before results are returned.
- An empty query never reaches SQL, and a failing query returns no results
  instead of an error screen.

## Where it appears

| Entry point | Scope |
| --- | --- |
| Notes destination → search entry | Whole library (`/notes/search`) |
| Subject screen → search | One subject (`subjectId`) |

Results are grouped by document, show the matching page and excerpt under each
file, and open the PDF viewer at the tapped page.
The subject-scoped screen also watches the indexing status, shows per-file
page progress, and offers a retry when OCR or text extraction fails. The library-wide screen also
reconciles its files so existing scans are indexed even when the student starts
from the global search entry.

The viewer's Find action searches both the PDF's selectable text and its
file-scoped FTS pages. This lets the same search find OCR text on scanned pages;
the match controls move between matching pages, while Syncfusion highlights
selectable-text matches where available. Starting a Find in a PDF that has not
yet been indexed starts its local index first. The page rail remains visible,
supports tap-to-jump and drag-to-scrub, and shows the current page and total
page count.

## Offline guarantee

PDF search performs no network request and reads no environment or build-time
key. Android bundles ML Kit's Latin and Devanagari recognition models, so the
first OCR run works offline. The added models increase app size. `INTERNET` in
the manifest exists only for the release check (`docs/RELEASE_CHECKLIST.md`).
Nothing about a document, a query, or a result leaves the device, and no
assembled context is persisted: the only stored text is the extracted page
text in `pdf_page_fts`.

## Tests

- `test/features/notes/pdf_extraction_service_test.dart` covers batching, the
  resume cursor, the document recycle path, unsupported files, and failure
  reporting against fake extraction, so no test reads a real document.
- `test/core/database/app_database_test.dart` covers the index and metadata
  writes through the DAO.
