FROM ubuntu:latest

# Install required packages and configure Apache
RUN apt-get update \
    && apt-get install -y curl \
    && apt-get install -y unzip \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && apt-get install -y apache2

# Add ServerName directive to Apache configuration
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 80
CMD ["apache2ctl", "-D", "FOREGROUND"]
