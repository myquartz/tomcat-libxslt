#!/bin/bash

echo catalina-xslt.sh starting at `date` for context=$DEPLOY_CONTEXT
echo Configuration will produce for LDAP_URL="$LDAP_URL" REALM_USERTAB="$REALM_USERTAB" DB_SOURCENAME="$DB_SOURCENAME" GLOBAL_DB_SOURCENAME="$GLOBAL_DB_SOURCENAME" DB_URL="$DB_URL" CDI_ENABLE="$CDI_ENABLE" TOMCAT_HTTP_PORT="$TOMCAT_HTTP_PORT"

CONTEXT_PARAMS=
CONTEXT_XSL=
CONTEXT_WAR=
CONTEXT_APP=
SERVER_PARAMS=
SERVER_XSL=

if [ -f "webapps/$DEPLOY_CONTEXT.war" ]; then
	echo Extract context.xml from webapps/$DEPLOY_CONTEXT.war
	jar -xf webapps/$DEPLOY_CONTEXT.war META-INF/context.xml
	CONTEXT_WAR=webapps/$DEPLOY_CONTEXT.war
	CONTEXT_APP=webapps/$DEPLOY_CONTEXT
elif [ -f "webapps/$DEPLOY_CONTEXT/META-INF/context.xml" ]; then
	echo copy context.xml from webapps/$DEPLOY_CONTEXT
	cp -f "webapps/$DEPLOY_CONTEXT/META-INF/context.xml" context.xml
	CONTEXT_APP=webapps/$DEPLOY_CONTEXT
elif [ -f "webapps/ROOT.war" ]; then
	echo Extract context.xml from webapps/ROOT.war
	jar -xf webapps/ROOT.war META-INF/context.xml
	DEPLOY_CONTEXT=ROOT
	CONTEXT_WAR=webapps/ROOT.war
	CONTEXT_APP=webapps/ROOT
elif [ -f "webapps/ROOT/META-INF/context.xml" ]; then
	echo Extract context.xml from webapps/ROOT.war
	cp -f "webapps/ROOT/META-INF/context.xml" context.xml
	DEPLOY_CONTEXT=ROOT
	CONTEXT_APP=webapps/ROOT
# docBase of the context, not in the webapps
elif [ -n "$CONTEXT_DOCBASE" -a -d "$CONTEXT_DOCBASE" -a -n "$DEPLOY_CONTEXT" ]; then
	echo "Creating context $DEPLOY_CONTEXT docbase for $CONTEXT_DOCBASE"
	CONTEXT_PARAMS="--param context_docbase=$CONTEXT_DOCBASE --param context_path=$CONTEXT_PATH"
	CONTEXT_XSL="context-docbase.xsl"
	[ -e "$CONTEXT_DOCBASE/META-INF/context.xml" ] && cp -f "$CONTEXT_DOCBASE/META-INF/context.xml" "context.xml"
	CONTEXT_APP=$CONTEXT_DOCBASE
fi

INPUT_CONTEXT=

if [ -e "META-INF/context.xml" ]; then
	#cp META-INF/context.xml context-output.xml
 	INPUT_CONTEXT=META-INF/context.xml
elif [ -e "context.xml" ]; then
#No context template, use a default
	#cp context.xml context-output.xml
 	INPUT_CONTEXT=context.xml
else
	echo Default context file
	echo "<Context></Context>" > context-default.xml
 	INPUT_CONTEXT=context-default.xml
fi

JAR_PROC=/usr/local/tomcat/bin/xslt-process.jar
XSLT_JAVA_OPTS="-Xms64m -Xmx64m"

#Using Epsilon from JDK11 for reducing XSLT processing for GC
if [ -n "$JRE_VERSION" -a "$JRE_VERSION" != "jre8" ]; then
	XSLT_JAVA_OPTS="-Xms64m -Xmx64m -XX:+UnlockExperimentalVMOptions -XX:+UseEpsilonGC"
elif [ -n "$JDK_VERSION" -a "$JDK_VERSION" != "jdk8" ]; then
	XSLT_JAVA_OPTS="-Xms64m -Xmx64m -XX:+UnlockExperimentalVMOptions -XX:+UseEpsilonGC"
