#!/bin/bash 

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
USERID=$(id -u)


LOGS_FOLDER="/var/log/shell-script-logs"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" #/var/log/shell-script-logs/18-logs.log
MONGODB_HOST=mongodb.sivadevops.space
START_TIME=$(date +%s)


mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then 
   echo "Error: Please run this script with root previlages" 
   exit 1 # failure is other than 0
fi 

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then 
      echo -e "$2... $R failed $N " | tee -a $LOG_FILE
      exit 1 # failure is other than 0
    else 
     echo -e "$2...$G success $N" | tee -a $LOG_FILE
    fi 

}

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "Copying rabbitmq repo"

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Installing rabbitmq"

systemctl enable rabbitmq-server  &>>$LOG_FILE
VALIDATE $? "Enabling rabbitmq"

systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Starting rabbitmq"

rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
VALIDATE $? "Setting up permissions"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"

