package vietfi;

import javax.xml.transform.*;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

public class JavaXSLTProcess {

    public static void main(String[] args) {
        boolean useSaxon = false;

        // Check if the first argument is --using-saxon
        if (args.length > 0 && "--using-saxon".equals(args[0])) {
            useSaxon = true;
            // Shift arguments to remove the --using-saxon option
            args = java.util.Arrays.copyOfRange(args, 1, args.length);
        }

        // Check for correct number of arguments
        if (args.length != 3) {
            System.err.println("Usage: JavaXSLTProcess [--using-saxon] <source.xml> <stylesheet.xsl> <output.xml>");
            System.exit(1);
        }
      
        String sourceFile = args[0];
        String stylesheetFile = args[1];
        String outputFile = args[2];

        try {
            // Create a TransformerFactory instance
            TransformerFactory factory = useSaxon ? 
                TransformerFactory.newInstance("net.sf.saxon.TransformerFactoryImpl", JavaXSLTProcess.class.getClassLoader()) :
                TransformerFactory.newInstance();

            // Create a Transformer instance from the stylesheet
            Transformer transformer = factory.newTransformer(new StreamSource(new FileInputStream(stylesheetFile)));

            // Set up input and output sources
            Source source = new StreamSource(new FileInputStream(sourceFile));
            Result result = new StreamResult(new FileOutputStream(outputFile));

            // Perform the transformation
            transformer.transform(source, result);

            System.out.println("Transformation completed successfully.");
        } catch (IOException | TransformerException e) {
            e.printStackTrace();
            System.exit(2);
        }
    }
}
