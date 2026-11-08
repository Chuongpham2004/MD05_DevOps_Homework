# Bài tập 3: Tối ưu hóa biến môi trường và Custom Network

## 1. Xử lý lỗ hổng Hardcode thông tin nhạy cảm
* **Giải pháp:** Tách toàn bộ thông tin cấu hình và mật khẩu Database (`DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`) ra file `.env`.
* **Bảo mật trên Git:** Đưa `.env` vào danh sách chặn của `.gitignore` để tránh lộ mật khẩu khi public mã nguồn. Cung cấp file `.env.example` làm khuôn mẫu cho các lập trình viên khác.
* **Cơ chế hoạt động:** Docker Compose tự động đọc file `.env` nằm cùng cấp với `docker-compose.yml` và truyền giá trị vào các cú pháp `${TÊN_BIẾN}`.

## 2. Cô lập mạng với Custom Network (`storex-net`) và đóng cổng Database
* **Loại bỏ Port Mapping (`5432:5432`):** Xóa cấu hình `ports` trên service `postgres`. Cơ sở dữ liệu giờ đây hoàn toàn ẩn mình trước máy host vật lý và mạng bên ngoài, triệt tiêu nguy cơ bị tấn công dò quét cổng trực tiếp từ bên ngoài.
* **Custom Bridge Network (`storex-net`):** Khai báo mạng riêng biệt dùng driver `bridge`. Chỉ những container được chỉ định tường minh vào mạng `storex-net` (như `backend` và `postgres`) mới có thể phân giải DNS và giao tiếp với nhau qua cổng nội bộ `5432`. Các container của dự án khác chạy trên cùng máy chủ sẽ không thể ping hay truy cập vào Database này.