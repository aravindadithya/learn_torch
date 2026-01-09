FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    SHELL=/bin/bash

# 1. System Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-dev \
    git \
    git-lfs \
    curl \
    iproute2 \
    iputils-ping \
    build-essential \
    tini && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /work

# 2. Install PyTorch 2.9.0 
RUN count=0; while [ $count -lt 5 ]; do \
    pip3 install --no-cache-dir \
    torch==2.9.0 \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu124 && break; \
    count=$((count+1)); echo "PyTorch install failed, retrying ($count/5)..."; \
    sleep 5; \
done

# 3. Install remaining requirements
COPY requirements.txt .
RUN count=0; while [ $count -lt 5 ]; do \
    pip3 install --no-cache-dir -r requirements.txt && break; \
    count=$((count+1)); echo "Requirements install failed, retrying ($count/5)..."; \
    sleep 5; \
done

# 4. Install JupyterLab with Terminal support
# 'terminado' is the key for the Jupyter Terminal
RUN count=0; while [ $count -lt 5 ]; do \
    pip3 install --no-cache-dir jupyterlab visdom terminado && break; \
    count=$((count+1)); echo "Tools install failed, retrying ($count/5)..."; \
    sleep 5; \
done

COPY start.sh /work/start.sh
RUN chmod +x /work/start.sh

EXPOSE 8097 8888

# Use tini to manage the sub-processes (Visdom + Jupyter)
ENTRYPOINT ["/usr/bin/tini", "--", "/bin/bash", "/work/start.sh"]

# Defaults: [Repo_Name] [Branch] [LFS_Skip]
CMD ["DLR", "master", "0"]