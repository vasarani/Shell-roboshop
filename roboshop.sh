#!/bin/bash

sg_id="sg-0f99207bb9a2cd68c"
ami_id="ami-0220d79f3f480ecf5"

for instance in $@
do
 instance_id=$(  aws ec2 run instances \
      --image-id $ami_id \
      --instance-type "t3.micro" \
      --security-group-ids $sg_id \
      --tag-specifications "ResourceType=instance, Tags=[{Key=Name, Value=$instance}]" \
      --query 'Instances[0].InstanceId' \
      --output text )
     if [ $instance == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservation[].Instances[].PublicIPAddress' \
            --output text
        )
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservation[].Instances[].PrivateIPAddress' \
            --output text
        )    
    fi    
    echo "IP Address: $IP"
done