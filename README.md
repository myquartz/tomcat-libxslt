
# Tomcat with XSLT Processing

This container image is built on Apache Tomcat and includes an XSLT processor. Originally, the processor was `xsltproc` from LibXSLT, but it has since been replaced with a custom Java-based program. The purpose of this addition is to facilitate the generation and manipulation of Tomcat's XML configuration files.

Key configuration files, such as `server.xml`, `tomcat-users.xml`, and `Catalina/localhost/your-app.xml`, are often modified for specific use cases. Using the XSLT processor, these files can be adjusted dynamically based on environment variables passed to the container, ensuring streamlined configuration management.

## The prebuilt images

You can find prebuilt images at the following public registries:

1. Docker Hub: [https://hub.docker.com/r/myquartz/tomcat-xslt](https://hub.docker.com/r/myquartz/tomcat-xslt) (without CDI) or [https://hub.docker.com/r/myquartz/tomcat-xslt-cdi](https://hub.docker.com/r/myquartz/tomcat-xslt-cdi) (Tomcat 9 or Tomcat 10 with CDI support). I update them every few weeks.
2. AWS Public ECR: these images are built for **Corretto OpenJDK** only that supported by AWS. [AWS ECR /myquartz/tomcat-xslt](https://gallery.ecr.aws/myquartz/tomcat-xslt) is without CDI, [AWS ECR /myquartz/tomcat-xslt-cdi](https://gallery.ecr.aws/myquartz/tomcat-xslt-cdi) is with CDI and Jax-RS. These images are built by AWS CodeBuild and are updated automatically on every push to the main branch.

## Supported features

The startup script manipulates the Apache Tomcat configuration for:

1. Tomcat HTTP, HTTPS, AJP Connector ports.
2. Database Resource for JNDI lookup
3. Realm resources for authentication/authorization (data source, LDAP, and Tomcat users).
4. Cluster manager with application session synchronization.
5. Context-based: the startup script creates/changes the deployed context file "conf/Catalina/localhost/application.xml" (by default derived from application.war/META-INF/context.xml).
6. Global resources: the startup script updates conf/server.xml (`<GlobalNamingResources />`) for the resource.
7. A bundle of Tomcat modules supporting CDI (the OWB library) and Jax-RS (the CXF library).
8. Context valves (remote address/CIDR filtering, access log, error report) and Tomcat users/roles.
9. AMD64 and ARM64/v8 platform support with docker buildx.

Supported Tomcat versions and variants are:

  1. Tomcat 8.5 with JDK 8, 11 (non-CDI/Jax-RS supported).
  2. Tomcat 9 with JDK 11, 17.
  3. Tomcat 10.0, 10.1 with JDK 11, 17, 21.
  
### The Tomcat's Web Application Context

For context-based deployment, the ENV **DEPLOY_CONTEXT** has to be defined to indicate your **application**.war name. If it is not defined, ROOT.war is assumed. Global resources are not affected by this variable.

Related ENV variables:

* **DEPLOY_CONTEXT**: the context name, the same as the WAR file or exploded directory name under `webapps/` (`ROOT` for the root context).
* *CONTEXT_DOCBASE*: a directory outside `webapps/` that holds your application. When it is set (together with DEPLOY_CONTEXT), a context file with this `docBase` is created.
* *CONTEXT_PATH*: the context `path` attribute used together with CONTEXT_DOCBASE.
* *DEBUG*: set any value to print the parameters, the stylesheets and the generated XML files at startup.

### HTTP/HTTPS/AJP Ports

You can change the listening port of the tomcat instance by the following ENV variables:

1. `TOMCAT_HTTP_PORT`: the HTTP port - default to 8080 - changing to `<Connector />` element in the server.xml.
2. `TOMCAT_HTTPS_PORT`: the HTTPS port - default to empty - changing to `<Connector />` element in the server.xml (no keystore yet).
3. `TOMCAT_AJP_PORT`: the AJP port - default to 8009 - changing to `<Connector />` element in the server.xml.
4. `TOMCAT_SHUTDOWN_PORT`: non-default shutdown port (allow to run multiple tomcat containers in the same Pod of Kubernetes Cluster).
5. `CONNECTOR_MAX_THREADS`: maximum threads of the connector.
6. `CONNECTOR_MIN_SPARE_THREADS`, `CONNECTOR_MAX_SPARE_THREADS`: minimum/maximum spare threads of the connector.
7. `CONNECTOR_REDIRECT_PORT`: the `redirectPort` of the connector (defaults to `TOMCAT_HTTPS_PORT` when that is defined).
8. `CONNECTOR_MAX_POST_SIZE`: the `maxPostSize` of the connector, in bytes.
9. `CONNECTOR_URI_ENCODING`: the `URIEncoding` of the connector, eg `UTF-8`.
10. `CONNECTOR_COMPRESSION`: the `compression` of the connector: `on`, `off` or `force`.
11. `TOMCAT_HTTP2`: set `true` to enable HTTP/2 upgrade on the HTTPS connector.

For HTTPS, you can define:

1. `TOMCAT_KEY_STORE`, `TOMCAT_KEY_STORE_PASSWORD` point to the key store file and its password.
2. `TOMCAT_APR_KEY, TOMCAT_APR_CERT, TOMCAT_APR_CHAIN` point to the key, certificate and chain files (in PEM format) for the APR HTTPS connector.
3. `TOMCAT_KEY_TYPE`: RSA or DSA for key type (RSA is default).
4. If you don't define any keys or certificates but specify `TOMCAT_HTTPS_PORT`, a self-signed certificate will be generated once for each container.

### Data Source

A context-based data source or a global-based data source will be added to context.xml or server.xml accordingly, based on which environment variable is defined.

The following ENV variables to define a data source:

* **DB_SOURCENAME** (context-based) or **GLOBAL_DB_SOURCENAME** (global): the data source name to create, eg: `jdbc/data_source`
* **DB_CLASS**: the class name of JDBC Driver, eg: `org.h2.Driver` or `com.mysql.cj.jdbc.Driver`
* **DB_URL**: the JDBC URL for the data source, eg: `jdbc:h2:mem:test` or `jdbc:mysql:server:port/dbname`
* *DB_USERNAME*: the username for connection to the database.
* *DB_PASSWORD* or *DB_PASSWORD_FILE*: the password or the file contains the password for database connection
* `DB_POOL_MAX`: maximum connections of the pool - 50 by default
* `DB_POOL_INIT`: initial connections when starting the data source - 0 by default
* `DB_IDLE_MAX`: idle connections
* `DB_VALIDATION_QUERY`: the query for connection validation, empty by default.

When defining these parameters, the `Resource` element will be added/updated to context.xml or server.xml file, it looks like:

~~~ xml
<!-- in server.xml, the GlobalNamingResources is the parent of the Resource, instead of Context -->
<Context>
<Resource
  auth="Container" 
  type="javax.sql.DataSource" 
  factory="org.apache.tomcat.jdbc.pool.DataSourceFactory" 
  minIdle="0"
  name="${DB_SOURCENAME} or ${GLOBAL_DB_SOURCENAME}" driverClassName="${DB_CLASS}"
  url="${DB_URL}" username="${DB_USERNAME}" password="${DB_PASSWORD}"
  maxActive="${DB_POOL_MAX}" initialSize="${DB_POOL_INIT}" maxIdle="${DB_IDLE_MAX}"
  validationQuery="${DB_VALIDATION_QUERY}" />
</Context>
~~~

### Data Source Realm

This realm is for servlet/application authentication by tables hosted in the data source.
If a context-based/global data source created, the realm will be set to context-based or global/context DB_SOURCENAME accordingly.

The following ENV variables to define the realm:

* **REALM_USERTAB**: the table name defines users' data.
* **REALM_ROLETAB**: the table name defines users' role data.
* *REALM_USERCOL*: the column name of username (default to *username*).
* *REALM_CREDCOL*: the column name of hashed password (default to hashpassword). More details about hashed passwords are at https://tomcat.apache.org/tomcat-9.0-doc/config/credentialhandler.html
* *REALM_ROLECOL*: the column name of a user's role.
* *ALL_ROLES_MODE*: the value of attribute "allRolesMode", one of value 'strict' or 'authOnly' or 'strictAuthOnly'.
* *REALM_ALGORITHM*: the algorithm for hashing passwords, default to SHA-512; it can be SHA-1, SHA-256, etc. The hashpassword column must be formatted as Tomcat expects.
* *REALM_INTERATIONS*: the iteration count for hashing passwords, it should be 1.
* *REALM_SALT_LENGTH*: the length of salt value.
* *REALM_ENCODING*: character encoding (eg UTF-8) while hashing.
* *GLOBAL_REALM*: set "yes" value to create global realm instead of context-based realm (only when the relevant global data source is defined).
  
When defining these parameters, the Realm element will be added/updated in context.xml or server.xml. It looks like:

~~~ xml
<!-- in server.xml, the Engine is the parent of the Realm, instead of Context -->
<Context>
<Realm className="org.apache.catalina.realm.DataSourceRealm"
  dataSourceName="${DB_SOURCENAME} or ${GLOBAL_DB_SOURCENAME}"
  userTable="${REALM_USERTAB}" userNameCol="${REALM_USERCOL}" userCredCol="${REALM_CREDCOL}"
  userRoleTable="${REALM_ROLETAB}" roleNameCol="${REALM_ROLECOL}"
  allRolesMode="${ALL_ROLES_MODE}">
  <!-- if REALM_ALGORITHM and REALM_INTERATIONS defined -->
  <CredentialHandler className="org.apache.catalina.realm.MessageDigestCredentialHandler"
    algorithm="${REALM_ALGORITHM}" interations="${REALM_INTERATIONS}"
    saltLength="${REALM_SALT_LENGTH}" encoding="${REALM_ENCODING}"
  />
</Realm>
</Context>
~~~

### LDAP Realm

This realm is for servlet/application authentication by an LDAP server. Tomcat supports JNDIRealm to query the LDAP server and look up users/groups for the realm.

The realm is set to context-based or global depending on whether LDAP_URL or GLOBAL_LDAP_URL is defined.

The following ENV variables to define the realm:

* **LDAP_URL** or **GLOBAL_LDAP_URL**: the LDAP URL, eg ldap://hostname:port
* *LDAP_ALT_URL*: alternative LDAP URL (when the main is not available).
* *LDAP_BIND*: the bind DN used for the lookup
* *LDAP_BIND_PASSWORD* or *LDAP_BIND_PASSWORD_FILE*: the password or the file contains the password for binding LDAP
* *LDAP_USER_BASEDN*: the base DN for looking up users.
* *LDAP_USER_SEARCH*: the user search string, replace {0} for user object search (eg uid={0})
* *LDAP_USER_PASSWD_ATTR*: the password attribute name (in Comparison mode only).
* *LDAP_SEARCHASUSER*: boolean value, `true` value indicates that search as the authenticated user.
* *LDAP_USER_SUBTREE*: `true` searches the whole subtree for users (otherwise one level only)
* *LDAP_USER_PATTERN*: the DN template for binding mode authentication (eg uid={0},ou=people,dc=mycompany,dc=com)
* *LDAP_GROUP_BASEDN*: the base of group search DN `(eg ou=groups,dc=mycompany,dc=com)`
* *LDAP_GROUP_SEARCH*: the group search string, (eg `(uniqueMember={0})`, replacing {0} {1} {2} to user's DN, username and user attribute)
* *LDAP_GROUP_SUBTREE*: `true` searches the whole subtree for groups/roles
* *LDAP_GROUP_ATTR*: the group attribute name of the group name (== role name in the servlet context).
* *AD_COMPAT*: Active Directory compatible
* *COMMON_ROLE*: a common role assigned to every authenticated user.
* *ALL_ROLES_MODE*: the value of attribute "allRolesMode", one of value 'strict' or 'authOnly' or 'strictAuthOnly'.

When defining these parameters, the Realm element will be added/updated in context.xml or server.xml. It looks like:

~~~ xml
<!-- in server.xml, the Engine is the parent of the Realm, instead of Context -->
<Context>
<Realm className="org.apache.catalina.realm.JNDIRealm"
  connectionURL="${LDAP_URL} or ${GLOBAL_LDAP_URL}" alternateURL="${LDAP_ALT_URL}"
  userSearchAsUser="${LDAP_SEARCHASUSER}" connectionName="${LDAP_BIND}" connectionPassword="${LDAP_BIND_PASSWORD}"
  userBase="${LDAP_USER_BASEDN}" userSubtree="${LDAP_USER_SUBTREE}" userSearch="${LDAP_USER_SEARCH}"
  userPassword="${LDAP_USER_PASSWD_ATTR}" userPattern="${LDAP_USER_PATTERN}" userRoleName="${LDAP_USER_ROLE_ATTR}"
  roleBase="${LDAP_GROUP_BASEDN}" roleSubtree="${LDAP_GROUP_SUBTREE}" roleName="${LDAP_GROUP_ATTR}"
  roleSearch="${LDAP_GROUP_SEARCH}" commonRole="${COMMON_ROLE}"
  allRolesMode="${ALL_ROLES_MODE}" adCompat="${AD_COMPAT}">
</Realm>
</Context>
~~~

### Tomcat users, roles and UserDatabase Realm

Users and roles are added into `conf/tomcat-users.xml` (Tomcat's global `UserDatabase`). Existing content is preserved.

* **TOMCAT_ROLES**: comma separated roles to create, eg `role1,role2,role3`. If empty, nothing is done.
* **TOMCAT_USERS**: comma separated user names, eg `user1,user2`.
* **TOMCAT_USERS_ROLES**: roles of the users by the same position as TOMCAT_USERS, roles of one user are separated by colon, eg `role1:role2,role3`.
* **TOMCAT_USERS_PASSWORD**: passwords by the same position as TOMCAT_USERS, used as-is (clear text or an already digested value); it can not contain a comma. A user without a password is skipped.
* *TOMCAT_USERS_REALM_ON*: `true` or `yes` to add the `org.apache.catalina.realm.UserDatabaseRealm` (resourceName `UserDatabase`) to the context (or to the server's Engine if there is no context). If another Realm (JDBC, LDAP...) exists, it is wrapped by a `CombinedRealm` declaring the UserDatabase first; if a `LockOutRealm` or `CombinedRealm` exists, UserDatabase is added as its first child.

### Other Context's resources

The application archive (war) can be configured with other resources. Several entries can be defined by separating the values with commas (up to 5 entries), for example:

#### Generic resources

> Note: EXPERIMENTAL, the **Resource** only supports a fixed set of attributes (see below) due to the limitation of static attribute names in XSL. You must implement a Factory class to build the resource instance, as described here [Adding_Custom_Resource_Factories](https://tomcat.apache.org/tomcat-9.0-doc/jndi-resources-howto.html#Adding_Custom_Resource_Factories)

The ENV variables (comma separated lists, matched by position):

* **RESOURCE_NAME**, **RESOURCE_TYPE**, **RESOURCE_FACTORY**: the JNDI name, the Java type and the factory class name (all three are required for an entry).
* *RESOURCE_AUTH*: `Application` (or `true`) for `auth="Application"`, otherwise `Container`.
* *RESOURCE_SCOPE*: `Unshareable` (or `true`) for `scope="Unshareable"`, otherwise `Shareable`.
* *RESOURCE_SINGLETON*: the `singleton` attribute (`true`/`false`).
* *RESOURCE_CLOSE_METHOD*: the `closeMethod` attribute, the method called when the resource is released.
* *RESOURCE_DESCRIPTION*: the `description` attribute.

Define docker environment names/values as follows:

~~~ shell
$ docker run -d -p 8080:8080 -e RESOURCE_NAME=mail/Session -e RESOURCE_TYPE=javax.mail.Session -e RESOURCE_FACTORY=your.factory.ClassName -e RESOURCE_AUTH=Application -e DEPLOY_CONTEXT=test-app -v ./webapps/test-app:/usr/local/tomcat/webapps/test-app myquartz/tomcat-xslt:9-jdk11
~~~

It will produce the Context configuration as the file **conf/Catalina/localhost/test-app.xml**:

~~~ xml
<Context>
<Resource name="mail/Session" auth="Container" type="javax.mail.Session" factory="your.factory.ClassName" auth="Application" scope="Shareable" />
</Context>
~~~

#### Context parameters

The ENV variables (comma separated lists, matched by position):

* **PARAMETER_NAME**, **PARAMETER_VALUE**: the parameter name and value (both required for an entry).
* *PARAMETER_OVERRIDE*: `true`/`false`, whether the application's `web.xml` value may override it.
* *PARAMETER_DESCRIPTION*: the description of the parameter.

Define docker parameter names/values as follows:

~~~ shell
$ docker run -d -p 8080:8080 -e PARAMETER_NAME=companyName,companyEmail -e PARAMETER_VALUE="My&#x0020;Company&#x002C;&#x0020;Incorporated,contact@example.com" -e PARAMETER_OVERRIDE=false,false  -e DEPLOY_CONTEXT=test-app -v ./webapps/test-app:/usr/local/tomcat/webapps/test-app myquartz/tomcat-xslt:9-jdk11
~~~

It will produce the Context configuration as the file **conf/Catalina/localhost/test-app.xml**:

~~~ xml
<Context>
<Parameter name="companyName" value="My Company, Incorporated" override="false"/>
<Parameter name="companyEmail" value="contact@example.com" override="false"/>
</Context>
~~~

> Note: `&#x002C;` is the comma (,) and `&#x0020;` is the space in XML.

#### Java EE's Environment entries

The ENV variables (comma separated lists, matched by position):

* **ENVIRONMENT_NAME**, **ENVIRONMENT_VALUE**: the entry name and value (both required for an entry).
* *ENVIRONMENT_TYPE*: the Java type, eg `java.lang.Integer`.
* *ENVIRONMENT_OVERRIDE*: `true`/`false`, whether the application's `web.xml` value may override it.
* *ENVIRONMENT_DESCRIPTION*: the description of the entry.

Define docker environment names/values as follows:

~~~ shell
$ docker run -d -p 8080:8080 -e ENVIRONMENT_NAME=minExemptions,maxExemptions -e ENVIRONMENT_TYPE=java.lang.Integer,java.lang.Integer -e ENVIRONMENT_VALUE=1,10 -e ENVIRONMENT_OVERRIDE=false,true  -e DEPLOY_CONTEXT=test-app -v ./webapps/test-app:/usr/local/tomcat/webapps/test-app myquartz/tomcat-xslt:9-jdk11
~~~

It will produce the Context configuration as the file **conf/Catalina/localhost/test-app.xml**:

~~~ xml
<Context>
<Environment name="minExemptions" value="1"
         type="java.lang.Integer" override="false"/>
<Environment name="maxExemptions" value="10"
         type="java.lang.Integer" override="true"/>
</Context>
~~~

### Context valves

The following valves are added to (or updated in) the context file:

#### Remote address / CIDR filter

* *VALVE_REMOTE_ADDR_ALLOW*, *VALVE_REMOTE_ADDR_DENY*: regular expressions of allowed/denied client IP addresses (`RemoteAddrValve`).
* *VALVE_REMOTE_DENY_STATUS*: the HTTP status returned to denied clients (default 403).
* *VALVE_REMOTE_CONNECTOR_PORT*: `true`/`false`, matches `IP;port` instead of the IP only (`addConnectorPort`).
* *VALVE_REMOTE_CIDR_ALLOW*, *VALVE_REMOTE_CIDR_DENY*: comma separated CIDR lists of allowed/denied clients (`RemoteCIDRValve`), eg `192.168.0.0/16,10.0.0.0/8`.

#### Access log

* **VALVE_ACCESS_LOG_DIR**: the log directory. Setting it enables the valve.
* *VALVE_ACCESS_LOG_PREFIX*, *VALVE_ACCESS_LOG_SUFFIX*: the file name prefix and suffix.
* *VALVE_ACCESS_LOG_ROTATE*: `true`/`false`, whether the log file is rotated daily.
* *VALVE_ACCESS_LOG_PATTERN*: the log pattern.
* *VALVE_ACCESS_LOG_EXTENDED*: `true` to use `ExtendedAccessLogValve`.
* *VALVE_LOG_FOR_CONTEXT*: when set, the access log valve is added to the context and the server-level access log is removed; otherwise it is configured in server.xml.
* *NO_ACCESS_LOG*: when set (any value), the server-level access log valve is removed from server.xml.

#### Error report

* *VALVE_SHOW_ERROR*: `true` to show the error report (stack trace) in error pages (`showReport`); any value enables the valve.
* *VALVE_SHOW_SERVER_INFO*: `true` to show the Tomcat server version in error pages (`showServerInfo`).

### Tomcat Server Cluster

Apache Tomcat also supports a cluster feature for synchronizing session data between Tomcat instances.

To define a cluster, please specify the ENV variable **CLUSTER** to one of two value "DeltaManager" or "BackupManager". Each kind of cluster is documented in the Tomcat manual at https://tomcat.apache.org/tomcat-9.0-doc/config/cluster-manager.html

Once you define either CLUSTER=DeltaManager or CLUSTER=BackupManager, the following ENV variables have to be defined to suit your container environment:

1. **KUBERNETES_NAMESPACE** or **OPENSHIFT_KUBE_PING_NAMESPACE** set to k8s namespace. Tomcat Cluster will detect members automatically without any further configuration.
   > *Note:* all tomcat pods of the same namespace will be added to the cluster, even they are different in deployment or statefulset.
2. **DNS_MEMBERSHIP_SERVICE_NAME** to the DNS name of the running containers (eg CloudMap of AWS ECS); the DNS A records are treated as members automatically. This mode is recommended for Docker Swarm tasks with `endpoint_mode: dnsrr`
3. **REPLICAS** (default mode): number of replicas (from 1 to 6, default to 2) to add cluster members in the `name{number}` format. Your container instance's hostname must end with a number from 1 to 6 (eg. Kubernetes StatefulSets) to use this mode.
   > *Solution:* for the Docker Swarm mode, create service with the parameter `--hostname="{{.Task.Name}}-{{.Task.Slot}}"` to let Docker assign task hostnames ending with the ordinal number. See https://docs.docker.com/engine/swarm/services/ to learn how to set up this kind of hostname in the cluster.
4. *RECEIVE_PORT*: the port for cluster's communication - default to 5002.
5. *REPLICATION_FILTER*: the request patterns that will be filtered out of replication.
6. *CHANNEL_SEND_OPTIONS*: the `channelSendOptions` of the cluster (eg `8` for asynchronous, `6` for synchronous replication).
7. *MCAST_ADDRESS*, *MCAST_PORT*, *MCAST_BIND*: (EXPERIMENTAL) use multicast membership with this address/port, optionally bound to an address.

When a cluster defined, the following element will be added into the Engine element (assuming we setup `CLUSTER=DeltaManager` and `KUBERNETES_NAMESPACE=your-cluster-name`):

~~~ xml
<Engine>
<Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster">
  <Manager className="org.apache.catalina.ha.session.DeltaManager"
	expireSessionsOnShutdown="false" notifyListenersOnReplication="true"/>
  <Channel className="org.apache.catalina.tribes.group.GroupChannel">
    <Membership className="org.apache.catalina.tribes.membership.cloud.CloudMembershipService"
        membershipProviderClassName="kubernetes" />
    <Receiver className="org.apache.catalina.tribes.transport.nio.NioReceiver"
	address="auto" port="${RECEIVE_PORT}" selectorTimeout="100" maxThreads="6">
    </Receiver>
    <Sender className="org.apache.catalina.tribes.transport.ReplicationTransmitter">
      <Transport className="org.apache.catalina.tribes.transport.nio.PooledParallelSender"/>
    </Sender>
    <Interceptor className="org.apache.catalina.tribes.group.interceptors.TcpFailureDetector"/>
    <Interceptor className="org.apache.catalina.tribes.group.interceptors.MessageDispatchInterceptor"/>
    <Interceptor className="org.apache.catalina.tribes.group.interceptors.ThroughputInterceptor"/>
  </Channel>
  <Valve className="org.apache.catalina.ha.tcp.ReplicationValve" filter="${REPLICATION_FILTER}">
  </Valve>
  <ClusterListener className="org.apache.catalina.ha.session.ClusterSessionListener"/>
</Cluster>
<!-- other elements -->
</Engine>
~~~

> For a small cluster whose replicas are not stable (unlike a StatefulSet) - the `CLUSTER=BackupManager` is recommended because the full set of session data is copied to every instance, not just the delta.

### CDI / Jax-RS enabled

To enable CDI support with the Tomcat OWB/CXF modules (Tomcat 9 to 10), set `CDI_ENABLE=yes` or `CDI_ENABLE=true`. The `tomcat-xslt-cdi` images are bundled with the jar libraries that support CDI/CXF web applications. See https://tomcat.apache.org/tomcat-9.0-doc/cdi.html for more details.

When CDI is enabled, in addition to the bundled libraries, the following element is added to the Server element in server.xml:

~~~ xml
<Server>
<Listener className="org.apache.webbeans.web.tomcat.OpenWebBeansListener" optional="true" startWithoutBeansXml="false" />
</Server>
~~~

## Catalina run command line

The original CMD **catalina.sh** of Tomcat will be override by **catalina-xslt.sh**. The catalina-xslt.sh produces context.xml and server.xml according to the defined environment variables, then it executes the original catalina.sh with the same arguments.

For example, to turn on remote debugging of JVM (the jpda debug) for the application war in `./webapps`, we can run `catalina-xslt.sh run jpda`, similar to:

~~~ shell
$ docker run -it --rm -p 8000:8000 -p 8080:8080 -e JPDA_ADDRESS=*:8000 -v ./webapps/test-app.war:/usr/local/tomcat/webapps/test-app.war myquartz/tomcat-xslt:9-jdk11 catalina-xslt.sh run jpda
~~~

then connect to docker-host:8000 by a JPDA debugger.

If you replace the command line back to `catalina.sh run`, you will run the original version of [tomcat container image](https://hub.docker.com/_/tomcat) instead:

~~~ shell
$ docker run -it --rm -p 8000:8000 -p 8080:8080 -e JPDA_ADDRESS=*:8000 -v ./webapps/test-app.war:/usr/local/tomcat/webapps/test-app.war myquartz/tomcat-xslt:9-jdk11 catalina.sh run
~~~

# Run container or build your application image

## Run directly without building

You can run directly a container by defining DEPLOY_CONTEXT and the CONTEXT_DOCBASE, for example:

~~~ shell
docker run -d --rm -p 8080:8080 -p 8443:8443 -e TOMCAT_HTTPS_PORT=8443 -e DEPLOY_CONTEXT=examples -e CONTEXT_DOCBASE=/usr/local/tomcat/webapps.dist/examples -e VALVE_REMOTE_ADDR_ALLOW=.+ myquartz/tomcat-xslt:9-jdk11
~~~

Then browsing: http://localhost:8080/examples or https://localhost:8443/examples for trying the examples of Tomcat. Replacing the docbase path to your mounted volume for the app.

> Note: the environment variable VALVE_REMOTE_ADDR_ALLOW=.+ allowes accessing from any IP Address, because the tomcat only allow 127.0.0.1 or ::1 for local testing but the docker container is deployed to the private network and the browser access to it as a different host IP.

## Your own application image

To build an image for the web application named `booking.war` in the container-based tomcat instance, your application lookup JNDI resource named "jdbc/ds" to access the MySQL Database. you can define a **Dockerfile** as:

~~~ docker
FROM myquartz/tomcat-xslt:9-jdk11

#Download appropriate drivers from Maven
RUN curl -sSo /usr/local/tomcat/lib/mysql-connector-java-8.0.30.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.30/mysql-connector-java-8.0.30.jar
#RUN curl -sSo /usr/local/tomcat/lib/postgresql-42.5.4.jar https://repo1.maven.org/maven2/org/postgresql/postgresql/42.5.4/postgresql-42.5.4.jar

ENV TOMCAT_HTTP_PORT=8088
EXPOSE 8088
 
ENV DEPLOY_CONTEXT=booking
ENV DB_SOURCENAME=jdbc/ds
ENV DB_CLASS=com.mysql.cj.jdbc.Driver
ENV DB_URL=jdbc:mysql://mysqldb:3306/dbname
ENV DB_USERNAME=db_username
ENV DB_PASSWORD=

COPY target/booking.war /usr/local/tomcat/webapps/booking.war
~~~

Build and run the image:

~~~ shell
mvn package
docker build -t booking-app .
docker run -d -p 8088:8088 -e DB_URL=jdbc:mysql://your-db-server-ip:3306/dbname -e DB_USERNAME=you -e DB_PASSWORD=your-password booking-app
~~~

Now open http://localhost:8088/booking for demostration.

## Sample Spring application

Taking the sample at https://www.baeldung.com/spring-persistence-jpa-jndi-datasource. Instead of "Declaring the Datasource on the Application Container" to setup the tomcat instance, you can define the Dockerfile to package your application as container by:

Dockerfile:

~~~ docker
FROM myquartz/tomcat-xslt:9-jdk11

#Download appropriate drivers from Maven
RUN curl -sSo /usr/local/tomcat/lib/postgresql-42.5.4.jar https://repo1.maven.org/maven2/org/postgresql/postgresql/42.5.4/postgresql-42.5.4.jar

ENV TOMCAT_HTTP_PORT=8080
EXPOSE 8080
 
#Using ROOT, optionally
#ENV DEPLOY_CONTEXT=ROOT
ENV GLOBAL_DB_SOURCENAME=jdbc/BaeldungDatabase
ENV DB_CLASS=org.postgresql.Driver
ENV DB_URL=jdbc:postgresql://localhost:5432/postgres
ENV DB_USERNAME=baeldung
ENV DB_PASSWORD=

COPY target/spring-hibernate-5-1.0.0-SNAPSHOT.war /usr/local/tomcat/webapps/ROOT.war
~~~

After setting up the PostgreSQL database, you are going to build and run the image:

~~~ shell
mvn package
docker build -t spring-hibernate-5 .
docker run -d -p 8080:8080 -e DB_URL=jdbc:postgresql://your-db-server-ip:5432/postgres -e DB_USERNAME=baeldung -e DB_PASSWORD=pass1234 \
  -e DB_POOL_MAX=20 -e DB_IDLE_MAX=10 spring-hibernate-5
~~~

Access the URL: http://localhost:8080/ for accessing the application.

---

Let be happy container packaging to the Apache Tomcat.

@MyQuartz

