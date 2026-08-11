import 'dart:convert';

import 'package:flutter/services.dart';

/// Machine-readable release facts shared by the app and release validation.
class ReleaseContract {
  ReleaseContract._({
    required this.contractVersion,
    required this.app,
    required this.data,
    required this.android,
    required this.native,
  });

  static const assetPath = 'assets/release_contract.json';
  static const compiledGitCommit = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: 'development',
  );

  final int contractVersion;
  final ReleaseAppInfo app;
  final ReleaseDataInfo data;
  final ReleaseAndroidInfo android;
  final ReleaseNativeInfo native;

  String get displayVersion => '${app.versionName}+${app.buildNumber}';

  static Future<ReleaseContract> load({AssetBundle? bundle}) async {
    final encoded = await (bundle ?? rootBundle).loadString(assetPath);
    return ReleaseContract.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
  }

  factory ReleaseContract.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> section(String key) =>
        Map<String, dynamic>.from(json[key] as Map);

    return ReleaseContract._(
      contractVersion: json['contractVersion'] as int,
      app: ReleaseAppInfo.fromJson(section('app')),
      data: ReleaseDataInfo.fromJson(section('data')),
      android: ReleaseAndroidInfo.fromJson(section('android')),
      native: ReleaseNativeInfo.fromJson(section('native')),
    );
  }
}

class ReleaseAppInfo {
  const ReleaseAppInfo({
    required this.name,
    required this.packageName,
    required this.versionName,
    required this.buildNumber,
    required this.gitCommitDartDefine,
  });

  final String name;
  final String packageName;
  final String versionName;
  final int buildNumber;
  final String gitCommitDartDefine;

  factory ReleaseAppInfo.fromJson(Map<String, dynamic> json) => ReleaseAppInfo(
    name: json['name'] as String,
    packageName: json['packageName'] as String,
    versionName: json['versionName'] as String,
    buildNumber: json['buildNumber'] as int,
    gitCommitDartDefine: json['gitCommitDartDefine'] as String,
  );
}

class ReleaseDataInfo {
  const ReleaseDataInfo({
    required this.databaseSchema,
    required this.backupManifest,
    required this.backupMagic,
    required this.supportedTargetProfileSchemas,
  });

  final int databaseSchema;
  final int backupManifest;
  final String backupMagic;
  final List<int> supportedTargetProfileSchemas;

  factory ReleaseDataInfo.fromJson(Map<String, dynamic> json) =>
      ReleaseDataInfo(
        databaseSchema: json['databaseSchema'] as int,
        backupManifest: json['backupManifest'] as int,
        backupMagic: json['backupMagic'] as String,
        supportedTargetProfileSchemas: List<int>.from(
          json['supportedTargetProfileSchemas'] as List,
        ),
      );
}

class ReleaseAndroidInfo {
  const ReleaseAndroidInfo({
    required this.requiredPermissions,
    required this.forbiddenPermissions,
    required this.releaseAbi,
    required this.requiredNativeLibraries,
  });

  final List<String> requiredPermissions;
  final List<String> forbiddenPermissions;
  final String releaseAbi;
  final List<String> requiredNativeLibraries;

  factory ReleaseAndroidInfo.fromJson(Map<String, dynamic> json) =>
      ReleaseAndroidInfo(
        requiredPermissions: List<String>.from(
          json['requiredPermissions'] as List,
        ),
        forbiddenPermissions: List<String>.from(
          json['forbiddenPermissions'] as List,
        ),
        releaseAbi: json['releaseAbi'] as String,
        requiredNativeLibraries: List<String>.from(
          json['requiredNativeLibraries'] as List,
        ),
      );
}

class ReleaseNativeInfo {
  const ReleaseNativeInfo({required this.vision, required this.shotTimer});

  final ReleaseVisionInfo vision;
  final ReleaseShotTimerInfo shotTimer;

  factory ReleaseNativeInfo.fromJson(Map<String, dynamic> json) =>
      ReleaseNativeInfo(
        vision: ReleaseVisionInfo.fromJson(
          Map<String, dynamic>.from(json['vision'] as Map),
        ),
        shotTimer: ReleaseShotTimerInfo.fromJson(
          Map<String, dynamic>.from(json['shotTimer'] as Map),
        ),
      );
}

class ReleaseVisionInfo {
  const ReleaseVisionInfo({
    required this.abiVersion,
    required this.engineVersion,
    required this.candidateAlgorithmVersion,
    required this.openCvVersion,
    required this.openCvSha256,
  });

  final int abiVersion;
  final String engineVersion;
  final String candidateAlgorithmVersion;
  final String openCvVersion;
  final String openCvSha256;

  factory ReleaseVisionInfo.fromJson(Map<String, dynamic> json) =>
      ReleaseVisionInfo(
        abiVersion: json['abiVersion'] as int,
        engineVersion: json['engineVersion'] as String,
        candidateAlgorithmVersion: json['candidateAlgorithmVersion'] as String,
        openCvVersion: json['openCvVersion'] as String,
        openCvSha256: json['openCvSha256'] as String,
      );
}

class ReleaseShotTimerInfo {
  const ReleaseShotTimerInfo({required this.detectorVersion});

  final String detectorVersion;

  factory ReleaseShotTimerInfo.fromJson(Map<String, dynamic> json) =>
      ReleaseShotTimerInfo(detectorVersion: json['detectorVersion'] as String);
}
