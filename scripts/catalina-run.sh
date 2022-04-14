#!/bin/sh

#No context template, use a default
if [ -e "context.xml" ]; then
	cp context.xml context-output.xml
else
	echo "<Context></Context>" > context-output.xml
fi

if [ -e "server-orig.xml" ]; then
	cp -f server-orig.xml server-output.xml
fi

#LDAP Realm for context
if [ "$LDAP_URL" != "" -a -e "context-ldap-realm.xsl" ]; then	
	echo "Creating context ldap-realm for $LDAP_URL"
	xsltproc --param LDAP_URL "'$LDAP_URL'" --param LDAP_ALT_URL "'$LDAP_ALT_URL'" --param LDAP_BIND "'$LDAP_BIND'" --param LDAP_BIND_PASSWORD "'$LDAP_BIND_PASSWORD'" --param LDAP_USER_BASEDN "'$LDAP_USER_BASEDN'" --param LDAP_USER_SEARCH "'$LDAP_USER_SEARCH'" --param LDAP_USER_PASSWD_ATTR "'$LDAP_USER_PASSWD_ATTR'" --param LDAP_USER_PATTERN "'$LDAP_USER_PATTERN'"  --param LDAP_GROUP_BASEDN "'$LDAP_GROUP_BASEDN'" --param LDAP_GROUP_SEARCH "'$LDAP_GROUP_SEARCH'" --param LDAP_GROUP_ATTR "'$LDAP_GROUP_ATTR'" --param AD_COMPAT "'$AD_COMPAT'" --param COMMON_ROLE "'$COMMON_ROLE'" --param ALL_ROLES_MODE "'${ALL_ROLES_MODE:-strict}'" context-ldap-realm.xsl context-output.xml > context-temp.xml
	[ -s context-temp.xml ] && mv -f context-temp.xml context-output.xml
#or LDAP Realm for global
elif [ "$GLOBAL_LDAP_URL" != "" -a -e "server-ldap-realm.xsl" ]; then	
	echo "Creating ldap-realm for $GLOBAL_LDAP_URL"
	xsltproc --param LDAP_URL "'$GLOBAL_LDAP_URL'" --param LDAP_ALT_URL "'$LDAP_ALT_URL'" --param LDAP_BIND "'$LDAP_BIND'" --param LDAP_BIND_PASSWORD "'$LDAP_BIND_PASSWORD'" --param LDAP_USER_BASEDN "'$LDAP_USER_BASEDN'" --param LDAP_USER_SEARCH "'$LDAP_USER_SEARCH'" --param LDAP_USER_PASSWD_ATTR "'$LDAP_USER_PASSWD_ATTR'" --param LDAP_USER_PATTERN "'$LDAP_USER_PATTERN'"  --param LDAP_GROUP_BASEDN "'$LDAP_GROUP_BASEDN'" --param LDAP_GROUP_SEARCH "'$LDAP_GROUP_SEARCH'" --param LDAP_GROUP_ATTR "'$LDAP_GROUP_ATTR'" --param AD_COMPAT "'$AD_COMPAT'" --param COMMON_ROLE "'$COMMON_ROLE'" --param ALL_ROLES_MODE "'${ALL_ROLES_MODE:-strict}'" server-ldap-realm.xsl server-output.xml > server-temp.xml
	[ -s server-temp.xml ] && mv -f server-temp.xml server-output.xml
fi

#Context DB Source
if [ "$DB_SOURCENAME" != "" -a "$DB_CLASS" != "" -a "$DB_URL" != "" -a -e "context-dbsource.xsl" ]; then	
	xsltproc --param DB_SOURCENAME "'$DB_SOURCENAME'" --param db_class \"$DB_CLASS\" --param db_url \"$DB_URL\" --param db_username \"$DB_USERNAME\" --param db_password \"$DB_PASSWORD\" --param db_pool_max \"${DB_POOL_MAX:-50}\" --param db_pool_init \"${DB_POOL_INIT:-0}\" --param db_idle_max \"${DB_IDLE_MAX:-5}\" --param validation_query \"$DB_VALIDATION_QUERY\" context-dbsource.xsl context-output.xml > context-temp.xml
	[ -s context-temp.xml ] && mv -f context-temp.xml context-output.xml
	
	#DataSource Realm for context
	if [ "$REALM_USERTAB" != "" -a -e "context-db-realm.xsl" ]; then
		echo "Creating context db-realm for $DB_SOURCENAME"
		xsltproc --param DB_SOURCENAME "'$DB_SOURCENAME'" --param REALM_USERTAB "'$REALM_USERTAB'" --param REALM_ROLETAB "'$REALM_ROLETAB'" --param REALM_USERCOL "'${REALM_USERCOL:-username}'" --param REALM_CREDCOL "'${REALM_CREDCOL:-hashpassword}'" --param REALM_ROLECOL "'$REALM_ROLECOL'" --param ALL_ROLES_MODE "'${ALL_ROLES_MODE:-strict}'" --param LOCAL_DS "'true'" context-db-realm.xsl context-output.xml > context-temp.xml
		[ -s context-temp.xml ] && mv -f context-temp.xml context-output.xml
	fi