fi

#LDAP Realm for context or server
if [ -n "$LDAP_BIND" -o -n "$LDAP_USER_BASEDN" ]; then
	if [ "$LDAP_BIND_PASSWORD" = "" -a "$LDAP_BIND_PASSWORD_FILE" != "" ]; then
		echo "Reading LDAP Bind password from $LDAP_BIND_PASSWORD_FILE"
		LDAP_BIND_PASSWORD=`cat "$LDAP_BIND_PASSWORD_FILE"`
	fi
	LDAP_PARAMS="--param LDAP_ALT_URL=$LDAP_ALT_URL --param LDAP_BIND=$LDAP_BIND --param LDAP_BIND_PASSWORD=$LDAP_BIND_PASSWORD --param LDAP_USER_BASEDN=$LDAP_USER_BASEDN --param LDAP_USER_SEARCH=$LDAP_USER_SEARCH"
	LDAP_PARAMS="$LDAP_PARAMS --param LDAP_USER_PASSWD_ATTR=$LDAP_USER_PASSWD_ATTR --param LDAP_USER_PATTERN=$LDAP_USER_PATTERN	--param LDAP_GROUP_BASEDN=$LDAP_GROUP_BASEDN --param LDAP_GROUP_SEARCH=$LDAP_GROUP_SEARCH --param LDAP_GROUP_ATTR=$LDAP_GROUP_ATTR"
	LDAP_PARAMS="$LDAP_PARAMS --param AD_COMPAT=$AD_COMPAT --param COMMON_ROLE=$COMMON_ROLE --param ALL_ROLES_MODE=$ALL_ROLES_MODE"
	LDAP_PARAMS="$LDAP_PARAMS --param LDAP_SEARCHASUSER=$LDAP_SEARCHASUSER --param LDAP_USER_SUBTREE=$LDAP_USER_SUBTREE --param LDAP_GROUP_SUBTREE=$LDAP_GROUP_SUBTREE"
fi

#LDAP Realm for context
if [ -n "$LDAP_URL" -a -n "$LDAP_PARAMS" -a -e "context-ldap-realm.xsl" ]; then	
	echo "Creating context ldap-realm for $LDAP_URL"
 	CONTEXT_PARAMS="$CONTEXT_PARAMS --param LDAP_URL=$LDAP_URL $LDAP_PARAMS"
 	CONTEXT_XSL="$CONTEXT_XSL context-ldap-realm.xsl"
#or LDAP Realm for global
elif [ -n "$GLOBAL_LDAP_URL" -a -n "$LDAP_PARAMS" -a -e "server-ldap-realm.xsl" ]; then	
	echo "Creating ldap-realm for $GLOBAL_LDAP_URL"
 	SERVER_PARAMS="$SERVER_PARAMS --param LDAP_URL=$GLOBAL_LDAP_URL $LDAP_PARAMS"
 	SERVER_XSL="$SERVER_XSL server-ldap-realm.xsl"
fi

#Context or Server DB Source parameters
if [ -n "$DB_CLASS" -a -n "$DB_URL" ]; then
	if [ "$DB_PASSWORD" = "" -a "$DB_PASSWORD_FILE" != "" ]; then
		echo "Reading database password from $DB_PASSWORD_FILE"
		DB_PASSWORD=`cat "$DB_PASSWORD_FILE"`
	fi
	DB_PARAMS="--param db_class=$DB_CLASS --param db_url=$DB_URL --param db_username=$DB_USERNAME --param db_password=$DB_PASSWORD --param db_pool_max=$DB_POOL_MAX --param db_pool_init=$DB_POOL_INIT --param db_idle_max=$DB_IDLE_MAX"
 	if [ -n "$DB_VALIDATION_QUERY" ]; then
		DB_PARAMS="$DB_PARAMS --param validation_query=$DB_VALIDATION_QUERY"
	fi
	 
	#Db realm
	if [ -n "$REALM_USERTAB" ]; then
		DBREALM_PARAMS="--param REALM_USERTAB=$REALM_USERTAB --param REALM_ROLETAB=$REALM_ROLETAB --param REALM_USERCOL=$REALM_USERCOL --param REALM_CREDCOL=$REALM_CREDCOL"
		DBREALM_PARAMS="$DBREALM_PARAMS --param REALM_ROLECOL=$REALM_ROLECOL --param ALL_ROLES_MODE=$ALL_ROLES_MODE"
		DBREALM_PARAMS="$DBREALM_PARAMS --param REALM_INTERATIONS=$REALM_INTERATIONS --param REALM_ALGORITHM=$REALM_ALGORITHM --param REALM_SALT_LENGTH=$REALM_SALT_LENGTH --param REALM_ENCODING=$REALM_ENCODING"
	fi
