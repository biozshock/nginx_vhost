NGINX_CONFIG='/etc/nginx/sites-available'
NGINX_SITES_ENABLED='/etc/nginx/sites-enabled'
WEB_DIR='/var/www'
IP='192.168.2.4'
SED=`which sed`
CURRENT_DIR=`dirname $0`

if [ -z $1 ]; then
	echo "No domain name given"
	exit 1
fi
DOMAIN=$1

# check the domain is roughly valid!
PATTERN="^([[:alnum:]]([[:alnum:]\-]{0,61}[[:alnum:]])?\.)+[[:alpha:]]{2,6}$"
if [[ "$DOMAIN" =~ $PATTERN ]]; then
	DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
	echo "Creating hosting for:" $DOMAIN
else
	echo "invalid domain name"
	exit 1 
fi

#Replace dots with underscores
SITE_DIR=`echo $DOMAIN | $SED 's/\./_/g'`

# Now we need to copy the virtual host template
CONFIG=$NGINX_CONFIG/$DOMAIN
sudo cp $CURRENT_DIR/virtual_host.template $CONFIG
sudo $SED -i "s/DOMAIN/$DOMAIN/g" $CONFIG
sudo $SED -i "s!ROOT!$WEB_DIR/$SITE_DIR!g" $CONFIG

# set up web root
sudo mkdir $WEB_DIR/$SITE_DIR
sudo chmod 600 $CONFIG

sudo sh -c "echo $IP $DOMAIN 'www.'$DOMAIN'\n\n' >> /etc/hosts"

# create symlink to enable site
#sudo ln -s $CONFIG $NGINX_SITES_ENABLED/$DOMAIN
sudo nensite $DOMAIN

# reload Nginx to pull in new config
sudo /etc/init.d/nginx reload

# put the template index.html file into the new domains web dir
sudo cp $CURRENT_DIR/index.php.template $WEB_DIR/$SITE_DIR/index.php
sudo $SED -i "s/SITE/$DOMAIN/g" $WEB_DIR/$SITE_DIR/index.php
sudo chown -R nginx:nginx $WEB_DIR/$SITE_DIR

echo "Site Created for $DOMAIN"
