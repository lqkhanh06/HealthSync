# Báo Cáo Phân Tích Sự Bất Nhất Dữ Liệu (Consistency Gap Analysis Report)

**Dự án:** Hệ thống quản lý phòng khám HealthSync  
**Người thực hiện:** System Analyst & Database Administrator  

---

### 1. Giới thiệu tổng quan
Quá trình đối chiếu giữa UML Activity Diagram ("Đặt lịch và Khám bệnh") với thiết kế cơ sở dữ liệu cũ (Legacy Schema) cho thấy sự sai lệch nghiêm trọng, khiến hệ thống không thể vận hành tính năng phạt cọc và kê đơn thuốc.

---

### 2. Ba điểm vênh nghiêm trọng nhất giữa nghiệp vụ và thiết kế cũ

1. **Vòng đời đa trạng thái bị thu hẹp thành giá trị nhị phân (Anti-pattern `is_active BOOLEAN`):**  
   Quy trình nghiệp vụ trải qua 5 trạng thái tuần tự: `PENDING` $\rightarrow$ `CONFIRMED` $\rightarrow$ `CHECKED_IN` $\rightarrow$ `COMPLETED` hoặc `CANCELLED`. Việc chỉ dùng cột `is_active` (True/False) làm mất dấu hoàn toàn tiến độ khám, không thể phân biệt giữa lịch chờ duyệt, lịch bệnh nhân đã đến phòng khám hay lịch đã hủy.

2. **Thiếu hoàn toàn các trường dữ liệu tài chính phục vụ phạt cọc:**  
   Quy trình yêu cầu bệnh nhân đóng tiền cọc (`deposit_amount`), ghi nhận lý do hủy (`cancel_reason`) và tính toán phí phạt (`penalty_fee`) trừ vào cọc nếu hủy lịch sau khi đã xác nhận. Bản thiết kế cũ không có các cột này, khiến kế toán không thể đối soát dòng tiền và chức năng phạt tiền cọc báo lỗi hệ thống.

3. **Bỏ quên thực thể Đơn thuốc (`Prescriptions`):**  
   Nghiệp vụ quy định khi khám xong (`COMPLETED`), bác sĩ bắt buộc phải kê đơn thuốc kèm theo lịch hẹn. CSDL cũ không có bảng `Prescriptions` và không có quan hệ liên kết với `Appointments`, khiến dữ liệu khám chữa bệnh bị đứt gãy hoàn toàn.

---

### 3. Kết luận và Giải pháp
Chúng tôi đã tái cấu trúc lại bảng `Appointments` (sử dụng `ENUM` cho `status`, bổ sung `DECIMAL` cho tài chính) và bổ sung bảng `Prescriptions` với ràng buộc toàn vẹn và trigger kiểm soát, giúp ERD khớp 100% với Activity Diagram.
