<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

	<xsl:param name="TOMCAT_HTTP_PORT" />
	<xsl:param name="TOMCAT_HTTPS_PORT" />
	<xsl:param name="TOMCAT_AJP_PORT" />
	<xsl:param name="CONNECTOR_MAX_THREADS" />

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
					<xsl:when test="name() = 'Connector'">
						<Connector>
						<xsl:attribute name="port">
							<xsl:choose>
								<xsl:when test="@protocol = 'AJP/1.3' and $TOMCAT_AJP_PORT != ''">
									<xsl:value-of select="$TOMCAT_AJP_PORT" />
								</xsl:when>
								<xsl:when test="boolean(@SSLEnabled) and @SSLEnabled != '' and $TOMCAT_HTTPS_PORT != ''">
									<xsl:value-of select="$TOMCAT_HTTPS_PORT" />
								</xsl:when>
								<xsl:when test="@protocol != 'AJP/1.3' and not(@SSLEnabled) and $TOMCAT_HTTP_PORT != ''">
									<xsl:value-of select="$TOMCAT_HTTP_PORT" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="@port" />
								</xsl:otherwise>
							</xsl:choose>
					  </xsl:attribute>				
							<xsl:for-each select="./attribute::*">
								<xsl:choose>
									<xsl:when test="name() = 'maxThreads' and $CONNECTOR_MAX_THREADS != ''">
										<xsl:attribute name="maxThreads">
											<xsl:value-of select="$CONNECTOR_MAX_THREADS" />
										</xsl:attribute>
									</xsl:when>
									<xsl:when test="name() != 'port'">
										<xsl:copy-of select="." />
									</xsl:when>
								</xsl:choose>
							</xsl:for-each>
							<xsl:if test="not(@maxThreads) and $CONNECTOR_MAX_THREADS != ''">
										<xsl:attribute name="maxThreads">
											<xsl:value-of select="$CONNECTOR_MAX_THREADS" />
										</xsl:attribute>
							</xsl:if>

							<xsl:copy-of select="./child::*" />
						</Connector>
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
