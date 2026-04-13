FROM ubuntu:22.04

RUN apt update && apt install -y curl unzip awscli nginx

RUN curl -LO https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip \
 && unzip terraform_1.7.5_linux_amd64.zip \
 && mv terraform /usr/local/bin/

COPY sync.sh /sync.sh
RUN chmod +x /sync.sh

CMD ["/sync.sh"]