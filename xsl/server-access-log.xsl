<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

	<xsl:param name="access_log_remove" />
	<xsl:param name="access_log_dir" />
	<xsl:param name="access_log_prefix" />
    <xsl:param name="access_log_suffix" />
    <xsl:param name="access_log_rotate" />
    <xsl:param name="access_log_extended" />
    <xsl:param name="access_log_pattern" />

	<xsl:template match="/">
		<Server>
			<xsl:copy-of select="Server/attribute::*" />
			
			<xsl:copy-of select="Server/child::*[name() != 'Service']" />
			
            <Service>
                <xsl:copy-of select="Server/Service/attribute::*" />
			    
                <xsl:copy-of select="Server/Service/child::*[name() != 'Engine']" />

                <Engine>
                    <xsl:copy-of select="Server/Service/Engine/attribute::*" />

                    <xsl:copy-of select="Server/Service/Engine/child::*[name() != 'Host']" />

                    <Host>
                        <xsl:copy-of select="Server/Service/Engine/Host/attribute::*" />

                        <xsl:copy-of select="Server/Service/Engine/Host/child::*[name() != 'Valve']" />
                        
                        <xsl:copy-of select="Server/Service/Engine/Host/Valve[not(@className='org.apache.catalina.valves.AccessLogValve' or @className='org.apache.catalina.valves.ExtendedAccessLogValve')]" />

                        <xsl:if test="$access_log_remove != 'true'">
                            <xsl:call-template name="add_valve" />
                        </xsl:if>
                    </Host>
                </Engine>
            </Service>
		</Server>
	</xsl:template>

    <xsl:template name="add_valve">
		<Valve>
            <xsl:choose>
                <xsl:when test="$access_log_extended = 'true'">
                    <xsl:attribute name="className">org.apache.catalina.valves.ExtendedAccessLogValve</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="className">org.apache.catalina.valves.AccessLogValve</xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:attribute name="directory">
                <xsl:value-of select="$access_log_dir" />
            </xsl:attribute>

            <xsl:if test="'' != $access_log_prefix">
                <xsl:attribute name="prefix">
                    <xsl:value-of select="$access_log_prefix" />
                </xsl:attribute>
            </xsl:if>

            <xsl:if test="'' != $access_log_suffix">
                <xsl:attribute name="suffix">
                    <xsl:value-of select="$access_log_suffix" />
                </xsl:attribute>
            </xsl:if>

            <xsl:if test="'true' = $access_log_rotate">
                <xsl:attribute name="rotatable">true</xsl:attribute>
            </xsl:if>
            <xsl:if test="'false' = $access_log_rotate">
                <xsl:attribute name="rotatable">false</xsl:attribute>
            </xsl:if>

            <xsl:if test="'' != $access_log_pattern">
                <xsl:attribute name="pattern">
                    <xsl:value-of select="$access_log_pattern" />
                </xsl:attribute>
            </xsl:if>
		</Valve>
	</xsl:template>

</xsl:stylesheet>
