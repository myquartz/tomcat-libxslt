#!/bin/sh

echo catalina-run.sh starting

if [ -e "webapps/$DEPLOY_CONTEXT.war" ]; then
	echo Extract context.xml from webapps/$DEPLOY_CONTEXT.war
	jar -xf webapps/$DEPLOY_CONTEXT.war META-INF/context.xml
elif [ -e "webapps/$DEPLOY_CONTEXT/META-INF/context.xml" ]; then
	echo copy context.xml from webapps/$DEPLOY_CONTEXT
	cp -f "webapps/$DEPLOY_CONTEXT/META-INF/context.xml" context.xml
elif [ -e "webapps/ROOT.war" ]; then
	echo Extract context.xml from webapps/ROOT.war
	jar -xf webapps/ROOT.war META-INF/context.xml
	DEPLOY_CONTEXT=ROOT
elif [ -e "webapps/ROOT/META-INF/context.xml" ]; then
	echo Extract context.xml from webapps/ROOT.war
	cp -f "webapps/ROOT/META-INF/context.xml" context.xml
	DEPLOY_CONTEXT=ROOT
fi

if [ -e "META-INF/context.xml" ]; then
	cp META-INF/context.xml context-output.xml
elif [ -e "context.xml" ]; then
#No context template, use a default
	cp context.xml context-output.xml
else
	echo Empty context-output.xml
	echo "<Context></Context>" > context-output.xml
fi

if [ -e "server-orig.xml" ]; then
	cp -f server-orig.xml server-output.xml
fi

#LDAP Realm for context
if [ "$LDAP_URL" != "" -a -e "context-ldap-realm.xsl" ]; then	
  if [ "$LDAP_BIND_PASSWORD" = "" -a "$LDAP_BIND_PASSWORD_FILE" != "" ]; then
    echo "Reading LDAP Bind password from $LDAP_BIND_PASSWORD_FILE"
    LDAP_BIND_PASSWORD=`cat "$LDAP_BIND_PASSWORD_FILE"`
  fi
	echo "Creating context ldap-realm for $LDAP_URL"
	xsltproc --param LDAP_URL "'$LDAP_URL'" --param LDAP_ALT_URL "'$LDAP_ALT_URL'" --param LDAP_BIND "'$LDAP_BIND'" --param LDAP_BIND_PASSWORD "'$LDAP_BIND_PASSWORD'" --param LDAP_USER_BASEDN "'$LDAP_USER_BASEDN'" --param LDAP_USER_SEARCH "'$LDAP_USER_SEARCH'" --param LDAP_USER_PASSWD_ATTR "'$LDAP_USER_PASSWD_ATTR'" --param LDAP_USER_PATTERN "'$LDAP_USER_PATTERN'"  --param LDAP_GROUP_BASEDN "'$LDAP_GROUP_BASEDN'" --param LDAP_GROUP_SEARCH "'$LDAP_GROUP_SEARCH'" --param LDAP_GROUP_ATTR "'$LDAP_GROUP_ATTR'" --param AD_COMPAT "'$AD_COMPAT'" --param COMMON_ROLE "'$COMMON_ROLE'" --param ALL_ROLES_MODE "'${ALL_ROLES_MODE:-strict}'" --param LDAP_SEARCHASUSER "'$LDAP_SEARCHASUSER'" --param LDAP_USER_SUBTREE "'$LDAP_USER_SUBTREE'" --param LDAP_GROUP_SUBTREE "'$LDAP_GROUP_SUBTREE'" context-ldap-realm.xsl context-output.xml > context-temp.xml
	[ -s context-temp.xml ] && mv -f context-temp.xml context-output.xml
