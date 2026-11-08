# Bài tập 2: Quản lý dữ liệu (Volumes) và Dependency giữa các container

## 1. Giải thích nguyên nhân lỗi ban đầu
* **Lỗi Crash Backend khi khởi động:** Mặc định, thuộc tính `depends_on` trong Docker Compose chỉ kiểm tra trạng thái **Container Started** (tiến trình gốc PID 1 vừa được gọi chạy), chứ không kiểm tra xem dịch vụ bên trong (PostgreSQL, Redis) đã khởi tạo xong socket và sẵn sàng nhận kết nối (**Ready for connections**) hay chưa. Do ứng dụng Backend khởi chạy song song hoặc trước khi Database mở cổng xong, kết nối bị từ chối dẫn đến crash ngay lập tức.
* **Lỗi mất dữ liệu khi `down` và `up` lại:** Dữ liệu của PostgreSQL mặc định được lưu trong lớp ghi tạm thời (Writable Layer) của container. Khi chạy lệnh `docker compose down`, toàn bộ container bị xóa bỏ kéo theo dữ liệu bên trong biến mất hoàn toàn.

---

## 2. Cơ chế `healthcheck` và `service_healthy` đã áp dụng

Để kiểm soát chặt chẽ thứ tự khởi động, hệ thống kết hợp bộ kiểm tra sức khỏe định kỳ (`healthcheck`) ở các dịch vụ nền tảng và điều kiện ràng buộc (`condition: service_healthy`) ở dịch vụ Backend:

### 2.1. Healthcheck trên PostgreSQL
* **Lệnh kiểm tra (`test`):** `["CMD-SHELL", "pg_isready -U admin -d storex_db"]`
* **Cơ chế hoạt động:** Sử dụng công cụ nội bộ `pg_isready` của PostgreSQL để kiểm tra trực tiếp xem Database Server đã hoàn tất quá trình khởi động và sẵn sàng nhận kết nối từ tài khoản `admin` vào cơ sở dữ liệu `storex_db` hay chưa. Khi sẵn sàng, lệnh trả về mã thoát `0` (Exit Code 0) và chuyển trạng thái container sang **`healthy`**.

### 2.2. Healthcheck trên Redis
* **Lệnh kiểm tra (`test`):** `["CMD", "redis-cli", "ping"]`
* **Cơ chế hoạt động:** Gửi lệnh `PING` trực tiếp tới Redis server thông qua `redis-cli`. Khi Redis đã nạp xong cấu hình trên RAM và sẵn sàng phục vụ caching, nó sẽ phản hồi lại chuỗi `PONG` (Exit Code 0), đánh dấu container đạt trạng thái **`healthy`**.

### 2.3. Các thông số chu kỳ kiểm tra
* **`interval: 5s`:** Định kỳ mỗi 5 giây Docker Engine sẽ thực thi lệnh kiểm tra một lần.
* **`timeout: 5s` (Postgres) / `3s` (Redis):** Thời gian chờ tối đa cho một lần chạy lệnh kiểm tra. Nếu quá thời gian này không có phản hồi, lần kiểm tra đó bị tính là thất bại.
* **`retries: 5`:** Số lần thử lại tối đa liên tiếp. Nếu thất bại cả 5 lần, container sẽ bị đánh dấu là `unhealthy`.

### 2.4. Ràng buộc `condition: service_healthy` tại Backend
* Thay vì chỉ đợi container `postgres` và `redis` bật lên, cấu hình `condition: service_healthy` khóa tiến trình khởi tạo của `backend` lại. Docker Compose chỉ bắt đầu khởi chạy container `backend` sau khi cả hai dịch vụ `postgres` và `redis` đều đã vượt qua bài kiểm tra `healthcheck` và chuyển sang trạng thái **`Healthy`**.

---

## 3. Cơ chế lưu trữ bền vững với Named Volume (`postgres_data`)
* Cấu hình `postgres_data:/var/lib/postgresql/data` ánh xạ thư mục chứa dữ liệu gốc của PostgreSQL bên trong container ra một **Named Volume** do Docker quản lý độc lập trên máy host.
* Khi thực hiện lệnh `docker compose down`, các container và mạng ảo bị xóa bỏ nhưng volume `postgres_data` vẫn được giữ lại an toàn. Khi chạy `docker compose up -d` trở lại, container PostgreSQL mới sẽ tự động gắn (mount) lại đúng volume cũ, giữ nguyên vẹn 100% các bảng và dữ liệu đã tạo trước đó.