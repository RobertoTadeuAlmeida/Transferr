import '../config/demo_config.dart';

class RepositoryFactory {
  static T choose<T>(T realImpl, T demoImpl) {
    return DemoConfig.isDemoMode ? demoImpl : realImpl;
  }
}