fi

#Context DB Source
if [ -n "$DB_SOURCENAME" -a -n "$DB_PARAMS" -a -e "context-dbsource.xsl" ]; then	
	if [ "$DB_PASSWORD" = "" -a "$DB_PASSWORD_FILE" != "" ]; then
		echo "Reading database password from $DB_PASSWORD_FILE"
		DB_PASSWORD=`cat "$DB_PASSWORD_FILE"`
	fi
	echo "Merging context DB Resource for $DB_SOURCENAME"
	CONTEXT_PARAMS="$CONTEXT_PARAMS --param DB_SOURCENAME=$DB_SOURCENAME $DB_PARAMS"
 	CONTEXT_XSL="$CONTEXT_XSL context-dbsource.xsl"
	
	#DataSource Realm for context
	if [ -n "$DBREALM_PARAMS" -a -e "context-db-realm.xsl" ]; then
		echo "Creating context db-realm for $DB_SOURCENAME"
		CONTEXT_PARAMS="$CONTEXT_PARAMS $DBREALM_PARAMS --param LOCAL_DS=true"
		CONTEXT_XSL="$CONTEXT_XSL context-db-realm.xsl"
	fi

#Global DB Source
elif [ -n "$GLOBAL_DB_SOURCENAME" -a -n "$DB_PARAMS" -a -e "server-dbsource.xsl" ]; then
	echo "Merging Global DB Resource for $GLOBAL_DB_SOURCENAME"
	SERVER_PARAMS="$SERVER_PARAMS --param DB_SOURCENAME=$DB_SOURCENAME $DB_PARAMS"
 	SERVER_XSL="$SERVER_XSL server-dbsource.xsl"
	
	#Global DataSource Realm for context
	if [ "$GLOBAL_REALM" != "yes" -a "$GLOBAL_REALM" = "" -a "$REALM_USERTAB" != "" -a -e "context-db-realm.xsl" ]; then	
		echo "Creating context db-realm for Global $GLOBAL_DB_SOURCENAME"
		CONTEXT_PARAMS="$CONTEXT_PARAMS $DBREALM_PARAMS --param LOCAL_DS=false"
		CONTEXT_XSL="$CONTEXT_XSL context-db-realm.xsl"
	
	#or DataSource Realm for global
	elif [ -n "$REALM_USERTAB" -a -e "server-db-realm.xsl" ]; then	
		echo "Creating global db-realm for global $GLOBAL_DB_SOURCENAME"
		SERVER_PARAMS="$SERVER_PARAMS $DBREALM_PARAMS"
		SERVER_XSL="$SERVER_XSL server-db-realm.xsl"
	fi
fi

