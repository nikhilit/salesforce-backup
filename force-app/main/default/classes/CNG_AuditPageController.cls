public with sharing class CNG_AuditPageController {
    public Integer currentTarget { get; set; }
    public Integer currentSale { get; set; }
    public Integer previousTarget { get; set; }
    public Integer previousSale { get; set; }


    public RO_Audit__c audit { get; private set; }

    public Map<Id, List<Audit_Answer__c>> dispenserAnswerMap { get; set; }
    public Map<Id, Account_Dispensor__c> dispenserMap { get; set; }
    public Map<Id, List<Audit_Answer__c>> compressorAnswerMap { get; set; }
    public Map<Id, Compressor__c> compressorMap { get; set; }
    public List<Audit_Answer__c> cngMRPVerification{get;set;}
    public List<Audit_Answer__c> statutoryRecords{get;set;}
     public List<Audit_Answer__c> brandingRecords{get;set;}
     public List<Audit_Answer__c> cleanandfunctoilets{get;set;}
     public List<Audit_Answer__c> freeair{get;set;}
     public List<Audit_Answer__c> customerOrientation{get;set;}
     public List<Audit_Answer__c> paymentRelated{get;set;}
     public List<Audit_Answer__c> customercomplaintbox{get;set;}
     public List<Audit_Answer__c> firstaidbox{get;set;}
     public List<Audit_Answer__c> safetysecurity{get;set;}
     public List<Audit_Answer__c> fireextinguisher{get;set;}
     public List<Audit_Answer__c> manpower{get;set;}

    // One file per Answer
    public Map<Id, ContentVersion> answerFileMap { get; set; }
    public Map<Id, Boolean> answerHasFileMap { get; set; }
    public Set<Id> answerIds { get; set; }
    public CNG_AuditPageController(ApexPages.StandardController sc) {
        /* ========================
           Load Audit
           ======================== */
        audit = [
            SELECT CreatedDate,
                   MIC_User__r.Name,
                   Audit_Score__c,
                   Business_Partner__r.Name,
                   Business_Partner__r.BP_Number__c,
                   Business_Partner__r.Zone__c,
                   Inspection_Date__c,
                   SCADA_Status__c,
                   Name_of_operationship_firm__c,
                   Name_of_Operator_dealer__c,
                   Name_of_inspecting_officer__c,
                   Non_Operational_Hours__c,
                   GPS__Latitude__s,
                   GPS__Longitude__s
            FROM RO_Audit__c
            WHERE Id = :sc.getId()
        ];

        dispenserAnswerMap = new Map<Id, List<Audit_Answer__c>>();
        dispenserMap = new Map<Id, Account_Dispensor__c>();
        compressorAnswerMap = new Map<Id, List<Audit_Answer__c>>();
        compressorMap = new Map<Id, Compressor__c>();
        answerFileMap = new Map<Id, ContentVersion>();
        answerHasFileMap = new Map<Id, Boolean>();
        answerIds = new Set<Id>();
        cngMRPVerification = new List<Audit_Answer__c>();
        statutoryRecords = new List<Audit_Answer__c>();
        brandingRecords = new List<Audit_Answer__c>();
        cleanandfunctoilets = new List<Audit_Answer__c>();
        freeair = new List<Audit_Answer__c>();
        customerOrientation = new List<Audit_Answer__c>();
        paymentRelated = new List<Audit_Answer__c>();
        customercomplaintbox = new List<Audit_Answer__c>();
        firstaidbox = new List<Audit_Answer__c>();
        safetysecurity = new List<Audit_Answer__c>();
        fireextinguisher = new List<Audit_Answer__c>();
        manpower = new List<Audit_Answer__c>();
        /* ========================
           Load Answers
           ======================== */
        List<Audit_Answer__c> auditAnswers = [
            SELECT Id,
                   Answer__c,Compressor__c,
                   Compressor__r.Name,
                   Account_Dispensor__c,Audit_Question__r.Category__c,
                   Account_Dispensor__r.Equipment_No__c,
                   Audit_Question__r.Question__c,
                   Audit_Question__r.Photo_Required__c,
                   Audit_Question__r.Name,Point__c
            FROM Audit_Answer__c
            WHERE RO_Audit__c = :sc.getId()
            ORDER BY Audit_Question__r.Name
        ];

        for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Account_Dispensor__c!=null){
            answerIds.add(ans.Id);
            answerHasFileMap.put(ans.Id, false); // default

            if (!dispenserAnswerMap.containsKey(ans.Account_Dispensor__c)) {
                dispenserAnswerMap.put(ans.Account_Dispensor__c, new List<Audit_Answer__c>());
                dispenserMap.put(ans.Account_Dispensor__c, ans.Account_Dispensor__r);
            }

            dispenserAnswerMap.get(ans.Account_Dispensor__c).add(ans);
        }
        }
        for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Compressor__c!=null){
            answerIds.add(ans.Id);
            answerHasFileMap.put(ans.Id, false); // default

            if (!compressorAnswerMap.containsKey(ans.Compressor__c)) {
                compressorAnswerMap.put(ans.Compressor__c, new List<Audit_Answer__c>());
                compressorMap.put(ans.Compressor__c, ans.Compressor__r);
            }

            compressorAnswerMap.get(ans.Compressor__c).add(ans);
        }
        }
        for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Audit_Question__r.Category__c=='Performance Comparison'){
                if(ans.Audit_Question__r.Name=='Q-0011'){
                    previousTarget  = Integer.valueOf(ans.Answer__c);
                }else if(ans.Audit_Question__r.Name=='Q-0012'){
                    previousSale    = Integer.valueOf(ans.Answer__c);
                }
                else if(ans.Audit_Question__r.Name=='Q-0013'){
                    currentTarget  = Integer.valueOf(ans.Answer__c);
                }else{
                    currentSale=Integer.valueOf(ans.Answer__c);
                }
            }
        }
         for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Audit_Question__r.Category__c=='CNG MRP Verification'){
                answerIds.add(ans.Id);
                answerHasFileMap.put(ans.Id, false); 
                cngMRPVerification.add(ans);
            }
        }
        for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Audit_Question__r.Category__c=='Statutory Compliances & Records'){
                answerIds.add(ans.Id);
                answerHasFileMap.put(ans.Id, false); 
                statutoryRecords.add(ans);
            }
        }
         for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Audit_Question__r.Category__c=='Branding And Awareness'){
                answerIds.add(ans.Id);
                answerHasFileMap.put(ans.Id, false); 
                brandingRecords.add(ans);
            }
        }
        for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Audit_Question__r.Category__c=='CUSTOMER ORIENTATION'){
                answerIds.add(ans.Id);
                answerHasFileMap.put(ans.Id, false); 
                customerOrientation.add(ans);
            }
        }
        for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Audit_Question__r.Category__c=='Free Air Filling Facility'){
                answerIds.add(ans.Id);
                answerHasFileMap.put(ans.Id, false); 
                freeair.add(ans);
            }
        }
        for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Audit_Question__r.Category__c=='Clean And Functional Toilets'){
                answerIds.add(ans.Id);
                answerHasFileMap.put(ans.Id, false); 
                cleanandfunctoilets.add(ans);
            }
        }
        for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Audit_Question__r.Category__c=='Customer Complaint Box'){
                answerIds.add(ans.Id);
                answerHasFileMap.put(ans.Id, false); 
                customercomplaintbox.add(ans);
            }
        }
        for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Audit_Question__r.Category__c=='First Aid Box'){
                answerIds.add(ans.Id);
                answerHasFileMap.put(ans.Id, false); 
                firstaidbox.add(ans);
            }
        }
        for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Audit_Question__r.Category__c=='Payment Related'){
                answerIds.add(ans.Id);
                answerHasFileMap.put(ans.Id, false); 
                paymentRelated.add(ans);
            }
        }
        for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Audit_Question__r.Category__c=='Fire Extinguisher'){
                answerIds.add(ans.Id);
                answerHasFileMap.put(ans.Id, false); 
                fireextinguisher.add(ans);
            }
        }
        for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Audit_Question__r.Category__c=='Safety and Security'){
                answerIds.add(ans.Id);
                answerHasFileMap.put(ans.Id, false); 
                safetysecurity.add(ans);
            }
        }
        for (Audit_Answer__c ans : auditAnswers) {
            if(ans.Audit_Question__r.Category__c=='Man Power'){
                answerIds.add(ans.Id);
                answerHasFileMap.put(ans.Id, false); 
                manpower.add(ans);
            }
        }
        /* ========================
           Load Files (One per Answer)
           ======================== */
        if (!answerIds.isEmpty()) {

            List<ContentDocumentLink> links = [
                SELECT LinkedEntityId,
                       ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :answerIds
            ];

            Set<Id> versionIds = new Set<Id>();
            for (ContentDocumentLink cdl : links) {
                versionIds.add(cdl.ContentDocument.LatestPublishedVersionId);
            }

            if (!versionIds.isEmpty()) {

                Map<Id, ContentVersion> versionMap =
                    new Map<Id, ContentVersion>([
                        SELECT Id, FileType
                        FROM ContentVersion
                        WHERE Id IN :versionIds
                    ]);

                for (ContentDocumentLink cdl : links) {
                    ContentVersion cv =
                        versionMap.get(cdl.ContentDocument.LatestPublishedVersionId);

                    if (cv != null) {
                        answerFileMap.put(cdl.LinkedEntityId, cv);
                        answerHasFileMap.put(cdl.LinkedEntityId, true);
                    }
                }
            }
        }
    }
}