#!/bin/bash
# 1. Dọn dẹp container cũ nếu tồn tại
docker rm -f rikkei-db 2>/dev/null

# 2. Khởi chạy PostgreSQL container với Persistent Volume
docker run -d \
  --name rikkei-db \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=Rikkei@2026 \
  -v /opt/rikkei/pg-data:/var/lib/postgresql/data \
  postgres:13

# 3. Đợi container khởi động rồi kiểm tra thư mục dữ liệu trên host
echo "Đang chờ database khởi tạo dữ liệu..."
sleep 5
ls -l /opt/rikkei/pg-data