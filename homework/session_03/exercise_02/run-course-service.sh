#!/bin/bash
docker rm -f rikkei-course-service 2>/dev/null
docker run -d \
  --name rikkei-course-service \
  -p 8081:80 \
  nginxdemos/hello
docker ps | grep rikkei-course-service