#or LDAP Realm for global
elif [ "$GLOBAL_LDAP_URL" != "" -a -e "server-ldap-realm.xsl" ]; then	
	echo "Creating ldap-realm for $GLOBAL_LDAP_URL"
	xsltproc --param LDAP_URL "'$GLOBAL_LDAP_URL'" --param LDAP_ALT_URL "'$LDAP_ALT_URL'" --param LDAP_BIND "'$LDAP_BIND'" --param LDAP_BIND_PASSWORD "'$LDAP_BIND_PASSWORD'" --param LDAP_USER_BASEDN "'$LDAP_USER_BASEDN'" --param LDAP_USER_SEARCH "'$LDAP_USER_SEARCH'" --param LDAP_USER_PASSWD_ATTR "'$LDAP_USER_PASSWD_ATTR'" --param LDAP_USER_PATTERN "'$LDAP_USER_PATTERN'"  --param LDAP_GROUP_BASEDN "'$LDAP_GROUP_BASEDN'" --param LDAP_GROUP_SEARCH "'$LDAP_GROUP_SEARCH'" --param LDAP_GROUP_ATTR "'$LDAP_GROUP_ATTR'" --param AD_COMPAT "'$AD_COMPAT'" --param COMMON_ROLE "'$COMMON_ROLE'" --param ALL_ROLES_MODE "'${ALL_ROLES_MODE:-strict}'"  --param LDAP_SEARCHASUSER "'$LDAP_SEARCHASUSER'" --param LDAP_USER_SUBTREE "'$LDAP_USER_SUBTREE'" --param LDAP_GROUP_SUBTREE "'$LDAP_GROUP_SUBTREE'" server-ldap-realm.xsl server-output.xml > server-temp.xml
	[ -s server-temp.xml ] && mv -f server-temp.xml server-output.xml
fi

#Context DB Source
if [ "$DB_SOURCENAME" != "" -a "$DB_CLASS" != "" -a "$DB_URL" != "" -a -e "context-dbsource.xsl" ]; then	
  if [ "$DB_PASSWORD" = "" -a "$DB_PASSWORD_FILE" != "" ]; then
    echo "Reading database password from $DB_PASSWORD_FILE"
    DB_PASSWORD=`cat "$DB_PASSWORD_FILE"`
  fi
	echo "Merging context DB Resource for $DB_SOURCENAME"
	xsltproc --param DB_SOURCENAME "'$DB_SOURCENAME'" --param db_class \"$DB_CLASS\" --param db_url \"$DB_URL\" --param db_username \"$DB_USERNAME\" --param db_password \"$DB_PASSWORD\" --param db_pool_max \"${DB_POOL_MAX:-50}\" --param db_pool_init \"${DB_POOL_INIT:-0}\" --param db_idle_max \"${DB_IDLE_MAX:-5}\" --param validation_query \"$DB_VALIDATION_QUERY\" context-dbsource.xsl context-output.xml > context-temp.xml
	[ -s context-temp.xml ] && mv -f context-temp.xml context-output.xml
	
	#DataSource Realm for context
	if [ "$REALM_USERTAB" != "" -a -e "context-db-realm.xsl" ]; then
		echo "Creating context db-realm for $DB_SOURCENAME"
		xsltproc --param DB_SOURCENAME "'$DB_SOURCENAME'" --param REALM_USERTAB "'$REALM_USERTAB'" --param REALM_ROLETAB "'$REALM_ROLETAB'" --param REALM_USERCOL "'${REALM_USERCOL:-username}'" --param REALM_CREDCOL "'${REALM_CREDCOL:-hashpassword}'" --param REALM_ROLECOL "'$REALM_ROLECOL'" --param ALL_ROLES_MODE "'${ALL_ROLES_MODE:-strict}'" --param LOCAL_DS "'true'" --param REALM_INTERATIONS "'$REALM_INTERATIONS'" --param REALM_ALGORITHM "'$REALM_ALGORITHM'" --param REALM_SALT_LENGTH "'$REALM_SALT_LENGTH'" --param REALM_ENCODING "'$REALM_ENCODING'" context-db-realm.xsl context-output.xml > context-temp.xml
		[ -s context-temp.xml ] && mv -f context-temp.xml context-output.xml
	fi

elif [ "$GLOBAL_DB_SOURCENAME" != "" -a "$DB_CLASS" != "" -a "$DB_URL" != "" -a -e "server-dbsource.xsl" ]; then
  if [ "$DB_PASSWORD" = "" -a "$DB_PASSWORD_FILE" != "" ]; then
    echo "Reading database password from $DB_PASSWORD_FILE"
    DB_PASSWORD=`cat "$DB_PASSWORD_FILE"`
  fi
	echo "Merging Global DB Resource for $GLOBAL_DB_SOURCENAME"
