FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S vfit \
    && adduser -S -G vfit -h /app -s /sbin/nologin vfit \
    && mkdir -p /app/uploads \
    && chown -R vfit:vfit /app
COPY --from=build --chown=vfit:vfit /app/target/vfit-backend-0.1.0.jar /app/vfit-backend.jar
USER vfit
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 CMD wget -q -O /dev/null http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "/app/vfit-backend.jar"]
