<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

	<xsl:param name="LDAP_URL" />
	<xsl:param name="LDAP_ALT_URL" />
	<xsl:param name="LDAP_BIND" />
	<xsl:param name="LDAP_BIND_PASSWORD" />
	<xsl:param name="LDAP_USER_BASEDN" />
	<xsl:param name="LDAP_USER_SEARCH" />
	<xsl:param name="LDAP_USER_PASSWD_ATTR" />
	<xsl:param name="LDAP_USER_ROLE_ATTR" />
	<xsl:param name="LDAP_USER_PATTERN" />
	<xsl:param name="LDAP_GROUP_BASEDN" />
	<xsl:param name="LDAP_GROUP_SEARCH" />
	<xsl:param name="LDAP_GROUP_ATTR" />
	<xsl:param name="COMMON_ROLE" />
	<xsl:param name="ALL_ROLES_MODE" />
	<xsl:param name="AD_COMPAT" />

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
		<Realm className="org.apache.catalina.realm.JNDIRealm">
			<xsl:attribute name="connectionURL">
				<xsl:value-of select="$LDAP_URL" />
			</xsl:attribute>

			<xsl:if
				test="boolean($LDAP_ALT_URL) and $LDAP_ALT_URL != ''">
				<xsl:attribute name="alternateURL">
					<xsl:value-of select="$LDAP_ALT_URL" />
				</xsl:attribute>
			</xsl:if>
			
			<xsl:if
				test="boolean($LDAP_BIND) and $LDAP_BIND != ''">
				<xsl:attribute name="connectionName">
					<xsl:value-of select="$LDAP_BIND" />
				</xsl:attribute>
			</xsl:if>
			<xsl:if
				test="boolean($LDAP_BIND_PASSWORD) and $LDAP_BIND_PASSWORD != ''">
				<xsl:attribute name="connectionPassword">
					<xsl:value-of select="$LDAP_BIND_PASSWORD" />
				</xsl:attribute>
			</xsl:if>
			<xsl:if
				test="boolean($LDAP_USER_BASEDN) and $LDAP_USER_BASEDN != ''">
				<xsl:attribute name="userBase">
					<xsl:value-of select="$LDAP_USER_BASEDN" />
				</xsl:attribute>
			</xsl:if>
			<xsl:if
				test="boolean($LDAP_USER_SEARCH) and $LDAP_USER_SEARCH != ''">
				<xsl:attribute name="userSearch">
					<xsl:value-of select="$LDAP_USER_SEARCH" />
				</xsl:attribute>
			</xsl:if>
			<xsl:if
				test="boolean($LDAP_USER_PASSWD_ATTR) and $LDAP_USER_PASSWD_ATTR != ''">
				<xsl:attribute name="userPassword">
					<xsl:value-of select="$LDAP_USER_PASSWD_ATTR" />
				</xsl:attribute>
			</xsl:if>
			<xsl:if
				test="boolean($LDAP_USER_ROLE_ATTR) and $LDAP_USER_ROLE_ATTR != ''">
				<xsl:attribute name="userRoleName">
					<xsl:value-of select="$LDAP_USER_ROLE_ATTR" />
				</xsl:attribute>
			</xsl:if>
			<xsl:if
				test="boolean($LDAP_USER_PATTERN) and $LDAP_USER_PATTERN != ''">
				<xsl:attribute name="userPattern">
					<xsl:value-of select="$LDAP_USER_PATTERN" />
				</xsl:attribute>
			</xsl:if>
			<xsl:if
				test="boolean($LDAP_GROUP_BASEDN) and $LDAP_GROUP_BASEDN != ''">
				<xsl:attribute name="roleBase">
					<xsl:value-of select="$LDAP_GROUP_BASEDN" />
				</xsl:attribute>
			</xsl:if>
			<xsl:if
				test="boolean($LDAP_GROUP_ATTR) and $LDAP_GROUP_ATTR != ''">
				<xsl:attribute name="roleName">
					<xsl:value-of select="$LDAP_GROUP_ATTR" />
				</xsl:attribute>
			</xsl:if>
			<xsl:if
				test="boolean($LDAP_GROUP_SEARCH) and $LDAP_GROUP_SEARCH != ''">
				<xsl:attribute name="roleSearch">
					<xsl:value-of select="$LDAP_GROUP_SEARCH" />
				</xsl:attribute>
			</xsl:if>
			
			<xsl:if
				test="boolean($COMMON_ROLE) and $COMMON_ROLE != ''">
				<xsl:attribute name="commonRole">
					<xsl:value-of select="$COMMON_ROLE" />
				</xsl:attribute>
			</xsl:if>
			
			<xsl:if
				test="boolean($ALL_ROLES_MODE) and $ALL_ROLES_MODE != ''">
				<xsl:attribute name="allRolesMode">
					<xsl:value-of select="$ALL_ROLES_MODE" />
				</xsl:attribute>
			</xsl:if>
			
			<xsl:if
				test="boolean($AD_COMPAT) and $AD_COMPAT != ''">
				<xsl:attribute name="adCompat">
					<xsl:value-of select="$AD_COMPAT" />
				</xsl:attribute>
			</xsl:if>
		</Realm>
	</xsl:template>
</xsl:stylesheet>
