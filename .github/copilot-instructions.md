# Repository guidance

## Build and verification

- The only production Java module is the XSLT processor. Run its tests with:
  ```bash
  mvn -f tools/java_xsltproc/pom.xml test
  ```
  Run one test with:
  ```bash
  mvn -f tools/java_xsltproc/pom.xml test -Dtest=JavaXSLTProcessTest
  ```
- Package the processor JAR with `mvn -f tools/java_xsltproc/pom.xml package`. The image build expects `xslt-process-1.0-SNAPSHOT.jar` under that module's `target/` directory.
- Package the sample WAR with `mvn -f tools/test_app1/pom.xml package`.
- There is no configured linter. Validate changed XSL files with `xmllint --noout xsl/*.xsl`.
- Build a limited local image set rather than every supported variant while iterating:
  ```bash
  bash build-images.sh "11-jdk17" no
  ```
  This requires Docker and downloads/builds the processor and, for CDI variants, Tomcat OWB/CXF artifacts. `build-images.sh` generates and removes a root `Dockerfile`; do not add that generated file to source control.

## Architecture

- This repository builds `tomcat-xslt` Docker images. `build-images.sh` selects Tomcat/JDK variants, packages `tools/java_xsltproc`, copies the XSL stylesheets and `scripts/catalina-xslt.sh` into the image, and replaces the default command with the startup script. GitHub Actions publishes multi-platform Docker Hub images; AWS CodeBuild specs build and publish ECR variants and manifests.
- At container startup, `catalina-xslt.sh` finds a deployed WAR/exploded application's `META-INF/context.xml`, uses an empty `<Context>` when none exists, and collects environment-derived parameters. It passes the input through an ordered context stylesheet pipeline and writes `conf/Catalina/localhost/<context>.xml`; independently, it transforms the image's preserved `server-orig.xml` into `conf/server.xml`, then delegates to Tomcat's original `catalina.sh`.
- `tools/java_xsltproc` is the transformation engine. `JavaXSLTProcess` applies every supplied stylesheet sequentially to one DOM document. `--bundle=<file>` selects a stylesheet and per-step parameters, and the startup script passes the comma-separated resource, context-parameter, and environment-entry lists (any length) to their stylesheets, which iterate over them in XSL.
- The stylesheets are feature-focused: `context-*` modify per-application context configuration, while `server-*` modify Tomcat-wide configuration. They cover datasource/realm configuration, valves, connectors, clustering, and CDI. `web-distributable.xsl` updates a clustered application's `WEB-INF/web.xml`.

## Repository conventions

- Treat each XSL file as a non-destructive XML update: preserve unrelated attributes and child elements, replace the matching managed element when present, and append it when absent. Keep the output rooted in the original Tomcat element (`Context` or `Server`).
- Environment variable names are the public container API. When adding a setting, wire it end-to-end: declare the XSL parameter, append the matching `--param` in `catalina-xslt.sh`, include a default `ENV` in the generated Dockerfile when appropriate, and document it in `README.md`.
- Parameter names are case-sensitive and are not always identical to their environment variables. In particular, the script maps `DB_*` variables to lowercase XSL parameters such as `db_url`, `db_class`, and `db_password`; preserve these existing names.
- Keep stylesheet ordering deliberate. The Java processor passes one transformed DOM result to the next stylesheet, so a later stylesheet sees and may replace elements produced by an earlier one.
- For repeated context resources, parameters, and environment entries, retain the existing bundle-file pattern rather than adding global command-line parameters: each bundle supplies the stylesheet on its first non-empty line and its step-specific values below it.
- `catalina-xslt.sh` accepts secret-file environment variables (`DB_PASSWORD_FILE` and `LDAP_BIND_PASSWORD_FILE`) in preference to inline values. Preserve that behavior when changing datasource or LDAP setup.
