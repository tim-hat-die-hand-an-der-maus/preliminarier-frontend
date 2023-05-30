FROM nginxinc/nginx-unprivileged:1.25

COPY build/web /usr/share/nginx/html/

EXPOSE 8080
