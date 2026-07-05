import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../library/book.dart';
import '../settings/settings_service.dart';
import '../rag/pdf_text_extractor.dart';
import 'glossy_explain_sheet.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book});
  final Book book;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  static const _charsPerPage = 1400;

  final _extractor = const PdfTextExtractor();
  final _settingsService = SettingsService();

  bool _isLoading = true;
  List<String> _pages = [];
  int _pageIndex = 0;
  String _modelLabel = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final text = await _extractor.extractText(widget.book.pdfPath);
    final saved = await _settingsService.loadSavedSettings();
    final pages = _paginate(text);
    setState(() {
      _pages = pages;
      _pageIndex = pages.isEmpty
          ? 0
          : (widget.book.progress * pages.length).floor().clamp(0, pages.length - 1);
      _modelLabel = saved.modelId ?? '';
      _isLoading = false;
    });
  }

  List<String> _paginate(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return [];
    final pages = <String>[];
    var start = 0;
    while (start < clean.length) {
      final end = (start + _charsPerPage).clamp(0, clean.length);
      pages.add(clean.substring(start, end));
      start = end;
    }
    return pages;
  }

  void _showExplainSheet(String selectedText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GlossyExplainSheet(
        bookId: widget.book.pdfPath,
        modelLabel: _modelLabel,
        selectedText: selectedText,
        surroundingPageText: _pages.isNotEmpty ? _pages[_pageIndex] : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageText = _pages.isNotEmpty ? _pages[_pageIndex] : '';
    final progress = _pages.isEmpty ? 0.0 : (_pageIndex + 1) / _pages.length;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          '${widget.book.title.toUpperCase()} · PG ${_pageIndex + 1}',
          style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: AppColors.muted),
        ),
        centerTitle: true,
        actions: const [IconButton(icon: Icon(Icons.more_horiz), onPressed: null)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SelectableText(
                pageText,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, height: 1.6, color: AppColors.ink),
                contextMenuBuilder: (context, state) {
                  final selected =
                  state.textEditingValue.selection.textInside(state.textEditingValue.text);
                  final buttons = <ContextMenuButtonItem>[
                    ...state.contextMenuButtonItems,
                    if (selected.trim().isNotEmpty)
                      ContextMenuButtonItem(
                        label: 'Glossy',
                        onPressed: () {
                          state.hideToolbar();
                          _showExplainSheet(selected);
                        },
                      ),
                  ];
                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: state.contextMenuAnchors,
                    buttonItems: buttons,
                  );
                },
              ),
            ),
          ),
          _buildFooter(progress),
        ],
      ),
    );
  }

  Widget _buildFooter(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Text('${_pageIndex + 1} / ${_pages.length}',
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: AppColors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: AppColors.secondary,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${(progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}