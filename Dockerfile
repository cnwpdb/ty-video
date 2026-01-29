# ============================================================================
# 方案A: 极简镜像架构 - 适合新账户和多账户部署
# ============================================================================
# 设计理念:
#   - 镜像只包含基础环境 (ComfyUI + 核心依赖)
#   - Custom Nodes 和模型全部放 Volume (灵活更新)
#   - 适合新账户部署和批量账户管理
# 
# 镜像大小: ~10GB (vs 10.7GB 原版)
# 冷启动: 6-8min (含 Nodes 安装)
# 热启动: 1-2min (Nodes 已安装)
# ============================================================================

# 1. 基础镜像 (CUDA + PyTorch + RunPod SDK)
FROM runpod/worker-comfyui:5.5.1-base

# 使用 bash
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# 2. 系统工具
RUN apt-get update && apt-get install -y \
    git \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# 3. ComfyUI 核心 (最新版,支持 Wan 2.2)
# ============================================================================
WORKDIR /
RUN rm -rf /comfyui && \
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /comfyui && \
    cd /comfyui && \
    pip install -r requirements.txt --no-cache-dir

# ============================================================================
# 4. 模型路径配置 (双路径支持)
# ============================================================================
# 创建空的 models 目录 (实际模型在 Volume)
RUN rm -rf /comfyui/models && \
    mkdir -p /comfyui/models

# 配置 extra_model_paths.yaml (指向 Volume)
RUN echo "runpod_volume_models:" > /comfyui/extra_model_paths.yaml && \
    echo "    base_path: /runpod-volume/models/" >> /comfyui/extra_model_paths.yaml && \
    echo "    checkpoints: checkpoints/" >> /comfyui/extra_model_paths.yaml && \
    echo "    clip: clip/" >> /comfyui/extra_model_paths.yaml && \
    echo "    clip_vision: clip_vision/" >> /comfyui/extra_model_paths.yaml && \
    echo "    text_encoders: text_encoders/" >> /comfyui/extra_model_paths.yaml && \
    echo "    unet: unet/" >> /comfyui/extra_model_paths.yaml && \
    echo "    diffusion_models: diffusion_models/" >> /comfyui/extra_model_paths.yaml && \
    echo "    vae: vae/" >> /comfyui/extra_model_paths.yaml && \
    echo "    loras: loras/" >> /comfyui/extra_model_paths.yaml && \
    echo "    upscale_models: upscale_models/" >> /comfyui/extra_model_paths.yaml && \
    echo "    controlnet: controlnet/" >> /comfyui/extra_model_paths.yaml && \
    echo "    embeddings: embeddings/" >> /comfyui/extra_model_paths.yaml && \
    echo "    hypernetworks: hypernetworks/" >> /comfyui/extra_model_paths.yaml && \
    echo "" >> /comfyui/extra_model_paths.yaml && \
    echo "workspace_models:" >> /comfyui/extra_model_paths.yaml && \
    echo "    base_path: /workspace/models/" >> /comfyui/extra_model_paths.yaml && \
    echo "    checkpoints: checkpoints/" >> /comfyui/extra_model_paths.yaml && \
    echo "    clip: clip/" >> /comfyui/extra_model_paths.yaml && \
    echo "    clip_vision: clip_vision/" >> /comfyui/extra_model_paths.yaml && \
    echo "    text_encoders: text_encoders/" >> /comfyui/extra_model_paths.yaml && \
    echo "    unet: unet/" >> /comfyui/extra_model_paths.yaml && \
    echo "    diffusion_models: diffusion_models/" >> /comfyui/extra_model_paths.yaml && \
    echo "    vae: vae/" >> /comfyui/extra_model_paths.yaml && \
    echo "    loras: loras/" >> /comfyui/extra_model_paths.yaml && \
    echo "    upscale_models: upscale_models/" >> /comfyui/extra_model_paths.yaml && \
    echo "    controlnet: controlnet/" >> /comfyui/extra_model_paths.yaml && \
    echo "    embeddings: embeddings/" >> /comfyui/extra_model_paths.yaml && \
    echo "    hypernetworks: hypernetworks/" >> /comfyui/extra_model_paths.yaml

# ============================================================================
# 5. 核心 Python 依赖 (全局)
# ============================================================================
# 注意: Custom Nodes 的依赖在 Volume 初始化时安装
RUN pip install --no-cache-dir \
    runpod \
    einops \
    blend_modes

