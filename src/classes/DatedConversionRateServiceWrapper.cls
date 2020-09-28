/**
 * Created by MaxymMirona on 27.12.2019.
 */

public class DatedConversionRateServiceWrapper {

    public class Errors {
        public String statusCode;
        public String message;
        public List<Fields> fields;

        public Errors(String statusCode, String message, List<Fields> fields){
            this.statusCode = statusCode;
            this.message = message;
            this.fields = fields;
        }
    }

    public class Fields {
    }

    public Boolean success;
    public List<Errors> errors;
    public String id;

    public DatedConversionRateServiceWrapper(Boolean success, List<Errors> errors, String id){
        this.success = success;
        this.errors = errors;
        this.id = id;
    }
}