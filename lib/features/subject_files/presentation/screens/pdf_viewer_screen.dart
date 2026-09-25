import 'dart:io';

import 'package:college_os/features/subject_files/domain/subject_file.dart';
import 'package:college_os/core/database/database_providers.dart';
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

  @override
  void initState() {
    super.initState();
    _loadFile();
    
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
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
      appBar: _showSearchToolbar ? _buildSearchAppBar(colors) : _buildDefaultAppBar(colors),
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
      bottom: _isSearchInitiated ? PreferredSize(
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
      ) : null,
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

    return SfPdfViewer.file(
      _localFile!,
      controller: _pdfViewerController,
      canShowScrollHead: false,
      currentSearchTextHighlightColor: colors.primary.withOpacity(0.4),
      otherSearchTextHighlightColor: colors.primary.withOpacity(0.15),
      onDocumentLoaded: (details) {
        if (widget.initialPageNumber != null) {
          _pdfViewerController.jumpToPage(widget.initialPageNumber!);
        }
        if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
          // Add a slight delay so the view renders before searching
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _executeSearch(widget.initialSearchQuery!);
            }
          });
        }
      },
    );
  }
}
