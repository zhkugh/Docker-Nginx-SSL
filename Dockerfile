FROM nginx:latest

COPY nginx/conf.d/default.conf.template /etc/nginx/templates/default.conf.template

COPY start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
