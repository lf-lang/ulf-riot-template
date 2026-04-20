FROM ubuntu:24.04

ARG REACTOR_UC_REF=main

ENV DEBIAN_FRONTEND=noninteractive

# Build / flash / RIOT / lfc(java) / Python tooling.
# python3-serial is the apt name for pyserial on Ubuntu (module is still `serial`).
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git make cmake build-essential pkg-config \
      openjdk-17-jdk-headless \
      python3 python3-pip python3-serial python3-psutil \
      gcc-arm-none-eabi binutils-arm-none-eabi libnewlib-arm-none-eabi \
      bossa-cli dfu-util libusb-1.0-0-dev \
      sudo \
   && rm -rf /var/lib/apt/lists/*

# UF2 conversion helper (Microsoft uf2conv.py).
RUN curl -fsSL -o /usr/local/bin/uf2conv.py \
      https://raw.githubusercontent.com/microsoft/uf2/master/utils/uf2conv.py \
 && curl -fsSL -o /usr/local/bin/uf2families.json \
      https://raw.githubusercontent.com/microsoft/uf2/master/utils/uf2families.json \
 && chmod +x /usr/local/bin/uf2conv.py

# reactor-uc (pinned), recursively for its submodules.
RUN git clone https://github.com/lf-lang/reactor-uc.git /opt/reactor-uc \
 && cd /opt/reactor-uc && git checkout ${REACTOR_UC_REF} \
 && git submodule update --init --recursive \
 && chown -R ${USER_UID}:${USER_GID} /opt/reactor-uc

ENV REACTOR_UC_PATH=/opt/reactor-uc
WORKDIR /workspace
CMD ["bash"]
