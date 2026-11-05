#!/bin/bash
# Ghi nối toàn bộ output và error vào file log chung
exec >> /opt/rikkei/deploy.log 2>&1

echo "=== [$(date)] Bắt đầu quy trình cập nhật rikkei-course-service ==="

# 1 & 2. Kiểm tra, dừng và xóa container cũ nếu tồn tại
if [ "$(docker ps -a -q -f name=rikkei-course-service)" ]; then
    echo "Phát hiện container cũ rikkei-course-service. Đang tiến hành dừng và xóa..."
    docker stop rikkei-course-service
    docker rm rikkei-course-service
else
    echo "Không tìm thấy container cũ rikkei-course-service. Bỏ qua bước xóa."
fi

# 3. Khởi chạy lại container mới từ image nginxdemos/hello ở cổng 8081
echo "Đang khởi chạy container rikkei-course-service mới..."
docker run -d \
  --name rikkei-course-service \
  -p 8081:80 \
  nginxdemos/hello

echo "=== [$(date)] Hoàn tất cập nhật thành công ==="
echo ""