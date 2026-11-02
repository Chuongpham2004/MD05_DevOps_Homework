# Báo cáo Chẩn đoán Sự cố Mạng và Giải phóng Cổng (Network Diagnosis & Port Management)

## Tình huống 1: Xử lý xung đột cổng kết nối 8080 (Address already in use)
Khi khởi chạy `user-service`, ứng dụng báo lỗi do cổng 8080 đã bị một tiến trình khác chiếm giữ. Quy trình xử lý gồm các bước sau:

1. **Phát hiện tiến trình chiếm dụng:**
   - **Lệnh sử dụng:** `sudo ss -tulpn | grep :8080`
   - **Mục đích:** Liệt kê các socket mạng đang mở (`-tulpn`) kết hợp lọc (`grep`) chính xác cổng `8080` để tìm ra Process ID (PID) và tên chương trình gây xung đột.
   
2. **Giải phóng cổng:**
   - **Lệnh sử dụng:** `sudo kill -9 <PID>`
   - **Mục đích:** Gửi tín hiệu ép buộc (`SIGKILL`) chấm dứt ngay lập tức tiến trình có mã PID tương ứng để trả lại quyền sử dụng cổng 8080 cho ứng dụng mới.

---

## Tình huống 2: Chẩn đoán sự cố kết nối tới Database PostgreSQL (`10.0.1.20:5432`)
Khi ứng dụng không thể kết nối tới cơ sở dữ liệu từ xa, chúng ta thực hiện chẩn đoán theo hai tầng mạng:

1. **Kiểm tra tầng mạng vật lý (Network Layer):**
   - **Lệnh sử dụng:** `ping -c 4 10.0.1.20`
   - **Mục đích:** Gửi 4 gói tin ICMP tới địa chỉ IP của máy chủ Database để kiểm tra độ trễ (latency) và xác định xem đường truyền mạng vật lý / định tuyến có hoạt động bình thường hay không.

2. **Kiểm tra tầng giao vận / cổng dịch vụ (Transport Layer):**
   - **Lệnh sử dụng:** `nc -zv 10.0.1.20 5432`
   - **Mục đích:** Sử dụng công cụ Netcat (`nc`) ở chế độ quét cổng (`-z`) và chi tiết (`-v`) để kiểm tra xem tường lửa (Firewall) có đang chặn hay cổng dịch vụ PostgreSQL (`5432`) trên máy chủ từ xa có thực sự đang lắng nghe kết nối hay không.