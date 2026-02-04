public class ConnectionTriggerHandler {
    public static void updateName(List<Connection__c> newList, Map<Id, Connection__c> oldMap) {
        for (Connection__c con : newList) {
            Boolean isNew = (oldMap == null || !oldMap.containsKey(con.Id));
            Boolean codeChanged = false;

            if (!isNew) {
                Connection__c oldCon = oldMap.get(con.Id);
                codeChanged = con.Connection_Code__c != oldCon.Connection_Code__c;
            }

            if (isNew || codeChanged) {
                if (con.Connection_Code__c != null) {
                    con.Name = con.Connection_Code__c;
                }
            }
        }
    }
}