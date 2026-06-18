public with sharing class TechDebtDuplicateChecker {

    public class DuplicateResult {
        @AuraEnabled public Boolean isDuplicate;
        @AuraEnabled public String duplicateId;
        @AuraEnabled public String duplicateTitle;
        @AuraEnabled public String message;

        public DuplicateResult(Boolean isDuplicate, String duplicateId, String duplicateTitle, String message) {
            this.isDuplicate = isDuplicate;
            this.duplicateId = duplicateId;
            this.duplicateTitle = duplicateTitle;
            this.message = message;
        }
    }

    public class InvocableRequest {
        @InvocableVariable(label='Component Name' required=true)
        public String componentName;

        @InvocableVariable(label='Debt Type' required=true)
        public String debtType;

        @InvocableVariable(label='Related Object' required=true)
        public String relatedObject;
    }

    public class InvocableResponse {
        @InvocableVariable(label='Is Duplicate')
        public Boolean isDuplicate;

        @InvocableVariable(label='Duplicate Record Id')
        public String duplicateId;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='Check for Duplicate Technical Debt Item')
    public static List<InvocableResponse> checkFromFlow(List<InvocableRequest> requests) {
        List<InvocableResponse> responses = new List<InvocableResponse>();

        for (InvocableRequest req : requests) {
            Technical_Debt_Item__c stub = new Technical_Debt_Item__c(
                Component_Name__c = req.componentName,
                Debt_Type__c = req.debtType,
                Related_Object__c = req.relatedObject
            );

            DuplicateResult result = checkSingle(stub);

            InvocableResponse resp = new InvocableResponse();
            resp.isDuplicate = result.isDuplicate;
            resp.duplicateId = result.duplicateId;
            resp.message = result.message;
            responses.add(resp);
        }

        return responses;
    }

    public static void checkBeforeInsert(List<Technical_Debt_Item__c> newRecords) {
        Set<String> debtTypes = new Set<String>();
        Set<String> relatedObjects = new Set<String>();

        for (Technical_Debt_Item__c rec : newRecords) {
            if (String.isNotBlank(rec.Debt_Type__c)) {
                debtTypes.add(rec.Debt_Type__c);
            }
            if (String.isNotBlank(rec.Related_Object__c)) {
                relatedObjects.add(rec.Related_Object__c);
            }
        }

        List<Technical_Debt_Item__c> existingRecords = [
            SELECT Id, Component_Name__c, Debt_Type__c, Related_Object__c, Status__c
            FROM Technical_Debt_Item__c
            WHERE Status__c != 'Resolved'
            AND Debt_Type__c IN :debtTypes
            AND Related_Object__c IN :relatedObjects
        ];

        Map<String, Technical_Debt_Item__c> existingKeyMap = new Map<String, Technical_Debt_Item__c>();

        for (Technical_Debt_Item__c existing : existingRecords) {
            existingKeyMap.put(
                buildKey(existing.Component_Name__c, existing.Debt_Type__c, existing.Related_Object__c),
                existing
            );
        }

        for (Technical_Debt_Item__c newRec : newRecords) {
            String key = buildKey(newRec.Component_Name__c, newRec.Debt_Type__c, newRec.Related_Object__c);

            if (existingKeyMap.containsKey(key)) {
                Technical_Debt_Item__c match = existingKeyMap.get(key);

                newRec.addError(
                    'Duplicate detected: An open Technical Debt Item already exists with the same Component Name, Debt Type, and Related Object. Existing record ID: ' + match.Id
                );
            }
        }
    }

    public static DuplicateResult checkSingle(Technical_Debt_Item__c candidate) {
        if (
            String.isBlank(candidate.Component_Name__c) ||
            String.isBlank(candidate.Debt_Type__c) ||
            String.isBlank(candidate.Related_Object__c)
        ) {
            return new DuplicateResult(false, null, null, 'Insufficient data to check for duplicates.');
        }

        String candidateKey = buildKey(
            candidate.Component_Name__c,
            candidate.Debt_Type__c,
            candidate.Related_Object__c
        );

        List<Technical_Debt_Item__c> matches = [
            SELECT Id, Component_Name__c, Debt_Type__c, Related_Object__c
            FROM Technical_Debt_Item__c
            WHERE Status__c != 'Resolved'
            AND Debt_Type__c = :candidate.Debt_Type__c
            AND Related_Object__c = :candidate.Related_Object__c
            LIMIT 200
        ];

        for (Technical_Debt_Item__c existing : matches) {
            if (buildKey(existing.Component_Name__c, existing.Debt_Type__c, existing.Related_Object__c) == candidateKey) {
                return new DuplicateResult(
                    true,
                    existing.Id,
                    existing.Component_Name__c,
                    'A matching open Technical Debt Item already exists.'
                );
            }
        }

        return new DuplicateResult(false, null, null, 'No duplicate found.');
    }

    @TestVisible
    private static String buildKey(String componentName, String debtType, String relatedObject) {
        String safeComponent = String.isNotBlank(componentName) ? componentName.toLowerCase().trim() : '';
        String safeDebtType = String.isNotBlank(debtType) ? debtType.toLowerCase().trim() : '';
        String safeRelatedObject = String.isNotBlank(relatedObject) ? relatedObject.toLowerCase().trim() : '';

        return safeComponent + '|' + safeDebtType + '|' + safeRelatedObject;
    }
}