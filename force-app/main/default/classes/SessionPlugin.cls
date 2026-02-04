global class SessionPlugin implements Process.Plugin
{    
    global Process.PluginDescribeResult describe()
    {
        Process.PluginDescribeResult result = new Process.PluginDescribeResult();
        result.description='This plug-in returns the no of concurrent sessions for the current user';
        result.tag='Identity';
        
        result.inputParameters = new List<Process.PluginDescribeResult.InputParameter> {
        };
        
        result.outputParameters = new List<Process.PluginDescribeResult.OutputParameter> {
            new Process.PluginDescribeResult.OutputParameter('CONCURRENT_NO',
                Process.PluginDescribeResult.ParameterType.INTEGER)
        };
        
        return result;
    }
    
    global Process.PluginResult invoke(Process.PluginRequest request)
    {   
        Map<String, Object> result = new Map<String, Object>();
        List<AuthSession> sessions;
        Integer no = 0;
        
        String userid   = UserInfo.getUserId();  
        
        sessions = [Select Id, ParentId, SessionType from AuthSession where UsersId=:userid];
        for (AuthSession s : sessions)
        {
            // Count only parent and non-temp sessions
            if(s.ParentId == null && s.SessionType != 'TempUIFrontdoor' )
            {
                    no++;
            }
        }
        
        result.put('CONCURRENT_NO', no);
           
        return new Process.PluginResult(result);
    }
}