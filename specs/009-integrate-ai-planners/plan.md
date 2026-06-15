# Implementation Plan: Tích hợp Premium AI Speed Dial & Gated VIP Access

**Branch**: `007-connect-ai-web2api` | **Date**: 2026-06-15

## Summary

Thiết lập nút bấm tròn mở rộng (Premium AI Speed Dial) mang phong cách VIP tại cả hai màn hình **Tập luyện** (Workout) và **Dinh dưỡng** (Nutrition). 
Nút này khi nhấn sẽ bung ra 2 tuỳ chọn:
1. **AI Coach (Miễn phí)**: Cho phép mọi tài khoản truy cập vào giao diện chat của AI Coach (`/ai/coach?tab=0`).
2. **AI Gen (Yêu cầu VIP)**: 
   - Trên tab Tập luyện: Tạo giáo án tập luyện AI (`/ai/coach?tab=1`).
   - Trên tab Dinh dưỡng: Tạo thực đơn dinh dưỡng AI (`/ai/coach?tab=2` hoặc `AiMealSheet`).
   - Nếu tài khoản thường: Mở pop-up yêu cầu VIP với giao diện bắt mắt ("lòe loẹt") `FlashyVipRequiredModal`.

---

## Technical Context

**Language/Version**: Dart 3.x, Flutter 3.x
**Primary Dependencies**: flutter_riverpod, go_router, flutter_bloc
**Target Platform**: Android / iOS
**Project Type**: Mobile Application (Frontend)
**Constraints**: Hoạt động mượt mà ở cả chế độ sáng (Light mode) và tối (Dark mode), hiệu ứng mở rộng mượt mà (Micro-animations).

---

## Constitution Check

- AI-native control plane is explicit for reasoning-driven behavior: **Yes, accesses FastAPI AI planner endpoints.**
- Prompt files under `skills/conversation/` own AI behavior: **Yes, backend prompts remain intact.**
- AI input and output contracts are bounded and reviewable: **Yes.**
- Premium AI paths enforce onboarding, JWT, subscription gates, rate limits, and fallback behavior: **Yes, checks user.isVipActive and shows FlashyVipRequiredModal.**

---

## Project Structure

### Documentation

