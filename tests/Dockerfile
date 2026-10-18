FROM ubuntu:24.04

ARG CHEZMOI_VERSION=2.73.2

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/opt/chezmoi:$PATH

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        make \
        shellcheck \
        zsh \
    && mkdir -p /opt/chezmoi \
    && curl -fsSL \
        "https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_amd64.tar.gz" \
        | tar -xz -C /opt/chezmoi chezmoi \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . .

CMD ["make", "test"]
