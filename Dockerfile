FROM ubuntu:24.04

# Avoid interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    bash-completion \
    binutils-dev \
    bison \
    build-essential \
    ccache \
    clang-format \
    cmake \
    cpufrequtils \
    curl \
    ethtool \
    exuberant-ctags \
    file \
    flatbuffers-compiler \
    flex \
    g++ \
    gcc \
    gdb \
    git \
    gnuradio \
    htop \
    inetutils-tools \
    iperf3 \
    iproute2 \
    iputils-ping \
    less \
    libbabeltrace-dev \
    libblas-dev \
    libboost-all-dev \
    libcap-dev \
    libconfig-dev \
    libncurses5-dev \
    libdwarf-dev \
    libelf-dev \
    libfftw3-dev \
    libflatbuffers-dev \
    libgtest-dev \
    libgrpc++-dev \
    libprotobuf-dev \
    libiberty-dev \
    libibverbs-dev \
    liblapack-dev \
    libmbedtls-dev \
    libnanomsg-dev \
    libnuma-dev \
    libpcre2-dev \
    libperl-dev \
    libreadline-dev \
    libsctp-dev \
    libslang2-dev \
    libssl-dev \
    libtool \
    libtree-sitter-dev \
    libunwind-dev \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    libusb-dev \
    libyaml-cpp-dev \
    libzmq3-dev \
    libzstd-dev \
    libconfig++-dev \
    libsctp-dev \
    linux-tools-common \
    linux-tools-generic \
    m4 \
    make \
    meson \
    netcat-openbsd \
    ninja-build \
    openssh-client \
    openssl \
    patch \
    pkg-config \
    protobuf-compiler-grpc \
    psmisc \
    python3 \
    python3-dev \
    python3-pip \
    python3-mako \
    python3-numpy \
    python3-requests \
    python3-scipy \
    python3-setuptools \
    python3-ruamel.yaml \
    python3-pyelftools \
    python3-venv \
    rdma-core \
    ripgrep \
    rsync \
    software-properties-common \
    systemtap-sdt-dev \
    telnet \
    tini \
    tmux \
    tree \
    unzip \
    vim \
    wget \
    xclip \
    xxd \
    xz-utils \
    zlib1g-dev && \
    pip3 install --ignore-installed pyyaml --break-system-packages && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv
RUN /opt/venv/bin/pip install --no-cache-dir jupyter numpy matplotlib pandas

ARG DPDK_VERSION=22.11
RUN wget --no-verbose http://fast.dpdk.org/rel/dpdk-$DPDK_VERSION.tar.xz && \
    tar -xf dpdk-$DPDK_VERSION.tar.xz && \
    cd dpdk-$DPDK_VERSION && \
    meson build && \
    ninja -C build && \
    ninja install -C build

RUN git clone https://github.com/EttusResearch/uhd.git && \
    cd uhd/host && \
    git checkout v4.9.0.0 && \
    mkdir build && \
    cd build && \
    cmake -DENABLE_B200=ON -DENABLE_LIBUHD=ON -DENABLE_DPDK=ON -DENABLE_EXAMPLES=ON -DENABLE_UTILS=ON ../ && \
    make -j$(nproc) && \
    make install

RUN ldconfig

# Install npm and opencode
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl gnupg git ripgrep \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && npm install -g opencode-ai@1.19.5 \
 && rm -rf /var/lib/apt/lists/*
 
# Working directory (will be bind-mounted from host)
ENV PROJECT_DIR=/workspace
RUN mkdir -p ${PROJECT_DIR}

WORKDIR ${PROJECT_DIR}

USER root

ARG TARGETARCH
RUN case "${TARGETARCH}" in \
        amd64) NVIM_ARCH="x86_64" ;; \
        arm64) NVIM_ARCH="arm64" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && curl -LO "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz" \
    && rm -rf /opt/nvim-linux-${NVIM_ARCH} /opt/nvim \
    && tar -C /opt -xzf nvim-linux-${NVIM_ARCH}.tar.gz \
    && mv /opt/nvim-linux-${NVIM_ARCH} /opt/nvim \
    && rm nvim-linux-${NVIM_ARCH}.tar.gz

ENV PATH="/opt/nvim/bin:${PATH}"

RUN git clone --branch cpp https://github.com/sakthivelvelumani/starter.git /root/.config/nvim

# Working directory (will be bind-mounted from host)
ENV PROJECT_DIR=/workspace
RUN mkdir -p ${PROJECT_DIR}

WORKDIR ${PROJECT_DIR}

# Friendly shell prompt showing we're inside the container
RUN echo 'export PS1="[docker:\W]\$ "' >> /root/.bashrc \
 && echo 'export GPG_TTY=$(tty)' >> /root/.bashrc \
 && echo 'source /usr/share/bash-completion/completions/git' >> /root/.bashrc

CMD ["/bin/bash"]
