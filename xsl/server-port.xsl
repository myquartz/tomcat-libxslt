<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

	<xsl:param name="TOMCAT_HTTP_PORT" />
	<xsl:param name="TOMCAT_HTTPS_PORT" />
	<xsl:param name="TOMCAT_AJP_PORT" />
	<xsl:param name="CONNECTOR_REDIRECT_PORT" />
	<xsl:param name="CONNECTOR_URI_ENCODING" />
	<xsl:param name="CONNECTOR_MAX_POST_SIZE" />
	<xsl:param name="CONNECTOR_COMPRESSION" />
	<xsl:param name="CONNECTOR_MIN_SPARE_THREADS" />
	<xsl:param name="CONNECTOR_MAX_SPARE_THREADS" />
	<xsl:param name="CONNECTOR_MAX_THREADS" />

	<xsl:template match="/">
		<Server>
			<xsl:copy-of select="Server/attribute::*" />
			
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
									<xsl:when test="name() = 'maxPostSize' and $CONNECTOR_MAX_POST_SIZE != ''">
										<xsl:attribute name="maxPostSize">
											<xsl:value-of select="$CONNECTOR_MAX_POST_SIZE" />
										</xsl:attribute>
									</xsl:when>
									<xsl:when test="name() = 'redirectPort' and $CONNECTOR_REDIRECT_PORT != ''">
										<xsl:attribute name="redirectPort">
											<xsl:value-of select="$CONNECTOR_REDIRECT_PORT" />
										</xsl:attribute>
									</xsl:when>
									<xsl:when test="name() = 'URIEncoding' and $CONNECTOR_URI_ENCODING != ''">
										<xsl:attribute name="URIEncoding">
											<xsl:value-of select="$CONNECTOR_URI_ENCODING" />
										</xsl:attribute>
									</xsl:when>
									<xsl:when test="name() = 'compression' and $CONNECTOR_COMPRESSION != ''">
										<xsl:attribute name="compression">
											<xsl:value-of select="$CONNECTOR_COMPRESSION" />
										</xsl:attribute>
									</xsl:when>
									<xsl:when test="name() = 'minSpareThreads' and $CONNECTOR_MIN_SPARE_THREADS != ''">
										<xsl:attribute name="minSpareThreads">
											<xsl:value-of select="$CONNECTOR_MIN_SPARE_THREADS" />
										</xsl:attribute>
									</xsl:when>
									<xsl:when test="name() = 'maxSpareThreads' and $CONNECTOR_MAX_SPARE_THREADS != ''">
										<xsl:attribute name="maxSpareThreads">
											<xsl:value-of select="$CONNECTOR_MAX_SPARE_THREADS" />
										</xsl:attribute>
									</xsl:when>
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

							<xsl:if test="not(@maxPostSize) and $CONNECTOR_MAX_POST_SIZE != ''">
										<xsl:attribute name="maxPostSize">
											<xsl:value-of select="$CONNECTOR_MAX_POST_SIZE" />
										</xsl:attribute>
							</xsl:if>

							<xsl:if test="not(@redirectPort) and $CONNECTOR_REDIRECT_PORT != ''">
										<xsl:attribute name="redirectPort">
											<xsl:value-of select="$CONNECTOR_REDIRECT_PORT" />
										</xsl:attribute>
							</xsl:if>

							<xsl:if test="not(@URIEncoding) and $CONNECTOR_URI_ENCODING != ''">
										<xsl:attribute name="URIEncoding">
											<xsl:value-of select="$CONNECTOR_URI_ENCODING" />
										</xsl:attribute>
							</xsl:if>

							<xsl:if test="not(@compression) and $CONNECTOR_COMPRESSION != ''">
										<xsl:attribute name="compression">
											<xsl:value-of select="$CONNECTOR_COMPRESSION" />
										</xsl:attribute>
							</xsl:if>

							<xsl:if test="not(@minSpareThreads) and $CONNECTOR_MIN_SPARE_THREADS != ''">
										<xsl:attribute name="minSpareThreads">
											<xsl:value-of select="$CONNECTOR_MIN_SPARE_THREADS" />
										</xsl:attribute>
							</xsl:if>

							<xsl:if test="not(@maxSpareThreads) and $CONNECTOR_MAX_SPARE_THREADS != ''">
										<xsl:attribute name="maxSpareThreads">
											<xsl:value-of select="$CONNECTOR_MAX_SPARE_THREADS" />
										</xsl:attribute>
							</xsl:if>

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
