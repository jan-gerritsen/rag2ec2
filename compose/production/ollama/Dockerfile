# Dockerfile to build a local Ollama server
FROM ollama/ollama:latest
# this image is based on Ubuntu 22.04

COPY entrypoint /entrypoint

RUN apt-get update && apt-get install -y curl

RUN echo "Setting up entrypoint script"
RUN sed -i 's/\r$//g' /entrypoint
RUN chmod +x /entrypoint
RUN echo "Entrypoint script set up successfully"
ENTRYPOINT ["/entrypoint"]

