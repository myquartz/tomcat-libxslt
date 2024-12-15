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
	<xsl:param name="ALL_ROLES_MODE" />
  <!-- MessageDigest configuration -->
	<xsl:param name="REALM_ALGORITHM" />
	<xsl:param name="REALM_INTERATIONS" />
	<xsl:param name="REALM_SALT_LENGTH" />
	<xsl:param name="REALM_ENCODING" />

	<xsl:template match="/">
		<Server>
			<xsl:copy-of select="Server/attribute::*" />
			<xsl:copy-of select="Server/Listener" />
			<xsl:copy-of select="Server/GlobalNamingResources" />
			
			<Service>
			<xsl:for-each select="Server/Service/attribute::*">
				<xsl:copy-of select="." />
			</xsl:for-each>
			<xsl:for-each select="Server/Service/child::*">
				<xsl:choose>
					<xsl:when test="name() = 'Engine'">
						<Engine>
							<xsl:for-each select="attribute::*">
								<xsl:copy-of select="." />
							</xsl:for-each>
							<xsl:choose>
								<xsl:when
									test="name() = 'Realm' and (@className='org.apache.catalina.realm.LockOutRealm' or @className='org.apache.catalina.realm.CombinedRealm')">
									<Realm>
										<xsl:for-each select="attribute::*">
											<xsl:copy-of select="." />
										</xsl:for-each>
										<!-- add new realm -->
										<xsl:call-template name="add_realm" />
										<xsl:copy-of select="./child::*" />
									</Realm>
								</xsl:when>
								<xsl:when
									test="name() = 'Realm' and count(../Realm) = 1">
									<Realm className="org.apache.catalina.realm.CombinedRealm">
										<!-- add new realm -->
										<xsl:call-template name="add_realm" />
										<xsl:copy-of select="." />
									</Realm>
								</xsl:when>
								<xsl:when test="name() != 'Realm'">
									<xsl:copy-of select="." />
								</xsl:when>
							</xsl:choose>
						</Engine>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			</Service>
		</Server>
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

			<xsl:if test="(boolean($REALM_ALGORITHM) and $REALM_ALGORITHM != '') or (boolean($REALM_INTERATIONS) and $REALM_INTERATIONS != '')">
			<CredentialHandler className="org.apache.catalina.realm.MessageDigestCredentialHandler">
			<xsl:if
				test="boolean($REALM_ALGORITHM) and $REALM_ALGORITHM != ''">
				<xsl:attribute name="algorithm">
					<xsl:value-of select="$REALM_ALGORITHM" />
				</xsl:attribute>
			</xsl:if>
			<xsl:if
				test="boolean($REALM_INTERATIONS) and $REALM_INTERATIONS != ''">
				<xsl:attribute name="interations">
					<xsl:value-of select="$REALM_INTERATIONS" />
				</xsl:attribute>
			</xsl:if>
			<xsl:if
				test="boolean($REALM_SALT_LENGTH) and $REALM_SALT_LENGTH != ''">
				<xsl:attribute name="saltLength">
					<xsl:value-of select="$REALM_SALT_LENGTH" />
				</xsl:attribute>
			</xsl:if>
			<xsl:if
				test="boolean($REALM_ENCODING) and $REALM_ENCODING != ''">
				<xsl:attribute name="encoding">
					<xsl:value-of select="$REALM_ENCODING" />
				</xsl:attribute>
			</xsl:if>
			</CredentialHandler>
			</xsl:if>
			
		</Realm>
	</xsl:template>
</xsl:stylesheet>