if [ "$RESOURCE_NAME" != "" ]; then
	IFS=',' read -r -a RES_NAME <<< "$RESOURCE_NAME"
	IFS=',' read -r -a RES_TYPE <<< "$RESOURCE_TYPE"
 	IFS=',' read -r -a RES_FACTORY <<< "$RESOURCE_FACTORY"
 	IFS=',' read -r -a RES_AUTH <<< "$RESOURCE_AUTH"
 	IFS=',' read -r -a RES_SINGLETON <<< "$RESOURCE_SINGLETON"
	IFS=',' read -r -a RES_SCOPE <<< "$RESOURCE_SCOPE"
 	IFS=',' read -r -a RES_CLOSE_METHOD <<< "$RESOURCE_CLOSE_METHOD"
 	IFS=',' read -r -a RES_DESCRIPTION <<< "$RESOURCE_DESCRIPTION"
			
	for key in 0 1 2 3 4; do
		#Context Resource (RES_NAME[0,1,2,3...], RES_TYPE[0,1,2,3...], RES_FACTORY[0,1,2,3...]
		if [ "${RES_NAME[$key]}" != "" -a "${RES_TYPE[$key]}" != "" -a "${RES_FACTORY[$key]}" != "" -a -e "context-any-resource.xsl" ]; then
			echo "Merging context Resource for ${RES_NAME[$key]} type ${RES_TYPE[$key]}"
	 		#output to bundle file
			echo "context-any-resource.xsl" > resource-${key}.txt
	 		echo "RESOURCE_NAME=${RES_NAME[$key]}" >> resource-${key}.txt
			echo "type_className=${RES_TYPE[$key]}" >> resource-${key}.txt
	 		echo "factory_className=${RES_FACTORY[$key]}" >> resource-${key}.txt
	 		[ -n "${RES_AUTH[$key]}" ] && echo "auth_Application=${RES_AUTH[$key]}" >> resource-${key}.txt
			[ -n "${RES_SCOPE[$key]}" ] && echo "scope_Unshareable=${RES_SCOPE[$key]}" >> resource-${key}.txt
			[ -n "${RES_SINGLETON[$key]}" ] && echo "singleton=${RES_SINGLETON[$key]}" >> resource-${key}.txt
	 		[ -n "${RES_CLOSE_METHOD[$key]}" ] && echo "closeMethod_name=${RES_CLOSE_METHOD[$key]}" >> resource-${key}.txt
	 		[ -n "${RES_DESCRIPTION[$key]}" ] && echo "description=${RES_DESCRIPTION[$key]}" >> resource-${key}.txt
			CONTEXT_XSL="$CONTEXT_XSL --bundle=resource-${key}.txt"
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
			echo "Merging context parameter for ${RES_NAME[$key]} description=${RES_DESCRIPTION[$key]}"
	 		#output to bundle file
			echo "context-parameter.xsl" > parameter-${key}.txt
	 		echo "param_name=${RES_NAME[$key]}" >> parameter-${key}.txt
			echo "param_value=${RES_VALUE[$key]}" >> parameter-${key}.txt
	 		echo "param_override=${RES_OVERRIDE[$key]}" >> parameter-${key}.txt
	 		[ -n "${RES_DESCRIPTION[$key]}" ] && echo "param_description=${RES_DESCRIPTION[$key]}" >> parameter-${key}.txt
			CONTEXT_XSL="$CONTEXT_XSL --bundle=parameter-${key}.txt"
		fi
	done
fi

if [ "$ENVIRONMENT_NAME" != "" ]; then
	IFS=',' read -r -a RES_NAME <<< "$ENVIRONMENT_NAME"
 	IFS=',' read -r -a RES_TYPE <<< "$ENVIRONMENT_TYPE"
 	IFS=',' read -r -a RES_VALUE <<< "$ENVIRONMENT_VALUE"
 	IFS=',' read -r -a RES_OVERRIDE <<< "$ENVIRONMENT_OVERRIDE"
	IFS=',' read -r -a RES_DESCRIPTION <<< "$ENVIRONMENT_DESCRIPTION"
			
	for key in 0 1 2 3 4; do
		#Context Parameter (RES_NAME[0,1,2,3...], RES_VALUE[0,1,2,3...], RES_OVERRIDE[0,1,2,3...]
		if [ "${RES_NAME[$key]}" != "" -a "${RES_VALUE[$key]}" != "" -a -e "context-parameter.xsl" ]; then
			echo "Merging context Resource for ${RES_NAME[$key]} description ${RES_DESCRIPTION[$key]}"
 			#output to bundle file
			echo "context-environment.xsl" > env-${key}.txt
	 		echo "env_name=${RES_NAME[$key]}" >> env-${key}.txt
			echo "env_value=${RES_VALUE[$key]}" >> env-${key}.txt
	 		echo "env_type=${RES_TYPE[$key]}" >> env-${key}.txt
	 		echo "env_override=${RES_OVERRIDE[$key]}" >> env-${key}.txt
	 		[ -n "${RES_DESCRIPTION[$key]}" ] && echo "env_description=${RES_DESCRIPTION[$key]}" >> env-${key}.txt
			CONTEXT_XSL="$CONTEXT_XSL --bundle=env-${key}.txt"
		fi
	done