#Global DB Source
	xsltproc --param DB_SOURCENAME "'$GLOBAL_DB_SOURCENAME'" --param db_class \"$DB_CLASS\" --param db_url \"$DB_URL\" --param db_username \"$DB_USERNAME\" --param db_password \"$DB_PASSWORD\" --param db_pool_max \"${DB_POOL_MAX:-50}\" --param db_pool_init \"${DB_POOL_INIT:-0}\" --param db_idle_max \"${DB_IDLE_MAX:-5}\" --param validation_query \"$DB_VALIDATION_QUERY\" server-dbsource.xsl server-output.xml > server-temp.xml 
	[ -s server-temp.xml ] && cp -f server-temp.xml server-output.xml
	
	#Global DataSource Realm for context
	if [ "$GLOBAL_REALM" != "yes" -a "$GLOBAL_REALM" = "" -a "$REALM_USERTAB" != "" -a -e "context-db-realm.xsl" ]; then	
		echo "Creating context db-realm for $GLOBAL_DB_SOURCENAME"
		xsltproc --param DB_SOURCENAME "'$GLOBAL_DB_SOURCENAME'" --param REALM_USERTAB "'$REALM_USERTAB'" --param REALM_ROLETAB "'$REALM_ROLETAB'" --param REALM_USERCOL "'${REALM_USERCOL:-username}'" --param REALM_CREDCOL "'${REALM_CREDCOL:-hashpassword}'" --param REALM_ROLECOL "'$REALM_ROLECOL'" --param ALL_ROLES_MODE "'${ALL_ROLES_MODE:-strict}'" --param LOCAL_DS "'false'" --param REALM_INTERATIONS "'$REALM_INTERATIONS'" --param REALM_ALGORITHM "'$REALM_ALGORITHM'" --param REALM_SALT_LENGTH "'$REALM_SALT_LENGTH'" --param REALM_ENCODING "'$REALM_ENCODING'" context-db-realm.xsl context-output.xml > context-temp.xml
		[ -s context-temp.xml ] && mv -f context-temp.xml context-output.xml
	#or DataSource Realm for global
	elif [ "$REALM_USERTAB" != "" -a -e "server-db-realm.xsl" ]; then	
		echo "Creating global db-realm for $GLOBAL_DB_SOURCENAME"
		xsltproc --param DB_SOURCENAME "'$GLOBAL_DB_SOURCENAME'" --param REALM_USERTAB "'$REALM_USERTAB'" --param REALM_ROLETAB "'$REALM_ROLETAB'" --param REALM_USERCOL "'${REALM_USERCOL:-username}'" --param REALM_CREDCOL "'${REALM_CREDCOL:-hashpassword}'" --param REALM_ROLECOL "'$REALM_ROLECOL'" --param ALL_ROLES_MODE "'${ALL_ROLES_MODE:-strict}'" --param REALM_INTERATIONS "'$REALM_INTERATIONS'" --param REALM_ALGORITHM "'$REALM_ALGORITHM'" --param REALM_SALT_LENGTH "'$REALM_SALT_LENGTH'" --param REALM_ENCODING "'$REALM_ENCODING'" server-db-realm.xsl server-output.xml > server-temp.xml 
		[ -s server-temp.xml ] && mv -f server-temp.xml server-output.xml
	fi
fi

if [ "$RESOURCE_NAME" != "" ]; then
	IFS=',' read -r -a RES_NAME <<< "$RESOURCE_NAME"
	IFS=',' read -r -a RES_TYPE <<< "$RESOURCE_TYPE"
 	IFS=',' read -r -a RES_FACTORY <<< "$RESOURCE_FACTORY"
  	IFS=',' read -r -a RES_SHARE <<< "$RESOURCE_SHARE"
   	IFS=',' read -r -a RES_SINGLETON <<< "$RESOURCE_SINGLETON"
    	IFS=',' read -r -a RES_CLOSE_METHOD <<< "$RESOURCE_CLOSE_METHOD"
     	IFS=',' read -r -a RES_DESCRIPTION <<< "$RESOURCE_DESCRIPTION"
      
	for key in 0 1 2 3 4; do
		#Context Resource (RES_NAME[0,1,2,3...], RES_TYPE[0,1,2,3...], RES_FACTORY[0,1,2,3...]
		if [ "${RES_NAME[$key]}" != "" -a "${RES_TYPE[$key]}" != "" -a "${RES_FACTORY[$key]}" != "" -a -e "context-any-resource.xsl" ]; then
			echo "Merging context Resource for ${RES_NAME[$key]} type ${RES_TYPE[$key]}"
			xsltproc --param RESOURCE_NAME "'${RES_NAME[$key]}'" --param type_className \"${RES_TYPE[$key]}\" --param factory_className \"${RES_FACTORY[$key]}\" \
		 		--param auth_Application \"${RES_SHARE[$key]}\" --param singleton \"${RES_SINGLETON[$key]}\" \
		   		--param scope_Unshareable \"${RES_SCOPE[$key]}\" --param closeMethod_name \"${RES_CLOSE_METHOD[$key]}\" \
		   		--param description \"${RES_DESCRIPTION[$key]}\" context-any-resource.xsl context-output.xml > context-temp.xml
			[ -s context-temp.xml ] && mv -f context-temp.xml context-output.xml
  		fi
	done
