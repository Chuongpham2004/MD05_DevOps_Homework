#!/bin/bash

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
  echo "Vui lòng chạy script này với quyền sudo: sudo ./setup-dirs.sh"
  exit 1
fi

echo "=== [1/3] Tạo cấu trúc thư mục /opt/quickbite/user-service ==="
mkdir -p /opt/quickbite/user-service

echo "=== [2/3] Thay đổi chủ sở hữu và nhóm sở hữu thành quickbite:quickbite ==="
chown -R quickbite:quickbite /opt/quickbite

echo "=== [3/3] Thiết lập phân quyền 750 cho thư mục /opt/quickbite ==="
chmod 750 /opt/quickbite

echo "=== HOÀN TẤT THIẾT LẬP THƯ MỤC VÀ PHÂN QUYỀN! ==="