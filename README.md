# HealthSync Database Re-architecture (Cơ Sở Dữ Liệu Phòng Khám HealthSync)

Dự án tái cấu trúc cơ sở dữ liệu phòng khám HealthSync, giải quyết triệt để sự thiếu nhất quán giữa UML Activity Diagram của BA và thiết kế cơ sở dữ liệu MySQL của Backend Developer.

## Danh mục tài liệu trong Repository:
1. [`healthsync_db.sql`](healthsync_db.sql): File kịch bản DDL tạo bảng, Trigger bảo vệ toàn vẹn, DML mô phỏng kịch bản thành công và hủy phạt, cùng các câu lệnh truy vấn kiểm tra đối soát.
2. [`consistency_report.md`](consistency_report.md): Báo cáo phân tích 3 điểm vênh nghiêm trọng nhất giữa thiết kế cũ và nghiệp vụ thực tế.
3. [`ai_prompt_log.md`](ai_prompt_log.md): Nhật ký chi tiết tương tác với AI trong quá trình thiết kế hệ thống.

## Hướng dẫn chạy thử nghiệm:
1. Mở MySQL Workbench hoặc MySQL CLI.
2. Chạy toàn bộ file `healthsync_db.sql` để khởi tạo Database, Tables, Trigger và nạp dữ liệu mô phỏng.
