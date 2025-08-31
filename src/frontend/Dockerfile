FROM nginx:alpine

# Copiar arquivos de configuração e aplicação
COPY index.html /usr/share/nginx/html/
COPY dist/output.css /usr/share/nginx/html/output.css
COPY script.js /usr/share/nginx/html/
COPY telemetry.js /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Definir permissões seguras e remover permissões desnecessárias
RUN chmod -R 755 /usr/share/nginx/html \
    && find /usr/share/nginx/html -type f -exec chmod 644 {} \; \
    && chmod 644 /etc/nginx/conf.d/default.conf \
    && chown -R nginx:nginx /usr/share/nginx/html \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /etc/nginx/conf.d \
    && touch /var/run/nginx.pid \
    && chown -R nginx:nginx /var/run/nginx.pid \
    && chmod -R a-w /etc/nginx

# Executar como usuário não-root
USER nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
