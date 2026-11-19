import 'package:json_annotation/json_annotation.dart';

part 'api_guild.g.dart';

@JsonSerializable()
class ApiGuildResponse {
  ApiGuildResponse({
    required this.code,
    required this.message,
    required this.result,
  });

  factory ApiGuildResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiGuildResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiGuildResponseToJson(this);

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
  ApiResponseResultList({required this.username, required this.score});

  factory ApiResponseResultList.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseResultListFromJson(json);

  Map<String, dynamic> toJson() => _$ApiResponseResultListToJson(this);

  @JsonKey(name: 'name')
  final String? username;
  @JsonKey(name: 'score')
  final int score;
}
