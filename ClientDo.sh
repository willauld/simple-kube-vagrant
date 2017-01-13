#!/bin/bash

if [ ! -z $1 ]; then

  sudo yum -y install mysql

  mysql -uroot -p -h$1 <<!
    show variables like '%version%';
!

else 

  echo "Please include the sql service ip as the first parameter"

fi
