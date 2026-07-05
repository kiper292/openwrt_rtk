FROM ubuntu:16.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libncurses5-dev \
    zlib1g-dev \
    gawk \
    git \
    gettext \
    libssl-dev \
    xsltproc \
    wget \
    unzip \
    python \
    python3 \
    subversion \
    mercurial \
    rsync \
    curl \
    sudo \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN git config --global http.postBuffer 524288000 && \
    git config --global core.compression 0

# Create build user
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set working directory
WORKDIR /home/builder

# Switch to build user
USER builder

# Default command: bash shell
CMD ["/bin/bash"]
