import javax.annotation.Resource;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.sql.DataSource;
import java.io.IOException;
import java.sql.*;

@WebServlet(name="DBResourceController", urlPatterns = "/db-time")
public class DBTimeService extends HttpServlet {

    @Resource(name =  "jdbc/test")
    DataSource dbResource;
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if(dbResource == null) {
            resp.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            resp.getWriter().println("Database Resource is not available");
            return;
        }

        try(Connection connection = dbResource.getConnection()) {
            DatabaseMetaData dbmeta = connection.getMetaData();
            //detect database
            String product = dbmeta.getDatabaseProductName();
            resp.getWriter().println("Trying to get the current timestamp of the Database \""+product+"\", version "
                    +dbmeta.getDatabaseMajorVersion()+"."
                    +dbmeta.getDatabaseMinorVersion()+"...");
            String command;
            if(product.contains("Oracle")) {
                command = "SELECT SYSDATE FROM DUAL";
            }
            else {
                command = "SELECT CURRENT_TIMESTAMP";
            }

            try(ResultSet rs = connection.createStatement().executeQuery(command)) {
                if(rs.next()) {
                    Timestamp ts = rs.getTimestamp(1);
                    resp.getWriter().println("Current time is "+ts);
                }
            }
        } catch (SQLException e) {
            resp.setStatus(HttpServletResponse.SC_ACCEPTED);
            resp.getWriter().println("Database connect/execute error: "+e.getErrorCode()+"/"+e.getSQLState()+": "+e.getMessage());
        }
    }
}
