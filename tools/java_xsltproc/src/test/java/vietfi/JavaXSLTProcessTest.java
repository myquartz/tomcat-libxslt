package vietfi;

import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.Properties;

import static org.junit.jupiter.api.Assertions.assertEquals;

class JavaXSLTProcessTest {

    @Test
    void parseParameterLinesTest() {
        Properties prop = new Properties();
        String[] out = JavaXSLTProcess.parseParameterLines(Arrays.asList("P1=VALUE1","P2= VALUE2","P3=","NON_PARSED"),
                (k,v) -> {
                    switch (k) {
                        case "P1":
                            assertEquals("VALUE1", v);
                            break;
                        case "P2":
                            assertEquals("VALUE2", v);
                            break;
                        case "P3":
                            assertEquals("", v);
                            break;
                    }
                });
        assertEquals(1, out.length);
        assertEquals("NON_PARSED", out[0]);
    }
}