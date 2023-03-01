#! /bin/sh
#Tak-1 Update packages
sudo apt update -y

#Start Variables
Myname='GondhiRakeshReddy'
S3_bucket='upgrad.gondhirakeshreddy'
timestamp=$(date '+%d%m%Y-%H%M%S')
inv_file="/var/www/html/inventory.html"
cron_file="/etc/cron.d/automation"

#2 Apache2
#Check for Apache2 is installed or not else install it.
if [ $(dpkg --list | grep apache2 | cut -d ' ' -f 3 | head -1) == 'apache2' ]
then
	echo "Apache is installed and is checking for the state"
	if [ $(systemctl status apache2 | grep disabled | cut -d ';' -f 2) == ' disabled' ]
		then
			systemctl enable apache2
			echo "Apache2 enabled now"
			systemctl start apache2
#If Apache 2 is installed then check whether it is started or not;	
		else
			if [ $(systemctl status apache2 | grep active | cut -d ':' -f 2 | cut -d ' ' -f 2) == 'active' ]
			then
				echo "Already Apache2 is running"
			else
				systemctl start apache2
				echo "Apache2 service started"
			fi
	fi					
else
	echo "Apache2 not installed. Please wait for its installation"
	printf 'Y\n' | apt-get install apache2
	echo "Apache2 service was installed"
	fi
# 3 - Back up the Log files and upload to S3 bucket
# Make the local backup /tmp/
tar -zvcf /tmp/${Myname}-httpd-logs-${timestamp}.tar /var/log/apache2/*.log
# Uploading to S3 bucket
#Optional - check for AWS CLI and install if not present / Upload the tar file of Logs to S3 bucket.
if [ $(dpkg --list | grep awscli | cut -d ' ' -f 3 | head -1) == 'awscli' ]
	then
		aws s3 \
		cp /tmp/${Myname}-httpd-logs-${timestamp}.tar \
		s3://${S3_bucket}/${Myname}-httpd-logs-${timestamp}.tar
	else
	echo "AWS CLI is not present, installing now..."	
	apt install awscli
	aws s3 \
	cp /tmp/${Myname}-httpd-logs-${timestamp}.tar \
	s3://${S3_bucket}/${Myname}-httpd-logs-${timestamp}.tar
fi
if [ -e $inv_file ]
then
    echo "Adding archive details to inventory.html file..."
    fsize=$(ls -lh /tmp/$filename | awk '{ print $5}')
    printf "<p>httpd-logs &emsp;&emsp;&emsp;&emsp; $timestamp &emsp;&emsp;&emsp;&emsp; tar &emsp;&emsp;&emsp;&emsp; $fsize \n" >> $inv_file
    echo "Details are added to inventory.html file."
else
    echo "Inventory.html file does not exists. Creating the file..."
    printf "<p style='padding: 10px; border: 2px solid #ccc; background-color:#f5f5f5;'>cat /var/www/html/inventory.html</p> \n <h3>Log Type &emsp;&emsp;&emsp; Date Created &emsp;&emsp;&emsp; Type &emsp;&emsp;&emsp; Size</h3> \n" > $inv_file
    fsize=$(ls -lh /tmp/$filename | awk '{ print $5}')
    printf "<p>httpd-logs &emsp;&emsp;&emsp;&emsp; $timestamp &emsp;&emsp;&emsp;&emsp; tar &emsp;&emsp;&emsp;&emsp; $fsize \n" >> $inv_file
    echo "Details are added to inventory.html file."
fi

# Check if Cron Job exists or not. If not create Cron Job to execute the script everyday:

if [ ! -f $cron_file ]
then
    echo "Creating a Cron Job..."
    printf "0 0 * * * root /root/Automation_Project/automation.sh\n" > $cron_file 
fi