fi

if [ "$PARAMETER_NAME" != "" ]; then
	IFS=',' read -r -a RES_NAME <<< "$PARAMETER_NAME"
 	IFS=',' read -r -a RES_VALUE <<< "$PARAMETER_VALUE"
 	IFS=',' read -r -a RES_OVERRIDE <<< "$PARAMETER_OVERRIDE"
     	IFS=',' read -r -a RES_DESCRIPTION <<< "$PARAMETER_DESCRIPTION"
      
	for key in 0 1 2 3 4; do
		#Context Parameter (RES_NAME[0,1,2,3...], RES_VALUE[0,1,2,3...], RES_OVERRIDE[0,1,2,3...]
		if [ "${RES_NAME[$key]}" != "" -a "${RES_VALUE[$key]}" != "" -a -e "context-parameter.xsl" ]; then
			echo "Merging context Resource for ${RES_NAME[$key]} description ${RES_DESCRIPTION[$key]}"
			xsltproc --param param_name "'${RES_NAME[$key]}'" --param param_value \"${RES_VALUE[$key]}\" \
		 		--param param_override \"${RES_OVERRIDE[$key]}\" --param param_description \"${RES_DESCRIPTION[$key]}\" \
		   		context-parameter.xsl context-output.xml > context-temp.xml
			[ -s context-temp.xml ] && mv -f context-temp.xml context-output.xml
  		fi
	done
fi

if [ "$ENVIRONMENT_NAME" != "" ]; then
	IFS=',' read -r -a RES_NAME <<< "$ENVIRONMENT_NAME"
 	IFS=',' read -r -a RES_TYPE <<< "$ENVIRONMENT_TYPE"
 	IFS=',' read -r -a RES_VALUE <<< "$ENVIRONMENT_VALUE"
 	IFS=',' read -r -a RES_OVERRIDE <<< "$ENVIRONMENT_OVERRIDE"
      
	for key in 0 1 2 3 4; do
		#Context Parameter (RES_NAME[0,1,2,3...], RES_VALUE[0,1,2,3...], RES_OVERRIDE[0,1,2,3...]
		if [ "${RES_NAME[$key]}" != "" -a "${RES_VALUE[$key]}" != "" -a -e "context-parameter.xsl" ]; then
			echo "Merging context Resource for ${RES_NAME[$key]} description ${RES_DESCRIPTION[$key]}"
			xsltproc --param env_name "'${RES_NAME[$key]}'" --param env_value \"${RES_VALUE[$key]}\" \
		 		--param env_type \"${RES_TYPE[$key]}\" --param env_override \"${RES_OVERRIDE[$key]}\" \
		   		context-environment.xsl context-output.xml > context-temp.xml
			[ -s context-temp.xml ] && mv -f context-temp.xml context-output.xml
  		fi
	done
fi

