# Bài tập 4: Xây dựng hệ thống Reverse Proxy với Nginx

## 1. Tại sao Nginx trả về lỗi `502 Bad Gateway`?
* **Nguyên nhân:** Trong cấu hình `nginx.conf` ban đầu, chỉ thị `proxy_pass` đang trỏ tới `http://localhost:8081/` và `http://localhost:8082/`. Do mỗi container có một không gian mạng (Network Namespace) riêng biệt, `localhost` bên trong `nginx_proxy` chính là bản thân container Nginx đó.
* **Hệ quả:** Tại container `nginx_proxy`, chỉ có tiến trình Nginx đang lắng nghe ở cổng `80`, hoàn toàn không có dịch vụ nào chạy ở cổng `8081` hay `8082`. Khi Nginx chuyển tiếp (forward) request vào các cổng này, kết nối bị từ chối (`Connection refused`), dẫn đến việc Nginx trả về mã lỗi **502 Bad Gateway** cho client.

## 2. Giải pháp sử dụng Internal DNS của Docker Compose
* Khi các service cùng nằm trong một file `docker-compose.yml` (cùng thuộc một mạng nội bộ), Docker Engine cung cấp sẵn một **Embedded DNS Server** giúp phân giải tự động tên của service (`user_service`, `product_service`) thành địa chỉ IP nội bộ của container tương ứng.
* Thay thế `localhost` bằng tên service:
  * `http://user_service:8081/`
  * `http://product_service:8082/`

## 3. Cơ chế tự động Rewrite Path thông qua dấu `/` (Trailing Slash) trong `proxy_pass`
* Khi khai báo `location /users/` kết hợp với `proxy_pass http://user_service:8081/;` (chú ý dấu `/` ở cuối cổng `8081/`), Nginx sẽ tự động cắt bỏ tiền tố `/users/` trước khi chuyển tiếp request vào backend:
  * Request từ người dùng: `http://localhost/users/profile` -> Chuyển tiếp tới `user_service`: `http://user_service:8081/profile`.
  * Nếu **không** có dấu `/` ở cuối (`proxy_pass http://user_service:8081;`), Nginx sẽ giữ nguyên toàn bộ URI gốc và gửi `http://user_service:8081/users/profile` vào backend.