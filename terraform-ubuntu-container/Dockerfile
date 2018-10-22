FROM ubuntu:latest
COPY ./entrypoint.sh /opt/entrypoint.sh
RUN apt-get update && apt-get install wget unzip -y \
    && wget https://releases.hashicorp.com/terraform/0.11.9/terraform_0.11.9_linux_amd64.zip -O /opt/terraform_0.11.9_linux_amd64.zip \
    && cd /opt && unzip *.zip && rm *.zip && mv terraform /bin \
    && chmod +x entrypoint.sh 
ENTRYPOINT ["/opt/entrypoint.sh"]