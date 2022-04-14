<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

	<xsl:param name="DB_SOURCENAME" />
	<xsl:param name="REALM_USERTAB" />
	<xsl:param name="REALM_ROLETAB" />
	<xsl:param name="REALM_USERCOL" />
	<xsl:param name="REALM_CREDCOL" />
	<xsl:param name="REALM_ROLECOL" />
	<xsl:param name="LOCAL_DS" />
	<xsl:param name="ALL_ROLES_MODE" />

	<xsl:template match="/">
		<Context>
			<xsl:for-each select="Context/child::*">
				<xsl:choose>
					<xsl:when
						test="name() = 'Realm' and (@className='org.apache.catalina.realm.CombinedRealm' or @className='org.apache.catalina.realm.LockOutRealm')">
						<Realm>
							<xsl:for-each select="attribute::*">
								<xsl:copy-of select="." />
							</xsl:for-each>
							<!-- child realm -->
							<xsl:call-template name="add_realm" />
							<!-- xsl:copy-of select="./child::*" / -->
						</Realm>
					</xsl:when>
					<xsl:when test="name() = 'Realm'">
						<!-- replace the old -->
						<xsl:call-template name="add_realm" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</Context>
	</xsl:template>

	<xsl:template name="add_realm">
		<Realm className="org.apache.catalina.realm.DataSourceRealm">
			<xsl:attribute name="dataSourceName">
				<xsl:value-of select="$DB_SOURCENAME" />
			</xsl:attribute>
			
			<xsl:attribute name="userTable">
				<xsl:value-of select="$REALM_USERTAB" />
			</xsl:attribute>
			
			<xsl:attribute name="userNameCol">
				<xsl:value-of select="$REALM_USERCOL" />
			</xsl:attribute>
			
			<xsl:attribute name="userCredCol">
				<xsl:value-of select="$REALM_CREDCOL" />
			</xsl:attribute>
			
			<xsl:attribute name="localDataSource">
				<xsl:value-of select="$LOCAL_DS" />
			</xsl:attribute>

			<xsl:if
				test="boolean($REALM_ROLETAB) and $REALM_ROLETAB != ''">
				<xsl:attribute name="userRoleTable">
					<xsl:value-of select="$REALM_ROLETAB" />
				</xsl:attribute>
			</xsl:if>

			<xsl:if
				test="boolean($REALM_ROLECOL) and $REALM_ROLECOL != ''">
				<xsl:attribute name="roleNameCol">
					<xsl:value-of select="$REALM_ROLECOL" />
				</xsl:attribute>
			</xsl:if>
			
			<xsl:if
				test="boolean($ALL_ROLES_MODE) and $ALL_ROLES_MODE != ''">
				<xsl:attribute name="allRolesMode">
					<xsl:value-of select="$ALL_ROLES_MODE" />
				</xsl:attribute>
			</xsl:if>
			
		</Realm>
	</xsl:template>
</xsl:stylesheet>