elif [ "$GLOBAL_DB_SOURCENAME" != "" -a "$DB_CLASS" != "" -a "$DB_URL" != "" -a -e "server-dbsource.xsl" ]; then
#Global DB Source
	xsltproc --param DB_SOURCENAME "'$GLOBAL_DB_SOURCENAME'" --param db_class \"$DB_CLASS\" --param db_url \"$DB_URL\" --param db_username \"$DB_USERNAME\" --param db_password \"$DB_PASSWORD\" --param db_pool_max \"${DB_POOL_MAX:-50}\" --param db_pool_init \"${DB_POOL_INIT:-0}\" --param db_idle_max \"${DB_IDLE_MAX:-5}\" --param validation_query \"$DB_VALIDATION_QUERY\" server-dbsource.xsl server-output.xml > server-temp.xml 
	[ -s server-temp.xml ] && cp -f server-temp.xml server-output.xml
	
	#Global DataSource Realm for context
	if [ "$REALM_USERTAB" != "" -a -e "context-db-realm.xsl" ]; then	
		echo "Creating db-realm for $DB_SOURCENAME"
		xsltproc --param DB_SOURCENAME "'$GLOBAL_DB_SOURCENAME'" --param REALM_USERTAB "'$REALM_USERTAB'" --param REALM_ROLETAB "'$REALM_ROLETAB'" --param REALM_USERCOL "'${REALM_USERCOL:-username}'" --param REALM_CREDCOL "'${REALM_CREDCOL:-hashpassword}'" --param REALM_ROLECOL "'$REALM_ROLECOL'" --param ALL_ROLES_MODE "'${ALL_ROLES_MODE:-strict}'" --param LOCAL_DS "'false'" context-db-realm.xsl context-output.xml > context-temp.xml
		[ -s context-temp.xml ] && mv -f context-temp.xml context-output.xml
	#or DataSource Realm for global
	elif [ "$REALM_USERTAB" != "" -a -e "server-db-realm.xsl" ]; then	
		echo "Creating ldap-realm for $GLOBAL_LDAP_URL"
		xsltproc --param DB_SOURCENAME "'$GLOBAL_DB_SOURCENAME'" --param REALM_USERTAB "'$REALM_USERTAB'" --param REALM_ROLETAB "'$REALM_ROLETAB'" --param REALM_USERCOL "'${REALM_USERCOL:-username}'" --param REALM_CREDCOL "'${REALM_CREDCOL:-hashpassword}'" --param REALM_ROLECOL "'$REALM_ROLECOL'" --param ALL_ROLES_MODE "'${ALL_ROLES_MODE:-strict}'" --param LOCAL_DS "'false'" server-db-realm.xsl server-output.xml > server-temp.xml 
		[ -s server-temp.xml ] && mv -f server-temp.xml server-output.xml
	fi
fi

#TCP Simple Cluster
if [ "$CLUSTER" = "DeltaManager" -o "$CLUSTER" = "BackupManager" ]; then
  if [ -e "server-cluster.xsl" ]; then
	echo "Creating Cluster of $CLUSTER"
	xsltproc --param CHANNEL_SEND_OPTIONS "'$CHANNEL_SEND_OPTIONS'" --param CLUSTER "'$CLUSTER'" --param MCAST_ADDRESS "'${MCAST_ADDRESS:-228.0.0.4}'" --param MCAST_PORT "'${MCAST_PORT:-45564}'" --param RECEIVE_PORT "'${RECEIVE_PORT:-5000}'" --param REPLICATION_FILTER "'$REPLICATION_FILTER'" server-cluster.xsl server-output.xml > server-temp.xml 
	[ -s server-temp.xml ] && mv -f server-temp.xml server-output.xml
  fi
fi

if [ -e "context-output.xml" ]; then
	mkdir -p conf/Catalina/localhost
	mv context-output.xml conf/Catalina/localhost/${DEPLOY_CONTEXT:-ROOT}.xml 
fi

if [ -e "server-output.xml" ]; then
	mv -f server-output.xml conf/server.xml 
fi

#exec bash
exec catalina.sh run
