import 'package:flutter/material.dart';
import '../../../app_colors.dart';
import '../../data/models/settings_models.dart';

// ---------------------------------------------------------------------------
// Health Dashboard — shows live status of every service at a glance.
// ---------------------------------------------------------------------------

class HealthDashboard extends StatelessWidget {
  const HealthDashboard({
    super.key,
    required this.orStatus,
    required this.groqStatus,
    required this.geminiStatus,
    required this.aiStatus,
    required this.pingResult,
    required this.selectedModelId,
  });

  final KeyStatus orStatus;
  final KeyStatus groqStatus;
  final KeyStatus geminiStatus;
  final String aiStatus;
  final ModelPingResult? pingResult;
  final String? selectedModelId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SYSTEM HEALTH',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 11,
            letterSpacing: 1.2,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 12),

        // 2×2 grid of health tiles
        Row(
          children: [
            Expanded(
              child: _HealthTile(
                label: 'OpenRouter',
                sublabel: 'LLM provider',
                status: orStatus,
                iconLabel: 'OR',
                iconColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HealthTile(
                label: 'Groq',
                sublabel: 'Fast inference',
                status: groqStatus,
                iconLabel: 'GQ',
                iconColor: const Color(0xFFF55036),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HealthTile(
                label: 'Gemini',
                sublabel: 'Embeddings',
                status: geminiStatus,
                iconLabel: 'GM',
                iconColor: const Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ModelHealthTile(
                pingResult: pingResult,
                selectedModelId: selectedModelId,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Overall status bar
        _OverallStatusBar(aiStatus: aiStatus),
      ],
    );
  }
}

// ── Single service health tile ────────────────────────────────────────────────

class _HealthTile extends StatelessWidget {
  const _HealthTile({
    required this.label,
    required this.sublabel,
    required this.status,
    required this.iconLabel,
    required this.iconColor,
  });

  final String label;
  final String sublabel;
  final KeyStatus status;
  final String iconLabel;
  final Color iconColor;

  Color get _dotColor => switch (status) {
    KeyStatus.idle => AppColors.muted,
    KeyStatus.checking => AppColors.warning,
    KeyStatus.valid => AppColors.success,
    KeyStatus.invalid => AppColors.danger,
    KeyStatus.networkError => AppColors.warning,
  };

  String get _statusText => switch (status) {
    KeyStatus.idle => 'Not configured',
    KeyStatus.checking => 'Checking...',
    KeyStatus.valid => 'Active',
    KeyStatus.invalid => 'Invalid key',
    KeyStatus.networkError => 'Unreachable',
  };

  @override
  Widget build(BuildContext context) {
    final isActive = status == KeyStatus.valid;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? _dotColor.withValues(alpha: 0.06) : AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? _dotColor.withValues(alpha: 0.30)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Provider badge
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Text(
                    iconLabel,
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Pulsing dot
              _StatusDot(
                color: _dotColor,
                isChecking: status == KeyStatus.checking,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _statusText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: _dotColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Model health tile ─────────────────────────────────────────────────────────

class _ModelHealthTile extends StatelessWidget {
  const _ModelHealthTile({
    required this.pingResult,
    required this.selectedModelId,
  });

  final ModelPingResult? pingResult;
  final String? selectedModelId;

  Color get _color => switch (pingResult) {
    null => AppColors.muted,
    ModelPingResult.success => AppColors.success,
    ModelPingResult.emptyResponse => AppColors.warning,
    ModelPingResult.noKey => AppColors.muted,
    _ => AppColors.danger,
  };

  String get _statusText => switch (pingResult) {
    null => 'Not tested',
    ModelPingResult.success => 'Responding',
    ModelPingResult.emptyResponse => 'Empty reply',
    ModelPingResult.failed => 'Failed',
    ModelPingResult.unauthorized => 'Auth error',
    ModelPingResult.networkError => 'Unreachable',
    ModelPingResult.noKey => 'No key',
  };

  @override
  Widget build(BuildContext context) {
    final isActive = pingResult == ModelPingResult.success;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? _color.withValues(alpha: 0.06) : AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? _color.withValues(alpha: 0.30) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  size: 14,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              _StatusDot(color: _color, isChecking: false),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Active Model',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _statusText,
            style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: _color),
          ),
        ],
      ),
    );
  }
}

// ── Overall status bar ────────────────────────────────────────────────────────

class _OverallStatusBar extends StatelessWidget {
  const _OverallStatusBar({required this.aiStatus});

  final String aiStatus;

  (Color, String, IconData) get _state => switch (aiStatus) {
    'active' => (
      AppColors.success,
      'All systems operational',
      Icons.check_circle_rounded,
    ),
    'checking' => (AppColors.warning, 'Verifying services...', Icons.sync),
    _ => (
      AppColors.danger,
      'Service offline — add a valid API key',
      Icons.error_outline,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _state;
    final isChecking = aiStatus == 'checking';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          isChecking
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated status dot ───────────────────────────────────────────────────────

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color, required this.isChecking});

  final Color color;
  final bool isChecking;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.isChecking) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_StatusDot old) {
    super.didUpdateWidget(old);
    if (widget.isChecking && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isChecking && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.isChecking ? _anim : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.50),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Legacy StatusBadge — kept for any existing callers ────────────────────────

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.aiStatus});

  final String aiStatus;

  static const _statuses = [
    (label: 'OFF', color: AppColors.danger, key: 'inactive'),
    (label: 'CHECKING', color: AppColors.warning, key: 'checking'),
    (label: 'ACTIVE', color: AppColors.success, key: 'active'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < _statuses.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: StatusBox(
              label: _statuses[i].label,
              color: _statuses[i].color,
              isActive: aiStatus == _statuses[i].key,
            ),
          ),
        ],
      ],
    );
  }
}

class StatusBox extends StatelessWidget {
  const StatusBox({
    super.key,
    required this.label,
    required this.color,
    required this.isActive,
  });

  final String label;
  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.08) : AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.5) : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color : color.withValues(alpha: 0.35),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              letterSpacing: 0.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.ink : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
