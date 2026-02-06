FROM runpod/worker-comfyui:5.5.1-base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y git && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /
RUN rm -rf /comfyui
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /comfyui
WORKDIR /comfyui
RUN pip install -r requirements.txt --no-cache-dir

RUN rm -rf /comfyui/models
RUN mkdir -p /comfyui/models

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

WORKDIR /comfyui/custom_nodes

# WAS Node Suite
RUN git clone --depth 1 https://github.com/WASasquatch/was-node-suite-comfyui.git
RUN cd was-node-suite-comfyui && pip install -r requirements.txt --no-cache-dir

# Impact-Pack
RUN git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Pack.git
RUN cd ComfyUI-Impact-Pack && pip install -r requirements.txt --no-cache-dir

# Impact-Subpack
RUN git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git
RUN cd ComfyUI-Impact-Subpack && ([ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip")

# PainterI2V
RUN git clone --depth 1 https://github.com/princepainter/ComfyUI-PainterI2V.git
RUN cd ComfyUI-PainterI2V && ([ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip")

# comfy_mtb
RUN git clone --depth 1 https://github.com/melMass/comfy_mtb.git
RUN cd comfy_mtb && ([ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip")

# VideoHelperSuite
RUN git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
RUN cd ComfyUI-VideoHelperSuite && ([ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip")

# KJNodes
RUN git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git
RUN cd ComfyUI-KJNodes && ([ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip")

# Easy-Use
RUN git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git
RUN cd ComfyUI-Easy-Use && ([ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip")

# essentials
RUN git clone --depth 1 https://github.com/cubiq/ComfyUI_essentials.git
RUN cd ComfyUI_essentials && ([ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip")

# LayerStyle
RUN git clone --depth 1 https://github.com/chflame163/ComfyUI_LayerStyle.git
RUN cd ComfyUI_LayerStyle && ([ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip")

# LayerStyle_Advance
RUN git clone --depth 1 https://github.com/chflame163/ComfyUI_LayerStyle_Advance.git
RUN cd ComfyUI_LayerStyle_Advance && ([ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip")

# Other nodes
RUN git clone --depth 1 https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git
RUN git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git
RUN git clone --depth 1 https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git
RUN git clone --depth 1 https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git
RUN git clone --depth 1 https://github.com/jamesWalker55/comfyui-various.git
RUN pip install soundfile rotary-embedding-torch --no-cache-dir

# RIFE Frame-Interpolation (补帧核心插件)
RUN git clone --depth 1 https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git
WORKDIR /comfyui/custom_nodes/ComfyUI-Frame-Interpolation
RUN pip install -r requirements-no-cupy.txt --no-cache-dir
RUN python install.py
RUN mkdir -p ckpts
WORKDIR /comfyui/custom_nodes

# Global dependencies
WORKDIR /comfyui
RUN pip install --no-cache-dir blend_modes diffusers transformers accelerate opencv-python opencv-contrib-python imageio imageio-ffmpeg einops basicsr lark runpod

# Output directories
RUN mkdir -p /comfyui/output /comfyui/temp
RUN chmod 777 /comfyui/output /comfyui/temp

# Handler
COPY rp_handler.py /rp_handler.py
CMD [ "python", "-u", "/rp_handler.py" ]

WORKDIR /
