# AWS ECS Connector

## Connect Tool

If you want an easy way to check and connect to an ECS container you can simply run the connect tool with
```shell
$ docker-compose run --rm aws connect
```

This will connect to your AWS account and give you a menu system to check/connect to your desired tasks.

### Usage flags

```shell
Usage: $PROGNAME [-v] [-p profile] [-r region]
```

- `-v` Run AWS cli commands in debug mode
- `-p <PROFILE>` Specify the AWS profile to run your commands
- `-r <REGION>` Specify the AWS region to run your commands in

## Checking if you can connect to an ECS Container

Validate that you can connect to the ECS cluster and task in question with:

```shell
docker-compose run --rm aws check-ecs <CLUSTER_NAME> <TASK_ID>
```

This is an open source tool created by [AWS Containers](https://github.com/aws-containers/amazon-ecs-exec-checker) which checks your setup has all the appropirate permissions and settings to allow a connection.

## Connecting to an ECS container

Connect to an ECS container with:

```shell
docker-compose run --rm aws aws ecs execute-command \
    --cluster <CLUSTER_NAME> \
    --task <TASK_ID> \
    --container <CONTAINER_NAME> \
    --interactive \
    --command "/bin/bash"
```

## Prerequisites

Please make sure you've read and understood [Using Amazon ECS Exec to access your containers on AWS Fargate and Amazon EC2](https://aws.amazon.com/blogs/containers/new-using-amazon-ecs-exec-access-your-containers-fargate-ec2/).

### Execute Command Enabled

Checking that your service and tasks have execute command enabled. You can do this manually by running:
```shell
docker-compose run --rm aws aws ecs describe-tasks \
    --output json \
    --query "tasks[0].enableExecuteCommand" \
    --cluster <CLUSTER_NAME> \
    --tasks <TASK_ID>
```

If this value is `false` then you can update it with:

```shell
docker-compose run --rm aws aws ecs update-service \
    --cluster <CLUSTER_NAME> \
    --service <SERVICE_NAME> \
    --enable-execute-command \
    --force-new-deployment 
```
If deployments are controlled by code deploy don't specify the `--force-new-deployment` flag and re-deploy normally.



### SSM Message Permissions

In the article suggested above there's various permissions they "advise", but in a nutshell all you need is the SSM permissions. 
For the task execution role which can be achieved by creating a policy like below and attaching it to your role.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        }
    ]
}
```

I would suggest avoiding a wildcard for your resource and directly reference the resources you actually plan to use.

## Tools

This has https://github.com/aws-containers/amazon-ecs-exec-checker built in
