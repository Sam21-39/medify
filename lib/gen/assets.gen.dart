// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' as _svg;
import 'package:vector_graphics/vector_graphics.dart' as _vg;

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// File path: assets/icons/add.svg
  SvgGenImage get add => const SvgGenImage('assets/icons/add.svg');

  /// File path: assets/icons/calendar.svg
  SvgGenImage get calendar => const SvgGenImage('assets/icons/calendar.svg');

  /// File path: assets/icons/capsule.svg
  SvgGenImage get capsule => const SvgGenImage('assets/icons/capsule.svg');

  /// File path: assets/icons/capture.svg
  SvgGenImage get capture => const SvgGenImage('assets/icons/capture.svg');

  /// File path: assets/icons/caregiver.svg
  SvgGenImage get caregiver => const SvgGenImage('assets/icons/caregiver.svg');

  /// File path: assets/icons/delete.svg
  SvgGenImage get delete => const SvgGenImage('assets/icons/delete.svg');

  /// File path: assets/icons/doctor.svg
  SvgGenImage get doctor => const SvgGenImage('assets/icons/doctor.svg');

  /// File path: assets/icons/drop.svg
  SvgGenImage get drop => const SvgGenImage('assets/icons/drop.svg');

  /// File path: assets/icons/history.svg
  SvgGenImage get history => const SvgGenImage('assets/icons/history.svg');

  /// File path: assets/icons/home.svg
  SvgGenImage get home => const SvgGenImage('assets/icons/home.svg');

  /// File path: assets/icons/injection.svg
  SvgGenImage get injection => const SvgGenImage('assets/icons/injection.svg');

  /// File path: assets/icons/list.svg
  SvgGenImage get list => const SvgGenImage('assets/icons/list.svg');

  /// File path: assets/icons/medicine.svg
  SvgGenImage get medicine => const SvgGenImage('assets/icons/medicine.svg');

  /// File path: assets/icons/medify-icon.png
  AssetGenImage get medifyIcon =>
      const AssetGenImage('assets/icons/medify-icon.png');

  /// File path: assets/icons/notify.svg
  SvgGenImage get notify => const SvgGenImage('assets/icons/notify.svg');

  /// File path: assets/icons/ointment.svg
  SvgGenImage get ointment => const SvgGenImage('assets/icons/ointment.svg');

  /// File path: assets/icons/other_medicine.svg
  SvgGenImage get otherMedicine =>
      const SvgGenImage('assets/icons/other_medicine.svg');

  /// File path: assets/icons/patient.svg
  SvgGenImage get patient => const SvgGenImage('assets/icons/patient.svg');

  /// File path: assets/icons/pills.svg
  SvgGenImage get pills => const SvgGenImage('assets/icons/pills.svg');

  /// File path: assets/icons/refresh.svg
  SvgGenImage get refresh => const SvgGenImage('assets/icons/refresh.svg');

  /// File path: assets/icons/reminder.svg
  SvgGenImage get reminder => const SvgGenImage('assets/icons/reminder.svg');

  /// File path: assets/icons/settings.svg
  SvgGenImage get settings => const SvgGenImage('assets/icons/settings.svg');

  /// File path: assets/icons/skip.svg
  SvgGenImage get skip => const SvgGenImage('assets/icons/skip.svg');

  /// File path: assets/icons/snooze.svg
  SvgGenImage get snooze => const SvgGenImage('assets/icons/snooze.svg');

  /// File path: assets/icons/statistics.svg
  SvgGenImage get statistics =>
      const SvgGenImage('assets/icons/statistics.svg');

  /// File path: assets/icons/tablets.svg
  SvgGenImage get tablets => const SvgGenImage('assets/icons/tablets.svg');

  /// File path: assets/icons/theme.svg
  SvgGenImage get theme => const SvgGenImage('assets/icons/theme.svg');

  /// File path: assets/icons/time.svg
  SvgGenImage get time => const SvgGenImage('assets/icons/time.svg');

  /// File path: assets/icons/voice_note.svg
  SvgGenImage get voiceNote => const SvgGenImage('assets/icons/voice_note.svg');

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

class Assets {
  const Assets._();

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

class SvgGenImage {
  const SvgGenImage(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = false;

  const SvgGenImage.vec(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = true;

  final String _assetName;
  final Size? size;
  final Set<String> flavors;
  final bool _isVecFormat;

  _svg.SvgPicture svg({
    Key? key,
    bool matchTextDirection = false,
    AssetBundle? bundle,
    String? package,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool allowDrawingOutsideViewBox = false,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    _svg.SvgTheme? theme,
    _svg.ColorMapper? colorMapper,
    ColorFilter? colorFilter,
    Clip clipBehavior = Clip.hardEdge,
    @deprecated Color? color,
    @deprecated BlendMode colorBlendMode = BlendMode.srcIn,
    @deprecated bool cacheColorFilter = false,
  }) {
    final _svg.BytesLoader loader;
    if (_isVecFormat) {
      loader = _vg.AssetBytesLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
      );
    } else {
      loader = _svg.SvgAssetLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
        theme: theme,
        colorMapper: colorMapper,
      );
    }
    return _svg.SvgPicture(
      loader,
      key: key,
      matchTextDirection: matchTextDirection,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter:
          colorFilter ??
          (color == null ? null : ColorFilter.mode(color, colorBlendMode)),
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
