# 1. Base Image
FROM runpod/worker-comfyui:5.5.1-base

# Use bash for better compatibility
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# 0. Basic tools (Git)
# This was Step 1 in the full file
RUN apt-get update && apt-get install -y git && apt-get clean && rm -rf /var/lib/apt/lists/*

# 1.5 CRITICAL: Reinstall ComfyUI Core
# This was Step 2 in the full file
# If this passes, the issue is likely in one of the plugin install blocks
WORKDIR /
RUN rm -rf /comfyui && \
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /comfyui && \
    cd /comfyui && \
    pip install -r requirements.txt --no-cache-dir

CMD ["echo", "Core Build Success - Ready for Plugins"]
