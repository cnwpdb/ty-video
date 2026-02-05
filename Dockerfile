# 1. 基础镜像
FROM runpod/worker-comfyui:5.5.1-base

# 使用 bash 避免兼容性问题
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# 0. 确保基础工具 (解决 git not found 警告)
RUN apt-get update && apt-get install -y git && apt-get clean && rm -rf /var/lib/apt/lists/*

# ============================================================================
# 1.5 CRITICAL: Completely reinstall ComfyUI for Wan2.1/T5 Support
# The base image has an old ComfyUI that doesn't recognize CLIPLoader type="wan".
# We must delete the old installation and clone fresh from the latest master.
# ============================================================================
WORKDIR /
RUN rm -rf /comfyui && \
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /comfyui && \
    cd /comfyui && \
    pip install -r requirements.txt --no-cache-dir

# 1.6 CRITICAL: 增强型模型路径配置
# Sreverless Network Volume 通常挂载在 /runpod-volume
# 但调试 Pod 中可能挂载在 /workspace
# 我们同时配置两个路径以确保万无一失
# ============================================================================
RUN rm -rf /comfyui/models && \
    mkdir -p /comfyui/models

# 复制本地准备好的 path 文件
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

# ============================================================================
# 2. 安装 Custom Nodes (根据用户本地 ComfyUI 完整列表)
# ============================================================================
WORKDIR /comfyui/custom_nodes

# --- A. 需要安装依赖的插件 (单独处理) ---

# WAS Node Suite (提供 Text Multiline 等核心节点)
RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui.git && \
    cd was-node-suite-comfyui && \
    pip install -r requirements.txt --no-cache-dir

# ComfyUI-Impact-Pack (提供 ImpactSwitch 等关键节点)
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    cd ComfyUI-Impact-Pack && \
    pip install -r requirements.txt --no-cache-dir

# ComfyUI-Impact-Subpack
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git && \
    cd ComfyUI-Impact-Subpack && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# ComfyUI-PainterI2V (Original - Required by Workflow)
RUN git clone https://github.com/princepainter/ComfyUI-PainterI2V.git && \
    cd ComfyUI-PainterI2V && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# ComfyUI-PainterI2V (forKJ Version - Optional/Legacy)
# RUN git clone https://github.com/princepainter/ComfyUI-PainterI2VforKJ.git \
#    && cd ComfyUI-PainterI2VforKJ \
#    && ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# comfy_mtb (Video Workflow 核心)
RUN git clone https://github.com/melMass/comfy_mtb.git && \
    cd comfy_mtb && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# ComfyUI-VideoHelperSuite (提供 VHS_VideoCombine 视频合成节点)
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

# ComfyUI_LayerStyle (依赖 blend_modes 和 opencv-contrib-python)
RUN git clone https://github.com/chflame163/ComfyUI_LayerStyle.git && \
    cd ComfyUI_LayerStyle && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# ComfyUI_LayerStyle_Advance
RUN git clone https://github.com/chflame163/ComfyUI_LayerStyle_Advance.git && \
    cd ComfyUI_LayerStyle_Advance && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# RES4LYF
# RUN git clone https://github.com/ClownsharkBatwing/RES4LYF.git \
#   && cd RES4LYF \
#   && ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# ComfyUI-Detail-Daemon
# RUN git clone https://github.com/Jonseed/ComfyUI-Detail-Daemon.git \
#    && cd ComfyUI-Detail-Daemon \
#    && ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "requirements.txt not found" )

# --- B. 其他无特殊依赖的插件 (批量克隆) ---
# 精简版: 仅保留 workflow_api_v3.json 明确使用的节点
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
    git clone https://github.com/rgthree/rgthree-comfy.git && \
    git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git && \
    git clone https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git && \
    git clone https://github.com/jamesWalker55/comfyui-various.git && \
    pip install soundfile rotary-embedding-torch --no-cache-dir

# ============================================================================
# 3. 安装全局 Python 依赖
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
# 4. 配置 VHS 视频输出支持
# ============================================================================
# 创建输出目录
RUN mkdir -p /comfyui/output && \
    mkdir -p /comfyui/temp && \
    chmod 777 /comfyui/output /comfyui/temp

# 创建自定义输出处理模块 RP_HANDLER
# 假设 rp_handler.py 在同一目录
COPY rp_handler.py /rp_handler.py

CMD [ "python", "-u", "/rp_handler.py" ]

# 5. 重置工作目录
WORKDIR /
