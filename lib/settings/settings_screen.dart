import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../ai_status.dart';
import 'settings_models.dart';
import 'settings_service.dart';
import 'provider_widgets.dart';
import 'settings_sections.dart';
import 'status_widgets.dart';

// ---------------------------------------------------------------------------
// SettingsScreen widget
// ---------------------------------------------------------------------------

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Static: persists across tab switches but resets on full app restart.
  static bool _hasAutoValidatedThisSession = false;

  final _apiKeyController = TextEditingController();
  final _modelSearchController = TextEditingController();
  final _service = SettingsService();

  // UI state
  bool _obscureApiKey = true;
  bool _isLoading = true;
  bool _isProviderOpen = false;

  // AI status initialised from notifier so tab-switch preserves it.
  String get _aiStatus => aiStatusNotifier.value;

  // Model state
  List<OpenRouterModel> _allModels = [];
  bool _isModelsLoading = true;
  String? _modelsFetchError;
  String? _selectedModelId;
  bool _freeOnly = false;
  String _searchQuery = '';
  String _embeddingMode = 'api';
  String _indexingTrigger = 'onAdd';
  final _embeddingApiKeyController = TextEditingController();
  bool _obscureEmbeddingKey = true;

  final _groqApiKeyController = TextEditingController();
  bool _obscureGroqApiKey = true;
  ModelProvider _selectedModelProvider = ModelProvider.openRouter;
  List<String> _modelFetchWarnings = [];

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelSearchController.dispose();
    _embeddingApiKeyController.dispose();
    _groqApiKeyController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Status helper — keeps instance + static in sync at all times
  // ---------------------------------------------------------------------------

  void _updateAiStatus(String status) {
    aiStatusNotifier.value = status;
    setState(() {}); // rebuild so _aiStatus getter reflects new value
  }

  // ---------------------------------------------------------------------------
  // Init helpers
  // ---------------------------------------------------------------------------

  Future<void> _init() async {
    await _loadSavedSettings();
    await _loadRagSettings();
    await _fetchModels();

    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isNotEmpty && !_hasAutoValidatedThisSession) {
      final result = await _runValidation(apiKey, showSnackbar: false);
      // Only mark validated if we got a real answer (not a transient network failure).
      if (result != ValidationResult.networkError) {
        _hasAutoValidatedThisSession = true;
      }
    }
  }

  Future<void> _loadSavedSettings() async {
    final saved = await _service.loadSavedSettings();

    setState(() {
      if (saved.apiKey != null) _apiKeyController.text = saved.apiKey!;
      if (saved.groqApiKey != null) {
        _groqApiKeyController.text = saved.groqApiKey!;
      }
      _selectedModelId = saved.modelId;
      _selectedModelProvider = saved.modelProvider;
      _isLoading = false;
    });
  }

  Future<void> _loadRagSettings() async {
    final rag = await _service.loadRagSettings();
    setState(() {
      _embeddingMode = rag.embeddingMode ?? 'api';
      _indexingTrigger = rag.indexingTrigger ?? 'onAdd';
      if (rag.embeddingApiKey != null) {
        _embeddingApiKeyController.text = rag.embeddingApiKey!;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Model fetching
  // ---------------------------------------------------------------------------

  Future<void> _fetchModels() async {
    setState(() {
      _isModelsLoading = true;
      _modelsFetchError = null;
      _modelFetchWarnings = [];
    });

    try {
      final result = await _service.fetchAllModels(
        groqApiKey: _groqApiKeyController.text.trim(),
      );

      setState(() {
        _allModels = result.models;
        _modelFetchWarnings = result.errors;
        _isModelsLoading = false;
      });

      await _ensureValidModelSelected();
    } catch (e) {
      setState(() {
        _modelsFetchError = 'Could not connect. Check your internet.';
        _isModelsLoading = false;
      });
      _updateAiStatus('inactive');
      _hasAutoValidatedThisSession = false;
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

  // Derived list — computed on read, no extra state variable needed.
  List<OpenRouterModel> get _filteredModels {
    final query = _searchQuery.toLowerCase();
    return _allModels.where((m) {
      if (_freeOnly && !m.isFree) return false;
      if (query.isNotEmpty &&
          !m.name.toLowerCase().contains(query) &&
          !m.id.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // API key save & validation
  // ---------------------------------------------------------------------------

  Future<void> _saveSettings() async {
    if (_selectedModelProvider == ModelProvider.groq) {
      final groqKey = _groqApiKeyController.text.trim();
      if (groqKey.isEmpty) {
        _showSnackBar('Enter a Groq API key first');
        return;
      }
      await Future.wait([
        _service.saveGroqApiKey(groqKey),
        if (_selectedModelId?.isNotEmpty ?? false)
          _service.saveModelId(_selectedModelId!)
        else
          _service.deleteModelId(),
        _service.saveModelProvider(_selectedModelProvider),
      ]);
      _updateAiStatus(
        'active',
      ); // Groq has no key-validation endpoint like OpenRouter's /key
      _showSnackBar('Settings saved — using Groq');
      return;
    }

    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      await _service.deleteApiKey();
      _updateAiStatus('inactive');
      _showSnackBar('API key cleared');
      return;
    }

    await Future.wait([
      _service.saveApiKey(apiKey),
      if (_selectedModelId?.isNotEmpty ?? false)
        _service.saveModelId(_selectedModelId!)
      else
        _service.deleteModelId(),
      _service.saveModelProvider(_selectedModelProvider),
    ]);

    _hasAutoValidatedThisSession = true;
    await _runValidation(apiKey, showSnackbar: true);
  }

  /// Shared validation runner used by both the Save button and the
  /// once-per-session auto-validation on screen load.
  Future<ValidationResult> _runValidation(
    String apiKey, {
    required bool showSnackbar,
  }) async {
    _updateAiStatus('checking');

    final result = await _service.validateApiKey(apiKey);

    _updateAiStatus(switch (result) {
      ValidationResult.valid => 'active',
      ValidationResult.unknown => 'active', // accepted but unconfirmed
      _ => 'inactive',
    });

    if (showSnackbar) {
      _showSnackBar(switch (result) {
        ValidationResult.valid => 'Settings saved — API key is valid',
        ValidationResult.invalid => 'Saved, but API key seems invalid',
        ValidationResult.networkError =>
          'Saved, but could not connect to verify the key',
        ValidationResult.unknown =>
          'Settings saved — could not fully verify right now, but key was accepted',
      });
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // SnackBar helper
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Refresh helper (model list + optional re-validation)
  // ---------------------------------------------------------------------------

  Future<void> _refreshModels() async {
    await _fetchModels();
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isNotEmpty && !_hasAutoValidatedThisSession) {
      final result = await _runValidation(apiKey, showSnackbar: false);
      if (result != ValidationResult.networkError) {
        _hasAutoValidatedThisSession = true;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AiProviderSection(
                  isProviderOpen: _isProviderOpen,
                  onProviderTap: () async {
                    setState(() => _isProviderOpen = true);
                    await showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: AppColors.paper,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (_) => const ProviderSheet(),
                    );
                    if (mounted) setState(() => _isProviderOpen = false);
                  },
                  apiKeyController: _apiKeyController,
                  obscureApiKey: _obscureApiKey,
                  onToggleObscureApiKey: () =>
                      setState(() => _obscureApiKey = !_obscureApiKey),
                  groqApiKeyController: _groqApiKeyController,
                  obscureGroqApiKey: _obscureGroqApiKey,
                  onToggleObscureGroqApiKey: () =>
                      setState(() => _obscureGroqApiKey = !_obscureGroqApiKey),
                  onGroqKeyChanged: (_) =>
                      setState(() {}), // allow re-fetch with new key
                ),
                const SizedBox(height: 24),

                ModelSection(
                  isModelsLoading: _isModelsLoading,
                  modelsFetchError: _modelsFetchError,
                  onRefresh: _refreshModels,
                  searchController: _modelSearchController,
                  onSearchChanged: (v) => setState(() => _searchQuery = v),
                  freeOnly: _freeOnly,
                  onFreeOnlyChanged: (v) => setState(() => _freeOnly = v),
                  allModels: _allModels,
                  filteredModels: _filteredModels,
                  fetchWarnings: _modelFetchWarnings,
                  selectedModelId: _selectedModelId,
                  onSelectModel: (id) async {
                    final model = _allModels.firstWhere((m) => m.id == id);
                    setState(() {
                      _selectedModelId = id;
                      _selectedModelProvider = model.provider;
                    });
                    await _service.saveModelId(id);
                    await _service.saveModelProvider(model.provider);
                  },
                ),
                const SizedBox(height: 24),

                // ── Save button ──────────────────────────────────────────
                ElevatedButton(
                  onPressed: _aiStatus == 'checking' ? null : _saveSettings,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _aiStatus == 'checking'
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
                const SizedBox(height: 24),

                RagSection(
                  embeddingMode: _embeddingMode,
                  onEmbeddingModeChanged: (v) async {
                    setState(() => _embeddingMode = v);
                    await _service.saveEmbeddingMode(v);
                  },
                  embeddingApiKeyController: _embeddingApiKeyController,
                  obscureEmbeddingKey: _obscureEmbeddingKey,
                  onToggleObscureEmbeddingKey: () => setState(
                    () => _obscureEmbeddingKey = !_obscureEmbeddingKey,
                  ),
                  onEmbeddingApiKeyChanged: (v) =>
                      _service.saveEmbeddingApiKey(v.trim()),
                  indexingTrigger: _indexingTrigger,
                  onIndexingTriggerChanged: (v) async {
                    setState(() => _indexingTrigger = v);
                    await _service.saveIndexingTrigger(v);
                  },
                ),
                const SizedBox(height: 24),

                StatusBadge(aiStatus: _aiStatus),
              ],
            ),
    );
  }
}