fi

if [ -n "$VALVE_REMOTE_ADDR_ALLOW" -o -n "$VALVE_REMOTE_ADDR_DENY" ]; then			
	#Context Valve Remote Address
	if [ -e "context-remote-address.xsl" ]; then
		echo "Creating context remote-address for $VALVE_REMOTE_ADDR_ALLOW and $VALVE_REMOTE_ADDR_DENY"
		CONTEXT_PARAMS="$CONTEXT_PARAMS --param remote_addr_allow=$VALVE_REMOTE_ADDR_ALLOW --param remote_addr_deny=$VALVE_REMOTE_ADDR_DENY --param deny_status=$VALVE_REMOTE_DENY_STATUS --param remote_connector_port=$VALVE_REMOTE_CONNECTOR_PORT"
		CONTEXT_XSL="$CONTEXT_XSL context-remote-address.xsl"
	else
		echo "Can not create remote-address for $VALVE_REMOTE_ADDR_ALLOW and $VALVE_REMOTE_ADDR_DENY"
	fi
fi

if [ -n "$VALVE_REMOTE_CIDR_ALLOW" -o -n "$VALVE_REMOTE_CIDR_DENY" ]; then			
	#Context Valve Remote Address
	if [ -e "context-remote-cidr.xsl" ]; then
		echo "Creating context remote-address for $VALVE_REMOTE_CIDR_ALLOW and $VALVE_REMOTE_CIDR_DENY"
		CONTEXT_PARAMS="$CONTEXT_PARAMS --param remote_cidr_allow=$VALVE_REMOTE_CIDR_ALLOW --param remote_cidr_deny=$VALVE_REMOTE_CIDR_DENY"
		CONTEXT_XSL="$CONTEXT_XSL context-remote-cidr.xsl"
	else
		echo "Can not create remote-cidr for $VALVE_REMOTE_CIDR_ALLOW and $VALVE_REMOTE_CIDR_DENY"
	fi
fi

if [ -n "$VALVE_ACCESS_LOG_DIR" ]; then
	#Context Valve Access Log
	if [ -n "$VALVE_LOG_FOR_CONTEXT" -a -e "context-access-log.xsl" ]; then
		echo "Creating context access-log for $VALVE_ACCESS_LOG_DIR, and remove server access log"
		CONTEXT_PARAMS="$CONTEXT_PARAMS --param access_log_dir=$VALVE_ACCESS_LOG_DIR --param access_log_prefix=$VALVE_ACCESS_LOG_PREFIX --param access_log_suffix=$VALVE_ACCESS_LOG_SUFFIX --param access_log_rotate=$VALVE_ACCESS_LOG_ROTATE --param access_log_extended=$VALVE_ACCESS_LOG_EXTENDED --param access_log_pattern=$VALVE_ACCESS_LOG_PATTERN"
		CONTEXT_XSL="$CONTEXT_XSL context-access-log.xsl"
		if [ -e "server-access-log.xsl" ]; then
			SERVER_PARAMS="$SERVER_PARAMS --param access_log_remove=true"
			SERVER_XSL="$SERVER_XSL server-access-log.xsl"
		fi
	#Server Valve Access Log
	elif [ -e "server-access-log.xsl" ]; then
		echo "Creating server access-log for $VALVE_ACCESS_LOG_DIR"
		SERVER_PARAMS="$SERVER_PARAMS --param access_log_dir=$VALVE_ACCESS_LOG_DIR --param access_log_prefix=$VALVE_ACCESS_LOG_PREFIX --param access_log_suffix=$VALVE_ACCESS_LOG_SUFFIX --param access_log_rotate=$VALVE_ACCESS_LOG_ROTATE --param access_log_extended=$VALVE_ACCESS_LOG_EXTENDED --param access_log_pattern=$VALVE_ACCESS_LOG_PATTERN"
		SERVER_XSL="$SERVER_XSL server-access-log.xsl"
	else
		echo "Can not create access-log for $VALVE_ACCESS_LOG_DIR"
	fi
