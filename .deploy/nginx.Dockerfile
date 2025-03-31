FROM nginx:alpine

COPY .deploy/config/nginx.conf /etc/nginx/conf.d/default.conf
