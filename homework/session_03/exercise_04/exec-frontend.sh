#!/bin/bash
# 1. Dọn dẹp container cũ nếu tồn tại
docker rm -f rikkei-frontend-qa 2>/dev/null

# 2. Khởi chạy container Nginx kèm biến môi trường API_ENDPOINT
docker run -d \
  --name rikkei-frontend-qa \
  -e API_ENDPOINT=https://qa-api.rikkei.edu.vn \
  nginx

# 3. Sử dụng docker exec để in giá trị biến môi trường từ bên trong container
docker exec -it rikkei-frontend-qa sh -c "echo \$API_ENDPOINT"