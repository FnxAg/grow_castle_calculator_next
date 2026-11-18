// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_leaderboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiLeaderboardResponse _$ApiLeaderboardResponseFromJson(
  Map<String, dynamic> json,
) => ApiLeaderboardResponse(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String,
  result: ApiResponseResult.fromJson(json['result'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ApiLeaderboardResponseToJson(
  ApiLeaderboardResponse instance,
) => <String, dynamic>{
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
  rank: (json['rank'] as num).toInt(),
  score: (json['score'] as num).toInt(),
  name: json['name'] as String,
);

Map<String, dynamic> _$ApiResponseResultListToJson(
  ApiResponseResultList instance,
) => <String, dynamic>{
  'rank': instance.rank,
  'score': instance.score,
  'name': instance.name,
};
