# DOCKER-VERSION        1.3.2

FROM nginx:1.13

COPY ./etc/nginx/nginx.conf /etc/nginx/
COPY ./etc/nginx/certs/* /etc/nginx/certs/
COPY ./var/www/index.html /var/www/
CMD ["nginx", "-g", "daemon off;"]