fi

if [ -n "$NO_ACCESS_LOG" ]; then
		if [ -e "server-access-log.xsl" ]; then
			SERVER_PARAMS="$SERVER_PARAMS --param access_log_remove=true"
			SERVER_XSL="$SERVER_XSL server-access-log.xsl"
		fi
fi

if [ -n "$VALVE_SHOW_ERROR" ]; then
	#Context Valve Show Error
	if [ -e "context-show-error.xsl" ]; then
		echo "Creating context show-error for $VALVE_SHOW_ERROR"
		CONTEXT_PARAMS="$CONTEXT_PARAMS --param show_error=$VALVE_SHOW_ERROR --param show_server_info=$VALVE_SHOW_SERVER_INFO"
		CONTEXT_XSL="$CONTEXT_XSL context-show-error.xsl"
	else
		echo "Can not create show-error for $VALVE_SHOW_ERROR"
	fi
fi

#TCP Simple Cluster
if [ "$CLUSTER" = "DeltaManager" -o "$CLUSTER" = "BackupManager" ]; then
	if [ -e "server-cluster.xsl" ]; then
		SERVER_PARAMS="$SERVER_PARAMS --param CLUSTER=$CLUSTER"
	 	[ -n "$REPLICATION_FILTER" ] && SERVER_PARAMS="$SERVER_PARAMS --param REPLICATION_FILTER=$REPLICATION_FILTER"
	 	[ -n "$CHANNEL_SEND_OPTIONS" ] && SERVER_PARAMS="$SERVER_PARAMS --param CHANNEL_SEND_OPTIONS=$CHANNEL_SEND_OPTIONS"
		SERVER_XSL="$SERVER_XSL server-cluster.xsl"
		LASTC=${HOSTNAME: -1}
		if [ -n "$MCAST_ADDRESS" ]; then
			echo "EXPERIMENTAL: Creating Cluster of $CLUSTER Multi-cast=$MCAST_ADDRESS"
			SERVER_PARAMS="$SERVER_PARAMS --param RECEIVE_PORT=$RECEIVE_PORT --param MCAST_ADDRESS=$MCAST_ADDRESS --param MCAST_PORT=$MCAST_PORT --param MCAST_BIND=$MCAST_BIND"
		elif [ -n "$DNS_MEMBERSHIP_SERVICE_NAME" -o -n "$KUBERNETES_NAMESPACE" -o -n "$OPENSHIFT_KUBE_PING_NAMESPACE" ]; then
			echo "Creating Cluster of $CLUSTER Kubernes=$KUBERNETES_NAMESPACE or $OPENSHIFT_KUBE_PING_NAMESPACE, DNS=$DNS_MEMBERSHIP_SERVICE_NAME"
			SERVER_PARAMS="$SERVER_PARAMS --param RECEIVE_PORT=$RECEIVE_PORT"
			[ -n "$KUBERNETES_NAMESPACE" ] && SERVER_PARAMS="$SERVER_PARAMS --param KUBERNETES_NAMESPACE=$KUBERNETES_NAMESPACE"
			[ -n "$OPENSHIFT_KUBE_PING_NAMESPACE" ] && SERVER_PARAMS="$SERVER_PARAMS --param OPENSHIFT_KUBE_PING_NAMESPACE=$OPENSHIFT_KUBE_PING_NAMESPACE"
			[ -n "$DNS_MEMBERSHIP_SERVICE_NAME" ] && SERVER_PARAMS="$SERVER_PARAMS --param DNS_MEMBERSHIP_SERVICE_NAME=$DNS_MEMBERSHIP_SERVICE_NAME"
		elif [ -n "$LASTC" -a "$LASTC" -eq "$LASTC" -a $LASTC -ge 1 -a $LASTC -le 6 ]; then
			echo "Creating Cluster of $CLUSTER static Replicas=$REPLICAS for $HOSTNAME (node index $LASTC)"
			SERVER_PARAMS="$SERVER_PARAMS --param HOSTNAME=${HOSTNAME} --param REPLICAS=${REPLICAS:-2} --param RECEIVE_PORT=${RECEIVE_PORT:-5002}"
		else
			echo "Can not create cluster Replicas=$REPLICAS because not match requirement of hostname=$HOSTNAME"
		fi

		if [ -f "web-distributable.xsl" ]; then
			if [ -n "$CONTEXT_WAR" -a -e "$CONTEXT_WAR" ]; then
				echo "extracting context app from $CONTEXT_WAR"
				mkdir -p $CONTEXT_APP && pushd $CONTEXT_APP && jar -xf $PWD/$CONTEXT_WAR && popd && rm -f $PWD/$CONTEXT_WAR
			fi

			if [ -f "$CONTEXT_APP/WEB-INF/web.xml" -a ! -e "web-orig.xml" ]; then
				mv "$CONTEXT_APP/WEB-INF/web.xml" web-orig.xml
				java $XSLT_JAVA_OPTS -jar $JAR_PROC -- web-orig.xml web-distributable.xsl $CONTEXT_APP/WEB-INF/web.xml
			elif [ ! -f "$CONTEXT_APP/WEB-INF/web.xml" ]; then
				echo "<web-app><distributable /></web-app>" > $CONTEXT_APP/WEB-INF/web.xml
			fi
		fi
	fi
