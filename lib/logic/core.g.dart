// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistConf _$PlaylistConfFromJson(Map<String, dynamic> json) => PlaylistConf(
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => TrackConf.fromJson(e as Map<String, dynamic>))
          .toList(),
    )
      ..shuffled = json['shuffled'] as bool?
      ..loopMode = $enumDecodeNullable(_$LoopModeEnumMap, json['loopMode']);

Map<String, dynamic> _$PlaylistConfToJson(PlaylistConf instance) =>
    <String, dynamic>{
      'tracks': instance.tracks,
      'shuffled': instance.shuffled,
      'loopMode': _$LoopModeEnumMap[instance.loopMode],
    };

const _$LoopModeEnumMap = {
  LoopMode.off: 'off',
  LoopMode.one: 'one',
  LoopMode.all: 'all',
};

TrackConf _$TrackConfFromJson(Map<String, dynamic> json) => TrackConf(
      relativePath: json['relativePath'] as String,
      volume: json['volume'] == null
          ? null
          : VolumeConf.fromJson(json['volume'] as Map<String, dynamic>),
      skip: json['skip'] == null
          ? null
          : SkipConf.fromJson(json['skip'] as Map<String, dynamic>),
      speed: json['speed'] == null
          ? null
          : SpeedConf.fromJson(json['speed'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TrackConfToJson(TrackConf instance) => <String, dynamic>{
      'relativePath': instance.relativePath,
      'volume': instance.volume,
      'skip': instance.skip,
      'speed': instance.speed,
    };

Effect _$EffectFromJson(Map<String, dynamic> json) => Effect();

Map<String, dynamic> _$EffectToJson(Effect instance) => <String, dynamic>{};

VolumeConf _$VolumeConfFromJson(Map<String, dynamic> json) => VolumeConf(
      startVolume: (json['startVolume'] as num?)?.toDouble() ?? 1,
      endVolume: (json['endVolume'] as num?)?.toDouble() ?? 1,
      isActive: json['isActive'] as bool? ?? false,
      transitionTimeSeconds:
          (json['transitionTimeSeconds'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$VolumeConfToJson(VolumeConf instance) =>
    <String, dynamic>{
      'isActive': instance.isActive,
      'startVolume': instance.startVolume,
      'endVolume': instance.endVolume,
      'transitionTimeSeconds': instance.transitionTimeSeconds,
    };

SkipConf _$SkipConfFromJson(Map<String, dynamic> json) => SkipConf(
      start: (json['start'] as num?)?.toInt() ?? 0,
      end: (json['end'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? false,
    );

Map<String, dynamic> _$SkipConfToJson(SkipConf instance) => <String, dynamic>{
      'isActive': instance.isActive,
      'start': instance.start,
      'end': instance.end,
    };

SpeedConf _$SpeedConfFromJson(Map<String, dynamic> json) => SpeedConf(
      speed: (json['speed'] as num?)?.toDouble() ?? 1,
      isActive: json['isActive'] as bool? ?? false,
    );

Map<String, dynamic> _$SpeedConfToJson(SpeedConf instance) => <String, dynamic>{
      'isActive': instance.isActive,
      'speed': instance.speed,
    };
