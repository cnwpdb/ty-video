FROM runpod/worker-comfyui:5.5.1-base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo "Hello World - Base Image OK"
