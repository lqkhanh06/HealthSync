# Nhật Ký Sử Dụng AI (AI Prompt Log)

**Học viên:** System Analyst & Database Administrator  
**Mục đích:** Hỗ trợ mô hình hóa dữ liệu, giải quyết bài toán chống làm tròn số tài chính và thiết kế ràng buộc toàn vẹn cho hệ thống HealthSync.

---

### Giai đoạn 1: Phân tích Anti-Pattern trạng thái vòng đời
* **Prompt học viên gửi:**  
  > "Trong thiết kế cơ sở dữ liệu quan hệ, tại sao việc dùng một cột `is_active` (kiểu TINYINT/BOOLEAN) để theo dõi vòng đời của một Đơn hàng/Lịch hẹn lại là một thiết kế tồi (Anti-pattern)? Tôi nên thay thế bằng cấu trúc nào để phản ánh 5 trạng thái: PENDING, CONFIRMED, CHECKED_IN, COMPLETED, CANCELLED?"
* **Phản hồi từ AI & Quyết định áp dụng:**  
  - Sử dụng kiểu dữ liệu `ENUM('PENDING', 'CONFIRMED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED')` trong MySQL để kiểm soát chặt chẽ giá trị đầu vào ngay tại tầng dữ liệu, tiết kiệm dung lượng lưu trữ (1 byte nội bộ) và ngăn chặn việc ghi nhận trạng thái không hợp lệ.

---

### Giai đoạn 2: Lựa chọn kiểu dữ liệu cho tiền cọc và phí phạt
* **Prompt học viên gửi:**  
  > "Khi thiết kế cột `deposit_amount` và `penalty_fee` trong MySQL phục vụ tính toán tài chính, tôi nên dùng kiểu dữ liệu FLOAT, DOUBLE hay DECIMAL? Tại sao?"
* **Phản hồi từ AI & Quyết định áp dụng:**  
  - `FLOAT` và `DOUBLE` là số thực dấu phẩy động nhị phân (IEEE 754), gây ra sai số làm tròn số học (Rounding / Precision Error), đặc biệt nghiêm trọng trong đối soát kế toán và kiểm toán.
  - Áp dụng `DECIMAL(12, 2)` (Fixed-point data type) để đảm bảo độ chính xác tuyệt đối từng xu/hào cho tiền cọc và tiền phạt, kết hợp ràng buộc `CHECK (deposit_amount >= 0)` và `CHECK (penalty_fee >= 0)`.

---

### Giai đoạn 3: Đảm bảo toàn vẹn dữ liệu cho Đơn thuốc (Prescriptions)
* **Prompt học viên gửi:**  
  > "Dựa vào ERD, nếu một lịch hẹn đang ở trạng thái PENDING (chưa khám), nhưng có người cố tình chèn (INSERT) một đơn thuốc vào bảng Prescriptions cho lịch hẹn đó, làm thế nào để tôi chặn hành động phi logic này ở tầng cơ sở dữ liệu thay vì chỉ dựa vào mã nguồn backend?"
* **Phản hồi từ AI & Quyết định áp dụng:**  
  - Viết `BEFORE INSERT TRIGGER` trên bảng `Prescriptions` kiểm tra `Appointments.status`. Nếu trạng thái khác `COMPLETED`, phát tín hiệu lỗi bằng `SIGNAL SQLSTATE '45000'` hủy transaction ngay lập tức.
  - Sử dụng ràng buộc `UNIQUE (appointment_id)` để đảm bảo quan hệ 1-1 chặt chẽ giữa Lịch hẹn hoàn tất và Đơn thuốc.
  - Cấu hình khóa ngoại `ON DELETE RESTRICT` để bảo vệ đơn thuốc không bị xóa ngoài ý muốn.
