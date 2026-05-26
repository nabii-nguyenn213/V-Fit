## Context

Để giải quyết yêu cầu bản đồ cơ bắp 3D xoay 360 độ và lọc chi tiết đến từng nhóm cơ phụ (ví dụ: vai trước, vai giữa, vai sau, ngực trên, ngực giữa, v.v.), chúng ta sẽ kích hoạt và sử dụng `InteractiveMuscleModelViewer` thay thế cho bản đồ SVG tĩnh `InteractiveMuscleMap`.

`InteractiveMuscleModelViewer` vẽ mô hình cơ bắp bằng CustomPainter sử dụng phép chiếu 3D toán học cơ bản kết hợp với các đa giác và thớ cơ vẽ tay đẹp mắt, cho phép vuốt xoay 360 độ mượt mà và hỗ trợ phân chia chi tiết các nhóm cơ phụ thông qua các vùng cơ (`_MuscleZone`).

## Goals / Non-Goals

**Goals:**
- Tích hợp `InteractiveMuscleModelViewer` làm widget hiển thị bản đồ cơ bắp trong `ExerciseLibraryPage` (`exercise_library_page.dart`).
- Đảm bảo tương tác chạm (hit-test) vào từng nhóm cơ phụ (như vai trước, vai giữa, ngực trên, ngực giữa, v.v.) hoạt động chính xác theo góc xoay hiện tại.
- Khi bấm chọn một nhóm cơ phụ cụ thể (ví dụ: cơ vai trước `front-delt`), hệ thống sẽ mở rộng (expand) danh sách bài tập của nhóm cơ phụ Vai trước trong `ExerciseGroupDetailPage` nhờ tham số `initialSubGroupId`.
- Đồng bộ mượt mà góc xoay bằng cử chỉ vuốt ngang (drag) và thanh trượt (slider).

**Non-Goals:**
- Không sử dụng file SVG cho mô hình xoay 3D (do SVG 2D chỉ hỗ trợ ảnh tĩnh và không thể chiếu xoay 3D động).
- Không làm thay đổi cơ chế tải danh sách bài tập từ bloc/repository hiện tại.

## Decisions

### Quyết định 1: Thay thế `InteractiveMuscleMap` bằng `InteractiveMuscleModelViewer`
- **Lý do:** Bản đồ SVG 2D chỉ có 2 mặt tĩnh và không thể xoay 360 độ liên tục. Mô hình 3D Custom Paint trong `InteractiveMuscleModelViewer` cho hiệu ứng xoay 360 độ mượt mà và trực quan hơn, đáp ứng yêu cầu người dùng.

### Quyết định 2: Hỗ trợ truyền `subGroupId` qua điều hướng trang chi tiết
- Khi chọn một cơ trong `InteractiveMuscleModelViewer`, callback `onSelection` trả về `MuscleMapSelection` chứa cả `group` (MuscleGroup) và `subGroupId` (String?).
- Điều hướng được thực hiện như sau:
  ```dart
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => ExerciseGroupDetailPage(
        group: selection.group,
        initialSubGroupId: selection.subGroupId,
      ),
    ),
  );
  ```
- Trong `ExerciseGroupDetailPage`, chúng ta sử dụng `initialSubGroupId` để tự động mở rộng (`initiallyExpanded: subGroup.id == initialSubGroupId`) cho nhóm cơ phụ được chọn, giúp người dùng trực tiếp thấy các bài tập cho cơ vai trước, vai sau, ngực trên, v.v.

## Risks / Trade-offs

- **[Risk] Khớp mã ID nhóm cơ phụ giữa UI và dữ liệu:**
  - *Mitigation:* Xác minh và đảm bảo các mã ID trong `_buildZones` (như `front-delt`, `side-delt`, `rear-delt`, `upper-chest`, `mid-chest`, `lower-chest`) khớp hoàn toàn với `id` của `SubMuscleGroup` được trả về trong `MuscleGroup.subGroups` từ API/Database.
