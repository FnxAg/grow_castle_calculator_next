import 'package:json_annotation/json_annotation.dart';

part 'api_leaderboard.g.dart';

@JsonSerializable()
class ApiLeaderboardResponse {
  ApiLeaderboardResponse({
    required this.code,
    required this.message,
    required this.result,
  });

  factory ApiLeaderboardResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiLeaderboardResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiLeaderboardResponseToJson(this);

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
    required this.rank,
    required this.score,
    required this.name,
  });

  factory ApiResponseResultList.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseResultListFromJson(json);

  Map<String, dynamic> toJson() => _$ApiResponseResultListToJson(this);

  @JsonKey(name: 'rank')
  final int rank;
  @JsonKey(name: 'score')
  final int score;
  @JsonKey(name: 'name')
  final String name;
}
