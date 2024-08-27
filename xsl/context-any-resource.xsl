<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
		
	<xsl:param name="RESOURCE_NAME" />
	<xsl:param name="type_className" />
	<xsl:param name="factory_className" />
	<xsl:param name="auth_Application" />
	<xsl:param name="singleton" />
	<xsl:param name="scope_Unshareable" />
	<xsl:param name="closeMethod_name" />
	<xsl:param name="description" />
	
	<xsl:template match="/">
		<Context>
			<xsl:for-each select="Context/child::*">
				<xsl:choose>
					<xsl:when test="name() = 'Resource' and @name = $RESOURCE_NAME">
						<xsl:call-template name="add_resource" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			<xsl:if test="not(/Context/Resource)">
				<xsl:call-template name="add_resource" />
			</xsl:if>
		</Context>
	</xsl:template>
	
	<xsl:template name="add_resource">
		<Resource>
			<xsl:attribute name="name">
				<xsl:value-of select="$RESOURCE_NAME" />
			</xsl:attribute>
			<xsl:attribute name="type">
				<xsl:value-of select="$type_className" />
			</xsl:attribute>
			<xsl:attribute name="factory">
				<xsl:value-of select="$factory_className" />
			</xsl:attribute>
			<xsl:attribute name="auth">
        <xsl:choose>
					<xsl:when test="'Application' = '$auth_Application' or 'true' = '$auth_Application'">
						Application
					</xsl:when>
					<xsl:otherwise>
						Container
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
      <xsl:attribute name="scope">
        <xsl:choose>
					<xsl:when test="'Unshareable' = '$scope_Unshareable' or 'true' = '$scope_Unshareable'">
						Unshareable
					</xsl:when>
					<xsl:otherwise>
						Shareable
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
      <xsl:if test="'' != '$singleton'">
        <xsl:attribute name="singleton">
  				<xsl:value-of select="$singleton" />
  			</xsl:attribute>
      </xsl:if>
			<xsl:if test="'' != '$closeMethod_name'">
        <xsl:attribute name="closeMethod">
  				<xsl:value-of select="$closeMethod_name" />
  			</xsl:attribute>
      </xsl:if>
      <xsl:if test="'' != '$description'">
        <xsl:attribute name="description">
  				<xsl:value-of select="$description" />
  			</xsl:attribute>
      </xsl:if>
		</Resource>
	</xsl:template>
</xsl:stylesheet>
