// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiPlayerResponse _$ApiPlayerResponseFromJson(Map<String, dynamic> json) =>
    ApiPlayerResponse(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      result: ApiResponseResult.fromJson(
        json['result'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ApiPlayerResponseToJson(ApiPlayerResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
    };

ApiResponseResult _$ApiResponseResultFromJson(Map<String, dynamic> json) =>
    ApiResponseResult(
      date: ApiResponseResultDate.fromJson(
        json['date'] as Map<String, dynamic>,
      ),
      list: (json['list'] as List<dynamic>)
          .map((e) => ApiResponseResultList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ApiResponseResultToJson(ApiResponseResult instance) =>
    <String, dynamic>{'date': instance.date, 'list': instance.list};

ApiResponseResultDate _$ApiResponseResultDateFromJson(
  Map<String, dynamic> json,
) => ApiResponseResultDate(
  seasonStart: DateTime.parse(json['start'] as String),
  seasonEnd: DateTime.parse(json['end'] as String),
);

Map<String, dynamic> _$ApiResponseResultDateToJson(
  ApiResponseResultDate instance,
) => <String, dynamic>{
  'start': instance.seasonStart.toIso8601String(),
  'end': instance.seasonEnd.toIso8601String(),
};

ApiResponseResultList _$ApiResponseResultListFromJson(
  Map<String, dynamic> json,
) => ApiResponseResultList(
  username: json['nick'] as String,
  wave: (json['wave'] as num?)?.toInt(),
  score: (json['score'] as num).toInt(),
  lastOnline: json['date'] == null
      ? null
      : DateTime.parse(json['date'] as String),
);

Map<String, dynamic> _$ApiResponseResultListToJson(
  ApiResponseResultList instance,
) => <String, dynamic>{
  'nick': instance.username,
  'wave': instance.wave,
  'score': instance.score,
  'date': instance.lastOnline?.toIso8601String(),
};
