<?xml version="1.0" encoding="UTF-8"?>
<!-- Adds any number of context Resource entries from comma separated lists matched by position.
     An entry needs a name, a type and a factory; an existing Resource of the same name is replaced in place. -->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

	<xsl:param name="RESOURCE_NAME" />
	<xsl:param name="RESOURCE_TYPE" />
	<xsl:param name="RESOURCE_FACTORY" />
	<xsl:param name="RESOURCE_AUTH" />
	<xsl:param name="RESOURCE_SINGLETON" />
	<xsl:param name="RESOURCE_SCOPE" />
	<xsl:param name="RESOURCE_CLOSE_METHOD" />
	<xsl:param name="RESOURCE_DESCRIPTION" />

	<!-- ",name1,name2," of all complete entries -->
	<xsl:variable name="valid_names">
		<xsl:call-template name="entries">
			<xsl:with-param name="mode" select="'names'" />
			<xsl:with-param name="names" select="$RESOURCE_NAME" />
			<xsl:with-param name="types" select="$RESOURCE_TYPE" />
			<xsl:with-param name="factories" select="$RESOURCE_FACTORY" />
			<xsl:with-param name="auths" select="$RESOURCE_AUTH" />
			<xsl:with-param name="singletons" select="$RESOURCE_SINGLETON" />
			<xsl:with-param name="scopes" select="$RESOURCE_SCOPE" />
			<xsl:with-param name="closes" select="$RESOURCE_CLOSE_METHOD" />
			<xsl:with-param name="descriptions" select="$RESOURCE_DESCRIPTION" />
		</xsl:call-template>
	</xsl:variable>

	<xsl:template match="/">
		<Context>
			<xsl:copy-of select="/Context/attribute::*" />

			<xsl:for-each select="Context/child::*">
				<xsl:choose>
					<xsl:when test="name() = 'Resource' and contains($valid_names, concat(',', normalize-space(@name), ','))">
						<xsl:call-template name="entries">
							<xsl:with-param name="mode" select="'replace'" />
							<xsl:with-param name="filter" select="normalize-space(@name)" />
							<xsl:with-param name="names" select="$RESOURCE_NAME" />
							<xsl:with-param name="types" select="$RESOURCE_TYPE" />
							<xsl:with-param name="factories" select="$RESOURCE_FACTORY" />
							<xsl:with-param name="auths" select="$RESOURCE_AUTH" />
							<xsl:with-param name="singletons" select="$RESOURCE_SINGLETON" />
							<xsl:with-param name="scopes" select="$RESOURCE_SCOPE" />
							<xsl:with-param name="closes" select="$RESOURCE_CLOSE_METHOD" />
							<xsl:with-param name="descriptions" select="$RESOURCE_DESCRIPTION" />
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			<xsl:call-template name="entries">
				<xsl:with-param name="mode" select="'append'" />
				<xsl:with-param name="names" select="$RESOURCE_NAME" />
				<xsl:with-param name="types" select="$RESOURCE_TYPE" />
				<xsl:with-param name="factories" select="$RESOURCE_FACTORY" />
				<xsl:with-param name="auths" select="$RESOURCE_AUTH" />
				<xsl:with-param name="singletons" select="$RESOURCE_SINGLETON" />
				<xsl:with-param name="scopes" select="$RESOURCE_SCOPE" />
				<xsl:with-param name="closes" select="$RESOURCE_CLOSE_METHOD" />
				<xsl:with-param name="descriptions" select="$RESOURCE_DESCRIPTION" />
			</xsl:call-template>
		</Context>
	</xsl:template>

	<!-- mode: names (list valid names), replace (entries named $filter), append (entries not in the Context yet) -->
	<xsl:template name="entries">
		<xsl:param name="mode" />
		<xsl:param name="filter" />
		<xsl:param name="names" />
		<xsl:param name="types" />
		<xsl:param name="factories" />
		<xsl:param name="auths" />
		<xsl:param name="singletons" />
		<xsl:param name="scopes" />
		<xsl:param name="closes" />
		<xsl:param name="descriptions" />
		<xsl:variable name="name">
			<xsl:choose>
				<xsl:when test="contains($names, ',')"><xsl:value-of select="normalize-space(substring-before($names, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($names)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="type">
			<xsl:choose>
				<xsl:when test="contains($types, ',')"><xsl:value-of select="normalize-space(substring-before($types, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($types)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="factory">
			<xsl:choose>
				<xsl:when test="contains($factories, ',')"><xsl:value-of select="normalize-space(substring-before($factories, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($factories)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="auth">
			<xsl:choose>
				<xsl:when test="contains($auths, ',')"><xsl:value-of select="normalize-space(substring-before($auths, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($auths)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="singleton">
			<xsl:choose>
				<xsl:when test="contains($singletons, ',')"><xsl:value-of select="normalize-space(substring-before($singletons, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($singletons)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="scope">
			<xsl:choose>
				<xsl:when test="contains($scopes, ',')"><xsl:value-of select="normalize-space(substring-before($scopes, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($scopes)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="close">
			<xsl:choose>
				<xsl:when test="contains($closes, ',')"><xsl:value-of select="normalize-space(substring-before($closes, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($closes)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="description">
			<xsl:choose>
				<xsl:when test="contains($descriptions, ',')"><xsl:value-of select="normalize-space(substring-before($descriptions, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($descriptions)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$name != '' and $type != '' and $factory != ''">
			<xsl:choose>
				<xsl:when test="$mode = 'names'">
					<xsl:value-of select="concat(',', $name, ',')" />
				</xsl:when>
				<xsl:when test="($mode = 'replace' and $name = $filter)
						or ($mode = 'append' and not(/Context/Resource[normalize-space(@name) = $name]))">
					<Resource name="{$name}" type="{$type}" factory="{$factory}">
						<xsl:attribute name="auth">
							<xsl:choose>
								<xsl:when test="'Application' = $auth or 'true' = $auth">Application</xsl:when>
								<xsl:otherwise>Container</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<xsl:attribute name="scope">
							<xsl:choose>
								<xsl:when test="'Unshareable' = $scope or 'true' = $scope">Unshareable</xsl:when>
								<xsl:otherwise>Shareable</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<xsl:if test="'' != $singleton">
							<xsl:attribute name="singleton"><xsl:value-of select="$singleton" /></xsl:attribute>
						</xsl:if>
						<xsl:if test="'' != $close">
							<xsl:attribute name="closeMethod"><xsl:value-of select="$close" /></xsl:attribute>
						</xsl:if>
						<xsl:if test="'' != $description">
							<xsl:attribute name="description"><xsl:value-of select="$description" /></xsl:attribute>
						</xsl:if>
					</Resource>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="contains($names, ',')">
			<xsl:call-template name="entries">
				<xsl:with-param name="mode" select="$mode" />
				<xsl:with-param name="filter" select="$filter" />
				<xsl:with-param name="names" select="substring-after($names, ',')" />
				<xsl:with-param name="types" select="substring-after($types, ',')" />
				<xsl:with-param name="factories" select="substring-after($factories, ',')" />
				<xsl:with-param name="auths" select="substring-after($auths, ',')" />
				<xsl:with-param name="singletons" select="substring-after($singletons, ',')" />
				<xsl:with-param name="scopes" select="substring-after($scopes, ',')" />
				<xsl:with-param name="closes" select="substring-after($closes, ',')" />
				<xsl:with-param name="descriptions" select="substring-after($descriptions, ',')" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
