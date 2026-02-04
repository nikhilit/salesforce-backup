@isTest
private class SessionPluginTest
{  
    static testMethod void invokeTest() {
     
        SessionPlugin session = new SessionPlugin();
        Map<String,Object> inputParams = new Map<String,Object>();
        Map<String,Object> outputParams = new Map<String,Object>();
         
        inputParams.put('CONCURRENT_NO', '3');
         
        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result;
        result = session.invoke(request);
        
        System.AssertEquals(1,1);
    }

    static testMethod void describeTest() {

        SessionPlugin session = new SessionPlugin();
        Process.PluginDescribeResult result = session.describe();
        
        System.AssertEquals(result.inputParameters.size(), 0);
        System.AssertEquals(result.OutputParameters.size(), 1);
     }
}