FROM debian:10.1-slim

# Tasks:
#   - install
#     - locales
#     - apt-utils
#   - update
#     - tzdata
#   - create and set the locale

RUN set -eux \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y locales apt-utils \
    && apt-get upgrade -y tzdata \
    && apt-get clean \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

USER 0:0
WORKDIR /root

CMD [ "/bin/bash" ]