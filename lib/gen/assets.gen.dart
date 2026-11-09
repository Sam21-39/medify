// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// File path: assets/icons/add.svg
  String get add => 'assets/icons/add.svg';

  /// File path: assets/icons/calendar.svg
  String get calendar => 'assets/icons/calendar.svg';

  /// File path: assets/icons/capsule.svg
  String get capsule => 'assets/icons/capsule.svg';

  /// File path: assets/icons/capture.svg
  String get capture => 'assets/icons/capture.svg';

  /// File path: assets/icons/caregiver.svg
  String get caregiver => 'assets/icons/caregiver.svg';

  /// File path: assets/icons/delete.svg
  String get delete => 'assets/icons/delete.svg';

  /// File path: assets/icons/doctor.svg
  String get doctor => 'assets/icons/doctor.svg';

  /// File path: assets/icons/drop.svg
  String get drop => 'assets/icons/drop.svg';

  /// File path: assets/icons/history.svg
  String get history => 'assets/icons/history.svg';

  /// File path: assets/icons/home.svg
  String get home => 'assets/icons/home.svg';

  /// File path: assets/icons/injection.svg
  String get injection => 'assets/icons/injection.svg';

  /// File path: assets/icons/list.svg
  String get list => 'assets/icons/list.svg';

  /// File path: assets/icons/medicine.svg
  String get medicine => 'assets/icons/medicine.svg';

  /// File path: assets/icons/medify-icon.png
  AssetGenImage get medifyIcon =>
      const AssetGenImage('assets/icons/medify-icon.png');

  /// File path: assets/icons/notify.svg
  String get notify => 'assets/icons/notify.svg';

  /// File path: assets/icons/ointment.svg
  String get ointment => 'assets/icons/ointment.svg';

  /// File path: assets/icons/other_medicine.svg
  String get otherMedicine => 'assets/icons/other_medicine.svg';

  /// File path: assets/icons/patient.svg
  String get patient => 'assets/icons/patient.svg';

  /// File path: assets/icons/pills.svg
  String get pills => 'assets/icons/pills.svg';

  /// File path: assets/icons/refresh.svg
  String get refresh => 'assets/icons/refresh.svg';

  /// File path: assets/icons/reminder.svg
  String get reminder => 'assets/icons/reminder.svg';

  /// File path: assets/icons/settings.svg
  String get settings => 'assets/icons/settings.svg';

  /// File path: assets/icons/skip.svg
  String get skip => 'assets/icons/skip.svg';

  /// File path: assets/icons/snooze.svg
  String get snooze => 'assets/icons/snooze.svg';

  /// File path: assets/icons/statistics.svg
  String get statistics => 'assets/icons/statistics.svg';

  /// File path: assets/icons/tablets.svg
  String get tablets => 'assets/icons/tablets.svg';

  /// File path: assets/icons/theme.svg
  String get theme => 'assets/icons/theme.svg';

  /// File path: assets/icons/time.svg
  String get time => 'assets/icons/time.svg';

  /// File path: assets/icons/voice_note.svg
  String get voiceNote => 'assets/icons/voice_note.svg';

  /// List of all assets
  List<dynamic> get values => [
    add,
    calendar,
    capsule,
    capture,
    caregiver,
    delete,
    doctor,
    drop,
    history,
    home,
    injection,
    list,
    medicine,
    medifyIcon,
    notify,
    ointment,
    otherMedicine,
    patient,
    pills,
    refresh,
    reminder,
    settings,
    skip,
    snooze,
    statistics,
    tablets,
    theme,
    time,
    voiceNote,
  ];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/Medify.png
  AssetGenImage get medify => const AssetGenImage('assets/images/Medify.png');

  /// List of all assets
  List<AssetGenImage> get values => [medify];
}

class $AssetsSongsGen {
  const $AssetsSongsGen();

  /// File path: assets/songs/new-notification-026-380249.mp3
  String get newNotification026380249 =>
      'assets/songs/new-notification-026-380249.mp3';

  /// List of all assets
  List<String> get values => [newNotification026380249];
}

abstract final class Assets {
  static const $AssetsIconsGen icons = $AssetsIconsGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
  static const $AssetsSongsGen songs = $AssetsSongsGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
