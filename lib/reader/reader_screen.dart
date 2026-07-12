import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../app_colors.dart';
import '../library/book.dart';
import '../settings/data/services/settings_service.dart';
import '../rag/pdf_text_extractor.dart';
import 'glossy_explain_sheet.dart';
import 'glossy_selection_menu.dart';

// ---------------------------------------------------------------------------
// ReaderScreen — REWRITTEN
// ---------------------------------------------------------------------------
// WHY THE REWRITE (not just a patch):
// The previous version extracted the whole PDF to plain text and displayed
// it as a single SelectableText inside a SingleChildScrollView. That
// single choice was the root cause of THREE separate reported bugs:
//   1. No real pagination -> user couldn't move to the next "page" at all.
//   2. Garbled text on some books -> extraction artifacts were shown
//      directly to the reader instead of the real, correctly-rendered PDF.
//   3. Selection toolbar looked wrong / cluttered -> relying on the OS
//      native/Adaptive toolbar pulls in every "Process Text" app installed
//      on the phone (ChatGPT, Grok, Perplexity, etc.), burying our own
//      button.
//
// Switching to `syncfusion_flutter_pdfviewer` (SfPdfViewer) renders the
// ACTUAL pdf pages (like Adobe Reader would), giving us free, correct
// scrolling/pagination and pixel-perfect text regardless of font quirks —
// while a fully custom GlossySelectionMenu replaces the native toolbar.
//
// ADD THIS DEPENDENCY to pubspec.yaml (same version family as your
// existing syncfusion_flutter_pdf):
//   syncfusion_flutter_pdfviewer: ^28.1.33
// ---------------------------------------------------------------------------

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book});
  final Book book;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _settingsService = SettingsService();
  final _extractor = const PdfTextExtractor();
  final PdfViewerController _pdfController = PdfViewerController();

  String _modelLabel = '';
  int _pageCount = 0;
  int _currentPage = 1;

  String _selectedText = '';
  Offset? _selectionAnchor;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final saved = await _settingsService.loadSavedSettings();
    if (mounted) setState(() => _modelLabel = saved.modelId ?? '');
  }

  void _clearSelection() {
    _pdfController.clearSelection();
    setState(() {
      _selectedText = '';
      _selectionAnchor = null;
    });
  }

  Future<void> _showExplainSheet(String selectedText) async {
    // Best-effort: grab the current page's text for extra AI context.
    // Runs in a background isolate (see pdf_text_extractor.dart) so it
    // never blocks the UI.
    final pageText = await _extractor.extractPageText(
      widget.book.pdfPath,
      _currentPage - 1,
    );

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GlossyExplainSheet(
        bookId: widget.book.pdfPath,
        modelLabel: _modelLabel,
        selectedText: selectedText,
        surroundingPageText: pageText.isNotEmpty ? pageText : selectedText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          '${widget.book.title.toUpperCase()} · PG $_currentPage'
          '${_pageCount > 0 ? ' / $_pageCount' : ''}',
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 12,
            color: AppColors.muted,
          ),
        ),
        centerTitle: true,
        actions: const [
          IconButton(icon: Icon(Icons.more_horiz), onPressed: null),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.file(
            File(widget.book.pdfPath),
            controller: _pdfController,
            enableTextSelection: true,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            onDocumentLoaded: (details) {
              final total = details.document.pages.count;
              setState(() {
                _pageCount = total;
                if (widget.book.progress > 0 && total > 0) {
                  final target = (widget.book.progress * total).round().clamp(
                    1,
                    total,
                  );
                  _pdfController.jumpToPage(target);
                }
              });
            },
            onPageChanged: (details) {
              setState(() => _currentPage = details.newPageNumber);
            },
            onTextSelectionChanged: (details) {
              final text = details.selectedText;
              if (text == null || text.trim().isEmpty) {
                setState(() {
                  _selectedText = '';
                  _selectionAnchor = null;
                });
                return;
              }
              setState(() {
                _selectedText = text;
                _selectionAnchor = details.globalSelectedRegion?.topCenter;
              });
            },
          ),
          if (_selectedText.isNotEmpty && _selectionAnchor != null)
            GlossySelectionMenu(
              anchor: _selectionAnchor!,
              selectedText: _selectedText,
              onGlossy: () {
                final text = _selectedText;
                _clearSelection();
                _showExplainSheet(text);
              },
            ),
        ],
      ),
    );
  }
}
