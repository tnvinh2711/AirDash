/// Route path constants for the FLUX application.
///
/// This class provides a centralized definition of all route paths
/// used in the application, preventing typos and providing a single
/// source of truth for navigation destinations.
abstract class Routes {
  /// The receive tab route path - default home destination.
  static const receive = '/receive';

  /// The send tab route path - file selection and peer discovery.
  static const send = '/send';

  /// The settings tab route path - app configuration.
  static const settings = '/settings';

  /// The transfer history route path - nested under receive.
  static const history = '/receive/history';
}