# ============================================================================
# 6. 创建 Custom Nodes 目录 (空,实际内容在 Volume)
# ============================================================================
RUN mkdir -p /comfyui/custom_nodes

# ============================================================================
# 7. 输出目录配置
# ============================================================================
RUN mkdir -p /comfyui/output && \
    mkdir -p /comfyui/temp && \
    chmod 777 /comfyui/output /comfyui/temp

# ============================================================================
# 8. RunPod Serverless Handler (支持视频输出)
# ============================================================================
# Handler 代码 (Base64 编码,与原版相同)
RUN echo "aW1wb3J0IHRpbWUNCmltcG9ydCBqc29uDQppbXBvcnQgdXJsbGliLnJlcXVlc3QNCmltcG9ydCB1cmxsaWIucGFyc2UNCmltcG9ydCBvcw0KaW1wb3J0IHN1YnByb2Nlc3MNCmltcG9ydCB0aHJlYWRpbmcNCmltcG9ydCBzeXMNCmltcG9ydCBnbG9iDQppbXBvcnQgYmFzZTY0DQppbXBvcnQgcnVucG9kDQoNCiMgTWluaW1hbCBDb21meVVJIENsaWVudA0KQVBQX1VSTCA9ICJodHRwOi8vMTI3LjAuMC4xOjgxODgiDQoNCmRlZiB3YWl0X2Zvcl9zZXJ2aWNlKHVybCwgdGltZW91dD0zMDApOg0KICAgIHN0YXJ0ID0gdGltZS50aW1lKCkNCiAgICB3aGlsZSB0aW1lLnRpbWUoKSAtIHN0YXJ0IDwgdGltZW91dDoNCiAgICAgICAgdHJ5Og0KICAgICAgICAgICAgdXJsbGliLnJlcXVlc3QudXJsb3Blbih1cmwsIHRpbWVvdXQ9MikNCiAgICAgICAgICAgIHByaW50KCJTZXJ2aWNlIGlzIFVQIikNCiAgICAgICAgICAgIHJldHVybiBUcnVlDQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb246DQogICAgICAgICAgICB0aW1lLnNsZWVwKDEpDQogICAgICAgICAgICBpZiBpbnQodGltZS50aW1lKCkgLSBzdGFydCkgJSAxMCA9PSAwOg0KICAgICAgICAgICAgICAgIHByaW50KCJXYWl0aW5nIGZvciBDb21meVVJLi4uIikNCiAgICByZXR1cm4gRmFsc2UNCg0KZGVmIGNoZWNrX291dHB1dHMocHJvbXB0X2lkKToNCiAgICBoaXN0b3J5X3VybCA9IGYie0FQUF9VUkx9L2hpc3Rvcnkve3Byb21wdF9pZH0iDQogICAgdHJ5Og0KICAgICAgICB3aXRoIHVybGxpYi5yZXF1ZXN0LnVybG9wZW4oaGlzdG9yeV91cmwpIGFzIHJlc3BvbnNlOg0KICAgICAgICAgICAgIGhpc3RvcnkgPSBqc29uLmxvYWRzKHJlc3BvbnNlLnJlYWQoKSkNCiAgICAgICAgcmV0dXJuIGhpc3RvcnkuZ2V0KHByb21wdF9pZCwge30pLmdldCgnb3V0cHV0cycsIHt9KQ0KICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToNCiAgICAgICAgcHJpbnQoZiJFcnJvciBjaGVja2luZyBvdXRwdXRzOiB7ZX0iKQ0KICAgICAgICByZXR1cm4ge30NCg0KZGVmIGdldF9iYXNlNjRfZmlsZShwYXRoKToNCiAgICB3aXRoIG9wZW4ocGF0aCwgInJiIikgYXMgZjoNCiAgICAgICAgcmV0dXJuIGJhc2U2NC5iNjRlbmNvZGUoZi5yZWFkKCkpLmRlY29kZSgndXRmLTgnKQ0KDQojIEhhbmRsZXIgRnVuY3Rpb24NCmRlZiBoYW5kbGVyKGV2ZW50KToNCiAgICBpbnB1dF9wYXlsb2FkID0gZXZlbnRbImlucHV0Il0NCiAgICANCiAgICAjIDEuIEhhbmRsZSBJbnB1dCBJbWFnZXMgKFNhdmUgdG8gL2NvbWZ5dWkvaW5wdXQpDQogICAgIyBTdGFuZGFyZCBmb3JtYXQ6IHsgIndvcmtmbG93Ijoge30sICJpbWFnZXMiOiBbeyJuYW1lIjogImZvby5wbmciLCAiaW1hZ2UiOiAiYjY0Li4uIn1dIH0NCiAgICB3b3JrZmxvdyA9IE5vbmUNCiAgICANCiAgICBpZiAiaW1hZ2VzIiBpbiBpbnB1dF9wYXlsb2FkOg0KICAgICAgICBmb3IgaW1nIGluIGlucHV0X3BheWxvYWRbImltYWdlcyJdOg0KICAgICAgICAgICAgdHJ5Og0KICAgICAgICAgICAgICAgIG5hbWUgPSBpbWdbIm5hbWUiXQ0KICAgICAgICAgICAgICAgIGI2NF9kYXRhID0gaW1nWyJpbWFnZSJdDQogICAgICAgICAgICAgICAgZmlsZV9wYXRoID0gb3MucGF0aC5qb2luKCIvY29tZnl1aS9pbnB1dCIsIG5hbWUpDQogICAgICAgICAgICAgICAgd2l0aCBvcGVuKGZpbGVfcGF0aCwgIndiIikgYXMgZjoNCiAgICAgICAgICAgICAgICAgICAgZi53cml0ZShiYXNlNjQuYjY0ZGVjb2RlKGI2NF9kYXRhKSkNCiAgICAgICAgICAgICAgICBwcmludChmIlNhdmVkIGlucHV0IGltYWdlOiB7bmFtZX0iKQ0KICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBlOg0KICAgICAgICAgICAgICAgIHByaW50KGYiRmFpbGVkIHRvIHNhdmUgaW5wdXQgaW1hZ2U6IHtzdHIoZSl9IikNCiAgICANCiAgICBpZiAid29ya2Zsb3ciIGluIGlucHV0X3BheWxvYWQ6DQogICAgICAgIHdvcmtmbG93ID0gaW5wdXRfcGF5bG9hZFsid29ya2Zsb3ciXQ0KICAgIGVsc2U6DQogICAgICAgICMgRmFsbGJhY2s6IGFzc3VtZSBpbnB1dCBJUyB0aGUgd29ya2Zsb3cNCiAgICAgICAgd29ya2Zsb3cgPSBpbnB1dF9wYXlsb2FkDQoNCiAgICAjIFNlbmQgUHJvbXB0DQogICAgcmVxX2RhdGEgPSBqc29uLmR1bXBzKHsicHJvbXB0Ijogd29ya2Zsb3d9KS5lbmNvZGUoJ3V0Zi04JykNCiAgICByZXEgPSB1cmxsaWIucmVxdWVzdC5SZXF1ZXN0KGYie0FQUF9VUkx9L3Byb21wdCIsIGRhdGE9cmVxX2RhdGEsIGhlYWRlcnM9eydDb250ZW50LVR5cGUnOiAnYXBwbGljYXRpb24vanNvbid9KQ0KICAgIA0KICAgIHRyeToNCiAgICAgICAgd2l0aCB1cmxsaWIucmVxdWVzdC51cmxvcGVuKHJlcSkgYXMgcmVzcG9uc2U6DQogICAgICAgICAgICByZXNwX2RhdGEgPSBqc29uLmxvYWRzKHJlc3BvbnNlLnJlYWQoKSkNCiAgICAgICAgICAgIHByb21wdF9pZCA9IHJlc3BfZGF0YVsncHJvbXB0X2lkJ10NCiAgICAgICAgICAgIHByaW50KGYiV29ya2Zsb3cgc3VibWl0dGVkLiBJRDoge3Byb21wdF9pZH0iKQ0KICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToNCiAgICAgICAgcmV0dXJuIHsiZXJyb3IiOiBmIkNvbWZ5VUkgU3VibWl0IEZhaWxlZDoge3N0cihlKX0ifQ0KDQogICAgIyBXYWl0IGZvciBDb21wbGV0aW9uIChQb2xsaW5nIEhpc3RvcnkpDQogICAgcHJpbnQoIldhdGNoaW5nIGZvciBjb21wbGV0aW9uLi4uIikNCiAgICB3aGlsZSBUcnVlOg0KICAgICAgICBoaXN0b3J5X3VybCA9IGYie0FQUF9VUkx9L2hpc3Rvcnkve3Byb21wdF9pZH0iDQogICAgICAgIHRyeToNCiAgICAgICAgICAgICB3aXRoIHVybGxpYi5yZXF1ZXN0LnVybG9wZW4oaGlzdG9yeV91cmwpIGFzIHJlc3BvbnNlOg0KICAgICAgICAgICAgICAgIGhpc3RvcnlfZGF0YSA9IGpzb24ubG9hZHMocmVzcG9uc2UucmVhZCgpKQ0KICAgICAgICAgICAgICAgIGlmIHByb21wdF9pZCBpbiBoaXN0b3J5X2RhdGE6DQogICAgICAgICAgICAgICAgICAgIHByaW50KCJXb3JrZmxvdyBGaW5pc2hlZC4iKQ0KICAgICAgICAgICAgICAgICAgICBicmVhaw0KICAgICAgICBleGNlcHQgRXhjZXB0aW9uOg0KICAgICAgICAgICAgcGFzcw0KICAgICAgICB0aW1lLnNsZWVwKDEpDQoNCiAgICAjIENvbGxlY3QgT3V0cHV0cw0KICAgIGZpbmFsX291dHB1dCA9IHsic3RhdHVzIjogInN1Y2Nlc3MiLCAiaW1hZ2VzIjogW10sICJ2aWRlb3MiOiBbXX0NCiAgICANCiAgICAjIDEuIEluc3BlY3QgQ29tZnlVSSBIaXN0b3J5IE91dHB1dCAoU3RhbmRhcmQgTm9kZXMpDQogICAgb3V0cHV0cyA9IGhpc3RvcnlfZGF0YVtwcm9tcHRfaWRdLmdldCgnb3V0cHV0cycsIHt9KQ0KICAgIA0KICAgICMgMi4gSGV1cmlzdGljOiBTY2FuIE91dHB1dCBGb2xkZXIgZm9yIHJlY2VudCBmaWxlcyAoUm9idXN0IGZhbGxiYWNrIGZvciBWSFMvQ3VzdG9tIG5vZGVzKQ0KICAgICMgV2UgbG9vayBmb3IgZmlsZXMgY3JlYXRlZCBpbiB0aGUgbGFzdCA2MCBzZWNvbmRzIHRvIGF2b2lkIHJldHVybmluZyBvbGQganVuaw0KICAgIG91dHB1dF9kaXIgPSAiL2NvbWZ5dWkvb3V0cHV0Ig0KICAgIHJlY2VudF9saW1pdCA9IDMwMCAjIExvb2sgYmFjayA1IG1pbnMNCiAgICBub3cgPSB0aW1lLnRpbWUoKQ0KICAgIA0KICAgIGZvdW5kX2ZpbGVzID0gW10NCiAgICANCiAgICAjIEV4dGVuc2lvbnMgdG8gY2FwdHVyZQ0KICAgIGV4dGVuc2lvbnMgPSBbJyoubXA0JywgJyouZ2lmJywgJyoucG5nJywgJyouanBnJywgJyoud2VicCddDQogICAgZm9yIGV4dCBpbiBleHRlbnNpb25zOg0KICAgICAgICBmb3IgZnBhdGggaW4gZ2xvYi5nbG9iKG9zLnBhdGguam9pbihvdXRwdXRfZGlyLCBleHQpKToNCiAgICAgICAgICAgIGlmIG9zLnBhdGguZ2V0bXRpbWUoZnBhdGgpID4gbm93IC0gcmVjZW50X2xpbWl0Og0KICAgICAgICAgICAgICAgIGZvdW5kX2ZpbGVzLmFwcGVuZChmcGF0aCkNCiAgICANCiAgICBmb3IgZnBhdGggaW4gZm91bmRfZmlsZXM6DQogICAgICAgIGZpbGVuYW1lID0gb3MucGF0aC5iYXNlbmFtZShmcGF0aCkNCiAgICAgICAgYjY0X2RhdGEgPSBnZXRfYmFzZTY0X2ZpbGUoZnBhdGgpDQogICAgICAgIA0KICAgICAgICBpZiBmaWxlbmFtZS5lbmRzd2l0aCgnLm1wNCcpIG9yIGZpbGVuYW1lLmVuZHN3aXRoKCcuZ2lmJyk6DQogICAgICAgICAgICBmaW5hbF9vdXRwdXRbInZpZGVvcyJdLmFwcGVuZCh7DQogICAgICAgICAgICAgICAgImZpbGVuYW1lIjogZmlsZW5hbWUsDQogICAgICAgICAgICAgICAgInR5cGUiOiAidmlkZW8iIGlmIGZpbGVuYW1lLmVuZHN3aXRoKCdtcDQnKSBlbHNlICJnaWYiLA0KICAgICAgICAgICAgICAgICJkYXRhIjogYjY0X2RhdGENCiAgICAgICAgICAgIH0pDQogICAgICAgIGVsc2U6DQogICAgICAgICAgICAgZmluYWxfb3V0cHV0WyJpbWFnZXMiXS5hcHBlbmQoew0KICAgICAgICAgICAgICAgICJmaWxlbmFtZSI6IGZpbGVuYW1lLA0KICAgICAgICAgICAgICAgICJ0eXBlIjogImltYWdlIiwNCiAgICAgICAgICAgICAgICAiZGF0YSI6IGI2NF9kYXRhDQogICAgICAgICAgICB9KQ0KDQogICAgaWYgbm90IGZpbmFsX291dHB1dFsiaW1hZ2VzIl0gYW5kIG5vdCBmaW5hbF9vdXRwdXRbInZpZGVvcyJdOg0KICAgICAgICBmaW5hbF9vdXRwdXRbInN0YXR1cyJdID0gInN1Y2Nlc3Nfbm9fb3V0cHV0cyINCiAgICAgICAgZmluYWxfb3V0cHV0WyJkZWJ1Z19oaXN0b3J5Il0gPSBvdXRwdXRzDQoNCiAgICByZXR1cm4gZmluYWxfb3V0cHV0DQoNCiMgU3RhcnQgQ29tZnlVSSBpbiBCYWNrZ3JvdW5kDQpkZWYgc3RhcnRfY29tZnkoKToNCiAgICBwcmludCgiU3RhcnRpbmcgQ29tZnlVSS4uLiIpDQogICAgDQogICAgIyBJbml0aWFsaXplIEN1c3RvbSBOb2RlcyBmcm9tIFZvbHVtZSAoaWYgbm90IGFscmVhZHkgZG9uZSkNCiAgICBpZiBvcy5wYXRoLmV4aXN0cygnL3J1bnBvZC12b2x1bWUvc2NyaXB0cy9pbml0X2N1c3RvbV9ub2Rlcy5zaCcpOg0KICAgICAgICBwcmludCgiSW5pdGlhbGl6aW5nIEN1c3RvbSBOb2RlcyBmcm9tIFZvbHVtZS4uLiIpDQogICAgICAgIHN1YnByb2Nlc3MucnVuKFsnYmFzaCcsICcvcnVucG9kLXZvbHVtZS9zY3JpcHRzL2luaXRfY3VzdG9tX25vZGVzLnNoJ10pDQogICAgDQogICAgc3VicHJvY2Vzcy5Qb3BlbihbInB5dGhvbiIsICJtYWluLnB5IiwgIi0tbGlzdGVuIiwgIi0tcG9ydCIsICI4MTg4Il0sIGN3ZD0iL2NvbWZ5dWkiKQ0KICAgIHJldHVybiB3YWl0X2Zvcl9zZXJ2aWNlKEFQUF9VUkwpDQoNCmlmIF9fbmFtZV9fID09ICJfX21haW5fXyI6DQogICAgaWYgc3RhcnRfY29tZnkoKToNCiAgICAgICAgcHJpbnQoIlN0YXJ0aW5nIFJ1blBvZCBTZXJ2ZXJsZXNzIEhhbmRsZXIiKQ0KICAgICAgICBydW5wb2Quc2VydmVybGVzcy5zdGFydCh7ImhhbmRsZXIiOiBoYW5kbGVyfSkNCiAgICBlbHNlOg0KICAgICAgICBwcmludCgiRkFUQUw6IENvbWZ5VUkgZmFpbGVkIHRvIHN0YXJ0IHdpdGhpbiB0aW1lb3V0LiBFeGl0aW5nLiIpDQogICAgICAgIHN5cy5leGl0KDEpDQo=" | base64 -d > /rp_handler.py

# ============================================================================
# 9. 启动命令
# ============================================================================
CMD ["python", "-u", "/rp_handler.py"]

# ============================================================================
# 镜像大小优化说明:
# - 不包含 Custom Nodes (在 Volume,~500MB 节省)
# - 使用 --no-cache-dir (减少 pip 缓存)
# - 清理 apt 缓存
# 
# 预估大小: ~10.0GB (vs 10.7GB 原版)
# ============================================================================
