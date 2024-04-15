<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

	<xsl:param name="CDI_ENABLE" />

	<xsl:template match="/">
		<Server>
			<xsl:for-each select="Server/attribute::*">
				<xsl:copy-of select="." />
			</xsl:for-each>
			
			<xsl:copy-of select="Server/Listener" />
			<xsl:if test="$CDI_ENABLE = 'yes' or $CDI_ENABLE = 'true'">
			<Listener className="org.apache.webbeans.web.tomcat.OpenWebBeansListener" optional="true" startWithoutBeansXml="false" />
			</xsl:if>
			<xsl:copy-of select="Server/GlobalNamingResources" />
			
			<xsl:copy-of select="Server/Service" />
		</Server>
	</xsl:template>

</xsl:stylesheet>
