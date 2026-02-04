/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 16-06-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-06-2025   Kartik Patkar, Appstrail   Initial Version
**/
@isTest
global class WhatsappAPIMockResponse implements HttpCalloutMock {

    public enum Scenario {
        SUCCESS,
        THROW_EXCEPTION,
        ACCESS_TOKEN_FAILURE,
        MESSAGE_FAILURE
    }

    private List<Scenario> scenarios;
    private Integer index = 0;

    public WhatsappAPIMockResponse(List<Scenario> scenarios) {
        this.scenarios = scenarios;
    }

    public HTTPResponse respond(HTTPRequest req) {
        if (index >= scenarios.size()) {
            throw new CalloutException('No more mock responses configured.');
        }

        Scenario current = scenarios[index++];
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        switch on current {
            when SUCCESS {
                if (req.getEndpoint().contains('auth')) {
                    res.setStatusCode(200);
                    res.setBody('{ "access_token":"mock_token", "expires_in":3600, "refresh_expires_in":1800, "refresh_token":"mock_refresh_token", "token_type":"Bearer", "session_state":"mock_session", "scope":"mock_scope" }');
                } else {
                    res.setStatusCode(200);
                    res.setBody('{"responseId":"abc123","success":"true"}');
                }
                return res;
            }
            when ACCESS_TOKEN_FAILURE {
                res.setStatusCode(401);
                res.setBody('{"error": "Unauthorized"}');
                return res;
            }
            when MESSAGE_FAILURE {
                res.setStatusCode(400);
                res.setBody('{"error": "Invalid message or token"}');
                return res;
            }
            when THROW_EXCEPTION {
                throw new CalloutException('Simulated callout failure');
            }
        }

        return res;
    }
}