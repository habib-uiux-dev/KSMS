/// Utility to filter out deleted, test, or excluded user accounts so they never
/// appear anywhere in the app.
class UserFilter {
  UserFilter._();

  static const Set<String> _excludedUids = {
    '4TEEuvMyfaTU5FZHXoaLKoA6w0W2',
    'Lx4FHOQY5sR3Qk9T9CcI9JFBHAh2',
    'ahdMhBZF4iVkZXz0pBVry05r3v73',
  };

  /// Returns true if this user matches one of the excluded accounts
  /// (e.g. "Md. Abidul Haque" or "MD. ALAMIN HOSSAIN").
  static bool isExcluded({
    String? uid,
    String? name,
    String? email,
  }) {
    if (uid != null && _excludedUids.contains(uid.trim())) {
      return true;
    }

    final n = (name ?? '')
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .trim();

    if (n.contains('abidulhaque') || n.contains('alaminhossain')) {
      return true;
    }

    final e = (email ?? '').toLowerCase().trim();
    if (e.contains('mdabidulhaque') ||
        e.contains('alamin35-486') ||
        e.contains('alamin.hossain')) {
      return true;
    }

    return false;
  }
}
