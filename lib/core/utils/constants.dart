/// Base URL + every endpoint path. Controllers reference these instead of
/// hard-coding strings, so a route change is a one-line edit here.
class Constants {
  Constants._();

  static const String appVersion = 'Version 1.0.1';

  static const String baseUrl = 'https://example.com';
  static const String subUrl = '/api';

  // Endpoints
  static const String loginUrl = '/auth/login';
  static const String profileUrl = '/user/profile';
  static const String homeUrl = '/home';

  /// Android needs the **Web** OAuth client id here (not the Android one) –
  /// that is what mints the ID token Firebase accepts. Copy it from the
  /// Firebase console: Project settings > General > Web API client, or from
  /// google-services.json under `oauth_client` with `client_type: 3`.
  static const String googleServerClientId =
      '230061925255-34ak8hc9qnv5bbs8d7m42v0mc4jorikl.apps.googleusercontent.com';

  /// The Firestore database this app talks to.
  ///
  /// Firestore's implicit default database is named `(default)` – with the
  /// parentheses. The console lets you create a *named* database instead, and
  /// this project has one called `default` (no parentheses). They are two
  /// different databases; using the wrong id fails every call with NOT_FOUND.
  static const String firestoreDatabaseId = 'default';

  /// iOS OAuth client id, from GoogleService-Info.plist (`CLIENT_ID`).
  static const String googleIosClientId =
      'REPLACE_ME.apps.googleusercontent.com';
}
