import 'package:json_annotation/json_annotation.dart';
import 'package:pffs/logic/storage.dart';
import 'package:path/path.dart' as p;

part 'core.g.dart';

@JsonSerializable()
class PlaylistConf {
  final List<TrackConf> tracks;

  PlaylistConf({required this.tracks});

  /// Connect the generated [_$PlaylistConfFromJson] function to the `fromJson`
  /// factory.
  factory PlaylistConf.fromJson(Map<String, dynamic> json) =>
      _$PlaylistConfFromJson(json);

  /// Connect the generated [_$PlaylistConfToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PlaylistConfToJson(this);
}

@JsonSerializable()
class TrackConf {
  final String relativePath;
  VolumeConf volume;
  SkipConf skip;

  TrackConf(
      {required this.relativePath, required this.volume, required this.skip});

  MediaInfo getMediaInfo(String libraryPath) {
    return MediaInfo(null, relativePath, p.join(libraryPath, relativePath),
        p.basenameWithoutExtension(relativePath));
  }

  /// Connect the generated [_$TrackConfFromJson] function to the `fromJson`
  /// factory.
  factory TrackConf.fromJson(Map<String, dynamic> json) =>
      _$TrackConfFromJson(json);

  /// Connect the generated [_$TrackConfToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$TrackConfToJson(this);
}

@JsonSerializable()
class Effect {
  Effect();

  /// Connect the generated [_$EffectFromJson] function to the `fromJson`
  /// factory.
  factory Effect.fromJson(Map<String, dynamic> json) => _$EffectFromJson(json);

  /// Connect the generated [_$EffectConfToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$EffectToJson(this);
}

@JsonSerializable()
class VolumeConf extends Effect {
  bool isActive;
  double startVolume;
  double endVolume;
  int transitionTimeSeconds;

  VolumeConf(
      {required this.startVolume,
      required this.endVolume,
      required this.isActive,
      required this.transitionTimeSeconds});

  static VolumeConf defaultConf() {
    return VolumeConf(
        transitionTimeSeconds: 0,
        startVolume: 1,
        endVolume: 1,
        isActive: false);
  }

  /// Connect the generated [_$VolumeConfFromJson] function to the `fromJson`
  /// factory.
  factory VolumeConf.fromJson(Map<String, dynamic> json) =>
      _$VolumeConfFromJson(json);

  /// Connect the generated [_$VolumeConfToJson] function to the `toJson` method.
  @override
  Map<String, dynamic> toJson() => _$VolumeConfToJson(this);
}

@JsonSerializable()
class SkipConf extends Effect {
  bool isActive;
  int start;
  int end;
  SkipConf({required this.start, required this.end, required this.isActive});

  static SkipConf defaultConf() {
    return SkipConf(start: 0, end: 0, isActive: false);
  }

  /// Connect the generated [_$SkipConfFromJson] function to the `fromJson`
  /// factory.
  factory SkipConf.fromJson(Map<String, dynamic> json) =>
      _$SkipConfFromJson(json);

  /// Connect the generated [_$SkipConfToJson] function to the `toJson` method.
  @override
  Map<String, dynamic> toJson() => _$SkipConfToJson(this);
}
