<?xml version="1.0" encoding="UTF-8"?>
<!-- Adds roles and users into tomcat-users.xml (UserDatabase). Existing content is preserved;
     a later <user> with the same username overrides the earlier one in Tomcat. -->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

	<!-- comma separated lists; TOMCAT_USERS_ROLES uses ':' between roles of one user -->
	<xsl:param name="TOMCAT_ROLES" />
	<xsl:param name="TOMCAT_USERS" />
	<xsl:param name="TOMCAT_USERS_ROLES" />
	<xsl:param name="TOMCAT_USERS_PASSWORD" />

	<xsl:variable name="ns" select="namespace-uri(/*)" />

	<xsl:template match="/*">
		<xsl:copy>
			<xsl:copy-of select="@*" />
			<xsl:copy-of select="node()" />
			<xsl:if test="normalize-space($TOMCAT_ROLES) != ''">
				<xsl:call-template name="add_roles">
					<xsl:with-param name="list" select="$TOMCAT_ROLES" />
				</xsl:call-template>
				<xsl:call-template name="add_users">
					<xsl:with-param name="users" select="$TOMCAT_USERS" />
					<xsl:with-param name="roles" select="$TOMCAT_USERS_ROLES" />
					<xsl:with-param name="passwords" select="$TOMCAT_USERS_PASSWORD" />
				</xsl:call-template>
			</xsl:if>
		</xsl:copy>
	</xsl:template>

	<xsl:template name="add_roles">
		<xsl:param name="list" />
		<xsl:variable name="first">
			<xsl:choose>
				<xsl:when test="contains($list, ',')"><xsl:value-of select="normalize-space(substring-before($list, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($list)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$first != '' and not(/*/*[local-name()='role'][@rolename = $first])">
			<xsl:element name="role" namespace="{$ns}">
				<xsl:attribute name="rolename"><xsl:value-of select="$first" /></xsl:attribute>
			</xsl:element>
		</xsl:if>
		<xsl:if test="contains($list, ',')">
			<xsl:call-template name="add_roles">
				<xsl:with-param name="list" select="substring-after($list, ',')" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template name="add_users">
		<xsl:param name="users" />
		<xsl:param name="roles" />
		<xsl:param name="passwords" />
		<xsl:variable name="user">
			<xsl:choose>
				<xsl:when test="contains($users, ',')"><xsl:value-of select="normalize-space(substring-before($users, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($users)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="userroles">
			<xsl:choose>
				<xsl:when test="contains($roles, ',')"><xsl:value-of select="normalize-space(substring-before($roles, ','))" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space($roles)" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- password is used as-is -->
		<xsl:variable name="password">
			<xsl:choose>
				<xsl:when test="contains($passwords, ',')"><xsl:value-of select="substring-before($passwords, ',')" /></xsl:when>
				<xsl:otherwise><xsl:value-of select="$passwords" /></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$user != '' and $password != ''">
			<xsl:element name="user" namespace="{$ns}">
				<xsl:attribute name="username"><xsl:value-of select="$user" /></xsl:attribute>
				<xsl:attribute name="password"><xsl:value-of select="$password" /></xsl:attribute>
				<xsl:if test="$userroles != ''">
					<xsl:attribute name="roles"><xsl:value-of select="translate($userroles, ':', ',')" /></xsl:attribute>
				</xsl:if>
			</xsl:element>
		</xsl:if>
		<xsl:if test="contains($users, ',')">
			<xsl:call-template name="add_users">
				<xsl:with-param name="users" select="substring-after($users, ',')" />
				<xsl:with-param name="roles" select="substring-after($roles, ',')" />
				<xsl:with-param name="passwords" select="substring-after($passwords, ',')" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
