# Lumen Android Offline PDF Search Architecture

Based on analysis of the Lumen repository (`https://github.com/royalgillz/Lumen`).

## 1. Text Extraction & Processing
Lumen uses the iText library (`com.itextpdf:itextg`) for PDF text extraction.
- **Extraction Strategy:** Extracts text page-by-page directly from the PDF file.
- **Worker Logic:** Uses Android WorkManager (`IndexLibraryWorker.kt`) for background processing.
- **Sanitization:** Removes non-alphanumeric characters, excessive whitespace, and lowercases everything before saving to the database.

## 2. Local Database & Schema
Uses Room Database (`LumenDatabase.kt`) coupled with SQLite FTS4 (Full Text Search).

**Tables:**
1. `PdfDocument` (Metadata)
   - `documentId` (PK)
   - `fileName`
   - `filePath`
   - `pageCount`
   - `lastIndexed`
2. `PdfPageFts` (Virtual Table)
   - `rowid`
   - `documentId`
   - `pageNumber`
   - `pageText`

*The FTS table uses the `MATCH` operator for lightning-fast keyword lookups.*

## 3. Background Indexing Service
- **Mechanism:** WorkManager (`androidx.work`).
- **Trigger:** When a user imports a PDF or launches the app.
- **Efficiency:** Compares `PdfDocument` table with the external files directory. It skips already indexed files by checking `documentId` and `lastIndexed` timestamps.

## 4. Search Results Display
The search DAO returns a structured list containing:
- Document Title (`fileName`)
- Matched Page Number (`pageNumber`)
- Snippet (`snippet(PdfPageFts)`) - SQLite provides this out-of-the-box, highlighting the searched keyword with `<b>` tags.

The UI (`SearchResultsAdapter.kt`) renders this snippet using `Html.fromHtml()` to make the keywords visually pop (bold).

## 5. Navigation to Matched Page
When a search result item is tapped, Lumen opens the PDF viewer activity and passes an Intent extra: `EXTRA_PAGE_NUMBER`.
- The PDF Viewer (using `AndroidPdfViewer` or similar) reads this extra on startup and immediately calls `pdfView.jumpTo(pageNumber)`.

## 6. Architecture Layers
- **UI / View:** Activities and Fragments with RecyclerViews.
- **ViewModel:** Coroutines handle async search queries and expose `LiveData` / `StateFlow` to the UI.
- **Repository:** `PdfRepository.kt` abstracts the Room DAOs and file system.
- **Background:** WorkManager handles the heavy lifting of parsing and inserting without blocking the main thread.
