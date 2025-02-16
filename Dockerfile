FROM ubuntu:24.04
COPY --from=docker:dind /usr/local/bin/ /usr/local/bin/ 