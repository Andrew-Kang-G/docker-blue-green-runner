FROM maven:3.6.3-jdk-8-slim AS build

ARG APP_ENV
ARG PROJECT_ROOT_IN_CONTAINER

COPY ./ $PROJECT_ROOT_IN_CONTAINER
USER root
WORKDIR $PROJECT_ROOT_IN_CONTAINER

RUN --mount=type=cache,target=/root/.m2 mvn -f $PROJECT_ROOT_IN_CONTAINER/pom.xml -T100 -DskipTests clean install

FROM openjdk:8-alpine

ARG APP_ENV
ARG PROJECT_ROOT_IN_CONTAINER

COPY --from=build $PROJECT_ROOT_IN_CONTAINER/ $PROJECT_ROOT_IN_CONTAINER

USER root
WORKDIR $PROJECT_ROOT_IN_CONTAINER

RUN cp $PROJECT_ROOT_IN_CONTAINER/target/*.jar  /app.jar

RUN ln -s $PROJECT_ROOT_IN_CONTAINER/.docker/entrypoint/$APP_ENV.sh /run-app.sh

RUN apk --no-cache add curl bash

EXPOSE 8200

ENTRYPOINT sh /run-app.sh && /bin/sh