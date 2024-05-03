# STAGE 1: Construção da aplicação e instalação de dependências
FROM alpine:latest as builder

# Atualizando pacotes e instalando ferramentas necessárias
RUN apk update && \
    apk add --no-cache wget unzip curl python3 python3-dev py3-pip && \
    pip3 install --upgrade pip setuptools

# Instalando Terraform
RUN wget https://releases.hashicorp.com/terraform/1.8.2/terraform_1.8.2_linux_amd64.zip && \
    unzip terraform_1.8.2_linux_amd64.zip && \
    mv terraform /usr/local/bin/

# Instalando AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin

# Configurando diretório de trabalho e copiando aplicação
WORKDIR /work/
COPY app/ .

# Instalando as dependências mínimas (requirements.txt)
RUN pip3 install -r requirements.txt

# STAGE 2: Criação da imagem final
FROM alpine:latest

WORKDIR /work

# Copiando binários do Terraform e AWS CLI
COPY --from=builder /usr/local/bin/terraform /usr/local/bin/
COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli

# Copiando aplicação e configurando ambiente Python
COPY --from=builder /work /work

ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION

# Configurando credenciais da AWS
RUN echo "[default]" >> /root/.aws/credentials && \
    echo "aws_access_key_id = $(echo $AWS_ACCESS_KEY_ID)" >> /root/.aws/credentials && \
    echo "aws_secret_access_key = $(echo $AWS_SECRET_ACCESS_KEY)" >> /root/.aws/credentials

# Instalando Python e dependências
RUN apk update && \
    apk add --no-cache python3 python3-dev py3-pip && \
    pip3 install -r requirements.txt

# Expondo porta e iniciando aplicação
EXPOSE 8080
CMD ["python3", "app.py"]
EXPOSE 8080

# Rodar a aplicação
CMD ["python3", "app.py"]
