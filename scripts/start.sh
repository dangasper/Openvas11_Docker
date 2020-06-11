#!/usr/bin/env bash

USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}

HTTPS=${HTTPS:-true}

if [ ! -f "/.armed" ]; then
	echo "Running first start configuration..."
	echo "Starting setup..."
	ldconfig

	if [ ! -d "/run/redis" ]; then
		mkdir /run/redis
	fi
	if  [ -S /run/redis/redis.sock ]; then
   	     rm /run/redis/redis.sock
	fi
	redis-server /etc/redis/redis.conf

	echo "Wait for redis socket to be created..."
	while  [ ! -S /run/redis/redis.sock ]; do
 	       sleep 1
	done

	echo "Testing redis status..."
	X="$(redis-cli -s /run/redis/redis.sock ping)"
	while  [ "${X}" != "PONG" ]; do
    	    echo "Redis not yet ready..."
        	sleep 1
        	X="$(redis-cli -s /run/redis/redis.sock ping)"
	done
	echo "Redis ready."

	if  [ ! -d /openvas ]; then
		echo "Creating Openvas folder..."
	        mkdir /openvas
	fi

	echo "Configure PostgreSQL..."
	sed -i 's|^#checkpoint_timeout = 5min|checkpoint_timeout = 1h|;s|^#checkpoint_warning = 30s|checkpoint_warning = 0|' /etc/postgresql/10/main/postgresql.conf
	{ echo; echo "host all all 127.0.0.1/32 trust"; } >> "/etc/postgresql/10/main/pg_hba.conf"

	if  [ ! -d /openvas/database ]; then
		echo "Creating Database folder..."
		mv /var/lib/postgresql/10/main /openvas/database
		ln -s /openvas/database /var/lib/postgresql/10/main
		chown postgres:postgres -R /var/lib/postgresql/10/main
		chown postgres:postgres -R /openvas/database
	fi

	if [ -d /var/lib/postgresql/10/main ]; then
		echo "Fixing Database folder..."
		rm -rf /var/lib/postgresql/10/main
		ln -s /openvas/database /var/lib/postgresql/10/main
		chown postgres:postgres -R /var/lib/postgresql/10/main
		chown postgres:postgres -R /openvas/database
	fi

	echo "Starting PostgreSQL..."
	/usr/bin/pg_ctlcluster --skip-systemctl-redirect 10 main start

	echo "[PostgreSQL] Wait until postgresql is ready..."
	sleep 1
	until grep "database system is ready to accept connections" /var/log/postgresql/postgresql-10-main.log
	do
		echo "[PostgreSQL] Waiting for PostgreSQL to start..."
		sleep 2
	done

	if [ ! -f "/.userarmed" ]; then
		echo "Running first start configuration..."

		echo "Creating Openvas NVT sync user..."
		useradd --home-dir /usr/local/share/openvas openvas-sync
		chown openvas-sync:openvas-sync -R /usr/local/share/openvas
		chown openvas-sync:openvas-sync -R /usr/local/var/lib/openvas

		echo "Creating Greenbone Vulnerability system user..."
		useradd --home-dir /usr/local/share/gvm gvm
		chown gvm:gvm -R /usr/local/share/gvm
		mkdir -p /usr/local/var/lib/gvm/cert-data
		chown gvm:gvm -R /usr/local/var/lib/gvm
		chmod 770 -R /usr/local/var/lib/gvm
		chown gvm:gvm -R /usr/local/var/log/gvm
		chown gvm:gvm -R /usr/local/var/run

		adduser openvas-sync gvm
		adduser gvm openvas-sync
		touch /.userarmed
	fi

	echo "Configuring database"
	if [ ! -f "/openvas/database/.dbarmed" ]; then
		echo "Creating Greenbone Vulnerability Manager database"
		su -c "createuser -DRS gvm" postgres
		su -c "createdb -O gvm gvmd" postgres
		su -c "psql --dbname=gvmd --command='create role dba with superuser noinherit;'" postgres
		su -c "psql --dbname=gvmd --command='grant dba to gvm;'" postgres
		su -c "psql --dbname=gvmd --command='create extension \"uuid-ossp\";'" postgres
		su -c "psql --dbname=gvmd --command='create extension \"pgcrypto\";'" postgres
		touch /openvas/database/.dbarmed
	fi

	if  [ ! -d /openvas/gvmd ]; then
		echo "Creating gvmd folder..."
		mkdir /openvas/gvmd
		chown gvm:gvm -R /openvas/gvmd
	fi

	if  [ ! -h /usr/local/var/lib/gvm/gvmd ]; then
		echo "Fixing gvmd folder..."
		rm -rf /usr/local/var/lib/gvm/gvmd
		ln -s /openvas/gvmd /usr/local/var/lib/gvm/gvmd
	fi

	if  [ ! -d /openvas/certs ] && [ $HTTPS == "true" ]; then
		echo "Creating certs folder..."
		mkdir -p /openvas/certs/CA
		mkdir -p /openvas/certs/private
	
		echo "Generating certs..."
		gvm-manage-certs -f -a -q
	
		cp /usr/local/var/lib/gvm/CA/* /openvas/certs/CA/
	
		cp -r /usr/local/var/lib/gvm/private/* /openvas/certs/private/
	
		chown gvm:gvm -R /openvas/certs
	fi

	if [ ! -h /usr/local/var/lib/gvm/CA ] && [ $HTTPS == "true" ]; then
		echo "Fixing certs CA folder..."
		rm -rf /usr/local/var/lib/gvm/CA
		ln -s /openvas/certs/CA /usr/local/var/lib/gvm/CA
		chown gvm:gvm -R /openvas/certs
		chown gvm:gvm -R /usr/local/var/lib/gvm/CA
	fi

	if [ ! -h /usr/local/var/lib/gvm/private ] && [ $HTTPS == "true" ]; then
		echo "Fixing certs private folder..."
		rm -rf /usr/local/var/lib/gvm/private
		ln -s /openvas/certs/private /usr/local/var/lib/gvm/private
		chown gvm:gvm -R /openvas/certs
		chown gvm:gvm -R /usr/local/var/lib/gvm/private
	fi

	if  [ ! -d /openvas/plugins ]; then
		echo "Creating gvmd folder..."
		mkdir /openvas/plugins
	fi

	if [ ! -h /usr/local/var/lib/openvas/plugins ]; then
		echo "Fixing NVT Plugins folder..."
		rm -rf /usr/local/var/lib/openvas/plugins
		ln -s /openvas/plugins /usr/local/var/lib/openvas/plugins
		chown openvas-sync:openvas-sync -R /openvas/plugins
		chown openvas-sync:openvas-sync -R /usr/local/var/lib/openvas/plugins
	fi

	if  [ ! -d /openvas/cert-data ]; then
		echo "Creating CERT Feed folder..."
		mkdir /openvas/cert-data
	fi

	if [ ! -h /usr/local/var/lib/gvm/cert-data ]; then
		echo "Fixing CERT Feed folder..."
		rm -rf /usr/local/var/lib/gvm/cert-data
		ln -s /openvas/cert-data /usr/local/var/lib/gvm/cert-data
		chown openvas-sync:openvas-sync -R /openvas/cert-data
		chown openvas-sync:openvas-sync -R /usr/local/var/lib/gvm/cert-data
	fi

	if  [ ! -d /openvas/scap-data ]; then
		echo "Creating SCAP Feed folder..."
		mkdir /openvas/scap-data
	fi

	if [ ! -h /usr/local/var/lib/gvm/scap-data ]; then
		echo "Fixing SCAP Feed folder..."
		rm -rf /usr/local/var/lib/gvm/scap-data
		ln -s /openvas/scap-data /usr/local/var/lib/gvm/scap-data
		chown openvas-sync:openvas-sync -R /openvas/scap-data
		chown openvas-sync:openvas-sync -R /usr/local/var/lib/gvm/scap-data
	fi

	echo "Updating NVTs..."
	su -c "rsync --compress-level=9 --links --times --omit-dir-times --recursive --partial --quiet rsync://feed.community.greenbone.net:/nvt-feed /usr/local/var/lib/openvas/plugins" openvas-sync
	sleep 5

	echo "Updating CERT data..."
	su -c "/cert-data-sync.sh" openvas-sync
	sleep 5

	echo "Updating SCAP data..."
	su -c "/scap-data-sync.sh" openvas-sync

	if [ -f /var/run/ospd.pid ]; then
  		rm /var/run/ospd.pid
	fi

	if [ -S /tmp/ospd.sock ]; then
		rm /tmp/ospd.sock
	fi

	if [ ! -d /var/run/ospd ]; then
		mkdir /var/run/ospd
	fi

	echo "Starting Open Scanner Protocol daemon for OpenVAS..."
	ospd-openvas --log-file /usr/local/var/log/gvm/ospd-openvas.log --unix-socket /tmp/ospd.sock --log-level INFO

	while  [ ! -S /tmp/ospd.sock ]; do
		sleep 1
	done

	chmod 666 /tmp/ospd.sock

	echo "Starting Greenbone Vulnerability Manager..."
	su -c "gvmd --listen=0.0.0.0 --port=9390 --max-ips-per-target=65536 --osp-vt-update=/tmp/ospd.sock" gvm

	until su -c "gvmd --get-users" gvm; do
		sleep 1
	done

	if  [ ! -f "/openvas/.created_gvm_user" ]; then
		echo "Creating Greenbone Vulnerability Manager admin user"
		su -c "gvmd --create-user=${USERNAME} --password=${PASSWORD}" gvm
	
		touch /openvas/.created_gvm_user
	fi
	echo "Updating openvas NVT database..."
	openvas -u
	
	echo "Rebuilding GVM database..."
	su -c "gvmd --rebuild"

	echo "Finished setup..."
	touch /.armed
fi

if  [ ! $(pgrep redis-server) ]; then
	if  [ -S /run/redis/redis.sock ]; then
    	    rm /run/redis/redis.sock
	fi
	redis-server /etc/redis/redis.conf

	echo "Wait for redis socket to be created..."
	while  [ ! -S /run/redis/redis.sock ]; do
	        sleep 1
	done

	echo "Testing redis status..."
	X="$(redis-cli -s /run/redis/redis.sock ping)"
	while  [ "${X}" != "PONG" ]; do
	        echo "Redis not yet ready..."
	        sleep 1
 	       X="$(redis-cli -s /run/redis/redis.sock ping)"
	done
	echo "Redis ready."
else
	echo "Redis already started...skipping"
fi

if  [ ! $(pgrep redis-server) ]; then
	echo "Starting PostgreSQL..."
	/usr/bin/pg_ctlcluster --skip-systemctl-redirect 10 main start

	echo "[PostgreSQL] Wait until postgresql is ready..."
	sleep 1
	until grep "database system is ready to accept connections" /var/log/postgresql/postgresql-10-main.log
	do
		echo "[PostgreSQL] Waiting for PostgreSQL to start..."
		sleep 2
	done
	echo "PostgreSQL ready."
else
	echo "PostgreSQL already started...skipping"
fi

if  [ ! $(pgrep ospd) ]; then
	if [ -f /var/run/ospd.pid ]; then
  	rm /var/run/ospd.pid
	fi

	if [ -S /tmp/ospd.sock ]; then
  	rm /tmp/ospd.sock
	fi

	if [ ! -d /var/run/ospd ]; then
  	mkdir /var/run/ospd
	fi

	echo "Starting Open Scanner Protocol daemon for OpenVAS..."
	ospd-openvas --log-file /usr/local/var/log/gvm/ospd-openvas.log --unix-socket /tmp/ospd.sock --log-level INFO

	while  [ ! -S /tmp/ospd.sock ]; do
		sleep 1
	done

	chmod 666 /tmp/ospd.sock
else
	echo "Open Scanner Protocol daemon already started...skipping"
fi

if  [ ! $(pgrep gvmd) ]; then
	echo "Starting Greenbone Vulnerability Manager..."
	su -c "gvmd --listen=0.0.0.0 --port=9390 --max-ips-per-target=65536 --osp-vt-update=/tmp/ospd.sock" gvm
else
	echo "GVMD already started...skipping"
fi

if  [ ! $(pgrep gsad) ]; then
	echo "Starting Greenbone Security Assistant..."
	if [ $HTTPS == "true" ]; then
	su -c "gsad --verbose --gnutls-priorities=SECURE128:-AES-128-CBC:-CAMELLIA-128-CBC:-VERS-SSL3.0:-VERS-TLS1.0 --no-redirect --mlisten=127.0.0.1 --mport=9390 --port=9392" gvm
	else
		su -c "gsad --verbose --http-only --no-redirect --mlisten=127.0.0.1 --mport=9390 --port=9392" gvm
	fi
else
	echo "GSAD already started...skipping"
fi

echo "++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ Your GVM 11 container is now ready to use! +"
echo "++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo "++++++++++++++++"
echo "+ Tailing logs +"
echo "++++++++++++++++"
tail -F /usr/local/var/log/gvm/*
