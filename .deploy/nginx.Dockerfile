FROM nginx:alpine

# Copiamos la configuración
COPY .deploy/nginx.conf /etc/nginx/conf.d/default.conf

# Eliminamos la configuración predeterminada
RUN rm -f /etc/nginx/conf.d/default.conf.default

# Creamos los directorios necesarios
RUN mkdir -p /var/www/html/public

# Configuramos usuario Nginx
RUN sed -i 's/user  nginx;/user  www-data;/' /etc/nginx/nginx.conf && \
    # Aseguramos que el usuario www-data existe
    adduser -u 1000 -D -S -G www-data www-data || true

# Creamos directorios para logs
RUN mkdir -p /var/log/nginx && \
    chown -R www-data:www-data /var/log/nginx

# Creamos directorio SSL si no existe
RUN mkdir -p /etc/nginx/ssl

# Exponemos puertos
EXPOSE 80 443

# Configuramos health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1

# Comando de inicio
CMD ["nginx", "-g", "daemon off;"]