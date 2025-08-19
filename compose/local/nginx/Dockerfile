FROM nginx:1.17.8-alpine
RUN rm -f /etc/nginx/conf.d/*.conf
COPY default.conf /etc/nginx/conf.d/default.conf
RUN rm -rf /usr/share/nginx/html/*
