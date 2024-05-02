# The tomcat-libxslt container build

This contains building scripts for Apache Tomcat with LibXSLT for XML configuration mangling. Supported Tomcat versions:

  1. Tomcat 8.5 with JDK 8, 11
  2. Tomcat 9 with JDK 11, 17
  3. Tomcat 10.0, 10.1 with JDK 11, 17, without or with CDI and CXF modules compiled.
  4. AMD64 and ARM64/v8 platform support.

# Supported features

1. Context-based: the startup script will create the context-deployed "conf/Catalina/localhost/application.xml" file for application.war.
2. Global resource: the startup script will update conf/server.xml into <GlobalNamingResources /> for the resource.

For context-based deployment, an ENV named **DEPLOY_CONTEXT** has to be defined to indicate your **application**.war name. If not, ROOT.war assumed.

## HTTP/HTTPS/AJP Ports

You can change the listening port of the tomcat instance by the following ENV variables:

1. TOMCAT_HTTP_PORT: the HTTP port - default to 8080 - changing to <Connector /> element in the server.xml.
2. TOMCAT_HTTPS_PORT: the HTTPS port - default to empty - changing to <Connector of SSL /> element in the server.xml (no keystore yet).
3. TOMCAT_AJP_PORT: the AJP port - default to 8009 - changing to <Connector /> element in the server.xml.
4. CONNECTOR_MAX_THREADS: maximum threads of the connector.

## Data Source

A context-based data source or a global-based data source will be added to context.xml or server.xml accordingly, based-on enviroment variables.

The following ENV variables to define a data source:

* **DB_SOURCENAME** (context-based) or **GLOBAL_DB_SOURCENAME** (global): the data source name to create, eg: jdbc/data_source
* **DB_CLASS**: the class name of JDBC Driver, eg: org.h2.Driver or com.mysql.cj.jdbc.Driver
* **DB_URL**: the JDBC URL for the data source, eg: jdbc:h2:mem:test or jdbc:mysql:server:port/dbname
* *DB_USERNAME*: the username for connection to the database.
* *DB_PASSWORD* or *DB_PASSWORD_FILE*: the password or the file contains the password for database connection
* DB_POOL_MAX: maximum connections of the pool - 50 by default
* DB_POOL_INIT: initial connections when starting the data source - 0 by default
* DB_IDLE_MAX: idle connections
* DB_VALIDATION_QUERY: the query for connection validation, empty by default.

When defining these parameters (bold name must have), the <Resource /> will be created/updated to context.xml or server.xml look like:

~~~ xml
<Resource
  auth="Container" 
  type="javax.sql.DataSource" 
  factory="org.apache.tomcat.jdbc.pool.DataSourceFactory" 
  minIdle="0"
  name="${DB_SOURCENAME} or ${GLOBAL_DB_SOURCENAME}" driverClassName="${DB_CLASS}"
  url="${DB_URL}" username="${DB_USERNAME}" password="${DB_PASSWORD}"
  maxActive="${DB_POOL_MAX}" initialSize="${DB_POOL_INIT}" maxIdle="${DB_IDLE_MAX}"
  validationQuery="${DB_VALIDATION_QUERY}" />
~~~

## Data Source Realm

This Realms is for Servlet/Application authentication by a table hosting at the data source.
If a context-based/global data source created, the realm will be set to context-based or global/context DB_SOURCENAME accordingly.

The following ENV variables to define the realm:

* **REALM_USERTAB**: the table name defines users' data.
* **REALM_ROLETAB**: the table name defines users' role data.
* *REALM_USERCOL*: the column name of username (default to *username*).
* *REALM_CREDCOL*: the column name of hassed password (default to hashpassword). More detail of hashed password is at https://tomcat.apache.org/tomcat-9.0-doc/config/credentialhandler.html)
* *REALM_ROLECOL*: the column name of an user's role.
* *ALL_ROLES_MODE*: the value of attribute "allRolesMode", one of value 'strict' or 'authOnly' or 'strictAuthOnly'.
* *REALM_ALGORITHM*: the algorithm for hashing password, default to SHA-512, it can be SHA-1, SHA-256.. the hashpassword column is formatted by Tomcat value.
* *REALM_INTERATIONS*: the interation count for hashing password, it should be 1.
* *REALM_SALT_LENGTH*: the length of salt value.
* *REALM_ENCODING*: character encoding (eg UTF-8) while hashing.

