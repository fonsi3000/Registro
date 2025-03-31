FROM nginx:alpine

# Copiamos la configuración
COPY .deploy/config/nginx.conf /etc/nginx/conf.d/default.conf

# Eliminamos la configuración predeterminada
RUN rm -f /etc/nginx/conf.d/default.conf.default

# Creamos los directorios necesarios
RUN mkdir -p /var/www/html/public

# Configuramos usuario Nginx y nos aseguramos que www-data existe
RUN sed -i 's/user  nginx;/user  www-data;/' /etc/nginx/nginx.conf && \
    adduser -u 1000 -D -S -G www-data www-data || true

# Creamos directorios para logs y configuramos permisos
RUN mkdir -p /var/log/nginx && \
    chown -R www-data:www-data /var/log/nginx

# Verificar configuración de Nginx
RUN nginx -t

# Exponemos puertos
EXPOSE 80 443

# Configuramos health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1

# Comando de inicio
CMD ["nginx", "-g", "daemon off;"]