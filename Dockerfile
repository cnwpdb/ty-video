FROM runpod/worker-comfyui:5.5.1-base
RUN echo "Hello World"
CMD ["python", "-u", "-c", "print('test')"]
