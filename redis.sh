#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

userid=$(id -u)
logs_folder="/var/log/shell-roboshop"
logs_file="$logs_folder/$0.logs"

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

dnf module disable redis -y
dnf module enable redis -y
VALIDATE $? "Enabled redis"

dnf install redis -y &>>$logs_file
VALIDATE $? "Installed Redis"

sed -i 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "allowing the remote connections"

systemctl enable redis &>>$logs_file
systemctl start redis
VALIDATE $? "Enabled and started redis"
