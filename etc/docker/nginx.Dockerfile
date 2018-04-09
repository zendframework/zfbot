# DOCKER-VERSION        1.3.2

FROM nginx:1.13

COPY ./etc/nginx/nginx.conf /etc/nginx/
COPY ./var/www/index.html /var/www/

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
