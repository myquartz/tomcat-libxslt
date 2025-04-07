<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

	<xsl:param name="TOMCAT_HTTP_PORT" />
	<xsl:param name="TOMCAT_HTTPS_PORT" />
	<xsl:param name="TOMCAT_AJP_PORT" />
	<xsl:param name="TOMCAT_SHUTDOWN_PORT" />
	<xsl:param name="CONNECTOR_PROTOCOL" />
	<xsl:param name="CONNECTOR_REDIRECT_PORT" />
	<xsl:param name="CONNECTOR_URI_ENCODING" />
	<xsl:param name="CONNECTOR_MAX_POST_SIZE" />
	<xsl:param name="CONNECTOR_COMPRESSION" />
	<xsl:param name="CONNECTOR_MIN_SPARE_THREADS" />
	<xsl:param name="CONNECTOR_MAX_SPARE_THREADS" />
	<xsl:param name="CONNECTOR_MAX_THREADS" />

	<!-- HTTPS need JKS for HTTPS config -->
	<xsl:param name="TOMCAT_HTTP2" />
	<xsl:param name="TOMCAT_KEY_STORE" />
	<xsl:param name="TOMCAT_KEY_STORE_PASSWORD" />
	<xsl:param name="TOMCAT_KEY_TYPE" />
  <!-- or using APR -->
	<xsl:param name="TOMCAT_APR_KEY" />
	<xsl:param name="TOMCAT_APR_CERT" />
	<xsl:param name="TOMCAT_APR_CHAIN" />

	<xsl:template match="/">
		<Server>
			<xsl:copy-of select="Server/attribute::*[name() != 'port']" />
			<!-- shutdown port should be configured -->
			<xsl:attribute name="port">
			<xsl:choose>
			<xsl:when test="$TOMCAT_SHUTDOWN_PORT != ''">
					<xsl:value-of select="$TOMCAT_SHUTDOWN_PORT" />
				</xsl:when>
				<xsl:otherwise>8005</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>				

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
								<xsl:when test="@SSLEnabled = 'true' and $TOMCAT_HTTPS_PORT != ''">
									<xsl:value-of select="$TOMCAT_HTTPS_PORT" />
								</xsl:when>
								<xsl:when test="$TOMCAT_HTTP_PORT != '' and not(@protocol = 'AJP/1.3') and not(@SSLEnabled = 'true')">
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
									<xsl:when test="name() = 'redirectPort' and $TOMCAT_HTTPS_PORT != ''">
										<xsl:attribute name="redirectPort">
											<xsl:value-of select="$TOMCAT_HTTPS_PORT" />
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
									<xsl:when test="name() = 'protocol' and $CONNECTOR_PROTOCOL != ''">
										<xsl:attribute name="protocol">
											<xsl:value-of select="$CONNECTOR_PROTOCOL" />
										</xsl:attribute>
									</xsl:when>
									<xsl:when test="name() = 'protocol'">
										<xsl:attribute name="protocol">
											<xsl:value-of select="." />
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
							<xsl:if test="not(@redirectPort) and $CONNECTOR_REDIRECT_PORT = '' and $TOMCAT_HTTPS_PORT != ''">
										<xsl:attribute name="redirectPort">
											<xsl:value-of select="$TOMCAT_HTTPS_PORT" />
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
					
						<!-- add one more HTTPS Connector, if not defined yet -->
						<xsl:if test="($TOMCAT_KEY_STORE != '' or $TOMCAT_APR_KEY != '') and not(following-sibling::Connector) and not(../Connector[@SSLEnabled = 'true'])">
							<Connector SSLEnabled="true" maxHttpHeaderSize="102400">
								<xsl:attribute name="port">
									<xsl:choose>
										<xsl:when test="$TOMCAT_HTTPS_PORT != ''">
											<xsl:value-of select="$TOMCAT_HTTPS_PORT" />
										</xsl:when>
										<xsl:otherwise>8443</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>

								<xsl:attribute name="protocol">
									<xsl:choose>
										<xsl:when test="$CONNECTOR_PROTOCOL != ''">
											<xsl:value-of select="$CONNECTOR_PROTOCOL" />
										</xsl:when>
										<xsl:when test="$TOMCAT_KEY_STORE = '' and $TOMCAT_APR_KEY != ''">org.apache.coyote.http11.Http11AprProtocol</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="../Connector[1]/@protocol" />
										</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>

								<xsl:attribute name="maxThreads">
 									<xsl:choose>
										<xsl:when test="$CONNECTOR_MAX_THREADS != ''">
											<xsl:value-of select="$CONNECTOR_MAX_THREADS" />
										</xsl:when>
										<xsl:otherwise>150</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>

								<!-- copy some attributes from the first Connector -->
								
								<xsl:if test="../Connector[1]/@connectionTimeout != ''">
										<xsl:attribute name="connectionTimeout">
											<xsl:value-of select="../Connector[1]/@connectionTimeout" />
										</xsl:attribute>
								</xsl:if>

								<xsl:if test="../Connector[1]/@maxParameterCount != ''">
										<xsl:attribute name="maxParameterCount">
											<xsl:value-of select="../Connector[1]/@maxParameterCount" />
										</xsl:attribute>
								</xsl:if>

								<xsl:if test="$CONNECTOR_MAX_POST_SIZE != ''">
										<xsl:attribute name="maxPostSize">
											<xsl:value-of select="$CONNECTOR_MAX_POST_SIZE" />
										</xsl:attribute>
								</xsl:if>

								<xsl:if test="$CONNECTOR_REDIRECT_PORT != ''">
										<xsl:attribute name="redirectPort">
											<xsl:value-of select="$CONNECTOR_REDIRECT_PORT" />
										</xsl:attribute>
								</xsl:if>

								<xsl:if test="$CONNECTOR_URI_ENCODING != ''">
										<xsl:attribute name="URIEncoding">
											<xsl:value-of select="$CONNECTOR_URI_ENCODING" />
										</xsl:attribute>
								</xsl:if>

								<xsl:if test="$CONNECTOR_COMPRESSION != ''">
										<xsl:attribute name="compression">
											<xsl:value-of select="$CONNECTOR_COMPRESSION" />
										</xsl:attribute>
								</xsl:if>

								<xsl:if test="$CONNECTOR_MIN_SPARE_THREADS != ''">
										<xsl:attribute name="minSpareThreads">
											<xsl:value-of select="$CONNECTOR_MIN_SPARE_THREADS" />
										</xsl:attribute>
								</xsl:if>

								<xsl:if test="$CONNECTOR_MAX_SPARE_THREADS != ''">
										<xsl:attribute name="maxSpareThreads">
											<xsl:value-of select="$CONNECTOR_MAX_SPARE_THREADS" />
										</xsl:attribute>
								</xsl:if>

								<xsl:if test="$TOMCAT_HTTP2 = 'true'">
									<UpgradeProtocol className="org.apache.coyote.http2.Http2Protocol" />
								</xsl:if>

								<xsl:choose>
								<xsl:when test="$TOMCAT_KEY_STORE != ''">
									<SSLHostConfig>
            				<Certificate>
											<xsl:attribute name="certificateKeystoreFile">
												<xsl:value-of select="$TOMCAT_KEY_STORE" />
											</xsl:attribute>
											<xsl:attribute name="type">
													<xsl:choose>
														<xsl:when test="$TOMCAT_KEY_TYPE != ''">
															<xsl:value-of select="$TOMCAT_KEY_TYPE" />
														</xsl:when>
														<xsl:otherwise>RSA</xsl:otherwise>
													</xsl:choose>
											</xsl:attribute>
											<xsl:if test="$TOMCAT_KEY_STORE_PASSWORD != ''">
												<xsl:attribute name="certificateKeystorePassword">
													<xsl:value-of select="$TOMCAT_KEY_STORE_PASSWORD" />
												</xsl:attribute>
											</xsl:if>
										</Certificate>
        					</SSLHostConfig>
								</xsl:when>
								<xsl:when test="$TOMCAT_KEY_STORE = '' and $TOMCAT_APR_KEY != ''">
									<SSLHostConfig>
            				<Certificate>
											<xsl:attribute name="certificateKeyFile">
												<xsl:value-of select="$TOMCAT_APR_KEY" />
											</xsl:attribute>
											<xsl:attribute name="certificateFile">
												<xsl:value-of select="$TOMCAT_APR_CERT" />
											</xsl:attribute>
											<xsl:if test="$TOMCAT_APR_CHAIN != ''">
												<xsl:attribute name="certificateChainFile">
													<xsl:value-of select="$TOMCAT_APR_CHAIN" />
												</xsl:attribute>
											</xsl:if>
											<xsl:attribute name="type">
													<xsl:choose>
														<xsl:when test="$TOMCAT_KEY_TYPE != ''">
															<xsl:value-of select="$TOMCAT_KEY_TYPE" />
														</xsl:when>
														<xsl:otherwise>RSA</xsl:otherwise>
													</xsl:choose>
											</xsl:attribute>
										</Certificate>
        					</SSLHostConfig>
								</xsl:when>
								</xsl:choose>
							</Connector>
						</xsl:if>
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
