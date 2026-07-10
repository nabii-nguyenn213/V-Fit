class BodyAnalysisTextLocalizer {
  const BodyAnalysisTextLocalizer._();

  static const _englishFallbacks = <String, String>{
    'Body analysis is temporarily unavailable.':
        'Phân tích hình thể tạm thời không khả dụng.',
    'No imbalance estimate available.':
        'Chưa có dữ liệu đánh giá độ lệch cơ thể.',
    'Minor left-right shoulder imbalance':
        'Vai trái và vai phải hơi mất cân đối',
    'Body type analysis pending': 'Đang chờ phân tích hình thể',
    'Body shape model is warming up':
        'Mô hình phân tích hình thể đang khởi động',
    'No significant imbalances': 'Không phát hiện lệch cơ thể đáng kể',
    'Keep the whole body visible in frame.':
        'Giữ toàn bộ cơ thể trong khung hình.',
    'Step fully into the camera frame.': 'Hãy đứng toàn thân trong khung hình.',
    'No pose landmarks available.': 'Không nhận diện được các mốc tư thế.',
    'Neutral posture baseline': 'Tư thế cân bằng',
    'No person detected': 'Không phát hiện người trong khung hình',
    'Center your body in frame': 'Hãy đứng ở giữa khung hình',
    'Continue current routine': 'Tiếp tục duy trì lịch tập hiện tại',
    'mobility and recomposition': 'cải thiện độ linh hoạt và thành phần cơ thể',
    'general fitness': 'thể lực tổng quát',
    'Analysis pending': 'Đang chờ phân tích',
    'Unknown': 'Chưa xác định',
    'Hypertrophy': 'phì đại cơ',
    'calories': 'năng lượng',
    'cardio': 'bài tập tim mạch',
    'protein': 'chất đạm',
  };

  static String localize(Object? value, {required String fallback}) {
    final rawText = value?.toString().trim();
    if (rawText == null || rawText.isEmpty) {
      return fallback;
    }

    return _englishFallbacks.entries.fold(
      rawText,
      (text, entry) => text.replaceAll(entry.key, entry.value),
    );
  }
}
