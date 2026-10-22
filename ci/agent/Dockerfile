FROM docker:29.9.1-cli@sha256:6fae2214c3121a28d5aa639d09032f61310b7c9c75ffbad1025f261a1b621800 AS docker-source
FROM aquasec/trivy:0.76.1@sha256:790fd66d1697395d8693d1acaa1ea702406a20f109b6fc7bac8db623eca6c06c AS trivy

FROM jenkins/inbound-agent:3391.va_37fa_a_305d6d-4-jdk25

USER root

COPY --from=docker-source /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker-source /usr/local/libexec/docker/cli-plugins/docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx
COPY --from=trivy /usr/local/bin/trivy /usr/local/bin/trivy

RUN mkdir -p /home/jenkins/.cache/trivy && chown jenkins /home/jenkins/.cache/trivy
RUN mkdir -p /home/jenkins/.m2 && chown jenkins /home/jenkins/.m2

USER jenkins
