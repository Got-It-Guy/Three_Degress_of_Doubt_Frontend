class StageProgress {
  final int stageId;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final int stageScore;
  final bool isCleared;
  final int bestRoundCount;

  const StageProgress({
    required this.stageId,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.stageScore,
    required this.isCleared,
    this.bestRoundCount = 0,
  });

  factory StageProgress.fromJson(Map<String, dynamic> json) {
    return StageProgress(
      stageId: json['stage_id'] as int,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      stageScore: json['stage_score'] as int? ?? 0,
      isCleared: json['is_cleared'] as bool? ?? false,
      bestRoundCount: json['best_round_count'] as int? ?? 0,
    );
  }

  StageProgress copyWith({
    int? stageId,
    String? title,
    String? description,
    String? thumbnailUrl,
    int? stageScore,
    bool? isCleared,
    int? bestRoundCount,
  }) {
    return StageProgress(
      stageId: stageId ?? this.stageId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      stageScore: stageScore ?? this.stageScore,
      isCleared: isCleared ?? this.isCleared,
      bestRoundCount: bestRoundCount ?? this.bestRoundCount,
    );
  }
}