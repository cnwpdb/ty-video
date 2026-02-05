# 1. Base Image
FROM runpod/worker-comfyui:5.5.1-base

# Use bash for better compatibility
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# 0. Basic tools
RUN apt-get update && apt-get install -y git && apt-get clean && rm -rf /var/lib/apt/lists/*

# ============================================================================
# 1.5 CRITICAL: Reinstall ComfyUI Core
# ============================================================================
WORKDIR /
RUN rm -rf /comfyui && \
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /comfyui && \
    cd /comfyui && \
    pip install -r requirements.txt --no-cache-dir

# 1.6 Model Config
RUN rm -rf /comfyui/models && mkdir -p /comfyui/models
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

# ============================================================================
# 2. Install Custom Nodes
# ============================================================================
WORKDIR /comfyui/custom_nodes

# --- A. Nodes with Dependencies ---

# WAS Node Suite
RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui.git && \
    cd was-node-suite-comfyui && \
    pip install -r requirements.txt --no-cache-dir

# ComfyUI-Impact-Pack
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    cd ComfyUI-Impact-Pack && \
    pip install -r requirements.txt --no-cache-dir

# ComfyUI-Impact-Subpack
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git && \
    cd ComfyUI-Impact-Subpack && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# ComfyUI-PainterI2V
RUN git clone https://github.com/princepainter/ComfyUI-PainterI2V.git && \
    cd ComfyUI-PainterI2V && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# comfy_mtb
RUN git clone https://github.com/melMass/comfy_mtb.git && \
    cd comfy_mtb && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# ComfyUI-VideoHelperSuite (VHS)
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# ComfyUI-KJNodes
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    cd ComfyUI-KJNodes && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# ComfyUI-Easy-Use
RUN git clone https://github.com/yolain/ComfyUI-Easy-Use.git && \
    cd ComfyUI-Easy-Use && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# ComfyUI_essentials
RUN git clone https://github.com/cubiq/ComfyUI_essentials.git && \
    cd ComfyUI_essentials && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# ComfyUI_LayerStyle
RUN git clone https://github.com/chflame163/ComfyUI_LayerStyle.git && \
    cd ComfyUI_LayerStyle && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# ComfyUI_LayerStyle_Advance
RUN git clone https://github.com/chflame163/ComfyUI_LayerStyle_Advance.git && \
    cd ComfyUI_LayerStyle_Advance && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# === CRITICAL FIX: MANUAL RIFE INSTALLATION ===
# We bypass the unstable 'install.py' script completely.
RUN git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git && \
    cd ComfyUI-Frame-Interpolation && \
    # 1. Manually install CuPy for CUDA 12 (RunPod Standard)
    pip install cupy-cuda12x --no-cache-dir && \
    # 2. Install rest of requirements
    pip install -r requirements-no-cupy.txt --no-cache-dir && \
    # 3. Create models directory
    mkdir -p ckpts

# --- B. Nodes without specific dependencies ---
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
    git clone https://github.com/rgthree/rgthree-comfy.git && \
    git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git && \
    git clone https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git && \
    git clone https://github.com/jamesWalker55/comfyui-various.git && \
    pip install soundfile rotary-embedding-torch --no-cache-dir

# ============================================================================
# 3. Install Global Dependencies
# ============================================================================
WORKDIR /comfyui
RUN pip install --no-cache-dir \
    blend_modes \
    diffusers>=0.26.0 \
    transformers>=4.38.0 \
    accelerate>=0.27.0 \
    opencv-python \
    opencv-contrib-python \
    imageio \
    imageio-ffmpeg \
    einops \
    basicsr \
    lark \
    runpod

# ============================================================================
# 4. Final Setup
# ============================================================================
RUN mkdir -p /comfyui/output && \
    mkdir -p /comfyui/temp && \
    chmod 777 /comfyui/output /comfyui/temp

# Copy handler
COPY rp_handler.py /rp_handler.py

CMD [ "python", "-u", "/rp_handler.py" ]

WORKDIR /
