FROM docker:29.9.1-cli AS docker-source

FROM jenkins/inbound-agent:3391.va_37fa_a_305d6d-4-jdk25

USER root

COPY --from=docker-source /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker-source /usr/local/libexec/docker/cli-plugins/docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx

RUN mkdir -p /home/jenkins/.m2 && chown jenkins /home/jenkins/.m2

USER jenkins
