import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app_colors.dart';
import '../../../data/models/settings_models.dart';
import '../../providers/settings_notifier.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/model_widgets.dart';
import '../../widgets/settings_scaffold.dart';

class PreferredModelScreen extends ConsumerWidget {
  const PreferredModelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final ctrl = ref.watch(settingsControllersProvider);

    return SettingsDetailScaffold(
      title: 'Preferred model',
      actions: [
        Padding(
          padding: const EdgeInsets.only(
            top: 8,
            right: 4,
          ), // Position set karne ke liye
          child: IconButton(
            // Jab loading ho tab button click nahi hoga
            onPressed: state.isModelsLoading ? null : notifier.refreshModels,
            icon: state.isModelsLoading
                ? const SizedBox(
                    width: 12, // Icon ke visual size se match karne ke liye
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, // Icon ki motai se match karne ke liye
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.ink,
                    size: 20, // Icon ka size 20 rakha
                  ),
          ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          if (state.modelsFetchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: InfoBanner(
                message: state.modelsFetchError!,
                color: AppColors.danger,
                icon: Icons.error_outline,
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.stage,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: ctrl.modelSearchCtrl,
                  onChanged: notifier.setSearchQuery,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search models...',
                    hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 14, 0),
              child: Row(
                children: [
                  Text(
                    '${state.filteredModels.length} models',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Free only',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: state.freeOnly,
                    onChanged: notifier.setFreeOnly,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                    inactiveThumbColor: AppColors.paper,
                    inactiveTrackColor: AppColors.muted.withValues(alpha: 0.3),
                    trackOutlineColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  ...ModelProvider.values.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(p.name.toUpperCase()),
                        selected: state.selectedProviders.contains(p),
                        onSelected: (selected) {
                          final next = Set<ModelProvider>.from(
                            state.selectedProviders,
                          );
                          if (selected) {
                            next.add(p);
                          } else {
                            next.remove(p);
                          }
                          notifier.setSelectedProviders(next);
                        },
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: state.selectedProviders.contains(p)
                              ? Colors.white
                              : AppColors.ink,
                        ),
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        backgroundColor: AppColors.stage,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                    child: VerticalDivider(width: 1, indent: 8, endIndent: 8),
                  ),
                  ...ModelType.values.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(t.name.toUpperCase()),
                        selected: state.selectedTypes.contains(t),
                        onSelected: (selected) {
                          final next = Set<ModelType>.from(state.selectedTypes);
                          if (selected) {
                            next.add(t);
                          } else {
                            next.remove(t);
                          }
                          notifier.setSelectedTypes(next);
                        },
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: state.selectedTypes.contains(t)
                              ? Colors.white
                              : AppColors.ink,
                        ),
                        selectedColor: AppColors.ink,
                        checkmarkColor: Colors.white,
                        backgroundColor: AppColors.stage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final w in state.modelFetchWarnings)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: InfoBanner(
                  message: w,
                  color: AppColors.warning,
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ModelList(
                models: state.filteredModels,
                selectedModelId: state.selectedModelId,
                onSelect: notifier.selectModel,
              ),
            ),
            if (state.selectedModelId != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _PingRow(
                  modelId: state.selectedModelId!,
                  isPinging: state.isPinging,
                  pingResult: state.modelPingResult,
                  onPing: notifier.pingModel,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PingRow extends StatelessWidget {
  const _PingRow({
    required this.modelId,
    required this.isPinging,
    required this.pingResult,
    required this.onPing,
  });

  final String modelId;
  final bool isPinging;
  final ModelPingResult? pingResult;
  final VoidCallback onPing;

  (Color, String) get _state {
    if (isPinging) return (AppColors.warning, 'Testing model...');
    return switch (pingResult) {
      null => (AppColors.muted, 'Run model test'),
      ModelPingResult.success => (AppColors.success, 'Model is responding'),
      ModelPingResult.emptyResponse => (AppColors.warning, 'Empty response'),
      ModelPingResult.failed => (AppColors.danger, 'Model failed'),
      ModelPingResult.unauthorized => (AppColors.danger, 'Unauthorized'),
      ModelPingResult.networkError => (AppColors.warning, 'No connection'),
      ModelPingResult.noKey => (AppColors.muted, 'No API key set'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _state;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 0.5),
      ),
      child: Row(
        children: [
          isPinging
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(
                  pingResult == ModelPingResult.success
                      ? Icons.check_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  size: 18,
                  color: color,
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                if (pingResult == ModelPingResult.success)
                  Text(
                    modelId,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: isPinging ? null : onPing,
            child: Text(
              pingResult == null ? 'Test' : 'Retest',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
