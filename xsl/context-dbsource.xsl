<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
		
	<xsl:param name="DB_SOURCENAME" />
	<xsl:param name="db_url" />
	<xsl:param name="db_class" />
	<xsl:param name="db_username" />
	<xsl:param name="db_password" />
	<xsl:param name="db_pool_max" />
	<xsl:param name="db_pool_init" />
	<xsl:param name="db_idle_max" />
	<xsl:param name="validation_query" />
	
	<xsl:template match="/">
		<Context>
			<xsl:for-each select="Context/child::*">
				<xsl:choose>
					<xsl:when test="name() = 'Resource' and @name = $DB_SOURCENAME">
						<xsl:call-template name="add_resource" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			<xsl:if test="not(/Context/Resource[@name = $DB_SOURCENAME])">
				<xsl:call-template name="add_resource" />
			</xsl:if>
		</Context>
	</xsl:template>
	
	<xsl:template name="add_resource">
		<Resource
			auth="Container" 
			type="javax.sql.DataSource" 
			factory="org.apache.tomcat.jdbc.pool.DataSourceFactory" 
			minIdle="0">
			<xsl:attribute name="name">
				<xsl:value-of select="$DB_SOURCENAME" />
			</xsl:attribute>
			<xsl:attribute name="driverClassName">
				<xsl:value-of select="$db_class" />
			</xsl:attribute>
			<xsl:attribute name="url">
				<xsl:value-of select="$db_url" />
			</xsl:attribute>
			<xsl:attribute name="username">
				<xsl:value-of select="$db_username" />
			</xsl:attribute>
			<xsl:attribute name="password">
				<xsl:value-of select="$db_password" />
			</xsl:attribute>
			<xsl:attribute name="maxActive">
				<xsl:value-of select="$db_pool_max" />
			</xsl:attribute>
			<xsl:attribute name="initialSize">
				<xsl:value-of select="$db_pool_init" />
			</xsl:attribute>
			<xsl:attribute name="maxIdle">
				<xsl:value-of select="$db_idle_max" />
			</xsl:attribute>
			<xsl:if test="$validation_query != ''">
				<xsl:attribute name="validationQuery">
					<xsl:value-of select="$validation_query" />
				</xsl:attribute>
			</xsl:if>
		</Resource>
	</xsl:template>
</xsl:stylesheet>
