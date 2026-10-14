import 'dart:io';

import 'package:college_os/features/subject_files/domain/subject_file.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/subject_files/presentation/widgets/pdf_page_scrubber.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({
    required this.file,
    this.initialPageNumber,
    this.initialSearchQuery,
    super.key,
  });

  final SubjectFile file;
  final int? initialPageNumber;
  final String? initialSearchQuery;

  /// Opens [file] above the shell.
  ///
  /// A document is read full-screen, so it is pushed on the root navigator: the
  /// floating dock belongs to the tab shell and would otherwise sit on top of
  /// the page the student opened, hiding its last lines and its page footer.
  /// Settings opens above the shell for the same reason.
  static Future<void> open(
    BuildContext context, {
    required SubjectFile file,
    int? initialPageNumber,
    String? initialSearchQuery,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) => PdfViewerScreen(
          file: file,
          initialPageNumber: initialPageNumber,
          initialSearchQuery: initialSearchQuery,
        ),
      ),
    );
  }

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();
  PdfTextSearchResult _pdfTextSearchResult = PdfTextSearchResult();

  File? _localFile;
  bool _isLoading = true;
  String? _error;
  bool _showSearchToolbar = false;
  bool _isSearchInitiated = false;

  /// Pages in the open document, and the page on screen. Both come from the
  /// viewer's own callbacks and drive the right-edge page scrubber.
  int _pageCount = 0;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadFile();

    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      _showSearchToolbar = true;
      _searchController.text = widget.initialSearchQuery!;
    }
  }

  Future<void> _loadFile() async {
    try {
      final service = ref.read(subjectFileStorageServiceProvider);
      final file = await service.resolveFile(widget.file.relativeFilePath);
      if (await file.exists()) {
        setState(() {
          _localFile = file;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'File not found on device.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _executeSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearchInitiated = true;
      _pdfTextSearchResult = _pdfViewerController.searchText(query);
      _pdfTextSearchResult.addListener(_onSearchProgress);
    });
  }

  void _onSearchProgress() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _pdfTextSearchResult.clear();
      _pdfViewerController.clearSelection();
      _isSearchInitiated = false;
      _pdfTextSearchResult.removeListener(_onSearchProgress);
    });
  }

  /// Turns to [page] from the scrubber.
  ///
  /// The page is held here as well as in the viewer so the thumb lands under
  /// the finger immediately instead of waiting for the viewer's own callback.
  void _goToPage(int page) {
    final target = page.clamp(1, _pageCount == 0 ? page : _pageCount);
    if (target == _currentPage) return;
    setState(() => _currentPage = target);
    _pdfViewerController.jumpToPage(target);
  }

  @override
  void dispose() {
    _pdfTextSearchResult.removeListener(_onSearchProgress);
    _pdfTextSearchResult.dispose();
    _pdfViewerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _showSearchToolbar
          ? _buildSearchAppBar(colors)
          : _buildDefaultAppBar(colors),
      body: _buildBody(colors),
    );
  }

  AppBar _buildDefaultAppBar(ColorScheme colors) {
    return AppBar(
      title: Text(widget.file.title),
      scrolledUnderElevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () {
            setState(() {
              _showSearchToolbar = true;
            });
          },
        ),
      ],
    );
  }

  AppBar _buildSearchAppBar(ColorScheme colors) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () {
          setState(() {
            _showSearchToolbar = false;
            _clearSearch();
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: widget.initialSearchQuery == null,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Find in document...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: _clearSearch,
                )
              : null,
        ),
        onSubmitted: _executeSearch,
        onChanged: (_) => setState(() {}),
      ),
      bottom: _isSearchInitiated
          ? PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: colors.surfaceContainerLow,
                child: Row(
                  children: [
                    if (!_pdfTextSearchResult.isSearchCompleted)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text(
                        _pdfTextSearchResult.hasResult
                            ? '${_pdfTextSearchResult.currentInstanceIndex} of ${_pdfTextSearchResult.totalInstanceCount}'
                            : 'No matches found',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    const Spacer(),
                    if (_pdfTextSearchResult.hasResult) ...[
                      IconButton(
                        icon: const Icon(Icons.navigate_before_rounded),
                        onPressed: () {
                          setState(() {
                            _pdfTextSearchResult.previousInstance();
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigate_next_rounded),
                        onPressed: () {
                          setState(() {
                            _pdfViewerController.clearSelection();
                            _pdfTextSearchResult.nextInstance();
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(ColorScheme colors) {
    if (_isLoading) {
      return const LoadingState(label: 'Loading document...');
    }

    if (_error != null || _localFile == null) {
      return ErrorState(
        title: 'Could not load PDF',
        message: _error ?? 'Unknown error',
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: SfPdfViewer.file(
            _localFile!,
            controller: _pdfViewerController,
            canShowScrollHead: false,
            currentSearchTextHighlightColor: colors.primary.withValues(
              alpha: 0.4,
            ),
            otherSearchTextHighlightColor: colors.primary.withValues(
              alpha: 0.15,
            ),
            onDocumentLoaded: (details) {
              final pageCount = details.document.pages.count;
              final initialPage = widget.initialPageNumber;
              setState(() {
                _pageCount = pageCount;
                _currentPage = (initialPage ?? _pdfViewerController.pageNumber)
                    .clamp(1, pageCount);
              });
              if (initialPage != null) {
                _pdfViewerController.jumpToPage(_currentPage);
              }
              if (widget.initialSearchQuery != null &&
                  widget.initialSearchQuery!.isNotEmpty) {
                // Add a slight delay so the view renders before searching
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _executeSearch(widget.initialSearchQuery!);
                  }
                });
              }
            },
            onPageChanged: (details) {
              setState(() => _currentPage = details.newPageNumber);
            },
          ),
        ),
        // The whole right edge is the document's scroller: it stays put instead
        // of fading, so the student can always see where they are in the file
        // and drag straight to another page.
        Positioned.fill(
          child: PdfPageScrubber(
            pageCount: _pageCount,
            currentPage: _currentPage,
            onPageSelected: _goToPage,
          ),
        ),
      ],
    );
  }
}
