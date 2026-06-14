class CoachMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;

  const CoachMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  factory CoachMessageModel.fromJson(Map<String, dynamic> json) {
    return CoachMessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CoachMessageModel copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? createdAt,
  }) {
    return CoachMessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
