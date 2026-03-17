#!/bin/bash

sg_id="sg-0f99207bb9a2cd68c"
ami_id="ami-0220d79f3f480ecf5"
zone_id="Z07217272DEU08NPF6AZQ"
domain_name="rawsd.in"

for instance in $@
do
    instance_id=$( aws ec2 run-instances \
    --image-id $ami_id \
    --instance-type "t3.micro" \
    --security-group-ids $sg_id \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
        )
        record_name="$domain_name" # daws88s.online
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
        record_name="$instance.$domain_name" # mongodb.daws88s.online
    fi

    echo "IP Address: $IP"
     
    aws route53 change-resource-record-sets \
    --hosted-zone-id $zone_id \
    --change-batch '
    {
        "Comment": "Updating record",
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$record_name'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
    }
    '

    echo "record updated for $instance"


done