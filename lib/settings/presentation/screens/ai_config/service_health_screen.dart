import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ai_status.dart';
import '../../widgets/status_widgets.dart';
import '../../providers/settings_notifier.dart';
import '../../widgets/settings_scaffold.dart';

class ServiceHealthScreen extends ConsumerWidget {
  const ServiceHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);

    return SettingsDetailScaffold(
      title: 'Service health',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ValueListenableBuilder<String>(
            valueListenable: aiStatusNotifier,
            builder: (context, aiStatus, _) {
              return HealthDashboard(
                orStatus: state.orStatus,
                groqStatus: state.groqStatus,
                geminiStatus: state.geminiStatus,
                aiStatus: aiStatus,
                pingResult: state.modelPingResult,
                selectedModelId: state.selectedModelId,
              );
            },
          ),
        ],
      ),
    );
  }
}
