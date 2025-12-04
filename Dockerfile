# Stage 1: Build the JAR file
# We use a Maven image based on Eclipse Temurin (Valid & Active)
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Run the JAR file
# We use the lightweight Eclipse Temurin JRE image
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
# Copy the jar file from the build stage
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
