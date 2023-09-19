# FROM ubuntu:latest

# RUN apt-get update \
#     && apt-get install -y curl \
#     && apt-get install -y unzip \
#     && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
#     && unzip awscliv2.zip \
#     && ./aws/install \
#     && apt-get install -y apache2 \
#     && echo "This is testing..." > /var/www/html/index.html \
#     && echo "ServerName localhost" >> /etc/apache2/apache2.conf 
# RUN chown -R www-data:www-data /var/www/html
# # CMD ["/usr/sbin/apachectl", "-D", "FOREGROUND"]

# EXPOSE 80
# CMD ["apache2ctl", "-D", "FOREGROUND"]

FROM ubuntu:latest

RUN apt-get update \
    && apt-get install -y curl \
    && apt-get install -y unzip \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install 

CMD ["/bin/bash", "pwd"]
ENTRYPOINT ["tail", "-f", "/dev/null"]