// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistConf _$PlaylistConfFromJson(Map<String, dynamic> json) => PlaylistConf(
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => TrackConf.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlaylistConfToJson(PlaylistConf instance) =>
    <String, dynamic>{
      'tracks': instance.tracks,
    };

TrackConf _$TrackConfFromJson(Map<String, dynamic> json) => TrackConf(
      relativePath: json['relativePath'] as String,
      name: json['name'] as String,
      volume: VolumeConf.fromJson(json['volume'] as Map<String, dynamic>),
      skip: SkipConf.fromJson(json['skip'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TrackConfToJson(TrackConf instance) => <String, dynamic>{
      'relativePath': instance.relativePath,
      'name': instance.name,
      'volume': instance.volume,
      'skip': instance.skip,
    };

Effect _$EffectFromJson(Map<String, dynamic> json) => Effect();

Map<String, dynamic> _$EffectToJson(Effect instance) => <String, dynamic>{};

VolumeConf _$VolumeConfFromJson(Map<String, dynamic> json) => VolumeConf(
      startVolume: (json['startVolume'] as num).toDouble(),
      endVolume: (json['endVolume'] as num).toDouble(),
      isActive: json['isActive'] as bool,
      transitionTimeSeconds: (json['transitionTimeSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$VolumeConfToJson(VolumeConf instance) =>
    <String, dynamic>{
      'isActive': instance.isActive,
      'startVolume': instance.startVolume,
      'endVolume': instance.endVolume,
      'transitionTimeSeconds': instance.transitionTimeSeconds,
    };

SkipConf _$SkipConfFromJson(Map<String, dynamic> json) => SkipConf(
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$SkipConfToJson(SkipConf instance) => <String, dynamic>{
      'isActive': instance.isActive,
      'start': instance.start,
      'end': instance.end,
    };