#TCP Simple Cluster
if [ "$CLUSTER" = "DeltaManager" -o "$CLUSTER" = "BackupManager" ]; then
  if [ -e "server-cluster.xsl" ]; then
  if [ "$MCAST_ADDRESS" != "" ]; then
		echo "Creating Cluster of $CLUSTER Multi-cast=$MCAST_ADDRESS"
		xsltproc --param CHANNEL_SEND_OPTIONS "'$CHANNEL_SEND_OPTIONS'" --param CLUSTER "'$CLUSTER'" --param RECEIVE_PORT "'${RECEIVE_PORT:-5000}'" --param REPLICATION_FILTER "'$REPLICATION_FILTER'" --param MCAST_ADDRESS "'${MCAST_ADDRESS}'" --param MCAST_PORT "'${MCAST_PORT:-45564}'" --param MCAST_BIND "'${MCAST_BIND}'" server-cluster.xsl server-output.xml > server-temp.xml 
  elif [ "$DNS_MEMBERSHIP_SERVICE_NAME" != "" -o "$KUBERNETES_NAMESPACE" != "" -o "$OPENSHIFT_KUBE_PING_NAMESPACE" != "" ]; then
		echo "Creating Cluster of $CLUSTER Kubernes=$KUBERNETES_NAMESPACE or $OPENSHIFT_KUBE_PING_NAMESPACE, DNS=$DNS_MEMBERSHIP_SERVICE_NAME"
		xsltproc --param CHANNEL_SEND_OPTIONS "'$CHANNEL_SEND_OPTIONS'" --param CLUSTER "'$CLUSTER'" --param RECEIVE_PORT "'${RECEIVE_PORT:-5001}'" --param REPLICATION_FILTER "'$REPLICATION_FILTER'" --param KUBERNETES_NAMESPACE "'$KUBERNETES_NAMESPACE'" --param OPENSHIFT_KUBE_PING_NAMESPACE "'$OPENSHIFT_KUBE_PING_NAMESPACE'" --param DNS_MEMBERSHIP_SERVICE_NAME "'$DNS_MEMBERSHIP_SERVICE_NAME'" server-cluster.xsl server-output.xml > server-temp.xml 
  elif [[ $HOSTNAME =~ "[1-6]$" ]]; then
		echo "Creating Cluster of $CLUSTER static Replicas=$REPLICAS for $HOSTNAME"
		xsltproc --param CHANNEL_SEND_OPTIONS "'$CHANNEL_SEND_OPTIONS'" --param CLUSTER "'$CLUSTER'" --param HOSTNAME "'${HOSTNAME}'" --param REPLICAS "'${REPLICAS:-2}'" --param RECEIVE_PORT "'${RECEIVE_PORT:-5002}'" --param REPLICATION_FILTER "'$REPLICATION_FILTER'" server-cluster.xsl server-output.xml > server-temp.xml 
  else
    echo "Can not create cluster because not match requirement"
  fi
	[ -s server-temp.xml ] && mv -f server-temp.xml server-output.xml
  fi
fi

#CDI enable (9.x or 10x)
if [ "$CDI_ENABLE" != "" -a -e "server-cdi.xsl" ]; then
	xsltproc --param CDI_ENABLE "'$CDI_ENABLE'" server-cdi.xsl server-output.xml > server-temp.xml 
	[ -s server-temp.xml ] && mv -f server-temp.xml server-output.xml
fi

#Tomcat Port manipulation
if [ "$TOMCAT_HTTP_PORT" != "" -o "$TOMCAT_HTTPS_PORT" != ""  -o "$TOMCAT_AJP_PORT" != "" ]; then
  if [ -e "server-cluster.xsl" ]; then
	echo "Changing Ports: HTTP $TOMCAT_HTTP_PORT HTTPS $TOMCAT_HTTPS_PORT AJP $TOMCAT_AJP_PORT"
	xsltproc --param TOMCAT_HTTP_PORT "'${TOMCAT_HTTP_PORT:-8080}'" --param TOMCAT_HTTPS_PORT "'${TOMCAT_HTTPS_PORT}'" --param TOMCAT_AJP_PORT "'${TOMCAT_AJP_PORT}'" --param CONNECTOR_MAX_THREADS "'${CONNECTOR_MAX_THREADS}'" server-port.xsl server-output.xml > server-temp.xml 
	[ -s server-temp.xml ] && mv -f server-temp.xml server-output.xml
  fi
fi

if [ "$DEPLOY_CONTEXT" != "" -a -e "context-output.xml" ]; then
	mkdir -p conf/Catalina/localhost
	mv context-output.xml conf/Catalina/localhost/$DEPLOY_CONTEXT.xml 
fi

if [ -e "server-output.xml" ]; then
	mv -f server-output.xml conf/server.xml 
fi

#exec parent
exec catalina.sh "$@"
