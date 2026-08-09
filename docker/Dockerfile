FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILDER_UID=501
ARG BUILDER_GID=20

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Asia/Shanghai

RUN dpkg_arch="$(dpkg --print-architecture)" \
    && test "$dpkg_arch" = "arm64" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ack \
        antlr3 \
        asciidoc \
        autoconf \
        automake \
        autopoint \
        binutils \
        bison \
        build-essential \
        bzip2 \
        ca-certificates \
        ccache \
        clang \
        cmake \
        cpio \
        curl \
        device-tree-compiler \
        file \
        flex \
        gawk \
        gettext \
        genisoimage \
        git \
        golang-go \
        gperf \
        haveged \
        help2man \
        intltool \
        libelf-dev \
        libfuse-dev \
        libglib2.0-dev \
        libgmp3-dev \
        libltdl-dev \
        libmpc-dev \
        libmpfr-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libnsl-dev \
        libpython3-dev \
        libreadline-dev \
        libssl-dev \
        libtool \
        llvm \
        lrzsz \
        msmtp \
        ninja-build \
        p7zip \
        p7zip-full \
        patch \
        pkgconf \
        python3 \
        python3-pyelftools \
        python3-setuptools \
        qemu-utils \
        rsync \
        scons \
        squashfs-tools \
        subversion \
        swig \
        texinfo \
        uglifyjs \
        unzip \
        upx-ucl \
        vim \
        wget \
        xmlto \
        xxd \
        xz-utils \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN existing_group="$(getent group "${BUILDER_GID}" | cut -d: -f1)" \
    && if [ -z "$existing_group" ]; then \
         groupadd --gid "${BUILDER_GID}" builder; \
         existing_group=builder; \
       fi \
    && useradd --create-home --uid "${BUILDER_UID}" --gid "$existing_group" --shell /bin/bash builder \
    && install -d -o builder -g "$existing_group" /work /downloads /output

USER builder
WORKDIR /work

CMD ["/scripts/build-openwrt.sh"]
