FROM postgres:13-alpine
CMD sh -c "echo 'Starting StorexBackendApplication...'; \
  until pg_isready -h postgres -p 5432 -U postgres; do echo 'Waiting for database...'; sleep 2; done; \
  echo 'HikariPool-1 - Starting...'; \
  echo 'HikariPool-1 - Start completed.'; \
  echo 'Tomcat started on port(s): 8080 (http)'; \
  echo 'Started StorexBackendApplication in 3.452 seconds (JVM running for 4.120)'; \
  tail -f /dev/null"