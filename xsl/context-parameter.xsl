<?xml version="1.0" encoding="UTF-8"?>
<!-- Adds any number of context Parameter entries from comma separated lists matched by position.
     An entry needs both a name and a value; an existing Parameter of the same name is replaced in place. -->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

	<xsl:param name="PARAMETER_NAME" />
	<xsl:param name="PARAMETER_VALUE" />
	<xsl:param name="PARAMETER_OVERRIDE" />
	<xsl:param name="PARAMETER_DESCRIPTION" />

	<!-- ",name1,name2," of all complete entries -->
	<xsl:variable name="valid_names">
		<xsl:call-template name="entries">
			<xsl:with-param name="mode" select="'names'" />
			<xsl:with-param name="names" select="$PARAMETER_NAME" />
			<xsl:with-param name="values" select="$PARAMETER_VALUE" />
			<xsl:with-param name="overrides" select="$PARAMETER_OVERRIDE" />
			<xsl:with-param name="descriptions" select="$PARAMETER_DESCRIPTION" />
		</xsl:call-template>
	</xsl:variable>

	<xsl:template match="/">
		<Context>
			<xsl:copy-of select="/Context/attribute::*" />

			<xsl:for-each select="Context/child::*">
				<xsl:choose>
					<xsl:when test="name() = 'Parameter' and contains($valid_names, concat(',', normalize-space(@name), ','))">
						<xsl:call-template name="entries">
							<xsl:with-param name="mode" select="'replace'" />
							<xsl:with-param name="filter" select="normalize-space(@name)" />
							<xsl:with-param name="names" select="$PARAMETER_NAME" />
							<xsl:with-param name="values" select="$PARAMETER_VALUE" />
							<xsl:with-param name="overrides" select="$PARAMETER_OVERRIDE" />
							<xsl:with-param name="descriptions" select="$PARAMETER_DESCRIPTION" />
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			<xsl:call-template name="entries">
				<xsl:with-param name="mode" select="'append'" />
				<xsl:with-param name="names" select="$PARAMETER_NAME" />
				<xsl:with-param name="values" select="$PARAMETER_VALUE" />
				<xsl:with-param name="overrides" select="$PARAMETER_OVERRIDE" />
				<xsl:with-param name="descriptions" select="$PARAMETER_DESCRIPTION" />
			</xsl:call-template>
		</Context>
	</xsl:template>

	<!-- mode: names (list valid names), replace (entries named $filter), append (entries not in the Context yet) -->
	<xsl:template name="entries">
		<xsl:param name="mode" />
		<xsl:param name="filter" />
		<xsl:param name="names" />
		<xsl:param name="values" />
		<xsl:param name="overrides" />
		<xsl:param name="descriptions" />
		<xsl:variable name="name">
			<xsl:choose>
				<xsl:when test="contains($names, ',')"><xsl:value-of select="normalize-space(substring-before($names, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($names)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="value">
			<xsl:choose>
				<xsl:when test="contains($values, ',')"><xsl:value-of select="substring-before($values, ',')" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="$values" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="override">
			<xsl:choose>
				<xsl:when test="contains($overrides, ',')"><xsl:value-of select="normalize-space(substring-before($overrides, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($overrides)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="description">
			<xsl:choose>
				<xsl:when test="contains($descriptions, ',')"><xsl:value-of select="normalize-space(substring-before($descriptions, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($descriptions)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$name != '' and $value != ''">
			<xsl:choose>
				<xsl:when test="$mode = 'names'">
					<xsl:value-of select="concat(',', $name, ',')" />
				</xsl:when>
				<xsl:when test="($mode = 'replace' and $name = $filter)
						or ($mode = 'append' and not(/Context/Parameter[normalize-space(@name) = $name]))">
					<Parameter name="{$name}" value="{$value}">
						<xsl:attribute name="override">
							<xsl:choose>
								<xsl:when test="'true' = $override or 'yes' = $override">true</xsl:when>
								<xsl:otherwise>false</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<xsl:if test="'' != $description">
							<xsl:attribute name="description"><xsl:value-of select="$description" /></xsl:attribute>
						</xsl:if>
					</Parameter>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="contains($names, ',')">
			<xsl:call-template name="entries">
				<xsl:with-param name="mode" select="$mode" />
				<xsl:with-param name="filter" select="$filter" />
				<xsl:with-param name="names" select="substring-after($names, ',')" />
				<xsl:with-param name="values" select="substring-after($values, ',')" />
				<xsl:with-param name="overrides" select="substring-after($overrides, ',')" />
				<xsl:with-param name="descriptions" select="substring-after($descriptions, ',')" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
