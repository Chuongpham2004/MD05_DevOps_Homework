# Sử dụng base image JRE 17 gọn nhẹ
FROM eclipse-temurin:17-jre-alpine

# Đặt thư mục làm việc mặc định trong container
WORKDIR /app

# Sao chép file JAR đã biên dịch vào container (Gradle thường build ra file trong thư mục build/libs)
COPY build/libs/*.jar app.jar

# Khai báo lệnh khởi chạy bằng Exec Form
CMD ["java", "-jar", "app.jar"]