/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 16-06-2025
 * @last modified by  : Kartik Patkar Appstrail 
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-06-2025   Kartik Patkar, Appstrail   Initial Version
**/
@isTest
private class WhatsappRequestBodyWrapperTest {
    
    @isTest
    static void testSerializationAndDeserialization() {
        // Prepare sample wrapper object
        WhatsappRequestBodyWrapper.Language lang = new WhatsappRequestBodyWrapper.Language();
        lang.code = 'en';
        lang.policy = 'deterministic';
        
        WhatsappRequestBodyWrapper.Template tmpl = new WhatsappRequestBodyWrapper.Template();
        tmpl.name = 'sample_template';
        tmpl.language = lang;
        
        WhatsappRequestBodyWrapper wrapper = new WhatsappRequestBodyWrapper();
        wrapper.recipient_type = 'individual';
        wrapper.to = '919999999999';
        wrapper.type = 'template';
        wrapper.template = tmpl;
        
        // Serialize to JSON
        String jsonString = wrapper.serialize();
        System.assertNotEquals(null, jsonString, 'Serialized JSON should not be null');
        
        // Deserialize from JSON
        WhatsappRequestBodyWrapper parsed = WhatsappRequestBodyWrapper.parse(jsonString);
        System.assertNotEquals(null, parsed, 'Deserialized object should not be null');
        System.assertEquals('individual', parsed.recipient_type);
        System.assertEquals('919999999999', parsed.to);
        System.assertEquals('template', parsed.type);
        System.assertEquals('sample_template', parsed.template.name);
        System.assertEquals('en', parsed.template.language.code);
        System.assertEquals('deterministic', parsed.template.language.policy);
    }
    
    @isTest
    static void testParseWithInvalidJson() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            WhatsappRequestBodyWrapper.parse('{ invalid_json: }');
        } catch (WhatsappRequestBodyWrapper.JSONException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, exceptionThrown, 'Exception should be thrown for invalid JSON');
    }
}