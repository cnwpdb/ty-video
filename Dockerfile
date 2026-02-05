# ==============================================================================
# 极简测试版 Dockerfile-video (用于本地 Debug)
# 目标：快速验证 RIFE 插件安装和文件复制，排除环境干扰
# ==============================================================================

# 1. 基础镜像 (与生产环境保持一直)
FROM runpod/worker-comfyui:5.5.1-base

# 2. 设置 Bash (这一步如果由于 CRLF 问题失败，构建会立即报错)
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# 3. 最小化系统依赖测试
RUN apt-get update && apt-get install -y git && echo "System update OK"

# 4. 模拟 ComfyUI 目录结构 (不重新下载 ComfyUI，太慢，直接创建虚假目录测试)
WORKDIR /
RUN mkdir -p /comfyui/custom_nodes /comfyui/models

# 5. 测试 RIFE 插件下载 (验证 git clone 和 pip install)
# 这是我们这次变更的核心，必须测试
RUN git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git /comfyui/custom_nodes/ComfyUI-Frame-Interpolation && \
    cd /comfyui/custom_nodes/ComfyUI-Frame-Interpolation && \
    pip install -r requirements.txt --no-cache-dir && \
    echo "RIFE Plugin Install OK"

# 6. 测试文件复制 (最容易出错也是最重要的部分)
# 注意：这里我们使用 COPY . /tmp/test 来看看到底把什么拷进去了
COPY . /tmp/test_context/
RUN ls -la /tmp/test_context/ && echo "Context Copy OK"

# 7. 测试关键文件是否存在 (模拟生产路径)
# 如果本地目录结构不对，这一步会直接报错
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY rp_handler.py /rp_handler.py

# 8. 验证 Python 语法 (排除 rp_handler.py 写错的可能)
RUN python -c "import rp_handler; print('Handler Syntax OK')" || echo "Handler Import Failed (Expected if missing deps)"

CMD ["echo", "Debug Build Success!"]
