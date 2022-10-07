FROM sykescottages/cdk:base

RUN curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb" && \
    dpkg -i /tmp/session-manager-plugin.deb && \
    rm -rf /tmp/session-manager-plugin.deb

# Checksum required to ensure nothing malicious is added in future releases
RUN curl https://raw.githubusercontent.com/aws-containers/amazon-ecs-exec-checker/b1d163bd95c5b6f915e2bb3ad810e6f2aecae985/check-ecs-exec.sh -o "/bin/check-ecs" && \
    echo "daf8be1b19b04ca97cb50de641ec2b8f21944855b0ed73287bf4c396cedeb92911f8fac22bff414ad8c41fe326ebd562 /bin/check-ecs" | sha384sum --check && \
    chmod +x /bin/check-ecs

RUN apt-get update && apt-get install -y \
    dialog

RUN apt-get autoremove -y -q && \
    apt-get autoclean -y -q && \
    rm -rf /var/lib/apt/lists/*

COPY connect.sh /bin/connect