fi

#CDI enable (9.x or 10x)
if [ -n "$CDI_ENABLE" -a -e "server-cdi.xsl" ]; then
	SERVER_PARAMS="$SERVER_PARAMS --param CDI_ENABLE=$CDI_ENABLE"
 	SERVER_XSL="$SERVER_XSL server-cdi.xsl"
fi

#Tomcat Port manipulation
if [ -n "$TOMCAT_HTTP_PORT" -o -n "$TOMCAT_HTTPS_PORT" -o -n "$TOMCAT_AJP_PORT" ]; then
	if [ -e "server-cluster.xsl" ]; then
		echo "Changing Ports: SHUTDOWN=$TOMCAT_SHUTDOWN_PORT HTTP=$TOMCAT_HTTP_PORT HTTPS=$TOMCAT_HTTPS_PORT AJP=$TOMCAT_AJP_PORT"
		SERVER_PARAMS="$SERVER_PARAMS --param TOMCAT_HTTP_PORT=${TOMCAT_HTTP_PORT:-8080}"
		[ -n "$CONNECTOR_REDIRECT_PORT" ] && SERVER_PARAMS="$SERVER_PARAMS --param CONNECTOR_REDIRECT_PORT=$CONNECTOR_REDIRECT_PORT"
		[ -n "$CONNECTOR_MAX_POST_SIZE" ] && SERVER_PARAMS="$SERVER_PARAMS --param CONNECTOR_MAX_POST_SIZE=$CONNECTOR_MAX_POST_SIZE"
		[ -n "$CONNECTOR_URI_ENCODING" ] && SERVER_PARAMS="$SERVER_PARAMS --param CONNECTOR_URI_ENCODING=$CONNECTOR_URI_ENCODING"
		[ -n "$CONNECTOR_COMPRESSION" ] && SERVER_PARAMS="$SERVER_PARAMS --param CONNECTOR_COMPRESSION=$CONNECTOR_COMPRESSION"
		[ -n "$CONNECTOR_MIN_SPARE_THREADS" ] && SERVER_PARAMS="$SERVER_PARAMS --param CONNECTOR_MIN_SPARE_THREADS=$CONNECTOR_MIN_SPARE_THREADS"
		[ -n "$CONNECTOR_MAX_SPARE_THREADS" ] && SERVER_PARAMS="$SERVER_PARAMS --param CONNECTOR_MAX_SPARE_THREADS=$CONNECTOR_MAX_SPARE_THREADS"
		[ -n "$CONNECTOR_MAX_THREADS" ] && SERVER_PARAMS="$SERVER_PARAMS --param CONNECTOR_MAX_THREADS=$CONNECTOR_MAX_THREADS"
		[ -n "$TOMCAT_AJP_PORT" ] && SERVER_PARAMS="$SERVER_PARAMS --param TOMCAT_AJP_PORT=$TOMCAT_AJP_PORT"
		[ -n "$TOMCAT_SHUTDOWN_PORT" ] && SERVER_PARAMS="$SERVER_PARAMS --param TOMCAT_SHUTDOWN_PORT=$TOMCAT_SHUTDOWN_PORT"
		[ -n "$TOMCAT_HTTPS_PORT" ] && SERVER_PARAMS="$SERVER_PARAMS --param TOMCAT_HTTPS_PORT=$TOMCAT_HTTPS_PORT"
		[ -n "$TOMCAT_HTTP2" ] && SERVER_PARAMS="$SERVER_PARAMS --param TOMCAT_HTTP2=$TOMCAT_HTTP2"
		[ -n "$TOMCAT_KEY_TYPE" ] && SERVER_PARAMS="$SERVER_PARAMS --param TOMCAT_KEY_TYPE=$TOMCAT_KEY_TYPE"
		#Implementation: certificates file configuration.
		if [ -n "$TOMCAT_KEY_STORE" ]; then
			SERVER_PARAMS="$SERVER_PARAMS --param TOMCAT_KEY_STORE=$TOMCAT_KEY_STORE --param TOMCAT_KEY_STORE_PASSWORD=$TOMCAT_KEY_STORE_PASSWORD"
		elif [ -n "$TOMCAT_APR_KEY" ]; then
			SERVER_PARAMS="$SERVER_PARAMS --param TOMCAT_APR_KEY=$TOMCAT_APR_KEY --param TOMCAT_APR_CERT=$TOMCAT_APR_CERT --param TOMCAT_APR_CHAIN=$TOMCAT_APR_CHAIN"
		elif [ -n "$TOMCAT_HTTPS_PORT" ]; then
			if [ ! -e "conf/keystore.jks" ]; then
				echo "generating a self-signed certificate saving as keystore.jks"
				keytool -genkey -keyalg RSA -noprompt -alias tomcat -dname "CN=$HOSTNAME, OU=NA, O=NA, L=NA, S=NA, C=NA" \
					-keystore conf/keystore.jks -validity 9999 -storepass autogenerate -keypass autogenerate
			fi
			SERVER_PARAMS="$SERVER_PARAMS --param TOMCAT_KEY_STORE=conf/keystore.jks --param TOMCAT_KEY_STORE_PASSWORD=autogenerate"
		fi
		SERVER_XSL="$SERVER_XSL server-port.xsl"
	fi
