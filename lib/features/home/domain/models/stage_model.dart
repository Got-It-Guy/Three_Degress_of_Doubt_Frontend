class StageModel {
  final int stageId;
  final String title;
  final String description;
  final String? thumbnailUrl; 
  final bool isRandom;
  final int stageScore;
  final int warningCount;
  final bool isCleared;

  StageModel({
    required this.stageId,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.isRandom,
    required this.stageScore,
    required this.warningCount,
    required this.isCleared,
  });

  factory StageModel.fromJson(Map<String, dynamic> json) {
    return StageModel(
      stageId: json['stage_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isRandom: json['is_random'] as bool,
      stageScore: json['stage_score'] as int,
      warningCount: json['warning_count'] as int,
      isCleared: json['is_cleared'] as bool,
    );
  }
}