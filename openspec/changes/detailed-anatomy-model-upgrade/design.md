## Context

Người dùng muốn mô hình 3D xoay 360 độ hiển thị các nhóm cơ có độ chi tiết giải phẫu học cao tương tự các ảnh minh họa y khoa chuyên nghiệp (hiển thị thớ cơ, gân bám, khung xương phụ trợ như xương quai xanh, đầu gối, cột sống). 

Chúng ta sẽ tận dụng chức năng của CustomPaint hiện tại và nâng cấp kỹ thuật vẽ trên canvas để mô phỏng hình ảnh y tế chân thực nhất mà không làm giảm hiệu năng ứng dụng.

## Goals / Non-Goals

**Goals:**
- Tăng độ chi tiết của mô hình cơ thể cơ bản bằng cách vẽ thêm:
  - Khung đầu chi tiết (có tai, mũi, cằm xoay theo góc nghiêng thực tế).
  - Khung xương quai xanh, xương sườn, xương bánh chè ở đầu gối, khuỷu tay.
  - Cột sống và phân chia cơ mông ở mặt sau.
- Tăng độ chi tiết của các nhóm cơ tương tác bằng cách vẽ thêm:
  - Các thớ cơ (muscle fibers/striations) chạy dọc hướng co duỗi của cơ bắp.
  - Điểm bám gân/fascia màu kem/sáng tại các đầu cơ.
- Đảm bảo hiệu năng vẽ mượt mà khi người dùng kéo xoay 360 độ (dùng các phép toán vector cơ bản trên Canvas thay vì nạp ảnh nặng hoặc mô hình 3D thực thể).

**Non-Goals:**
- Không thay đổi logic tương tác chạm (hit-test) và điều hướng bài tập.
- Không tích hợp thư viện đồ họa 3D bên ngoài (như OpenGL/Filament).

## Decisions

### Quyết định 1: Sử dụng kỹ thuật ClipPath và vẽ sợi cơ (striations) động
- Mỗi nhóm cơ được định nghĩa bởi một `Path`. Khi vẽ nhóm cơ, chúng ta sẽ lưu canvas (`canvas.save`), cắt theo đường dẫn (`canvas.clipPath(path)`), sau đó vẽ 5-10 đường sọc mảnh song song/hướng tâm đại diện cho thớ cơ với opacity vừa phải (0.15 - 0.35). Cuối cùng phục hồi canvas (`canvas.restore`).
- Việc này giúp sợi cơ luôn nằm hoàn hảo trong ranh giới cơ bắp dù mô hình xoay ở bất kỳ góc độ nào, tạo cảm giác lập thể 3D cực kỳ cao cấp.

### Quyết định 2: Tự động chiếu (project) các chi tiết giải phẫu học tĩnh
- Các chi tiết như xương quai xanh, cột sống sẽ được tính toán vị trí Z để khi xoay 360 độ, độ sáng/độ hiển thị (visibility) của chúng sẽ mờ dần hoặc biến mất tùy thuộc vào góc nhìn (mặt trước vs mặt sau), tránh tình trạng chi tiết mặt trước hiển thị xuyên thấu ra mặt sau.

## Risks / Trade-offs

- **[Risk] Vẽ quá nhiều đường thẳng trên Canvas gây giật lag khi drag xoay:**
  - *Mitigation:* Giới hạn số lượng thớ cơ vẽ trên mỗi vùng cơ từ 3 đến 8 sợi. Sử dụng các nét vẽ cơ bản (`drawLine` hoặc `drawPath` đơn giản) có hiệu năng dựng hình phần cứng (hardware accelerated) cực kỳ cao trên Flutter.
