import 'package:json_annotation/json_annotation.dart';

part 'api_player.g.dart';

@JsonSerializable()
class ApiPlayerResponse {
  ApiPlayerResponse({
    required this.code,
    required this.message,
    required this.result,
  });

  factory ApiPlayerResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiPlayerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiPlayerResponseToJson(this);

  @JsonKey(name: 'code')
  final int code;
  @JsonKey(name: 'message')
  final String message;
  @JsonKey(name: 'result')
  final ApiResponseResult result;
}

@JsonSerializable()
class ApiResponseResult {
  ApiResponseResult({required this.date, required this.list});

  factory ApiResponseResult.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseResultFromJson(json);

  Map<String, dynamic> toJson() => _$ApiResponseResultToJson(this);

  final ApiResponseResultDate date;
  final List<ApiResponseResultList> list;
}

@JsonSerializable()
class ApiResponseResultDate {
  ApiResponseResultDate({required this.seasonStart, required this.seasonEnd});

  factory ApiResponseResultDate.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseResultDateFromJson(json);

  Map<String, dynamic> toJson() => _$ApiResponseResultDateToJson(this);

  @JsonKey(name: 'start')
  final DateTime seasonStart;
  @JsonKey(name: 'end')
  final DateTime seasonEnd;
}

@JsonSerializable()
class ApiResponseResultList {
  ApiResponseResultList({
    required this.username,
    required this.wave,
    required this.score,
    required this.lastOnline,
  });

  factory ApiResponseResultList.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseResultListFromJson(json);

  Map<String, dynamic> toJson() => _$ApiResponseResultListToJson(this);

  @JsonKey(name: 'nick')
  final String username;
  @JsonKey(name: 'wave')
  final int? wave;
  @JsonKey(name: 'score')
  final int score;
  @JsonKey(name: 'date')
  final DateTime? lastOnline;
}
