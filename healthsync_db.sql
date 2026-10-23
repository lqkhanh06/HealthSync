-- =======================================================================
-- HỆ THỐNG PHÒNG KHÁM HEALTHSYNC - TÁI CẤU TRÚC CƠ SỞ DỮ LIỆU CHUẨN NGHIỆP VỤ
-- File: healthsync_db.sql
-- =======================================================================

DROP DATABASE IF EXISTS healthsync_db;
CREATE DATABASE healthsync_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE healthsync_db;

-- -----------------------------------------------------------------------
-- PHẦN 1: TẠO CẤU TRÚC BẢNG (DDL)
-- -----------------------------------------------------------------------

-- 1. Bảng Bệnh nhân (Patients)
CREATE TABLE Patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE
);

-- 2. Bảng Bác sĩ (Doctors)
CREATE TABLE Doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(50) NOT NULL
);

-- 3. Bảng Lịch hẹn (Appointments) - Đã tái cấu trúc
-- Thay thế is_active bằng ENUM status biểu diễn 5 bước vòng đời
-- Bổ sung deposit_amount, penalty_fee dạng DECIMAL chuẩn tài chính và cancel_reason
CREATE TABLE Appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    status ENUM('PENDING', 'CONFIRMED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
    deposit_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00 CHECK (deposit_amount >= 0),
    penalty_fee DECIMAL(12, 2) NOT NULL DEFAULT 0.00 CHECK (penalty_fee >= 0),
    cancel_reason VARCHAR(255) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
);

-- 4. Bảng Đơn thuốc (Prescriptions) - Khắc phục thiếu hụt của thiết kế cũ
-- Mỗi lịch hẹn đã hoàn thành có 1 đơn thuốc đi kèm (UNIQUE appointment_id)
CREATE TABLE Prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,
    medication_details TEXT NOT NULL,
    issued_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES Appointments(appointment_id) ON DELETE RESTRICT
);

-- -----------------------------------------------------------------------
-- PHẦN 2: TRIGGER BẢO VỆ TOÀN VẸN DỮ LIỆU TẦNG CSDL (NÂNG CAO)
-- Ngăn chặn kê đơn thuốc khi lịch hẹn chưa ở trạng thái 'COMPLETED'
-- -----------------------------------------------------------------------
DELIMITER $$
CREATE TRIGGER trg_before_insert_prescription
BEFORE INSERT ON Prescriptions
FOR EACH ROW
BEGIN
    DECLARE app_status VARCHAR(20);
    
    SELECT status INTO app_status 
    FROM Appointments 
    WHERE appointment_id = NEW.appointment_id;
    
    IF app_status <> 'COMPLETED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi nghiệp vụ: Không thể kê đơn thuốc khi lịch hẹn chưa đạt trạng thái COMPLETED!';
    END IF;
END$$
DELIMITER ;

-- -----------------------------------------------------------------------
-- PHẦN 3: DỮ LIỆU MẪU BAN ĐẦU (SEED DATA)
-- -----------------------------------------------------------------------
INSERT INTO Patients (full_name, phone) VALUES 
('Nguyễn Văn An', '0901234567'),
('Trần Thị Bình', '0912345678'),
('Lê Hoàng Nam', '0988776655');

INSERT INTO Doctors (full_name, specialty) VALUES 
('BS. Lê Quang Minh', 'Tim Mạch'),
('BS. Phạm Thanh Hương', 'Nhi Khoa');

-- -----------------------------------------------------------------------
-- PHẦN 4: MÔ PHỎNG LUỒNG DỮ LIỆU THỰC TẾ (DML SCENARIOS)
-- -----------------------------------------------------------------------

-- =======================================================================
-- KỊCH BẢN 1 (KHÁM BỆNH THÀNH CÔNG):
-- Bệnh nhân Nguyễn Văn An đặt lịch -> Xác nhận cọc 500.000đ -> Check-in -> Khám xong -> Bác sĩ kê đơn thuốc
-- =======================================================================

-- 1. Bệnh nhân tạo lịch hẹn mới (PENDING), đóng cọc 500.000đ
INSERT INTO Appointments (patient_id, doctor_id, appointment_date, status, deposit_amount)
VALUES (1, 1, '2026-10-25 09:00:00', 'PENDING', 500000.00);

-- Giả sử ID vừa tạo là 1:
-- 2. Phòng khám xác nhận đã nhận cọc -> Chuyển CONFIRMED
UPDATE Appointments 
SET status = 'CONFIRMED' 
WHERE appointment_id = 1;

-- 3. Ngày khám: Bệnh nhân đến phòng khám -> Chuyển CHECKED_IN
UPDATE Appointments 
SET status = 'CHECKED_IN' 
WHERE appointment_id = 1;

-- 4. Bác sĩ khám xong -> Chuyển COMPLETED
UPDATE Appointments 
SET status = 'COMPLETED' 
WHERE appointment_id = 1;

-- 5. Bác sĩ kê đơn thuốc cho lịch hẹn số 1
INSERT INTO Prescriptions (appointment_id, medication_details)
VALUES (1, '1. Panadol Extra (500mg): 10 viên, uống 1 viên/lần sau ăn.\n2. Vitamin C (1000mg): 1 vỉ, uống sáng.');

-- =======================================================================
-- KỊCH BẢN 2 (HỦY LỊCH VÀ PHẠT TIỀN CỌC):
-- Bệnh nhân Trần Thị Bình đặt lịch cọc 300.000đ -> Đã CONFIRMED -> Báo hủy -> CANCELLED kèm lý do & phạt 150.000đ
-- =======================================================================

-- 1. Tạo lịch hẹn đã xác nhận đặt cọc 300.000đ
INSERT INTO Appointments (patient_id, doctor_id, appointment_date, status, deposit_amount)
VALUES (2, 2, '2026-10-26 14:30:00', 'CONFIRMED', 300000.00);

-- Giả sử ID vừa tạo là 2:
-- 2. Bệnh nhân hủy lịch -> Cập nhật trạng thái CANCELLED, lý do và áp dụng phí phạt 150.000đ
UPDATE Appointments 
SET status = 'CANCELLED',
    cancel_reason = 'Bận việc đột xuất không thể sắp xếp đến khám',
    penalty_fee = 150000.00
WHERE appointment_id = 2;

-- -----------------------------------------------------------------------
-- PHẦN 5: TRUY VẤN KIỂM TRA ĐỐI SOÁT NGHIỆP VỤ (VERIFICATION QUERIES)
-- -----------------------------------------------------------------------

-- 1. Danh sách bệnh nhân đã hoàn tất khám bệnh kèm chi tiết đơn thuốc
SELECT 
    a.appointment_id,
    p.full_name AS patient_name,
    p.phone AS patient_phone,
    d.full_name AS doctor_name,
    a.appointment_date,
    a.status,
    a.deposit_amount,
    pr.prescription_id,
    pr.medication_details,
    pr.issued_date
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Doctors d ON a.doctor_id = d.doctor_id
LEFT JOIN Prescriptions pr ON a.appointment_id = pr.appointment_id
WHERE a.status = 'COMPLETED';

-- 2. Báo cáo đối soát tài chính: Tiền cọc thu, Phí phạt và Doanh thu giữ lại từ hủy lịch
SELECT 
    appointment_id,
    status,
    deposit_amount AS tien_dat_coc,
    penalty_fee AS phi_phat_huy_lich,
    cancel_reason AS ly_do_huy,
    (deposit_amount - penalty_fee) AS tien_hoan_lai_khach
FROM Appointments;
