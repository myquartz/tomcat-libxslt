<?xml version="1.0" encoding="UTF-8"?>
<!-- Adds the Tomcat UserDatabase realm (context.xml). Existing LockOutRealm/CombinedRealm gets it as first child,
     any other Realm is wrapped by a CombinedRealm with UserDatabase declared first. -->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" />
		</xsl:copy>
	</xsl:template>

	<xsl:template match="Context[not(Realm)]">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" />
			<xsl:call-template name="userdb" />
		</xsl:copy>
	</xsl:template>

	<xsl:template match="Context/Realm">
		<xsl:variable name="cn" select="string(@className)" />
		<xsl:choose>
			<xsl:when test="$cn = 'org.apache.catalina.realm.UserDatabaseRealm'">
				<xsl:copy-of select="." />
			</xsl:when>
			<xsl:when test="$cn = 'org.apache.catalina.realm.LockOutRealm' or $cn = 'org.apache.catalina.realm.CombinedRealm'">
				<xsl:copy>
					<xsl:apply-templates select="@*" />
					<xsl:if test="not(Realm[@className='org.apache.catalina.realm.UserDatabaseRealm'])">
						<xsl:call-template name="userdb" />
					</xsl:if>
					<xsl:apply-templates select="node()" />
				</xsl:copy>
			</xsl:when>
			<xsl:otherwise>
				<Realm className="org.apache.catalina.realm.CombinedRealm">
					<xsl:call-template name="userdb" />
					<xsl:copy-of select="." />
				</Realm>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="userdb">
		<Realm className="org.apache.catalina.realm.UserDatabaseRealm" resourceName="UserDatabase" />
	</xsl:template>
</xsl:stylesheet>
