# 1. Base Image
FROM runpod/worker-comfyui:5.5.1-base

# Use bash
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# 0. Basic tools
RUN apt-get update && apt-get install -y git && apt-get clean && rm -rf /var/lib/apt/lists/*

# 1.5 CRITICAL: Reinstall ComfyUI Core
WORKDIR /
RUN rm -rf /comfyui && \
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /comfyui && \
    cd /comfyui && \
    pip install -r requirements.txt --no-cache-dir

# 1.6 Model Config
RUN rm -rf /comfyui/models && mkdir -p /comfyui/models
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

# ============================================================================
# 2. Key Custom Nodes (RIFE + VHS) - MANUAL INSTALL METHOD
# ============================================================================
WORKDIR /comfyui/custom_nodes

# ComfyUI-VideoHelperSuite (Standard)
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# ComfyUI-Frame-Interpolation (RIFE) - MANUAL INSTALL
# We bypass the flaky 'install.py' script completely.
RUN git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git && \
    cd ComfyUI-Frame-Interpolation && \
    # 1. Manually install CuPy for CUDA 12 (RunPod Standard)
    pip install cupy-cuda12x --no-cache-dir && \
    # 2. Install rest of requirements
    pip install -r requirements-no-cupy.txt --no-cache-dir && \
    # 3. Create models directory
    mkdir -p ckpts

# Global Python Deps
WORKDIR /comfyui
RUN pip install --no-cache-dir runpod imageio imageio-ffmpeg

# 4. Handler
COPY rp_handler.py /rp_handler.py
CMD [ "python", "-u", "/rp_handler.py" ]

WORKDIR /
