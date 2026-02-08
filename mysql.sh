#!/bin/bash 

check_root



dnf install mysql-server -y  &>>$LOG_FILE
VALIDATE $? "Installing mysql"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabling mysql"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Starting mysql"

mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
VALIDATE $? "Setting up Root password to MySql server"

print_total_time

