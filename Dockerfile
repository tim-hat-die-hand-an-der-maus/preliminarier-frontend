FROM nginxinc/nginx-unprivileged:1.24

COPY build/web /usr/share/nginx/html/

EXPOSE 8080
