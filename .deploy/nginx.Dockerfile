FROM nginx:alpine

COPY _deploy/config/nginx.conf /etc/nginx/conf.d/default.conf
