
FROM ubuntu:latest

RUN apt-get update \
    && apt-get install -y curl \
    && apt-get install -y unzip \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install 


CMD ["/bin/bash", "pwd"]
ENTRYPOINT ["tail", "-f", "/dev/null"]