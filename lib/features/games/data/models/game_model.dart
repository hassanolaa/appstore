class ScreenshotModel {
  final int id;
  final String appId;
  final String? source;
  final String? thumbnail;
  final int? width;
  final int? height;

  ScreenshotModel({
    required this.id,
    required this.appId,
    this.source,
    this.thumbnail,
    this.width,
    this.height,
  });

  factory ScreenshotModel.fromMap(Map<String, dynamic> map) {
    return ScreenshotModel(
      id: map['id'] as int,
      appId: map['app_id'] as String,
      source: map['source'] as String?,
      thumbnail: map['thumbnail'] as String?,
      width: map['width'] as int?,
      height: map['height'] as int?,
    );
  }
}

class BundleModel {
  final int id;
  final String appId;
  final String? flatpakRef;
  final String? runtime;
  final String? sdk;
  final String? arch;
  final String? branch;

  BundleModel({
    required this.id,
    required this.appId,
    this.flatpakRef,
    this.runtime,
    this.sdk,
    this.arch,
    this.branch,
  });

  factory BundleModel.fromMap(Map<String, dynamic> map) {
    return BundleModel(
      id: map['id'] as int,
      appId: map['app_id'] as String,
      flatpakRef: map['flatpak_ref'] as String?,
      runtime: map['runtime'] as String?,
      sdk: map['sdk'] as String?,
      arch: map['arch'] as String?,
      branch: map['branch'] as String?,
    );
  }
}

class GameModel {
  final String id;
  final String? name;
  final String? summary;
  final String? description;
  final String? developer;
  final String? license;
  final String? icon64;
  final String? icon128;
  final List<ScreenshotModel> screenshots;
  final List<BundleModel> bundles;

  GameModel({
    required this.id,
    this.name,
    this.summary,
    this.description,
    this.developer,
    this.license,
    this.icon64,
    this.icon128,
    this.screenshots = const [],
    this.bundles = const [],
  });

  factory GameModel.fromMap(
    Map<String, dynamic> map, {
    List<ScreenshotModel> screenshots = const [],
    List<BundleModel> bundles = const [],
  }) {
    return GameModel(
      id: map['id'] as String,
      name: map['name'] as String?,
      summary: map['summary'] as String?,
      description: map['description'] as String?,
      developer: map['developer'] as String?,
      license: map['license'] as String?,
      icon64: map['icon64'] as String?,
      icon128: map['icon128'] as String?,
      screenshots: screenshots,
      bundles: bundles,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'summary': summary,
      'description': description,
      'developer': developer,
      'license': license,
      'icon64': icon64,
      'icon128': icon128,
    };
  }
}