fi

echo "generating context-based XSL: $CONTEXT_XSL"
if [ -n "$DEPLOY_CONTEXT" -a -n "$INPUT_CONTEXT" -a -n "$CONTEXT_XSL" -a -e "$INPUT_CONTEXT" -a ! -e "conf/Catalina/localhost/$DEPLOY_CONTEXT.xml" ]; then
	mkdir -p conf/Catalina/localhost
 	#XSL Processing
	[ -n "$DEBUG" ] && echo "CONTEXT_PARAMS: $CONTEXT_PARAMS"
	[ -n "$DEBUG" ] && echo "CONTEXT_XSL: $INPUT_CONTEXT $CONTEXT_XSL"
	java $XSLT_JAVA_OPTS -jar $JAR_PROC $CONTEXT_PARAMS -- $INPUT_CONTEXT $CONTEXT_XSL conf/Catalina/localhost/$DEPLOY_CONTEXT.xml
	[ -n "$DEBUG" ] && cat conf/Catalina/localhost/$DEPLOY_CONTEXT.xml
fi

echo "generating server-based XSL: $SERVER_XSL"
if [ -n "$SERVER_XSL" -a -e "server-orig.xml" ]; then
	[ -n "$DEBUG" ] && echo "SERVER_PARAMS: $SERVER_PARAMS"
	[ -n "$DEBUG" ] && echo "SERVER_XSL: server-orig.xml $SERVER_XSL"
	java $XSLT_JAVA_OPTS -jar $JAR_PROC $SERVER_PARAMS -- server-orig.xml $SERVER_XSL conf/server.xml
	[ -n "$DEBUG" ] && cat conf/server.xml
 	#mark a change for faster next start time
 	mv "server-orig.xml" "server-orig.xml.bak"
fi

#exec parent
exec catalina.sh "$@"
