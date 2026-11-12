FROM ubuntu:24.04

RUN apt-get update && apt-get install -y nginx curl && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html/errors && rm -f /etc/nginx/sites-enabled/default

COPY errors/503.html /var/www/html/errors/503.html
COPY nginx_shield.conf /etc/nginx/sites-available/shield.conf

RUN ln -sf /etc/nginx/sites-available/shield.conf /etc/nginx/sites-enabled/shield.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
