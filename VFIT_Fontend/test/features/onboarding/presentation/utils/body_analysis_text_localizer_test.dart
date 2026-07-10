import 'package:flutter_test/flutter_test.dart';
import 'package:vfit_frontend/features/onboarding/presentation/utils/body_analysis_text_localizer.dart';

void main() {
  group('BodyAnalysisTextLocalizer', () {
    test('dịch các phản hồi dự phòng tiếng Anh từ máy chủ', () {
      expect(
        BodyAnalysisTextLocalizer.localize(
          'Unknown - No person detected',
          fallback: 'Đang phân tích...',
        ),
        'Chưa xác định - Không phát hiện người trong khung hình',
      );
      expect(
        BodyAnalysisTextLocalizer.localize(
          'Analysis pending - Body shape model is warming up',
          fallback: 'Đang phân tích...',
        ),
        'Đang chờ phân tích - Mô hình phân tích hình thể đang khởi động',
      );
      expect(
        BodyAnalysisTextLocalizer.localize(
          'Keep the whole body visible in frame.',
          fallback: 'Duy trì lịch tập luyện hiện tại.',
        ),
        'Giữ toàn bộ cơ thể trong khung hình.',
      );
    });

    test('giữ nguyên phản hồi tiếng Việt và dùng nội dung dự phòng khi trống',
        () {
      expect(
        BodyAnalysisTextLocalizer.localize(
          'Tư thế cân bằng',
          fallback: 'Đang phân tích...',
        ),
        'Tư thế cân bằng',
      );
      expect(
        BodyAnalysisTextLocalizer.localize(
          '  ',
          fallback: 'Đang phân tích...',
        ),
        'Đang phân tích...',
      );
    });
  });
}
