FROM alpine:3.20
RUN echo "build ok"
CMD ["sh", "-lc", "echo run ok && sleep 3600"]
