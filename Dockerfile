FROM runpod/worker-comfyui:5.5.1-base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y git && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /
RUN rm -rf /comfyui && \
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /comfyui && \
    cd /comfyui && \
    pip install -r requirements.txt --no-cache-dir

RUN rm -rf /comfyui/models && mkdir -p /comfyui/models
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

WORKDIR /comfyui/custom_nodes

RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui.git && \
    cd was-node-suite-comfyui && \
    pip install -r requirements.txt --no-cache-dir

RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    cd ComfyUI-Impact-Pack && \
    pip install -r requirements.txt --no-cache-dir

RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git && \
    cd ComfyUI-Impact-Subpack && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip" )

RUN git clone https://github.com/princepainter/ComfyUI-PainterI2V.git && \
    cd ComfyUI-PainterI2V && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip" )

RUN git clone https://github.com/melMass/comfy_mtb.git && \
    cd comfy_mtb && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip" )

RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip" )

RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    cd ComfyUI-KJNodes && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip" )

RUN git clone https://github.com/yolain/ComfyUI-Easy-Use.git && \
    cd ComfyUI-Easy-Use && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip" )

RUN git clone https://github.com/cubiq/ComfyUI_essentials.git && \
    cd ComfyUI_essentials && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip" )

RUN git clone https://github.com/chflame163/ComfyUI_LayerStyle.git && \
    cd ComfyUI_LayerStyle && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip" )

RUN git clone https://github.com/chflame163/ComfyUI_LayerStyle_Advance.git && \
    cd ComfyUI_LayerStyle_Advance && \
    ( [ -f requirements.txt ] && pip install -r requirements.txt --no-cache-dir || echo "skip" )

RUN git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git && \
    cd ComfyUI-Frame-Interpolation && \
    pip install cupy-cuda12x --no-cache-dir && \
    pip install -r requirements-no-cupy.txt --no-cache-dir && \
    mkdir -p ckpts

RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
    git clone https://github.com/rgthree/rgthree-comfy.git && \
    git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git && \
    git clone https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git && \
    git clone https://github.com/jamesWalker55/comfyui-various.git && \
    pip install soundfile rotary-embedding-torch --no-cache-dir

WORKDIR /comfyui
RUN pip install --no-cache-dir blend_modes diffusers transformers accelerate opencv-python opencv-contrib-python imageio imageio-ffmpeg einops basicsr lark runpod

RUN mkdir -p /comfyui/output /comfyui/temp && chmod 777 /comfyui/output /comfyui/temp

COPY rp_handler.py /rp_handler.py
CMD [ "python", "-u", "/rp_handler.py" ]
WORKDIR /
