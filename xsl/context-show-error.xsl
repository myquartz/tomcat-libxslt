<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
		
	<xsl:param name="show_error" />
	<xsl:param name="show_server_info" />
	
	<xsl:template match="/">
		<Context>
			<xsl:copy-of select="/Context/attribute::*" />

            <xsl:copy-of select="Context/child::*" />

            <xsl:call-template name="add_valve" />
		</Context>
	</xsl:template>
	
	<xsl:template name="add_valve">
		<Valve className="org.apache.catalina.valves.ErrorReportValve">
            <xsl:if test="'true' = $show_error">
                <xsl:attribute name="showReport">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="'true' = $show_server_info">
                <xsl:attribute name="showServerInfo">true</xsl:attribute>
            </xsl:if>
		</Valve>
	</xsl:template>
</xsl:stylesheet>
