import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../ai_status.dart';
import 'settings_models.dart';
import 'settings_service.dart';
import 'settings_sections.dart';
import 'status_widgets.dart';

// ---------------------------------------------------------------------------
// SettingsScreen
// ---------------------------------------------------------------------------

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static bool _hasAutoValidatedThisSession = false;

  final _service = SettingsService();

  // Controllers
  final _orKeyCtrl     = TextEditingController();
  final _groqKeyCtrl   = TextEditingController();
  final _geminiKeyCtrl = TextEditingController();
  final _modelSearchCtrl = TextEditingController();

  // Obscure toggles
  bool _obscureOr     = true;
  bool _obscureGroq   = true;
  bool _obscureGemini = true;

  // Loading
  bool _isLoading        = true;
  bool _isSaving         = false;
  bool _isModelsLoading  = true;
  String? _modelsFetchError;
  List<String> _modelFetchWarnings = [];

  // Per-key validation status
  KeyStatus _orStatus     = KeyStatus.idle;
  KeyStatus _groqStatus   = KeyStatus.idle;
  KeyStatus _geminiStatus = KeyStatus.idle;

  // Model ping
  ModelPingResult? _modelPingResult;
  bool _isPinging = false;

  // Model state
  List<OpenRouterModel> _allModels      = [];
  String? _selectedModelId;
  ModelProvider _selectedModelProvider  = ModelProvider.openRouter;
  bool _freeOnly      = false;
  String _searchQuery = '';

  // RAG
  String _embeddingMode    = 'api';
  String _indexingTrigger  = 'onAdd';

  String get _aiStatus => aiStatusNotifier.value;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _orKeyCtrl.dispose();
    _groqKeyCtrl.dispose();
    _geminiKeyCtrl.dispose();
    _modelSearchCtrl.dispose();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    await Future.wait([_loadSaved(), _loadRag()]);
    await _fetchModels();

    // Auto-validate keys that are already saved
    if (!_hasAutoValidatedThisSession) {
      await _autoValidateAll();
      _hasAutoValidatedThisSession = true;
    }
  }

  Future<void> _loadSaved() async {
    final s = await _service.loadSavedSettings();
    setState(() {
      if (s.apiKey     != null) _orKeyCtrl.text   = s.apiKey!;
      if (s.groqApiKey != null) _groqKeyCtrl.text = s.groqApiKey!;
      _selectedModelId       = s.modelId;
      _selectedModelProvider = s.modelProvider;
      _isLoading             = false;
    });
  }

  Future<void> _loadRag() async {
    final r = await _service.loadRagSettings();
    setState(() {
      _embeddingMode   = r.embeddingMode   ?? 'api';
      _indexingTrigger = r.indexingTrigger ?? 'onAdd';
      if (r.embeddingApiKey != null) _geminiKeyCtrl.text = r.embeddingApiKey!;
    });
  }

  // ── Model fetching ────────────────────────────────────────────────────────

  Future<void> _fetchModels() async {
    setState(() {
      _isModelsLoading  = true;
      _modelsFetchError = null;
      _modelFetchWarnings = [];
    });

    try {
      final result = await _service.fetchAllModels(
        groqApiKey: _groqKeyCtrl.text.trim(),
      );
      setState(() {
        _allModels          = result.models;
        _modelFetchWarnings = result.errors;
        _isModelsLoading    = false;
      });
      await _ensureValidModelSelected();
    } catch (e) {
      setState(() {
        _modelsFetchError = 'Could not connect. Check your internet.';
        _isModelsLoading  = false;
      });
    }
  }

  Future<void> _ensureValidModelSelected() async {
    if (_allModels.isEmpty) {
      if (_selectedModelId != null) {
        setState(() => _selectedModelId = null);
        await _service.deleteModelId();
      }
      return;
    }
    final stillValid = _allModels.any((m) => m.id == _selectedModelId);
    if (_selectedModelId == null || !stillValid) {
      final fallback = _allModels.first;
      setState(() => _selectedModelId = fallback.id);
      await _service.saveModelId(fallback.id);
    }
  }

  List<OpenRouterModel> get _filteredModels {
    final q = _searchQuery.toLowerCase();
    return _allModels.where((m) {
      if (_freeOnly && !m.isFree) return false;
      if (q.isNotEmpty &&
          !m.name.toLowerCase().contains(q) &&
          !m.id.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  Future<void> _autoValidateAll() async {
    final or     = _orKeyCtrl.text.trim();
    final groq   = _groqKeyCtrl.text.trim();
    final gemini = _geminiKeyCtrl.text.trim();

    await Future.wait([
      if (or.isNotEmpty)     _validateOrKey(or,     announce: false),
      if (groq.isNotEmpty)   _validateGroqKey(groq, announce: false),
      if (gemini.isNotEmpty) _validateGeminiKey(gemini, announce: false),
    ]);

    _syncAiStatus();
  }

  Future<void> _validateOrKey(String key, {bool announce = true}) async {
    setState(() => _orStatus = KeyStatus.checking);
    final result = await _service.validateOpenRouterKey(key);
    setState(() {
      _orStatus = _toKeyStatus(result);
    });
    if (announce) {
      _syncAiStatus();
      _showSnackBar(_orSnackLabel(result));
    }
  }

  Future<void> _validateGroqKey(String key, {bool announce = true}) async {
    setState(() => _groqStatus = KeyStatus.checking);
    final result = await _service.validateGroqKey(key);
    setState(() {
      _groqStatus = _toKeyStatus(result);
    });
    if (announce) {
      _syncAiStatus();
      _showSnackBar(_groqSnackLabel(result));
    }
  }

  Future<void> _validateGeminiKey(String key, {bool announce = true}) async {
    setState(() => _geminiStatus = KeyStatus.checking);
    final result = await _service.validateGeminiKey(key);
    setState(() {
      _geminiStatus = _toKeyStatus(result);
    });
    if (announce) {
      _showSnackBar(_geminiSnackLabel(result));
    }
  }

  KeyStatus _toKeyStatus(ValidationResult r) => switch (r) {
    ValidationResult.valid        => KeyStatus.valid,
    ValidationResult.invalid      => KeyStatus.invalid,
    ValidationResult.networkError => KeyStatus.networkError,
    ValidationResult.unknown      => KeyStatus.valid, // accepted; treat as valid
  };

  void _syncAiStatus() {
    final anyActive =
        _orStatus == KeyStatus.valid || _groqStatus == KeyStatus.valid;
    final anyChecking =
        _orStatus == KeyStatus.checking || _groqStatus == KeyStatus.checking;

    aiStatusNotifier.value = anyChecking
        ? 'checking'
        : anyActive
            ? 'active'
            : 'inactive';
    setState(() {});
  }

  // ── Model ping ────────────────────────────────────────────────────────────

  Future<void> _pingModel() async {
    final modelId = _selectedModelId;
    if (modelId == null) return;

    final apiKey = _selectedModelProvider == ModelProvider.groq
        ? _groqKeyCtrl.text.trim()
        : _orKeyCtrl.text.trim();

    setState(() {
      _isPinging       = true;
      _modelPingResult = null;
    });

    final result = await _service.pingModel(
      modelId:  modelId,
      provider: _selectedModelProvider,
      apiKey:   apiKey,
    );

    setState(() {
      _isPinging       = false;
      _modelPingResult = result;
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _isSaving = true);

    await _service.saveAllSettings(
      openRouterKey:   _orKeyCtrl.text.trim(),
      groqKey:         _groqKeyCtrl.text.trim(),
      geminiKey:       _geminiKeyCtrl.text.trim(),
      modelId:         _selectedModelId,
      modelProvider:   _selectedModelProvider,
      embeddingMode:   _embeddingMode,
      indexingTrigger: _indexingTrigger,
    );

    // Validate all non-empty keys after save
    await _autoValidateAll();

    setState(() => _isSaving = false);
    _showSnackBar('Settings saved');
  }

  // ── Snack labels ──────────────────────────────────────────────────────────

  String _orSnackLabel(ValidationResult r) => switch (r) {
    ValidationResult.valid        => 'OpenRouter key is valid ✓',
    ValidationResult.invalid      => 'OpenRouter key is invalid',
    ValidationResult.networkError => 'Could not reach OpenRouter',
    ValidationResult.unknown      => 'OpenRouter key accepted',
  };

  String _groqSnackLabel(ValidationResult r) => switch (r) {
    ValidationResult.valid        => 'Groq key is valid ✓',
    ValidationResult.invalid      => 'Groq key is invalid',
    ValidationResult.networkError => 'Could not reach Groq',
    ValidationResult.unknown      => 'Groq key accepted',
  };

  String _geminiSnackLabel(ValidationResult r) => switch (r) {
    ValidationResult.valid        => 'Gemini key is valid ✓',
    ValidationResult.invalid      => 'Gemini key is invalid',
    ValidationResult.networkError => 'Could not reach Google',
    ValidationResult.unknown      => 'Gemini key accepted',
  };

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.paper,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        elevation: 4,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: Theme.of(context).textTheme.headlineMedium),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                // ── API Keys section ────────────────────────────────────────
                ApiKeysSection(
                  orKeyCtrl:           _orKeyCtrl,
                  obscureOr:           _obscureOr,
                  onToggleObscureOr:   () => setState(() => _obscureOr = !_obscureOr),
                  orStatus:            _orStatus,
                  onValidateOr:        () {
                    final k = _orKeyCtrl.text.trim();
                    if (k.isNotEmpty) _validateOrKey(k);
                  },
                  groqKeyCtrl:         _groqKeyCtrl,
                  obscureGroq:         _obscureGroq,
                  onToggleObscureGroq: () => setState(() => _obscureGroq = !_obscureGroq),
                  groqStatus:          _groqStatus,
                  onValidateGroq:      () {
                    final k = _groqKeyCtrl.text.trim();
                    if (k.isNotEmpty) _validateGroqKey(k);
                  },
                  geminiKeyCtrl:         _geminiKeyCtrl,
                  obscureGemini:         _obscureGemini,
                  onToggleObscureGemini: () => setState(() => _obscureGemini = !_obscureGemini),
                  geminiStatus:          _geminiStatus,
                  onValidateGemini:      () {
                    final k = _geminiKeyCtrl.text.trim();
                    if (k.isNotEmpty) _validateGeminiKey(k);
                  },
                ),

                const SizedBox(height: 24),

                // ── Model section ───────────────────────────────────────────
                ModelSection(
                  isModelsLoading:  _isModelsLoading,
                  modelsFetchError: _modelsFetchError,
                  onRefresh:        _refreshModels,
                  searchController: _modelSearchCtrl,
                  onSearchChanged:  (v) => setState(() => _searchQuery = v),
                  freeOnly:         _freeOnly,
                  onFreeOnlyChanged:(v) => setState(() => _freeOnly = v),
                  allModels:        _allModels,
                  filteredModels:   _filteredModels,
                  fetchWarnings:    _modelFetchWarnings,
                  selectedModelId:  _selectedModelId,
                  onSelectModel:    _handleModelSelect,
                  // ping
                  isPinging:        _isPinging,
                  pingResult:       _modelPingResult,
                  onPing:           _pingModel,
                ),

                const SizedBox(height: 24),

                // ── Save button ─────────────────────────────────────────────
                SaveButton(isSaving: _isSaving, onSave: _save),

                const SizedBox(height: 24),

                // ── RAG section ─────────────────────────────────────────────
                RagSection(
                  embeddingMode:           _embeddingMode,
                  onEmbeddingModeChanged:  (v) => setState(() => _embeddingMode = v),
                  embeddingApiKeyController: _geminiKeyCtrl,
                  obscureEmbeddingKey:     _obscureGemini,
                  onToggleObscureEmbeddingKey:
                      () => setState(() => _obscureGemini = !_obscureGemini),
                  onEmbeddingApiKeyChanged: (v) {},  // saved on Save press
                  indexingTrigger:         _indexingTrigger,
                  onIndexingTriggerChanged:(v) => setState(() => _indexingTrigger = v),
                ),

                const SizedBox(height: 24),

                // ── Health dashboard ────────────────────────────────────────
                HealthDashboard(
                  orStatus:     _orStatus,
                  groqStatus:   _groqStatus,
                  geminiStatus: _geminiStatus,
                  aiStatus:     _aiStatus,
                  pingResult:   _modelPingResult,
                  selectedModelId: _selectedModelId,
                ),

                const SizedBox(height: 8),
              ],
            ),
    );
  }

  Future<void> _handleModelSelect(String id) async {
    final model = _allModels.firstWhere((m) => m.id == id);
    setState(() {
      _selectedModelId       = id;
      _selectedModelProvider = model.provider;
      _modelPingResult       = null; // reset ping on new model
    });
    await _service.saveModelId(id);
    await _service.saveModelProvider(model.provider);
  }

  Future<void> _refreshModels() async {
    await _fetchModels();
    await _autoValidateAll();
  }
}
