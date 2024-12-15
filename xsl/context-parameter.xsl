<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
		
	<xsl:param name="param_name" />
	<xsl:param name="param_value" />
	<xsl:param name="param_override" />
	<xsl:param name="param_description" />
	
	<xsl:template match="/">
		<Context>
			<xsl:copy-of select="/Context/attribute::*" />

			<xsl:for-each select="Context/child::*">
				<xsl:choose>
					<xsl:when test="name() = 'Parameter' and @name = $param_name">
						<xsl:call-template name="add_parameter" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			<xsl:if test="not(/Context/Parameter[@name = $param_name])">
				<xsl:call-template name="add_parameter" />
			</xsl:if>
		</Context>
	</xsl:template>
	
	<xsl:template name="add_parameter">
		<Parameter>
			<xsl:attribute name="name">
				<xsl:value-of select="$param_name" />
			</xsl:attribute>
			<xsl:attribute name="value">
				<xsl:value-of select="$param_value" />
			</xsl:attribute>
      			<xsl:attribute name="override">
        			<xsl:choose>
					<xsl:when test="'true' = $param_override or 'yes' = $param_override">
						<xsl:value-of select="'true'" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="'false'" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
      			<xsl:if test="'' != $param_description">
        			<xsl:attribute name="param_description">
  				<xsl:value-of select="$param_description" />
  				</xsl:attribute>
      			</xsl:if>
		</Parameter>
	</xsl:template>
</xsl:stylesheet>
