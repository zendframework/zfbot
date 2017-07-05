# DOCKER-VERSION        1.3.2

FROM nginx:1.13

COPY data/etc/nginx/nginx.conf /etc/nginx/
COPY data/etc/nginx/certs/* /etc/nginx/certs/
COPY data/var/www/index.html /var/www/
CMD ["nginx", "-g", "daemon off;"]
