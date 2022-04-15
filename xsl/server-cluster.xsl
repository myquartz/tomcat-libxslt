<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

	<xsl:param name="CHANNEL_SEND_OPTIONS" />
	<xsl:param name="CLUSTER" />
	<xsl:param name="MCAST_ADDRESS" />
	<xsl:param name="MCAST_PORT" />
	<xsl:param name="MCAST_BIND" />
	<xsl:param name="RECEIVE_PORT" />
	<xsl:param name="REPLICATION_FILTER" />
	<xsl:param name="LOCAL_DS" />
	<xsl:param name="ALL_ROLES_MODE" />

	<xsl:template match="/">
		<Server>
			<xsl:for-each select="Server/attribute::*">
				<xsl:copy-of select="." />
			</xsl:for-each>
			
			<xsl:copy-of select="Server/Listener" />
			<xsl:copy-of select="Server/GlobalNamingResources" />
			
			<Service>
			<xsl:for-each select="Server/Service/attribute::*">
				<xsl:copy-of select="." />
			</xsl:for-each>
			<xsl:for-each select="Server/Service/child::*">
				<xsl:choose>
					<xsl:when test="name() = 'Engine'">
						<Engine>
							<xsl:copy-of select="attribute::*" />
							<Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster">
								<xsl:if
									test="boolean($CHANNEL_SEND_OPTIONS) and $CHANNEL_SEND_OPTIONS != ''">
									<xsl:attribute name="channelSendOptions">
										<xsl:value-of select="$CHANNEL_SEND_OPTIONS" />
									</xsl:attribute>
								</xsl:if>
								
								<xsl:choose>
									<xsl:when test="$CLUSTER = 'BackupManager'">
										<Manager className="org.apache.catalina.ha.session.BackupManager"
										   expireSessionsOnShutdown="false"
										   notifyListenersOnReplication="true"
										   mapSendOptions="6"/>
									</xsl:when>
									<xsl:when test="$CLUSTER = 'DeltaManager'">
										<Manager className="org.apache.catalina.ha.session.DeltaManager"
										   expireSessionsOnShutdown="false"
										   notifyListenersOnReplication="true"/>
									</xsl:when>
								</xsl:choose>
								
							    <Channel className="org.apache.catalina.tribes.group.GroupChannel">
									<Membership className="org.apache.catalina.tribes.membership.McastService"
										frequency="500"
										dropTime="3000">
										<xsl:attribute name="address">
											<xsl:value-of select="$MCAST_ADDRESS" />
										</xsl:attribute>
										<xsl:attribute name="port">
											<xsl:value-of select="$MCAST_PORT" />
										</xsl:attribute>
										<xsl:if test="boolean($MCAST_BIND) and $MCAST_BIND != ''">
                     <xsl:attribute name="bind">
											<xsl:value-of select="$MCAST_BIND" />
										</xsl:attribute>
										</xsl:if>
									</Membership>
									<Receiver className="org.apache.catalina.tribes.transport.nio.NioReceiver"
										address="auto"
										selectorTimeout="100"
										maxThreads="6">
										<xsl:attribute name="port">
											<xsl:value-of select="$RECEIVE_PORT" />
										</xsl:attribute>
									</Receiver>

									<Sender className="org.apache.catalina.tribes.transport.ReplicationTransmitter">
									  <Transport className="org.apache.catalina.tribes.transport.nio.PooledParallelSender"/>
									</Sender>
									<Interceptor className="org.apache.catalina.tribes.group.interceptors.TcpFailureDetector"/>
									<Interceptor className="org.apache.catalina.tribes.group.interceptors.MessageDispatchInterceptor"/>
									<Interceptor className="org.apache.catalina.tribes.group.interceptors.ThroughputInterceptor"/>
							    </Channel>

							    <Valve className="org.apache.catalina.ha.tcp.ReplicationValve"
									filter="">
									<xsl:choose>
										<xsl:when test="boolean($REPLICATION_FILTER) and $REPLICATION_FILTER != ''">
											<xsl:attribute name="filter">
											<xsl:value-of select="$REPLICATION_FILTER" />
											</xsl:attribute>
										</xsl:when>
										<xsl:otherwise>
											<xsl:attribute name="filter">
											<xsl:value-of select="'.*\.gif|.*\.js|.*\.jpeg|.*\.jpg|.*\.png|.*\.htm|.*\.html|.*\.css|.*\.txt'" />
											</xsl:attribute>
										</xsl:otherwise>
									</xsl:choose>
								</Valve>

								<ClusterListener className="org.apache.catalina.ha.session.ClusterSessionListener"/>
							</Cluster>
							
							<xsl:copy-of select="./child::*" />
						</Engine>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			</Service>
		</Server>
	</xsl:template>
</xsl:stylesheet>
