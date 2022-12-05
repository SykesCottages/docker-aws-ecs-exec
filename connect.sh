#!/usr/bin/env bash

PROGNAME=$0

usage() {
  echo "Usage: $PROGNAME [-v] [-p profile] [-r region]"
  exit 1
}

PROFILE=""
REGION=""
VERBOSE=""

while getopts r:p:v o; do
  case $o in
    r) REGION="--region $OPTARG";;
    p) PROFILE="--profile $OPTARG";;
    v) VERBOSE="--debug";;
    *) usage
  esac
done

RESPONSE=-1

function printOptions()
{
  BACKTITLE=$1
  TITLE=$2
  MENU=$3
  HEIGHT=$4
  WIDTH=$5
  CHOICE_HEIGHT=$6
  ARRAY="${*:7}"

  INDEX=0
  COUNTER=1
  for OPTION in ${ARRAY[@]}
  do
      OPTIONS[INDEX++]=$COUNTER
      OPTIONS[INDEX++]=$OPTION
      LOOKUP[$COUNTER]=$OPTION
      COUNTER=$((COUNTER+1))
  done

  CHOICE=$(dialog --clear \
                  --backtitle "$BACKTITLE" \
                  --title "$TITLE" \
                  --menu "$MENU" \
                  $HEIGHT \
                  $WIDTH \
                  $CHOICE_HEIGHT \
                  "${OPTIONS[@]}" \
                  2>&1 >/dev/tty)

  clear

  RESPONSE=${LOOKUP[$CHOICE]}

  if [ -z "$RESPONSE" ]; then
    exit 0
  fi

  unset OPTIONS
  unset LOOKUP
}

BACKTITLE="ECS Fargate SSH Connect"
HEIGHT=28
WIDTH=60
CHOICE_HEIGHT=20

aws $PROFILE $REGION $VERBOSE sts get-caller-identity > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "AWS Credential failure - check the key or the profile"
    exit 1;
fi

CLUSTERS=$(aws $PROFILE $REGION $VERBOSE ecs list-clusters | jq -r '.clusterArns[] |= sub("arn:aws:ecs:[a-z]{2}-[a-z]{4}-[0-9]+:[0-9]+:[a-z]+/"; "") | .clusterArns[]'|sort)

if [ -z ${CLUSTERS[@]} ]; then
    echo "AWS Permission failure - check the permissions and that the region is specified"
    exit 2;
fi

printOptions "$BACKTITLE" "1. Select your ECS Cluster" "ECS Clusters" "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" "${CLUSTERS[@]}"

CLUSTER=$RESPONSE

SERVICES=$(aws $PROFILE $REGION $VERBOSE ecs list-services --cluster $CLUSTER|jq -r ".serviceArns[] |= sub(\"arn:aws:ecs:[a-z]{2}-[a-z]{4}-[0-9]+:[0-9]+:[a-z]+/${CLUSTER}/\"; \"\") | .serviceArns[]" | sort)

printOptions "$BACKTITLE" "2. Select your ECS Service" "ECS Services" "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" "${SERVICES[@]}"

SERVICE=$RESPONSE

TASKS=$(aws $PROFILE $REGION $VERBOSE ecs list-tasks --cluster $CLUSTER --service-name $SERVICE|jq -r ".taskArns[] |= sub(\"arn:aws:ecs:[a-z]{2}-[a-z]{4}-[0-9]+:[0-9]+:[a-z]+/${CLUSTER}/\"; \"\") | .taskArns[]" | sort)

printOptions "$BACKTITLE" "3. Select your ECS Task" "ECS Tasks" "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" "${TASKS[@]}"

TASK=$RESPONSE

COMMANDS=(
  "Check"
  "Connect"
)

printOptions "$BACKTITLE" "4. Select your operation" "Operations" "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" "${COMMANDS[@]}"

COMMAND=$RESPONSE

if [ "$COMMAND" = "Check" ]; then
  check-ecs $CLUSTER $TASK
else
  CONTAINERS=$(aws $PROFILE $REGION $VERBOSE ecs describe-tasks --cluster $CLUSTER --tasks $TASK | jq -r ".tasks[].containers[].name" | sort)

  printOptions "$BACKTITLE" "5. Select your Container" "ECS Containers" "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" "${CONTAINERS[@]}"

  CONTAINER=$RESPONSE

  aws $PROFILE $REGION $VERBOSE ecs execute-command \
      --cluster $CLUSTER \
      --task $TASK \
      --container $CONTAINER \
      --interactive \
      --command "/bin/bash"
fi
