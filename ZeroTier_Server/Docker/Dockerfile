# Use Debian as a base
FROM debian:latest

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Configure and install
# What commands do:
# 1. Allow for Packet Forwarding
# 2. Update the system
# 3. Install necessary packets and iproute2 (Quality of Life improvement)
# 4. Install ZeroTier
RUN echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf && \
    apt update && apt full-upgrade -y && \
    apt install -y curl gnupg iproute2 iptables iptables-persistent && \
    curl -s https://install.zerotier.com | bash

# Ensure the ZeroTier service starts automatically
CMD ["/bin/bash", "-c", "service zerotier-one start; tail -f /dev/null"]