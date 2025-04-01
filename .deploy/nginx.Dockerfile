FROM nginx:1.27-alpine

# Elimina el default.conf que viene por defecto
RUN rm /etc/nginx/conf.d/default.conf

# Copia tu configuración de nginx personalizada
COPY ./.deploy/config/nginx.conf /etc/nginx/nginx.conf
COPY ./.deploy/config/app.conf /etc/nginx/conf.d/app.conf

# Exponer el puerto 9092 (externo)
EXPOSE 9092
