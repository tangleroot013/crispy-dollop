FROM debian:bookworm-slim

LABEL maintainer="bilbywilby"
LABEL description="Crispy-Dollop WireGuard Resilient VPN Node"

# Avoid interactive prompts during apt install
ENV DEBIAN_FRONTEND=noninteractive

# Install core runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wireguard-tools \
    iproute2 \
    iptables \
    ip6tables \
    curl \
    jq \
    dnsutils \
    tcpdump \
    procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/crispy-dollop

# Copy repository structure
COPY . /opt/crispy-dollop/
RUN chmod +x setup.sh scripts/*.sh

ENTRYPOINT ["./setup.sh"]