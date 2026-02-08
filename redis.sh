#!/bin/bash 

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
USERID=$(id -u)


LOGS_FOLDER="/var/log/shell-script-logs"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" #/var/log/shell-script-logs/redis-sh.log
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

### Redis Installation ###
dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disabling Default Redis"
dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enabling Redis 7 version"
dnf install redis -y  &>>$LOG_FILE
VALIDATE $? "Installing Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>>$LOG_FILE
VALIDATE $? "Allowing Remote connections to Redis and making protected-mode no"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "Enabling Redis"
systemctl start redis &>>$LOG_FILE
VALIDATE $? "Starting Redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
