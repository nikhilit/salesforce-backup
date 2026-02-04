public class BulkCaseCreationForBPs_Processor {

    public static void process(List<Map<String, String>> rows) {

        /* ----------------------------
           1. Collect BP Numbers
        -----------------------------*/
        Set<String> bpNumbers = new Set<String>();
        for (Map<String, String> r : rows) {
            if (String.isNotBlank(r.get('BP_Number__c'))) {
                bpNumbers.add(r.get('BP_Number__c').trim());
            }
        }

        /* ----------------------------
           2. BP → Account Map
        -----------------------------*/
        Map<String, Id> bpToAccount = new Map<String, Id>();
        if (!bpNumbers.isEmpty()) {
            for (Account a : [
                SELECT Id, BP_Number__c
                FROM Account
                WHERE BP_Number__c IN :bpNumbers
            ]) {
                bpToAccount.put(a.BP_Number__c, a.Id);
            }
        }

        /* ----------------------------
           3. Picklist Maps
        -----------------------------*/
        Map<String, String> categoryLabelToValue =
            getPicklistLabelToValueMap(Case.Category__c);
        Map<String, String> originLabelToValue =
            getPicklistLabelToValueMap(Case.Origin);
        Map<String, String> priorityLabelToValue =
            getPicklistLabelToValueMap(Case.Priority);
        Map<String, String> directionLabelToValue =
            getPicklistLabelToValueMap(Case.Contact_Directions__c);

        /* ----------------------------
           4. Build Cases
        -----------------------------*/
        List<Case> casesToInsert = new List<Case>();

        for (Map<String, String> r : rows) {

            String bp = r.get('BP_Number__c');

            if (String.isBlank(bp)) {
                continue; // BP missing
            }
            if (!bpToAccount.containsKey(bp)) {
                continue; // BP not found
            }


            Case c = new Case();
            c.AccountId     = bpToAccount.get(bp);
            c.Department__c = r.get('Department__c');
            c.Type__c       = r.get('Type__c');
            c.Sub_Type__c   = r.get('Sub_Type__c');
            c.Value_1__c    = r.get('Value_1__c');
            c.Remarks__c    = r.get('Remarks__c');

            /* -------- Picklist mapping (LABEL → API) -------- */

            String categoryKey = normalize(r.get('Category__c'));
            if (categoryKey != null && categoryLabelToValue.containsKey(categoryKey)) {
                c.Category__c = categoryLabelToValue.get(categoryKey);
            }

            String originKey = normalize(r.get('Origin'));
            if (originKey != null && originLabelToValue.containsKey(originKey)) {
                c.Origin = originLabelToValue.get(originKey);
            }

            String priorityKey = normalize(r.get('Priority'));
            if (priorityKey != null && priorityLabelToValue.containsKey(priorityKey)) {
                c.Priority = priorityLabelToValue.get(priorityKey);
            }

            String directionKey = normalize(r.get('Contact_Directions__c'));
            if (directionKey != null && directionLabelToValue.containsKey(directionKey)) {
                c.Contact_Directions__c =
                    directionLabelToValue.get(directionKey);
            }

            casesToInsert.add(c);
        }

        /* ----------------------------
           5. Insert (ASYNC SAFE)
        -----------------------------*/
        if (!casesToInsert.isEmpty()) {
            System.debug('Inserting ' + casesToInsert.size() + ' cases');
            Database.insert(casesToInsert, false);
        }
    }

    /* ============================
       Helpers
    ============================ */

    private static String normalize(String input) {
        if (String.isBlank(input)) return null;
        return input.trim()
                    .toLowerCase()
                    .replace('-', ' ')
                    .replace('_', ' ')
                    .replaceAll('\\s+', ' ');
    }

    private static Map<String, String> getPicklistLabelToValueMap(
        Schema.SObjectField fieldRef
    ) {
        Map<String, String> mapValues = new Map<String, String>();
        for (Schema.PicklistEntry p :
            fieldRef.getDescribe().getPicklistValues()) {
            mapValues.put(normalize(p.getLabel()), p.getValue());
        }
        return mapValues;
    }
}


// public class BulkCaseCreationForBPs_Processor {

//     /* =========================================================
//        CONTEXT (cached data shared across all chunks)
//     ========================================================= */
//     public class Context {
//         public Map<String, Id> bpToAccount;
//         public Map<String, String> categoryMap;
//         public Map<String, String> originMap;
//         public Map<String, String> priorityMap;
//         public Map<String, String> directionMap;
//     }

