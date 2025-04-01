FROM nginx:alpine

# Instalar openssl
RUN apk add --no-cache openssl

# Copiar configuración personalizada
COPY .deploy/config/nginx.conf /etc/nginx/conf.d/default.conf

# Generar certificado SSL autofirmado
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 \
    -subj "/C=US/ST=State/L=City/O=Company/CN=localhost" \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/selfsigned.key \
    -out /etc/nginx/ssl/selfsigned.crt
