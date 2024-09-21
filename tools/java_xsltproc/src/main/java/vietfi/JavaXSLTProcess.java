package vietfi;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.BiConsumer;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.w3c.dom.Document;
import org.xml.sax.SAXException;

/**
 * Java XSLT processor,
 * Written by Tran Thach Anh myquartz at gmail.com
 * 
 */
public class JavaXSLTProcess {

	public static void main(String[] args) {
        boolean useSaxon = false;
        Map<String, String> parameters = new LinkedHashMap<>();
        
        int pi = 0;
        while (pi < args.length-3) {
        	if("--using-saxon".equals(args[pi]))
        		useSaxon = true;
        	else if("--param".equals(args[pi])) {
				if(pi+1 >= args.length) {
					System.err.println("--param must be follow with NAME[=VALUE]");
					System.exit(1);
				}

				String param = args[pi+1];
				int eq_pos = param.indexOf('=');
        		String name = eq_pos > 0 ? param.substring(0, eq_pos) : param;
        		String value = eq_pos < 0 ? "" : param.substring(eq_pos+1);
        		if(value.length()>=2) {
					if (value.startsWith("'") && value.endsWith("'"))
						value = value.substring(1, value.length() - 1).replace("''", "'");
					else if (value.startsWith("\"") && value.endsWith("\""))
						value = value.substring(1, value.length() - 1).replaceAll("\\\\(.)", "$1");
				}

        		parameters.put(name, value);
				pi++;
        	}
			else if("--param-file".equals(args[pi])) {
				if(pi+1 >= args.length) {
					System.err.println("--param-file must be follow with file_name");
					System.exit(1);
				}
				Path paramFile = Paths.get(args[pi+1]);
                try {
                    List<String> lines = Files.readAllLines(paramFile);
					parseParameterLines(lines, (k, v) -> parameters.put(k, v));
                } catch (IOException e) {
					System.err.println("Can not read "+paramFile+": "+e.getMessage());
					System.exit(1);
                }
				pi++;
            }
        	else if(!args[pi].startsWith("--")) {
        		break;
        	}
			else if(args[pi].equals("--")) {
				pi++;
				break;
			}
			else {
				System.err.println("Invalid parameter: "+args[pi]);
				System.exit(1);
			}
        	pi++;
        }
        
        // Check for correct number of arguments
        if (args.length - pi < 3) {
            System.err.println("Usage: JavaXSLTProcess [--using-saxon] [--param-file <param_file.txt>] [--param <NAME>=[VALUE]]... [--] <source.xml> <xsl1.xsl> <xsl2.xsl> bundle=<xsl-with-param.txt> ... <output.xml>");
			System.err.println("param_file.txt: a file text of env style:\n"
					+"  PARAM_NAME1=PARAM_VALUE1\n"
					+"  PARAM_NAME2=PARAM_VALUE2\n"
					+"  PARAM_NAME3=\n"
			);
            System.err.println("xsl-with-param.txt: a file text of definition for specific transformation step with the following lines:\n"
            		+"  xsl3.xsl (XSL file name at the first non-empty line)\n"
            		+"  PARAM_NAME=PARAM_VALUE\n"
            		+"  PARAM_NAME=PARAM_VALUE\n"
            		);
            System.exit(1);
        }

        final String bundlePrefix = "--bundle=";

        String sourceFile = args[pi];
        String outputFile = args[args.length - 1];
        String[] xsls = java.util.Arrays.copyOfRange(args, pi+1, args.length - 1);

        try {
        	TransformerFactory factory = useSaxon ?
                    TransformerFactory.newInstance("net.sf.saxon.TransformerFactoryImpl", JavaXSLTProcess.class.getClassLoader()) :
                    TransformerFactory.newInstance();

            // Load the source XML document
            DocumentBuilderFactory docFactory = DocumentBuilderFactory.newInstance();
            docFactory.setNamespaceAware(true);  // Important for XSLT processing
			System.out.println("Reading XML from "+sourceFile);
            DocumentBuilder docBuilder = docFactory.newDocumentBuilder();
            Document document = docBuilder.parse(new File(sourceFile));

            // Perform each XSLT transformation in the pipeline
            for (String p : xsls) {
            	Transformer transformer = null;
                // Create a Transformer for the current XSLT
            	if(p.startsWith(bundlePrefix)) {
					Path bundleFile = Paths.get(p.substring(bundlePrefix.length()));
            		List<String> lines = Files.readAllLines(bundleFile);
					if(lines.isEmpty()) {
						System.err.println(bundleFile+": is empty file");
						System.exit(1);
					}
					Transformer finalTransformer = factory.newTransformer(new StreamSource(new FileInputStream(lines.get(0))));
					parseParameterLines(lines, (k, v) -> finalTransformer.setParameter(k, v));
					transformer = finalTransformer;
            	}
            	else {
            		transformer = factory.newTransformer(new StreamSource(new FileInputStream(p)));
            		System.out.println("Transforming by XSL file "+ p);
            	}

                for(Map.Entry<String, String> e: parameters.entrySet())
                	transformer.setParameter(e.getKey(), e.getValue());

                // Transform the current Document to a temporary output
                DOMSource source = new DOMSource(document);
                DOMResult result = new DOMResult();
		transformer.transform(source, result);

		//Next stage
                document = (Document) result.getNode();
            }

            // Write the final transformed Document to the output file
            Transformer transformer = factory.newTransformer();
            transformer.setOutputProperty(OutputKeys.INDENT, "yes");
            transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "2");
            DOMSource source = new DOMSource(document);
			System.out.println("Writing out to "+outputFile);
            StreamResult result = new StreamResult(new FileOutputStream(outputFile));

            transformer.transform(source, result);

            System.out.println("Transformation pipeline completed successfully.");
        } catch (IOException | TransformerException | ParserConfigurationException | SAXException e) {
            e.printStackTrace();
            System.exit(2);
        }
    }

	/**
	 *	Parsing parameter file as (no quote)
	 *
	 *   PARAM_NAME1=PARAM_VALUE1\n
	 *   PARAM_NAME2=PARAM_VALUE2\n
	 *   PARAM_NAME3=\n
	 *   NON_PARSING
	 *   #COMMENTING
	 *
	 * @param lines
	 * @param setter
	 * @return
	 */
	static String[] parseParameterLines(List<String> lines, BiConsumer<String, String> setter) {
		List<String> inseparableString = new ArrayList<>(lines.size());
		for(String l:lines) {
			l = l.trim();
			//comments
			if(l.isEmpty() || l.startsWith("#")) {
				//commenting
				continue;
			}

			int spi = l.indexOf('=');
			if(spi < 0) { //in-able to parse
				inseparableString.add(l);
			}
			else {
				int nv = spi+1;
				while(nv < l.length() && Character.isWhitespace(l.charAt(nv)))
					nv++;
				setter.accept(l.substring(0, spi).trim(), l.substring(nv).trim());
			}
		}
		return inseparableString.toArray(new String[inseparableString.size()]);
	}
}
