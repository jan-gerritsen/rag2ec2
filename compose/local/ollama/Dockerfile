# Dockerfile to build a local Ollama server

FROM ghcr.io/ollama/ollama:latest
ARG BUILD_ENVIRONMENT=local
ARG APP_HOME=/app
ENV BUILD_ENV ${BUILD_ENVIRONMENT}
WORKDIR ${APP_HOME}
COPY ./compose/local/ollama/entrypoint /entrypoint
RUN sed -i 's/\r$//g' /entrypoint
RUN chmod +x /entrypoint
COPY ./compose/local/ollama/start /start
RUN sed -i 's/\r$//g' /start
RUN chmod +x /start
ENTRYPOINT ["/compose/local/ollama/entrypoint"]
CMD ["/start"]
