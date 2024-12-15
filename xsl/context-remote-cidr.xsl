<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
		
	<xsl:param name="remote_cidr_allow" />
	<xsl:param name="remote_cidr_deny" />
	
	<xsl:template match="/">
		<Context>
			<xsl:copy-of select="/Context/attribute::*" />

            <xsl:for-each select="Context/child::*">
				<xsl:choose>
					<xsl:when test="name() = 'Valve' and @className='org.apache.catalina.valves.RemoteCIDRValve'">
						<xsl:call-template name="add_valve" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			<xsl:if test="not(/Context/Valve[@className='org.apache.catalina.valves.RemoteCIDRValve'])">
				<xsl:call-template name="add_valve" />
			</xsl:if>
		</Context>
	</xsl:template>
	
	<xsl:template name="add_valve">
		<Valve className="org.apache.catalina.valves.RemoteCIDRValve">
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
		</Valve>
	</xsl:template>
</xsl:stylesheet>
