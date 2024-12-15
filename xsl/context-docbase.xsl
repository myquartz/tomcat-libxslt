<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
		
	<xsl:param name="context_docbase" />
    <xsl:param name="context_path" />
	
    <xsl:template match="/">
        <xsl:apply-templates select="/Context" />
    </xsl:template>

	<xsl:template match="/Context">
		<Context>
            <xsl:copy-of select="attribute::*[name() != 'docBase' and name() != 'path']" />

            <xsl:attribute name="docBase">
                <xsl:value-of select="$context_docbase" />
            </xsl:attribute>
            
            <xsl:if test="$context_path != ''">
                <xsl:attribute name="path">
                    <xsl:value-of select="$context_path" />
                </xsl:attribute>
            </xsl:if>
			
			<xsl:copy-of select="child::*" />
		</Context>
	</xsl:template>
	
</xsl:stylesheet>
