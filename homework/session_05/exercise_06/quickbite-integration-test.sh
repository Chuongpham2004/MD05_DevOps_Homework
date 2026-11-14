#!/bin/bash

# Khai báo biến màu sắc để in log
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Xử lý tham số 'clean'
if [ "$1" == "clean" ]; then
    echo "Đang dọn dẹp hệ thống..."
    docker compose down
    exit 0

# 2. Xử lý tham số 'run'
elif [ "$1" == "run" ]; then
    echo "Khởi chạy cụm container..."
    docker compose up -d --build

    echo "Đang kiểm tra kết nối PostgreSQL..."
    DB_READY=false
    for i in {1..5}; do
        # Sử dụng docker exec để chạy lệnh pg_isready bên trong container DB
        if docker exec quickbite-db pg_isready -U postgres > /dev/null 2>&1; then
            DB_READY=true
            echo "PostgreSQL đã sẵn sàng!"
            break
        fi
        echo "Chờ PostgreSQL phản hồi... ($i/5)"
        sleep 2
    done

    # Nếu DB không lên sau 10s (5 lần x 2s)
    if [ "$DB_READY" = false ]; then
        echo -e "${RED}LỖI: PostgreSQL không phản hồi sau 10 giây!${NC}"
        docker compose down
        exit 1
    fi

    # Chờ Spring Boot khởi động theo đúng yêu cầu
    echo "Chờ 20 giây để Spring Boot khởi động..."
    sleep 20

    # Gọi Gateway và chỉ lấy mã trạng thái HTTP (200, 404, 502...)
    echo "Đang gửi Healthcheck tới Gateway..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/v1/users/actuator/health)

    # Kiểm tra kết quả Healthcheck
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo -e "${GREEN}CỔNG GATEWAY HOẠT ĐỘNG ỔN ĐỊNH. HỆ THỐNG LIÊN THÔNG THÀNH CÔNG!${NC}"
        exit 0
    else
        echo -e "${RED}LỖI: Healthcheck thất bại, mã HTTP trả về: $HTTP_STATUS${NC}"
        
        echo -e "${RED}--- LOG QUICKBITE-GATEWAY (30 dòng cuối) ---${NC}"
        docker compose logs --tail=30 quickbite-gateway
        
        echo -e "${RED}--- LOG QUICKBITE-USER (30 dòng cuối) ---${NC}"
        docker compose logs --tail=30 quickbite-user
        
        echo "Đang tự động dọn dẹp tài nguyên..."
        docker compose down
        exit 1
    fi

# 3. Xử lý khi nhập sai tham số
else
    echo "Cú pháp không hợp lệ!"
    echo "Sử dụng: ./quickbite-integration-test.sh [run | clean]"
    exit 1
fi