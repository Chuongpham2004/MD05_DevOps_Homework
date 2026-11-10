#!/bin/bash

# 1. Khai báo các mã màu để in log
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 2. Khai báo biến môi trường (Điều chỉnh lại tên service cho đúng với docker-compose.yml của bạn)
DB_SERVICE="quickbite-db"
BACKEND_SERVICE="quickbite-user"
DB_USER="postgres"
BACKEND_PORT="8080" # Đổi thành cổng nội bộ Spring Boot đang chạy nếu khác 8080

# ==========================================
# HÀM XỬ LÝ LỖI VÀ DỌN DẸP
# ==========================================
function handle_error() {
    echo -e "${RED}LỖI: $1${NC}"
    echo -e "${RED}--- 20 DÒNG LOG CUỐI CỦA BACKEND ---${NC}"
    
    # In 20 dòng log cuối
    docker compose logs --tail=20 $BACKEND_SERVICE
    
    echo -e "${RED}Đang dọn dẹp hệ thống để tránh treo tài nguyên...${NC}"
    docker compose down
    
    # Thoát với mã lỗi 1 để luồng CI/CD biết là thất bại
    exit 1
}

# ==========================================
# LUỒNG KHỞI ĐỘNG (START)
# ==========================================
function start_system() {
    echo "Đang khởi động hệ thống..."
    docker compose up -d --build

    echo "Đang kiểm tra trạng thái Database ($DB_SERVICE)..."
    TIMEOUT=10
    ELAPSED=0
    DB_READY=false

    # Vòng lặp kiểm tra pg_isready mỗi 2 giây
    while [ $ELAPSED -lt $TIMEOUT ]; do
        # Lưu ý: Cần thêm cờ -T vào exec khi chạy trong Bash script để bỏ qua cấp phát TTY ảo
        if docker compose exec -T $DB_SERVICE pg_isready -U $DB_USER > /dev/null 2>&1; then
            DB_READY=true
            break
        fi
        echo "Đợi Database sẵn sàng... ($ELAPSED/$TIMEOUT s)"
        sleep 2
        ELAPSED=$((ELAPSED + 2))
    done

    # Bẫy lỗi 1: Hết timeout mà DB chưa lên
    if [ "$DB_READY" = false ]; then
        handle_error "Database không sẵn sàng sau $TIMEOUT giây (Timeout)!"
    fi

    echo "Database đã sẵn sàng. Đang kiểm tra Backend API..."
    
    # Cho Backend thêm thời gian để JVM/Spring Boot nạp xong (điều chỉnh tuỳ cấu hình máy)
    sleep 5 
    
    API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$BACKEND_PORT/actuator/health || echo "000")
    
    # Bẫy lỗi 2: API trả về khác 200 OK
    if [ "$API_STATUS" = "200" ]; then
        echo -e "${GREEN}HỆ THỐNG QUICKBITE HOẠT ĐỘNG ỔN ĐỊNH!${NC}"
        exit 0
    else
        handle_error "Backend API phản hồi lỗi hoặc không kết nối được (HTTP Status: $API_STATUS)!"
    fi
}

# ==========================================
# LUỒNG TẠM DỪNG (STOP) VÀ DỌN DẸP (CLEAN)
# ==========================================
function stop_system() {
    echo "Đang tạm dừng hệ thống..."
    docker compose stop
}

function clean_system() {
    echo "Đang dọn dẹp toàn bộ tài nguyên (kể cả volumes)..."
    docker compose down -v
}

# ==========================================
# ĐIỀU HƯỚNG THAM SỐ ĐẦU VÀO
# ==========================================
case "$1" in
    start)
        start_system
        ;;
    stop)
        stop_system
        ;;
    clean)
        clean_system
        ;;
    *)
        echo "Sử dụng sai cú pháp. Hướng dẫn: $0 {start|stop|clean}"
        exit 1
        ;;
esac