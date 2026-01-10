FROM nvidia/cuda:12.4.1-base-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    SHELL=/bin/bash

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip python3-dev git git-lfs curl iproute2 tini tmux build-essential && \
    # Link python to python3 so VS Code kernels don't break
    ln -s /usr/bin/python3 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /work

RUN count=0; while [ $count -lt 5 ]; do \
    pip3 install --no-cache-dir \
    torch==2.6.0 \
    --index-url https://download.pytorch.org/whl/cu124 && break; \
    count=$((count+1)); echo "PyTorch install failed, retrying ($count/5)..."; \
    sleep 5; \
done


COPY requirements.txt .
RUN count=0; while [ $count -lt 5 ]; do \
    pip3 install --no-cache-dir -r requirements.txt visdom && \
    apt-get purge -y build-essential python3-dev && \
    apt-get autoremove -y && \
    rm -rf /root/.cache/pip && \
    break; \
    count=$((count+1)); echo "Requirements install failed, retrying ($count/5)..."; \
    sleep 5; \
done

EXPOSE 8097 8888

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["/bin/bash"]
