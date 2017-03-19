#!/bin/bash
#Bring Drupal On-Line
(echo -n "(CiviCRMUpdate) Drupal OnLine: "; date) >> /tmp/cdLog.txt
cd /var/www/html/sites/default
/home/ec2-user/.composer/vendor/drush/drush/drush vset site_offline 0
