#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

userid=$(id -u)
logs_folder="/var/log/shell-roboshop"
logs_file="$logs_folder/$0.logs"
script_dir=$PWD
mongodb_host=mongodb.rawsd.in

if [ $userid -ne 0 ]; then
 echo -e "$R Please run this script with the root user access $N" | tee -a $logs_file
 exit 1
fi 

mkdir -p $logs_folder

VALIDATE(){
    if [ $1 -ne 0 ]; then
       echo -e "$2... $R FAILURE $N" | tee -a $logs_file
    else
       echo -e "$2... $G SUCCESS $N" | tee -a $logs_file
    fi      
}


dnf module disable nodejs -y &>>$logs_file
VALIDATE $? "Disabling NodeJS Default version"

dnf module enable nodejs:20 -y &>>$logs_file
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$logs_file
VALIDATE $? "Install NodeJS"

id roboshop &>>$logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$logs_file
VALIDATE $? "Downloading user code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/user.zip &>>$logs_file
VALIDATE $? "Uzip user code"

npm install  &>>$logs_file
VALIDATE $? "Installing dependencies"

cp $script_dir/user.service /etc/systemd/system/user.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable user  &>>$logs_file
systemctl start user
VALIDATE $? "Starting and enabling user"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y

index=$(mongosh --host $mongodb_host --quiet  --eval 'db.getMongo().getDBNames().indexOf("user")')

if [ $index -le 0 ]; then
    mongosh --host $mongodb_host </app/db/master-data.js
    VALIDATE $? "Loading products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl restart user
VALIDATE $? "Restarting user"