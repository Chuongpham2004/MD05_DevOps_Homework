#!/bin/bash
# 1. Tạo user rikkeilms mới
sudo useradd -m -s /bin/bash rikkeilms

# 2. Tạo thư mục gốc cho course-service
sudo mkdir -p /opt/rikkei/course-service

# 3. Phân quyền sở hữu cho user và group rikkeilms
sudo chown -R rikkeilms:rikkeilms /opt/rikkei

# 4. Cấp quyền truy cập 755
sudo chmod 755 /opt/rikkei/course-service

# 5. Kiểm tra kết quả
ls -ld /opt/rikkei/course-service