- [plan.md](file:///d:/EXE_PRM/specs/009-integrate-ai-planners/plan.md)

### Source Code

```text
VFIT_Fontend/
└── lib/
    ├── core/
    │   └── widgets/
    │       ├── flashy_vip_required_modal.dart   # Shared premium VIP prompt modal [NEW]
    │       └── premium_ai_speed_dial.dart       # Reusable expandable floating button [NEW]
    ├── features/
    │   ├── ai/
    │   │   └── presentation/
    │   │       └── pages/
    │   │           └── ai_coach_page.dart       # Supporting initial tab parameter [MODIFY]
    │   ├── workout/
    │   │   └── presentation/
    │   │       └── pages/
    │   │           └── workout_page.dart        # Add speed dial to Scaffold FAB [MODIFY]
    │   └── nutrition/
    │   │       └── presentation/
    │   │           └── pages/
    │   │               └── nutrition_page.dart  # Add speed dial to Scaffold FAB [MODIFY]
```

---

## Proposed Changes

### 1. Core Widgets Layer

#### [NEW] [flashy_vip_required_modal.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/core/widgets/flashy_vip_required_modal.dart)
- Định nghĩa dialog `FlashyVipRequiredModal` với thiết kế premium cực kỳ bắt mắt:
  - Header với biểu tượng Vương miện vàng toả sáng (Golden Crown).
  - Tiêu đề phụ hiệu "V-FIT VIP MEMBER" áp dụng ShaderMask chuyển màu gradient (Neon hồng, xanh, vàng).
  - Nền chuyển sắc sâu (Deep gradient) kết hợp đổ bóng phát sáng (BoxShadow glow).
  - Liệt kê các quyền lợi VIP của AI Planner & AI Body Scan.
  - Nút nâng cấp điều hướng thẳng tới trang `/premium`.

#### [NEW] [premium_ai_speed_dial.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/core/widgets/premium_ai_speed_dial.dart)
- Thiết kế một Floating Action Button (FAB) tròn, có hiệu ứng chuyển màu gradient đặc sắc đại diện cho tính năng AI.
- Khi người dùng chạm vào nút, nó sẽ bung ra (Speed dial) hiển thị 2 nút chức năng nhỏ theo chiều dọc đi kèm animation xoay nhẹ nút chính:
  - Nút **AI Coach** (Icon chat bong bóng).
  - Nút **AI Planner** (Icon lấp lánh / vương miện đại diện cho VIP).
- Gắn kèm logic xác thực:
  - Nếu tuỳ chọn yêu cầu VIP được bấm: kiểm tra `user.isVipActive`. Nếu không thoả mãn, hiển thị `FlashyVipRequiredModal`. Nếu thoả mãn, kích hoạt luồng AI Planner.

---

### 2. Presentation Layer

#### [MODIFY] [ai_coach_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/ai/presentation/pages/ai_coach_page.dart)
- Cập nhật constructor để nhận tham số tuỳ chọn `initialTab` (mặc định là `0`).
- Gán `initialIndex: widget.initialTab` vào `DefaultTabController` để khi được điều hướng từ bên ngoài, màn hình sẽ mở đúng Tab mong muốn.
- Thay thế các dialog nâng cấp VIP mặc định bằng `FlashyVipRequiredModal` để thống nhất trải nghiệm người dùng.

#### [MODIFY] [app_router.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/core/router/app_router.dart)
- Cập nhật route `/ai/coach` để đọc tham số truy vấn `tab` từ URL (ví dụ `/ai/coach?tab=1`) và truyền vào widget `AiCoachPage`.

#### [MODIFY] [workout_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/workout/presentation/pages/workout_page.dart)
- Tích hợp `PremiumAiSpeedDial` vào thuộc tính `floatingActionButton` của `Scaffold`.
- Tuỳ chọn VIP: Lập kế hoạch tập luyện bằng AI (`/ai/coach?tab=1`).
- Thay thế `VipRequiredModal` bằng `FlashyVipRequiredModal`.

#### [MODIFY] [nutrition_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/nutrition/presentation/pages/nutrition_page.dart)
- Tích hợp `PremiumAiSpeedDial` vào thuộc tính `floatingActionButton` của `Scaffold`.
- Tuỳ chọn VIP: Thiết lập thực đơn ăn uống AI (`/ai/coach?tab=2` hoặc gọi trực tiếp `AiMealSheet.show`).
- Thay thế `VipRequiredModal` bằng `FlashyVipRequiredModal`.

---

## Verification Plan

### Automated Tests
- Chạy `flutter analyze` để xác thực toàn bộ codebase không gặp lỗi biên dịch hoặc cảnh báo tĩnh.

### Manual Verification
1. **Kiểm tra nút bấm**: Mở ứng dụng, chuyển qua lại giữa màn hình Workout và Nutrition, xác nhận nút tròn Premium AI Speed Dial xuất hiện ở góc dưới bên phải.
2. **Kiểm tra tính năng AI Coach**: Nhấn nút tròn -> chọn "AI Coach" -> Hệ thống điều hướng vào màn hình chat AI Coach thành công (không yêu cầu VIP).
3. **Kiểm tra tính năng AI Planner (Tài khoản thường)**: Đăng nhập tài khoản thường -> nhấn nút tròn -> chọn AI Planner -> Xác nhận hiện lên dialog `FlashyVipRequiredModal` vô cùng đẹp mắt. Bấm nút nâng cấp chuyển hướng đến trang `/premium`.
4. **Kiểm tra tính năng AI Planner (Tài khoản VIP)**: Đăng nhập tài khoản VIP -> nhấn nút tròn -> chọn AI Planner -> Hệ thống điều hướng trực tiếp vào tab Lập lịch tập / Tạo thực đơn tương ứng.
