import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ai_status.dart';
import '../../data/models/settings_models.dart';
import '../../data/services/settings_service.dart';
import 'settings_state.dart';

// ---------------------------------------------------------------------------
// Riverpod providers for Settings.
// ---------------------------------------------------------------------------

final settingsServiceProvider = Provider<SettingsService>(
  (ref) => SettingsService(),
);

final settingsControllersProvider = Provider<SettingsControllers>((ref) {
  final controllers = SettingsControllers();
  ref.onDispose(controllers.dispose);
  return controllers;
});

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

// ---------------------------------------------------------------------------
// SettingsNotifier — all business logic lives here.
// ---------------------------------------------------------------------------

class SettingsNotifier extends Notifier<SettingsState> {
  static bool _hasAutoValidatedThisSession = false;

  SettingsService get _service => ref.read(settingsServiceProvider);
  SettingsControllers get _ctrl => ref.read(settingsControllersProvider);

  @override
  SettingsState build() {
    Future.microtask(_init);
    return const SettingsState();
  }

  Future<void> _init() async {
    await Future.wait([_loadSaved(), _loadRag()]);
    await fetchModels();
    if (!_hasAutoValidatedThisSession) {
      await autoValidateAll();
      _hasAutoValidatedThisSession = true;
    }
  }

  Future<void> _loadSaved() async {
    final s = await _service.loadSavedSettings();
    if (s.apiKey != null) _ctrl.orKeyCtrl.text = s.apiKey!;
    if (s.groqApiKey != null) _ctrl.groqKeyCtrl.text = s.groqApiKey!;
    state = state.copyWith(
      selectedModelId: s.modelId,
      selectedModelProvider: s.modelProvider,
      isLoading: false,
    );
  }

  Future<void> _loadRag() async {
    final r = await _service.loadRagSettings();
    if (r.embeddingApiKey != null) {
      _ctrl.geminiKeyCtrl.text = r.embeddingApiKey!;
    }
    state = state.copyWith(
      embeddingMode: r.embeddingMode ?? 'api',
      indexingTrigger: r.indexingTrigger ?? 'onAdd',
    );
  }

  Future<void> fetchModels() async {
    state = state.copyWith(
      isModelsLoading: true,
      modelsFetchError: null,
      modelFetchWarnings: [],
    );
    try {
      final result = await _service.fetchAllModels(
        groqApiKey: _ctrl.groqKeyCtrl.text.trim(),
        geminiApiKey: _ctrl.geminiKeyCtrl.text.trim(),
      );
      state = state.copyWith(
        allModels: result.models,
        modelFetchWarnings: result.errors,
        isModelsLoading: false,
      );
      await _ensureValidModelSelected();
    } catch (_) {
      state = state.copyWith(
        modelsFetchError: 'Could not connect. Check your internet.',
        isModelsLoading: false,
      );
    }
  }

  Future<void> _ensureValidModelSelected() async {
    if (state.allModels.isEmpty) {
      if (state.selectedModelId != null) {
        state = state.copyWith(selectedModelId: null);
        await _service.deleteModelId();
      }
      return;
    }
    final stillValid = state.allModels.any(
      (m) => m.id == state.selectedModelId,
    );
    if (state.selectedModelId == null || !stillValid) {
      final fallback = state.allModels.first;
      state = state.copyWith(selectedModelId: fallback.id);
      await _service.saveModelId(fallback.id);
    }
  }

  Future<void> autoValidateAll() async {
    final or = _ctrl.orKeyCtrl.text.trim();
    final groq = _ctrl.groqKeyCtrl.text.trim();
    final gemini = _ctrl.geminiKeyCtrl.text.trim();
    await Future.wait([
      if (or.isNotEmpty) validateOrKey(or, announce: false),
      if (groq.isNotEmpty) validateGroqKey(groq, announce: false),
      if (gemini.isNotEmpty) validateGeminiKey(gemini, announce: false),
    ]);
    _syncAiStatus();
  }

  Future<void> validateOrKey(String key, {bool announce = true}) async {
    state = state.copyWith(orStatus: KeyStatus.checking);
    final result = await _service.validateOpenRouterKey(key);
    state = state.copyWith(orStatus: _toKeyStatus(result));
    if (announce) {
      _syncAiStatus();
      _showSnack(_orLabel(result));
    }
  }

  Future<void> validateGroqKey(String key, {bool announce = true}) async {
    state = state.copyWith(groqStatus: KeyStatus.checking);
    final result = await _service.validateGroqKey(key);
    state = state.copyWith(groqStatus: _toKeyStatus(result));
    if (announce) {
      _syncAiStatus();
      _showSnack(_groqLabel(result));
    }
  }

  Future<void> validateGeminiKey(String key, {bool announce = true}) async {
    state = state.copyWith(geminiStatus: KeyStatus.checking);
    final result = await _service.validateGeminiKey(key);
    state = state.copyWith(geminiStatus: _toKeyStatus(result));
    if (announce) _showSnack(_geminiLabel(result));
  }

