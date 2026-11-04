
#!/bin/bash
# init-staging.sh - Khoi tao moi truong Staging (PostgreSQL) tu dong

CONTAINER_NAME="quickbite-db"
DB_IMAGE="postgres:15-alpine"
DB_PORT=5432
DB_PASSWORD="12345678"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }

# ===== Giai doan 1: Don dep tai nguyen cu =====
info "Giai doan 1: Kiem tra container cu '${CONTAINER_NAME}'..."
if docker ps -a --format '{{.Names}}' | grep -wq "${CONTAINER_NAME}"; then
    docker stop "${CONTAINER_NAME}" > /dev/null
    docker rm "${CONTAINER_NAME}" > /dev/null
    ok "Da don dep container cu '${CONTAINER_NAME}' thanh cong."
else
    ok "Khong co container cu '${CONTAINER_NAME}', bo qua buoc don dep."
fi

# ===== Giai doan 2: Kiem tra cong mang (Fail fast) =====
info "Giai doan 2: Kiem tra cong ${DB_PORT} tren host..."
PORT_INFO=$(ss -ltnp "sport = :${DB_PORT}" 2>/dev/null | tail -n +2)

if [ -n "${PORT_INFO}" ]; then
    if echo "${PORT_INFO}" | grep -q "docker-proxy"; then
        error "Cong ${DB_PORT} dang bi chiem boi mot container Docker khac:"
        docker ps --filter "publish=${DB_PORT}" --format '  - {{.Names}} ({{.Image}})'
    else
        error "Cong ${DB_PORT} dang bi chiem dung boi tien trinh ngoai Docker:"
        echo -e "${RED}${PORT_INFO}${NC}"
    fi
    error "Dung script. Hay giai phong cong ${DB_PORT} roi chay lai."
    exit 1
fi
ok "Cong ${DB_PORT} dang trong."

# ===== Giai doan 3: Khoi tao Database =====
info "Giai doan 3: Khoi chay container '${CONTAINER_NAME}' tu image ${DB_IMAGE}..."
if ! docker run -d \
    --name "${CONTAINER_NAME}" \
    -p ${DB_PORT}:5432 \
    -e POSTGRES_PASSWORD="${DB_PASSWORD}" \
    "${DB_IMAGE}" > /dev/null; then
    error "Khong the khoi chay container '${CONTAINER_NAME}'."
    exit 1
fi
ok "Da khoi chay container '${CONTAINER_NAME}'."

# ===== Giai doan 4: Smoke Test =====
info "Giai doan 4: Cho 5 giay de PostgreSQL khoi dong..."
sleep 5

if docker exec "${CONTAINER_NAME}" pg_isready -U postgres; then
    echo -e "${GREEN}DATABASE STAGING KHỞI TẠO THÀNH CÔNG!${NC}"
    exit 0
else
    error "DATABASE STAGING KHỞI TẠO THẤT BẠI! 20 dong log cuoi cua container:"
    docker logs --tail 20 "${CONTAINER_NAME}"
    exit 1
fi