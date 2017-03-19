#!/bin/bash
#
# Copyright (C) 2010 Kasper Souren 
# Licensed to CiviCRM under the GNU General Public License v2 or later
# Modified and updated to support current drush syntax by btm on 07-02-2017
#
#
 
# based on
# http://wiki.civicrm.org/confluence/display/CRMDOC/Upgrade+Drupal+Sites+to+3.1
# and (btm 07-02-2017): https://wiki.civicrm.org/confluence/display/CRMDOC/Upgrading+CiviCRM+for+Drupal+7#UpgradingCiviCRMforDrupal7-1.DownloadthemostrecentCiviCRMPackage 

##
## Change this to the location of your backup directory.  Make sure
## it's not inside your Drupal modules directories, and possibly
## outside of your web server path.
##
(echo -n "(CiviCRMUpdate) Update: "; date) >> /tmp/cdLog.txt


##  
## Change this to the location of your drush.
##
DRUSH=drush

##
##
##

DRUPALROOT=/var/www/html
CIVICRMDIR=$DRUPALROOT/sites/all/modules/civicrm
CIVIPACKAGENAME=/tmp/CiviCRM.Update.CD-$(date +%Y%m%d-%H%m%S).tgz
BACKUPDIR=~/backups/civicrm-$(date +%Y%m%d-%H%m%S)
mkdir -p $BACKUPDIR

if [ -z $DRUSH ]; then
    DRUSH=drush
fi

echo "1. Starting CiviCRM Upgrade Process (Offline Drupal)..."
cd $DRUPALROOT
$DRUSH vset site_offline 1
sleep 2

echo "2. Disable CiviCRM modules"
EXT_MODULES=$($DRUSH pm-list --status=enabled --pipe | grep civicrm_)
if [ "$EXT_MODULES" != "" ]; then
    echo "2a. Disabling the following modules: $EXT_MODULES"
    $DRUSH --yes disable $EXT_MODULES
else
    echo "2a. No modules found that required to be disabled"
fi

echo "3. Get CiviCRM UpDate Package:  civicrm-4.7.16-drupal"
wget -q -O $CIVIPACKAGENAME https://sourceforge.net/projects/civicrm/files/civicrm-stable/4.7.16/civicrm-4.7.16-drupal.tar.gz/download

echo "4. Backup (move) CiviCRM Modules to $BACKUPDIR"
mv $CIVICRMDIR $BACKUPDIR

echo "5. Install CiviCRM tarball files"
tar -xf $CIVIPACKAGENAME --directory `dirname $CIVICRMDIR`
find . -type d -exec chmod 0775 {} \;
find . -type f -exec chmod 0764 {} \;
chown -R ec2-user:apache $CIVICRMDIR
echo "6. Run upgrade script (codbase)"
$DRUSH --yes civicrm-upgrade --backup-dir=$BACKUPDIR --tarfile=$CIVIPACKAGENAME

echo "7. Set file permissions/ownership (may not be necessary, but just doit)"
find . -type d -exec chmod 0775 {} \;
find . -type f -exec chmod 0764 {} \;
chown -R ec2-user:apache $CIVICRMDIR

echo "8. Run upgrade script (db)"
$DRUSH --yes civicrm-upgrade-db

echo "9. Re-enable CiviCRM modules"
if [ "$EXT_MODULES" != "" ]; then
    echo "9a. Enabling the following modules: $EXT_MODULES"
    $DRUSH --yes enable $EXT_MODULES
else
   echo "9a. No CiviCRM Modules to be enabled."
fi

echo "10. Clear ALL Caches"
rm -rf                /var/www/html/sites/default/files/civicrm/templates_c/*
mkdir -m 0775         /var/www/html/sites/default/files/civicrm/templates_c/en_US
chown ec2-user:apache /var/www/html/sites/default/files/civicrm/templates_c/en_US
chmod 755             /var/www/html/sites/default
chmod 744             /var/www/html/sites/default/settings.php /var/www/html/sites/default/civicrm.settings.php
$DRUSH cache-clear all
if [ -e /usr/sbin/SetDrupalFilePerm.sh ]; then
   echo "11. Setting Drupal/CiviCRM File Permissions."
   SetDrupalFilePerm.sh
else
   echo "11. Drupal/CiviCRM File Permissions net set to most restrictive settings"
fi

echo "12. Enable CiviCRM -- Completed!"
$DRUSH --yes pm-enable civicrm

