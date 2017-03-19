#!/bin/bash
#Validate Drupal has security updates
(echo -n "(CiviCRMUpdate) Validate CiviCRM Upgrade: "; date) >>/tmp/cdLog.txt
cd /var/www/html/sites/default
/home/ec2-user/.composer/vendor/drush/drush/drush pml | grep '(civicrm)' | grep Enabled
if [ "$?" != "0" ]
then
   echo -n "CiviValidate FAILED!!!" >>/tmp/cdLog.txt
   exit 1
fi
echo -n "CiviValidate SUCCEEDED!!!" >>/tmp/cdLog.txt
exit 0