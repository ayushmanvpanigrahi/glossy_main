// ---------------------------------------------------------------------------
// Route path constants.
// ---------------------------------------------------------------------------

abstract final class AppRoutes {
  static const library = '/library';
  static const settings = '/settings';
}

abstract final class SettingsRoutes {
  static const profile = 'profile';
  static const plan = 'plan';
  static const apiKeys = 'api-keys';
  static const preferredModel = 'preferred-model';
  static const aiProvider = 'ai-provider';
  static const customPrompt = 'custom-prompt';
  static const rag = 'rag';
  static const serviceHealth = 'service-health';
  static const appearances = 'appearances';
  static const readingStats = 'reading-stats';
  static const notifications = 'notifications';
  static const language = 'language';
  static const privacy = 'privacy';
  static const help = 'help';

  static String path(String segment) => '${AppRoutes.settings}/$segment';
}
