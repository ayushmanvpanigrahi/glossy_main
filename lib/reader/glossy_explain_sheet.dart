import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../library/indexing_status_service.dart';
import '../rag/rag_models.dart';
import 'ai_explain_service.dart';
import 'explain_cards.dart';
import 'explain_sheet_header.dart';
import 'follow_up_bar.dart';

class GlossyExplainSheet extends StatefulWidget {
  const GlossyExplainSheet({
    super.key,
    required this.bookId,
    required this.modelLabel,
    required this.selectedText,
    required this.surroundingPageText,
  });

  final String bookId;
  final String modelLabel;
  final String selectedText;
  final String surroundingPageText;

  @override
  State<GlossyExplainSheet> createState() => _GlossyExplainSheetState();
}

class _GlossyExplainSheetState extends State<GlossyExplainSheet> {
  final _service = AiExplainService();
  final _followUpController = TextEditingController();

  bool _isLoadingExplain = true;
  String? _error;
  ExplainResult? _result;

  final List<ChatTurn> _followUpHistory = [];
  final List<String> _followUpAnswers = [];
  bool _isSendingFollowUp = false;

  bool? _lastRagUsed;

  @override
  void initState() {
    super.initState();
    _loadExplanation();
  }

  @override
  void dispose() {
    _followUpController.dispose();
    super.dispose();
  }

  Future<void> _loadExplanation() async {
    setState(() {
      _isLoadingExplain = true;
      _error = null;
    });
    try {
      final result = await _service.explain(
        selectedText: widget.selectedText,
        surroundingPageText: widget.surroundingPageText,
      );
      setState(() {
        _result = result;
        _isLoadingExplain = false;
      });
    } catch (e) {
      debugPrint('Glossy explain error: $e');
      setState(() {
        _error = 'Could not get an explanation right now.\n($e)';
        _isLoadingExplain = false;
      });
    }
  }

  Future<void> _sendFollowUp(String question) async {
    if (question.trim().isEmpty || _isSendingFollowUp) return;
    setState(() => _isSendingFollowUp = true);
    _followUpController.clear();

    final priorHistory = List<ChatTurn>.from(_followUpHistory);
    _followUpHistory.add(ChatTurn(role: 'user', content: question));

    try {
      final answer = await _service.askFollowUp(
        bookId: widget.bookId,
        selectedText: widget.selectedText,
        history: priorHistory,
        question: question,
        onRagStatus: (used) => setState(() => _lastRagUsed = used),
      );
      setState(() {
        _followUpHistory.add(ChatTurn(role: 'assistant', content: answer));
        _followUpAnswers.add(answer);
      });
    } catch (e) {
      debugPrint('Glossy follow-up error: $e');
      setState(
        () => _followUpAnswers.add(
          'Sorry, kuch gadbad ho gayi — dobara try karo.\n($e)',
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingFollowUp = false);
    }
  }

  String? _ragStatusLabel(Map<String, BookIndexStatus> statuses) {
    if (_lastRagUsed == true) return 'RAG used';
    if (_lastRagUsed == false) return 'RAG: no match';

    final indexStatus = statuses[widget.bookId] ?? BookIndexStatus.notIndexed;
    switch (indexStatus) {
      case BookIndexStatus.indexed:
        return 'RAG ready';
      case BookIndexStatus.indexing:
        return 'Indexing…';
      case BookIndexStatus.failed:
        return 'RAG error';
      case BookIndexStatus.notIndexed:
        return 'RAG off';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              ValueListenableBuilder<Map<String, BookIndexStatus>>(
                valueListenable: IndexingStatusService.instance.statusNotifier,
                builder: (context, statuses, _) => ExplainSheetHeader(
                  modelLabel: widget.modelLabel,
                  ragStatusLabel: _ragStatusLabel(statuses),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    SelectedPassageCard(text: widget.selectedText),
                    const SizedBox(height: 16),
                    if (_isLoadingExplain)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      ErrorCard(message: _error!, onRetry: _loadExplanation)
                    else if (_result != null) ...[
                      LabeledCard(
                        label: 'CORE MEANING',
                        labelColor: AppColors.primary,
                        background: AppColors.stage,
                        text: _result!.coreMeaning,
                      ),
                      const SizedBox(height: 12),
                      ContextCard(text: _result!.context),
                      const SizedBox(height: 12),
                      LabeledCard(
                        label: '✦ Real-life Example',
                        labelColor: AppColors.primary,
                        background: AppColors.primary.withValues(alpha: 0.08),
                        text: _result!.example,
                      ),
                    ],
                    for (final answer in _followUpAnswers) ...[
                      const SizedBox(height: 12),
                      LabeledCard(
                        label: 'FOLLOW-UP',
                        labelColor: AppColors.muted,
                        background: AppColors.stage,
                        text: answer,
                      ),
                    ],
                    if (_isSendingFollowUp)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              FollowUpBar(
                controller: _followUpController,
                isSending: _isSendingFollowUp,
                onSend: _sendFollowUp,
              ),
            ],
          ),
        );
      },
    );
  }
}
