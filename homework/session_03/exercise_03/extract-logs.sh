#!/bin/bash
# Trích xuất 15 dòng log cuối cùng kèm theo timestamps của container rikkei-course-service
docker logs --tail 15 --timestamps rikkei-course-service