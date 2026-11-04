#!/bin/bash
docker rm -f quickbite-user
docker run -d \
  --name quickbite-user \
  -p 8081:8081 \
  -v /root/quickbite:/app \
  -w /app \
  --add-host=host.docker.internal:host-gateway \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/postgres \
  -e SPRING_DATASOURCE_USERNAME=postgres \
  -e SPRING_DATASOURCE_PASSWORD=12345678 \
  eclipse-temurin:17-jre-alpine java -jar user-service-0.0.1-SNAPSHOT.jar