  KeyStatus _toKeyStatus(ValidationResult r) => switch (r) {
    ValidationResult.valid => KeyStatus.valid,
    ValidationResult.invalid => KeyStatus.invalid,
    ValidationResult.networkError => KeyStatus.networkError,
    ValidationResult.unknown => KeyStatus.valid,
  };

  void _syncAiStatus() {
    final anyActive =
        state.orStatus == KeyStatus.valid ||
        state.groqStatus == KeyStatus.valid;
    final anyChecking =
        state.orStatus == KeyStatus.checking ||
        state.groqStatus == KeyStatus.checking;
    aiStatusNotifier.value = anyChecking
        ? 'checking'
        : anyActive
        ? 'active'
        : 'inactive';
  }

  Future<void> pingModel() async {
    final modelId = state.selectedModelId;
    if (modelId == null) return;
    final apiKey = switch (state.selectedModelProvider) {
      ModelProvider.groq => _ctrl.groqKeyCtrl.text.trim(),
      ModelProvider.gemini => _ctrl.geminiKeyCtrl.text.trim(),
      ModelProvider.openRouter => _ctrl.orKeyCtrl.text.trim(),
    };
    state = state.copyWith(isPinging: true, clearPingResult: true);
    final result = await _service.pingModel(
      modelId: modelId,
      provider: state.selectedModelProvider,
      apiKey: apiKey,
    );
    state = state.copyWith(isPinging: false, modelPingResult: result);
  }

  Future<void> save() async {
    state = state.copyWith(isSaving: true);
    await _service.saveAllSettings(
      openRouterKey: _ctrl.orKeyCtrl.text.trim(),
      groqKey: _ctrl.groqKeyCtrl.text.trim(),
      geminiKey: _ctrl.geminiKeyCtrl.text.trim(),
      modelId: state.selectedModelId,
      modelProvider: state.selectedModelProvider,
      embeddingMode: state.embeddingMode,
      indexingTrigger: state.indexingTrigger,
    );
    await autoValidateAll();
    state = state.copyWith(isSaving: false);
    _showSnack('Settings saved');
  }

  Future<void> selectModel(String id) async {
    final model = state.allModels.firstWhere((m) => m.id == id);
    state = state.copyWith(
      selectedModelId: id,
      selectedModelProvider: model.provider,
      clearPingResult: true,
    );
    await _service.saveModelId(id);
    await _service.saveModelProvider(model.provider);
  }

  Future<void> refreshModels() async {
    await fetchModels();
    await autoValidateAll();
  }

  void toggleObscureOr() => state = state.copyWith(obscureOr: !state.obscureOr);

  void toggleObscureGroq() =>
      state = state.copyWith(obscureGroq: !state.obscureGroq);

  void toggleObscureGemini() =>
      state = state.copyWith(obscureGemini: !state.obscureGemini);

  void setSearchQuery(String v) => state = state.copyWith(searchQuery: v);

  void setFreeOnly(bool v) => state = state.copyWith(freeOnly: v);

  void setSelectedProviders(Set<ModelProvider> v) =>
      state = state.copyWith(selectedProviders: v);

  void setSelectedTypes(Set<ModelType> v) =>
      state = state.copyWith(selectedTypes: v);

  void setEmbeddingMode(String v) => state = state.copyWith(embeddingMode: v);

  void setIndexingTrigger(String v) =>
      state = state.copyWith(indexingTrigger: v);

  void setDarkMode(bool v) => state = state.copyWith(darkMode: v);

  void setAutoScroll(bool v) => state = state.copyWith(autoScroll: v);

  void clearSnackbar() => state = state.copyWith(clearSnackbar: true);

  void signOut() => _showSnack('Signed out');

  String _orLabel(ValidationResult r) => switch (r) {
    ValidationResult.valid => 'OpenRouter key is valid ✓',
    ValidationResult.invalid => 'OpenRouter key is invalid',
    ValidationResult.networkError => 'Could not reach OpenRouter',
    ValidationResult.unknown => 'OpenRouter key accepted',
  };

  String _groqLabel(ValidationResult r) => switch (r) {
    ValidationResult.valid => 'Groq key is valid ✓',
    ValidationResult.invalid => 'Groq key is invalid',
    ValidationResult.networkError => 'Could not reach Groq',
    ValidationResult.unknown => 'Groq key accepted',
  };

  String _geminiLabel(ValidationResult r) => switch (r) {
    ValidationResult.valid => 'Gemini key is valid ✓',
    ValidationResult.invalid => 'Gemini key is invalid',
    ValidationResult.networkError => 'Could not reach Google',
    ValidationResult.unknown => 'Gemini key accepted',
  };

  void _showSnack(String msg) {
    state = state.copyWith(snackbarMessage: msg);
  }
}
