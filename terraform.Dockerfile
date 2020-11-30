FROM hashicorp/terraform:0.12.29

RUN apk add py3-pip
RUN pip install awscli

COPY ./scripts /scripts
ENTRYPOINT [ "/scripts/execute_terraform.sh" ]