When defining these parameters, the <Resource /> will be created/updated to context.xml or server.xml look like:

~~~ xml
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
~~~

## LDAP Realm

This Realms is for Servlet/Application authentication by a LDAP server.
The realm will be set to context-based or global/context depending on LDAP_URL or GLOBAL_LDAP_URL defined.

The following ENV variables to define the realm:

* **LDAP_URL** or **GLOBAL_LDAP_URL**: the LDAP URL, eg ldap://hostname:port
* *LDAP_ALT_URL*: alternative LDAP URL (when the main is not available).
* *LDAP_BIND*: the bind DN for lookup authentication
* *LDAP_BIND_PASSWORD* or *LDAP_BIND_PASSWORD_FILE*: the password or the file contains the password for binding LDAP
* *LDAP_USER_BASEDN*: the user based DN for lookup user.
* *LDAP_USER_SEARCH*: the user search string, replace {0} for user object search (eg uid={0})
* *LDAP_USER_PASSWD_ATTR*: the password attribute name (in Comparison mode only).
* *LDAP_SEARCHASUSER*: boolean value, `true` value indicates that search as the authenticated user.
* *LDAP_USER_SUBTREE*: `true` value indicates that sub tree users searching (one level)
* *LDAP_USER_PATTERN*: the DN template for binding mode authentication (eg uid={0},ou=people,dc=mycompany,dc=com)
* *LDAP_GROUP_BASEDN*: the base of group search DN `(eg ou=groups,dc=mycompany,dc=com)`
* *LDAP_GROUP_SEARCH*: the group search string, (eg `(uniqueMember={0})`, replacing {0} {1} {2} to user's DN, username and user attribute)
* *LDAP_GROUP_SUBTREE*: `true` value indicates that sub tree of roles searching 
* *LDAP_GROUP_ATTR*: the group attribute name of the group name (== role name in the servlet context).
* *AD_COMPAT*: Active Directory compatible
* *COMMON_ROLE*: the common role (an user without any role).
* *ALL_ROLES_MODE*: the value of attribute "allRolesMode", one of value 'strict' or 'authOnly' or 'strictAuthOnly'.

## Tomcat Cluster

The Apache Tomcat additional supports Cluster feature for synchronization of session data between the tomcat instances.

To define a cluster, please specify the ENV variable **CLUSTER** to one of two value "DeltaManager" or "BackupManager". Each kinds of cluster are documented by Tomcat manual at https://tomcat.apache.org/tomcat-9.0-doc/config/cluster-manager.html

Once you define either CLUSTER=DeltaManager or CLUSTER=BackupManager, the following ENV variables have to be defined to adapt with your container enviroment:

1. **KUBERNETES_NAMESPACE** or **OPENSHIFT_KUBE_PING_NAMESPACE** set to k8s namespace. Tomcat Cluster will detect member automatically without any further configuration.
2. **DNS_MEMBERSHIP_SERVICE_NAME** to DNS name of the containers running (eg CloudMap of AWS ECS), the DNS A records will be treated as members automatically.
3. **REPLICAS** (default mode): number of replicas (from 1 to 6, default to 2) if you running by docker swarm and your container instance's hostname end with number from 1 to 6, you can use this mode. See the link to know how plus using `--hostname="tomcat-{{.Task.Slot}}"` to setup this kind of the cluster: https://docs.docker.com/engine/swarm/services/

## CDI / CXF enable

To enable CDI support by Tomcat OWB/Jax-RS modules (from verion 9 to 10), you can set CDI_ENABLE=yes or CDI_ENABLE=true. The base name of image are `tomcat-xslt-cdi:tag` are bundle with jar library that support CDI web application. See https://tomcat.apache.org/tomcat-9.0-doc/cdi.html for more detail.

# The prebuilt images

You can find prebuilt images at https://hub.docker.com/repository/docker/myquartz/tomcat-xslt/general (without CDI) or https://hub.docker.com/repository/docker/myquartz/tomcat-xslt-cdi/general (Tomcat 9 or Tomcat 10 with CDI support). I update them some weeks regularity.

# Build your application image

## Your own application

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
Let be happy container packaging
@MyQuartz

