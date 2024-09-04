<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
		
	<xsl:param name="env_name" />
  <xsl:param name="env_type" />
	<xsl:param name="env_value" />
	<xsl:param name="env_override" />
	
	<xsl:template match="/">
		<Context>
			<xsl:for-each select="Context/child::*">
				<xsl:choose>
					<xsl:when test="name() = 'Environment' and @name = $env_name">
						<xsl:call-template name="add_environment" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			<xsl:if test="not(/Context/Environment[@name = $env_name])">
				<xsl:call-template name="add_environment" />
			</xsl:if>
		</Context>
	</xsl:template>
	
	<xsl:template name="add_environment">
		<Environment>
			<xsl:attribute name="name">
				<xsl:value-of select="$env_name" />
			</xsl:attribute>
      <xsl:attribute name="type">
  		  <xsl:value-of select="$env_type" />
  		</xsl:attribute>
			<xsl:attribute name="value">
				<xsl:value-of select="$env_value" />
			</xsl:attribute>
      <xsl:attribute name="override">
        <xsl:choose>
					<xsl:when test="'true' = $env_override or 'yes' = $env_override">
						<xsl:value-of select="'true'" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="'false'" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
		</Environment>
	</xsl:template>
</xsl:stylesheet>
