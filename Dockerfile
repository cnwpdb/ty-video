# Test File Presence Only
FROM runpod/worker-comfyui:5.5.1-base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Test copying files - if these don't exist in the Repo Root, build will crash
COPY extra_model_paths.yaml /tmp/extra_model_paths.yaml
COPY rp_handler.py /tmp/rp_handler.py

RUN ls -la /tmp/ && echo "Copy Success"