//     /* =========================================================
//        BUILD CONTEXT (ONE TIME ONLY)
//     ========================================================= */
//     public static Context buildContext(List<Map<String, String>> rows) {

//         Context ctx = new Context();

//         /* -------- Collect BP Numbers -------- */
//         Set<String> bpNumbers = new Set<String>();
//         for (Map<String, String> r : rows) {
//             if (String.isNotBlank(r.get('BP_Number__c'))) {
//                 bpNumbers.add(r.get('BP_Number__c').trim());
//             }
//         }

//         /* -------- BP → Account (SINGLE SOQL) -------- */
//         ctx.bpToAccount = new Map<String, Id>();
//         if (!bpNumbers.isEmpty()) {
//             for (Account acc : [
//                 SELECT Id, BP_Number__c
//                 FROM Account
//                 WHERE BP_Number__c IN :bpNumbers
//             ]) {
//                 ctx.bpToAccount.put(acc.BP_Number__c, acc.Id);
//             }
//         }

//         /* -------- Picklist LABEL → VALUE (NO SOQL) -------- */
//         ctx.categoryMap  = getPicklistLabelToValueMap(Case.Category__c);
//         ctx.originMap    = getPicklistLabelToValueMap(Case.Origin);
//         ctx.priorityMap  = getPicklistLabelToValueMap(Case.Priority);
//         ctx.directionMap = getPicklistLabelToValueMap(
//             Case.Contact_Directions__c
//         );

//         return ctx;
//     }

//     /* =========================================================
//        PROCESS CHUNK (NO SOQL INSIDE)
//     ========================================================= */
//     public static void process(
//         List<Map<String, String>> rows,
//         Context ctx
//     ) {

//         List<Case> casesToInsert = new List<Case>();

//         for (Map<String, String> r : rows) {

//             String bp = r.get('BP_Number__c');

//             if (String.isBlank(bp) || !ctx.bpToAccount.containsKey(bp)) {
//                 continue;
//             }

//             Case c = new Case();
//             c.AccountId     = ctx.bpToAccount.get(bp);
//             c.Department__c = r.get('Department__c');
//             c.Type__c       = r.get('Type__c');
//             c.Sub_Type__c   = r.get('Sub_Type__c');
//             c.Value_1__c    = r.get('Value_1__c');
//             c.Remarks__c    = r.get('Remarks__c');

//             /* -------- Picklist Mapping -------- */
//             String key;

//             key = normalize(r.get('Category__c'));
//             if (key != null && ctx.categoryMap.containsKey(key)) {
//                 c.Category__c = ctx.categoryMap.get(key);
//             }

//             key = normalize(r.get('Origin'));
//             if (key != null && ctx.originMap.containsKey(key)) {
//                 c.Origin = ctx.originMap.get(key);
//             }

//             key = normalize(r.get('Priority'));
//             if (key != null && ctx.priorityMap.containsKey(key)) {
//                 c.Priority = ctx.priorityMap.get(key);
//             }

//             key = normalize(r.get('Contact_Directions__c'));
//             if (key != null && ctx.directionMap.containsKey(key)) {
//                 c.Contact_Directions__c =
//                     ctx.directionMap.get(key);
//             }

//             casesToInsert.add(c);
//         }

//         /* -------- Insert -------- */
//         if (!casesToInsert.isEmpty()) {
//             System.debug('📦 Inserting ' + casesToInsert.size() + ' cases');
//             Database.insert(casesToInsert, false);
//         }
//     }

//     /* =========================================================
//        HELPERS
//     ========================================================= */
//     private static String normalize(String input) {
//         if (String.isBlank(input)) return null;
//         return input.trim()
//             .toLowerCase()
//             .replace('-', ' ')
//             .replace('_', ' ')
//             .replaceAll('\\s+', ' ');
//     }

//     private static Map<String, String> getPicklistLabelToValueMap(
//         Schema.SObjectField fieldRef
//     ) {
//         Map<String, String> mapValues = new Map<String, String>();
//         for (Schema.PicklistEntry p :
//             fieldRef.getDescribe().getPicklistValues()) {
//             mapValues.put(normalize(p.getLabel()), p.getValue());
//         }
//         return mapValues;
//     }
// }