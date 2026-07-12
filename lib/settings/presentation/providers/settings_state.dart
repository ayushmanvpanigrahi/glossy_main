import 'package:flutter/material.dart';
import '../../data/models/settings_models.dart';

// ---------------------------------------------------------------------------
// Immutable UI state for the Settings feature.
// ---------------------------------------------------------------------------

class SettingsState {
  const SettingsState({
    this.isLoading = true,
    this.isSaving = false,
    this.isModelsLoading = true,
    this.modelsFetchError,
    this.modelFetchWarnings = const [],
    this.obscureOr = true,
    this.obscureGroq = true,
    this.obscureGemini = true,
    this.orStatus = KeyStatus.idle,
    this.groqStatus = KeyStatus.idle,
    this.geminiStatus = KeyStatus.idle,
    this.modelPingResult,
    this.isPinging = false,
    this.allModels = const [],
    this.selectedModelId,
    this.selectedModelProvider = ModelProvider.openRouter,
    this.freeOnly = false,
    this.searchQuery = '',
    this.selectedProviders = const {
      ModelProvider.openRouter,
      ModelProvider.groq,
      ModelProvider.gemini,
    },
    this.selectedTypes = const {
      ModelType.text,
      ModelType.embedding,
      ModelType.other,
    },
    this.embeddingMode = 'api',
    this.indexingTrigger = 'onAdd',
    this.darkMode = false,
    this.autoScroll = true,
    this.fontSize = 'Medium',
    this.pageLayout = 'Single page',
    this.notificationsEnabled = true,
    this.language = 'English',
    this.snackbarMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final bool isModelsLoading;
  final String? modelsFetchError;
  final List<String> modelFetchWarnings;
  final bool obscureOr;
  final bool obscureGroq;
  final bool obscureGemini;
  final KeyStatus orStatus;
  final KeyStatus groqStatus;
  final KeyStatus geminiStatus;
  final ModelPingResult? modelPingResult;
  final bool isPinging;
  final List<OpenRouterModel> allModels;
  final String? selectedModelId;
  final ModelProvider selectedModelProvider;
  final bool freeOnly;
  final String searchQuery;
  final Set<ModelProvider> selectedProviders;
  final Set<ModelType> selectedTypes;
  final String embeddingMode;
  final String indexingTrigger;
  final bool darkMode;
  final bool autoScroll;
  final String fontSize;
  final String pageLayout;
  final bool notificationsEnabled;
  final String language;
  final String? snackbarMessage;

  static const userName = 'Aarav Mehta';
  static const userEmail = 'aarav@glossy.app';
  static const isPro = false;
  static const appVersion = 'v0.4.2';

  List<OpenRouterModel> get filteredModels {
    final q = searchQuery.toLowerCase();
    return allModels.where((m) {
      if (freeOnly && !m.isFree) return false;
      if (!selectedProviders.contains(m.effectiveProvider)) return false;
      if (!selectedTypes.contains(m.type)) return false;
      if (q.isNotEmpty &&
          !m.name.toLowerCase().contains(q) &&
          !m.id.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  SettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isModelsLoading,
    String? modelsFetchError,
    List<String>? modelFetchWarnings,
    bool? obscureOr,
    bool? obscureGroq,
    bool? obscureGemini,
    KeyStatus? orStatus,
    KeyStatus? groqStatus,
    KeyStatus? geminiStatus,
    ModelPingResult? modelPingResult,
    bool clearPingResult = false,
    bool? isPinging,
    List<OpenRouterModel>? allModels,
    String? selectedModelId,
    ModelProvider? selectedModelProvider,
    bool? freeOnly,
    String? searchQuery,
    Set<ModelProvider>? selectedProviders,
    Set<ModelType>? selectedTypes,
    String? embeddingMode,
    String? indexingTrigger,
    bool? darkMode,
    bool? autoScroll,
    String? fontSize,
    String? pageLayout,
    bool? notificationsEnabled,
    String? language,
    String? snackbarMessage,
    bool clearSnackbar = false,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isModelsLoading: isModelsLoading ?? this.isModelsLoading,
      modelsFetchError: modelsFetchError,
      modelFetchWarnings: modelFetchWarnings ?? this.modelFetchWarnings,
      obscureOr: obscureOr ?? this.obscureOr,
      obscureGroq: obscureGroq ?? this.obscureGroq,
      obscureGemini: obscureGemini ?? this.obscureGemini,
      orStatus: orStatus ?? this.orStatus,
      groqStatus: groqStatus ?? this.groqStatus,
      geminiStatus: geminiStatus ?? this.geminiStatus,
      modelPingResult: clearPingResult
          ? null
          : (modelPingResult ?? this.modelPingResult),
      isPinging: isPinging ?? this.isPinging,
      allModels: allModels ?? this.allModels,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      selectedModelProvider:
          selectedModelProvider ?? this.selectedModelProvider,
      freeOnly: freeOnly ?? this.freeOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedProviders: selectedProviders ?? this.selectedProviders,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      embeddingMode: embeddingMode ?? this.embeddingMode,
      indexingTrigger: indexingTrigger ?? this.indexingTrigger,
      darkMode: darkMode ?? this.darkMode,
      autoScroll: autoScroll ?? this.autoScroll,
      fontSize: fontSize ?? this.fontSize,
      pageLayout: pageLayout ?? this.pageLayout,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      snackbarMessage: clearSnackbar
          ? null
          : (snackbarMessage ?? this.snackbarMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Text controllers — owned separately so they survive state rebuilds.
// ---------------------------------------------------------------------------

class SettingsControllers {
  SettingsControllers()
    : orKeyCtrl = TextEditingController(),
      groqKeyCtrl = TextEditingController(),
      geminiKeyCtrl = TextEditingController(),
      modelSearchCtrl = TextEditingController();

  final TextEditingController orKeyCtrl;
  final TextEditingController groqKeyCtrl;
  final TextEditingController geminiKeyCtrl;
  final TextEditingController modelSearchCtrl;

  void dispose() {
    orKeyCtrl.dispose();
    groqKeyCtrl.dispose();
    geminiKeyCtrl.dispose();
    modelSearchCtrl.dispose();
  }
}
