/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 04-06-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   04-06-2025   Kartik Patkar, Appstrail   Initial Version
**/
public class WhatsappRequestBodyWrapper {

    public class Language {
        public String policy { get; set; }
        public String code { get; set; }
    }

    public class Template {
        public String name { get; set; }
        public Language language { get; set; }
        public List<Component> components {get; set;}
    }

    public String recipient_type { get; set; }
    public String to { get; set; }
    public String type { get; set; }
    public Template template { get; set; }
    
    public class Component {
        public String type {get;set;}
        public List<Parameter> parameters {get;set;}
    }

public class Parameter {
        public String type {get;set;}
        public String text {get;set;}
            public Parameter(String type, String text) {
                this.type = type;
                this.text = text;
            }

    }
    
    /**
    * @description 
    * @author Kartik Patkar, Appstrail | 04-06-2025 
    * @param String json 
    * @return WhatsappRequestBodyWrapper 
    **/
    public static WhatsappRequestBodyWrapper parse(String json) {
        try {
            return (WhatsappRequestBodyWrapper) System.JSON.deserialize(json, WhatsappRequestBodyWrapper.class);
        } catch (Exception e) {
            System.debug('JSON parsing error: ' + e.getMessage());
            throw new JSONException('Invalid JSON format for WhatsappRequestBodyWrapper');
        }
    }

    /**
    * @description 
    * @author Kartik Patkar, Appstrail | 04-06-2025 
    * @return String 
    **/
    public String serialize() {
        try {
            return System.JSON.serialize(this);
        } catch (Exception e) {
            System.debug('JSON serialization error: ' + e.getMessage());
            return null;
        }
    }
    
    public class JSONException extends Exception {}
}