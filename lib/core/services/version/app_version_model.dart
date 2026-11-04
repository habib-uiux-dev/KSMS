class AppVersionModel {
  final int minBuildNumber;
  final String minVersion;
  final String latestVersion;
  final String updateUrl;
  final bool forceUpdate;
  final String title;
  final String message;
  final List<String> releaseNotes;

  const AppVersionModel({
    required this.minBuildNumber,
    required this.minVersion,
    required this.latestVersion,
    required this.updateUrl,
    required this.forceUpdate,
    required this.title,
    required this.message,
    this.releaseNotes = const [],
  });

  factory AppVersionModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const AppVersionModel(
        minBuildNumber: 0,
        minVersion: '1.0.0',
        latestVersion: '1.0.0',
        updateUrl: '',
        forceUpdate: false,
        title: 'নতুন আপডেট এসেছে!',
        message: 'KSMS অ্যাপ ব্যবহার চালিয়ে যেতে অনুগ্রহ করে এখনই আপডেট করুন।',
      );
    }

    final rawMinBuild = data['min_build_number'];
    final minBuild = rawMinBuild is int
        ? rawMinBuild
        : int.tryParse(rawMinBuild?.toString() ?? '') ?? 0;

    final notesRaw = data['release_notes'];
    final List<String> notes = notesRaw is List
        ? notesRaw.map((e) => e.toString()).toList()
        : const [];

    return AppVersionModel(
      minBuildNumber: minBuild,
      minVersion: (data['min_version'] ?? '1.0.0').toString(),
      latestVersion: (data['latest_version'] ?? '1.0.0').toString(),
      updateUrl: (data['update_url'] ?? '').toString(),
      forceUpdate: data['force_update'] as bool? ?? false,
      title: (data['title'] ?? 'নতুন আপডেট এসেছে!').toString(),
      message: (data['message'] ??
              'KSMS অ্যাপ ব্যবহার চালিয়ে যেতে অনুগ্রহ করে এখনই আপডেট করুন।')
          .toString(),
      releaseNotes: notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'min_build_number': minBuildNumber,
      'min_version': minVersion,
      'latest_version': latestVersion,
      'update_url': updateUrl,
      'force_update': forceUpdate,
      'title': title,
      'message': message,
      'release_notes': releaseNotes,
    };
  }
}
