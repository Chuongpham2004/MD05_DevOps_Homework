# Bài tập 5: Thiết kế kiến trúc triển khai Đa môi trường (Multi-environment)

## 1. Kiến trúc phân tách file theo nguyên tắc DRY
Hệ thống sử dụng kỹ thuật nạp chồng (Compose Overriding) để tránh lặp lại mã cấu hình:
* **`docker-compose.yml` (Base):** Khai báo các service cốt lõi, mạng nội bộ (`storex-net`), cơ chế lưu trữ (`volumes`), healthcheck và các biến môi trường bất biến.
* **`docker-compose.override.yml` (Dev/Staging):** Cấu hình tự động nạp trong quá trình phát triển. Bổ sung port mapping ra host (`8080`, `5435`) để debug, đặt `ENV=dev`.
* **`docker-compose.prod.yml` (Production):** Thiết lập an toàn cho môi trường chạy thật. Đặt policy `restart: always`, gỡ bỏ port mapping trực tiếp trên host để tránh xung đột cổng khi chạy nhiều bản sao, quy định `replicas: 3` và áp đặt giới hạn tài nguyên (`limits.memory: 512M`).

---

## 2. Kịch bản triển khai cho từng môi trường

### 2.1. Triển khai môi trường Dev / Staging
Docker Compose mặc định tự động tìm và kết hợp `docker-compose.yml` với `docker-compose.override.yml`:
```bash
# Khởi động Staging/Dev
docker compose up -d

# Dừng môi trường Staging/Dev
docker compose down
```

### 2.2. Triển khai môi trường Production
Trên máy chủ Production, sử dụng cờ `-f` để kết hợp file Base và file Prod (loại bỏ hoàn toàn cấu hình dev trong file override):
```bash
# Khởi động Production với 3 replicas và resource limits
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Xem danh sách các replicas và tài nguyên sử dụng
docker compose -f docker-compose.yml -f docker-compose.prod.yml ps
docker stats --no-stream

# Dừng môi trường Production
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
```

---

## 3. Quản lý tài nguyên trên Production
Để tránh hiện tượng OOM (Out Of Memory) làm tê liệt máy chủ, service `backend` trên Production được khóa trần tài nguyên:
* `limits.memory: 512M`: Mỗi container replica chỉ được chiếm dụng tối đa 512MB RAM.
* `limits.cpus: '0.50'`: Mỗi replica chỉ được sử dụng tối đa 50% một nhân CPU.