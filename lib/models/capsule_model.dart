import 'dart:convert';

class CapsuleModel {
  final String id;
  final String title;
  final String rawTranscript;
  final String summary;
  final List<String> actionItems;
  final DateTime createdAt;
  final bool isProcessed;
  final List<String> tags;

  const CapsuleModel({
    required this.id,
    required this.title,
    required this.rawTranscript,
    this.summary = '',
    this.actionItems = const [],
    required this.createdAt,
    this.isProcessed = false,
    this.tags = const [],
  });

  CapsuleModel copyWith({
    String? id,
    String? title,
    String? rawTranscript,
    String? summary,
    List<String>? actionItems,
    DateTime? createdAt,
    bool? isProcessed,
    List<String>? tags,
  }) {
    return CapsuleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      summary: summary ?? this.summary,
      actionItems: actionItems ?? this.actionItems,
      createdAt: createdAt ?? this.createdAt,
      isProcessed: isProcessed ?? this.isProcessed,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'rawTranscript': rawTranscript,
      'summary': summary,
      'actionItems': actionItems,
      'createdAt': createdAt.toIso8601String(),
      'isProcessed': isProcessed,
      'tags': tags,
    };
  }

  factory CapsuleModel.fromMap(Map<String, dynamic> map) {
    return CapsuleModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      rawTranscript: map['rawTranscript'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      actionItems: List<String>.from(map['actionItems'] ?? const []),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isProcessed: map['isProcessed'] as bool? ?? false,
      tags: List<String>.from(map['tags'] ?? const []),
    );
  }

  String toJson() => json.encode(toMap());

  factory CapsuleModel.fromJson(String source) =>
      CapsuleModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CapsuleModel(id: , title: , isProcessed: , createdAt: )';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CapsuleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
