#!/bin/bash

# ==============================================================================
# KỊCH BẢN TRIỂN KHAI TỰ ĐỘNG (ONE-CLICK DEPLOYMENT) - QUICKBITE USER-SERVICE
# ==============================================================================

# 1. Định nghĩa bảng màu ANSI trực quan
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 2. Biến cấu hình đường dẫn
PROJECT_DIR="/home/chuong/quickbite-source/user-service"
DEPLOY_DIR="/opt/quickbite/user-service"
JAR_DEST="/opt/quickbite/user-service-0.0.1.jar"
LOG_FILE="$DEPLOY_DIR/app.log"
APP_USER="quickbite"
APP_GROUP="quickbite"
APP_PORT=8080

# Kiểm tra quyền root (sudo)
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Vui lòng chạy script với quyền root: sudo ./deploy-local.sh${NC}"
  exit 1
fi

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}   BẮT ĐẦU QUY TRÌNH DEPLOY TỰ ĐỘNG: QUICKBITE USER-SERVICE      ${NC}"
echo -e "${BLUE}=================================================================${NC}"

# ------------------------------------------------------------------------------
# BƯỚC 1: Biên dịch mã nguồn (Build & Test) - Áp dụng Fail-fast
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}---> [Bước 1/5] Biên dịch và đóng gói mã nguồn (./gradlew clean bootJar)...${NC}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo -e "${RED}[FAIL-FAST] Không tìm thấy thư mục mã nguồn tại: $PROJECT_DIR${NC}"
  exit 1
fi

cd "$PROJECT_DIR" || exit 1
chmod +x ./gradlew
./gradlew clean bootJar

# Kiểm tra Exit Code ($?) ngay sau lệnh build
BUILD_STATUS=$?
if [ $BUILD_STATUS -ne 0 ]; then
  echo -e "${RED}=================================================================${NC}"
  echo -e "${RED}[FAIL-FAST] LỖI BIÊN DỊCH MÃ NGUỒN! (Exit Code: $BUILD_STATUS)${NC}"
  echo -e "${RED}Quy trình triển khai bị hủy bỏ ngay lập tức để bảo vệ hệ thống.${NC}"
  echo -e "${RED}=================================================================${NC}"
  exit 1
fi
echo -e "${GREEN}[OK] Đóng gói file JAR thành công!${NC}"

# ------------------------------------------------------------------------------
# BƯỚC 2: Chuẩn bị hạ tầng thư mục
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}---> [Bước 2/5] Kiểm tra và chuẩn bị hạ tầng thư mục...${NC}"

if [ ! -d "$DEPLOY_DIR" ]; then
  mkdir -p "$DEPLOY_DIR"
  echo -e "${GREEN}[INFO] Đã tạo mới thư mục $DEPLOY_DIR${NC}"
fi

chown -R "$APP_USER":"$APP_GROUP" /opt/quickbite
chmod 750 /opt/quickbite
echo -e "${GREEN}[OK] Đã cấp quyền sở hữu cho $APP_USER:$APP_GROUP trên /opt/quickbite.${NC}"

# ------------------------------------------------------------------------------
# BƯỚC 3: Dừng dịch vụ cũ và Sao chép ứng dụng mới
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}---> [Bước 3/5] Dừng tiến trình cũ và sao chép bản build mới...${NC}"

OLD_PID=$(pgrep -f "$JAR_DEST")
if [ -n "$OLD_PID" ]; then
  echo -e "${YELLOW}[INFO] Phát hiện tiến trình cũ (PID: $OLD_PID). Đang dừng...${NC}"
  kill -9 $OLD_PID
  sleep 1
fi

# Tìm file JAR vừa được Gradle đóng gói trong build/libs/ (bỏ qua file -plain.jar)
BUILT_JAR=$(find "$PROJECT_DIR/build/libs" -type f -name "*.jar" ! -name "*-plain.jar" | head -n 1)

if [ -z "$BUILT_JAR" ]; then
  echo -e "${RED}[FAIL-FAST] Không tìm thấy file JAR đầu ra trong build/libs/!${NC}"
  exit 1
fi

cp "$BUILT_JAR" "$JAR_DEST"
chown "$APP_USER":"$APP_GROUP" "$JAR_DEST"
chmod 750 "$JAR_DEST"
echo -e "${GREEN}[OK] Đã sao chép $(basename "$BUILT_JAR") tới $JAR_DEST${NC}"

# ------------------------------------------------------------------------------
# BƯỚC 4: Khởi động dịch vụ dưới quyền user quickbite
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}---> [Bước 4/5] Khởi chạy dịch vụ ngầm với user '$APP_USER'...${NC}"

# Tạo sẵn file log và cấp quyền ghi cho user quickbite
touch "$LOG_FILE"
chown "$APP_USER":"$APP_GROUP" "$LOG_FILE"

# Chạy ngầm bằng runuser (vì user quickbite dùng shell /bin/false)
runuser -u "$APP_USER" -- nohup java -jar "$JAR_DEST" > "$LOG_FILE" 2>&1 &

echo -e "${GREEN}[OK] Lệnh khởi chạy đã được kích hoạt trong nền.${NC}"

# ------------------------------------------------------------------------------
# BƯỚC 5: Smoke Test (Kiểm tra cổng 8080 sau 5 giây)
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}---> [Bước 5/5] Thực hiện Smoke Test (Đợi 5 giây để JVM khởi tạo)...${NC}"
sleep 5

if ss -tulpn | grep -q ":$APP_PORT "; then
  echo -e "${GREEN}=================================================================${NC}"
  echo -e "${GREEN} 🚀 DEPLOYS DỊCH VỤ THÀNH CÔNG! Cổng $APP_PORT đang lắng nghe.   ${NC}"
  echo -e "${GREEN}=================================================================${NC}"
  ss -tulpn | grep ":$APP_PORT "
  exit 0
else
  echo -e "${RED}=================================================================${NC}"
  echo -e "${RED} ❌ [SMOKE TEST FAILED] Cổng $APP_PORT không phản hồi!           ${NC}"
  echo -e "${RED} Đang trích xuất 30 dòng log cuối cùng từ $LOG_FILE:             ${NC}"
  echo -e "${RED}=================================================================${NC}"
  tail -n 30 "$LOG_FILE"
  exit 1
fi
