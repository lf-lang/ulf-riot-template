FROM ubuntu:24.04

ARG REACTOR_UC_REF=main

ENV DEBIAN_FRONTEND=noninteractive
ENV REACTOR_UC_PATH=/opt/reactor-uc

# Toolchain for Lingua Franca (lfc is Java) + RIOT ARM cross-build.
# python3-serial is the apt name for pyserial on Ubuntu (module is `serial`).
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git make cmake build-essential pkg-config \
      openjdk-17-jdk-headless \
      python3 python3-serial python3-psutil \
      gcc-arm-none-eabi binutils-arm-none-eabi libnewlib-arm-none-eabi \
 && rm -rf /var/lib/apt/lists/*

# UF2 conversion helper. The build produces a .uf2 inside the container;
# flashing is done from the host by copying it to the mounted board.
RUN curl -fsSL -o /usr/local/bin/uf2conv.py \
      https://raw.githubusercontent.com/microsoft/uf2/master/utils/uf2conv.py \
 && curl -fsSL -o /usr/local/bin/uf2families.json \
      https://raw.githubusercontent.com/microsoft/uf2/master/utils/uf2families.json \
 && chmod +x /usr/local/bin/uf2conv.py

# reactor-uc (pinned), with its submodules.
RUN git clone https://github.com/lf-lang/reactor-uc.git ${REACTOR_UC_PATH} \
 && git -C ${REACTOR_UC_PATH} checkout ${REACTOR_UC_REF} \
 && git -C ${REACTOR_UC_PATH} submodule update --init --recursive

# We run the container as the host UID via `docker run -u ...`. Git 2.35+
# refuses to operate on repositories owned by a different UID; whitelist
# everywhere since /workspace and /opt/reactor-uc both qualify.
RUN git config --system --add safe.directory '*'

WORKDIR /workspace
CMD ["bash"]
