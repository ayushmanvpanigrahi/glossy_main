import 'package:flutter/material.dart';
import '../app_colors.dart';

// ---------------------------------------------------------------------------
// FollowUpBar — quick-reply chips + text field + send button.
// Stateless: all state (controller, sending flag) lives in the parent sheet.
// ---------------------------------------------------------------------------

class FollowUpBar extends StatelessWidget {
  const FollowUpBar({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final ValueChanged<String> onSend;

  static const _quickReplies = ['Simpler please', 'Hindi only', 'Give an example'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reply in _quickReplies)
                  ActionChip(
                    label: Text(
                      reply,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                    ),
                    backgroundColor: AppColors.stage,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: isSending ? null : () => onSend(reply),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Ask a follow-up... e.g. 'aur example'",
                      filled: true,
                      fillColor: AppColors.stage,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: onSend,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: isSending ? null : () => onSend(controller.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
