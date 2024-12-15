<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
		
	<xsl:param name="remote_addr_allow" />
	<xsl:param name="remote_addr_deny" />
	<xsl:param name="deny_status" />
	<xsl:param name="remote_connector_port" />
	
	<xsl:template match="/">
		<Context>
			<xsl:copy-of select="/Context/attribute::*" />

            <xsl:for-each select="Context/child::*">
				<xsl:choose>
					<xsl:when test="name() = 'Valve' and @className='org.apache.catalina.valves.RemoteAddrValve'">
						<xsl:call-template name="add_valve" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			<xsl:if test="not(/Context/Valve[@className='org.apache.catalina.valves.RemoteAddrValve'])">
				<xsl:call-template name="add_valve" />
			</xsl:if>
		</Context>
	</xsl:template>
	
	<xsl:template name="add_valve">
		<Valve className="org.apache.catalina.valves.RemoteAddrValve">
            <xsl:if test="'' != $remote_addr_allow">
                <xsl:attribute name="allow">
                    <xsl:value-of select="$remote_addr_allow" />
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="'' != $remote_addr_deny">
                <xsl:attribute name="deny">
                    <xsl:value-of select="$remote_addr_deny" />
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="'' != $deny_status">
                <xsl:attribute name="denyStatus">
                    <xsl:value-of select="$deny_status" />
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="'true' = $remote_connector_port">
                <xsl:attribute name="addConnectorPort">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="'false' = $remote_connector_port">
                <xsl:attribute name="addConnectorPort">false</xsl:attribute>
            </xsl:if>
		</Valve>
	</xsl:template>
</xsl:stylesheet>
