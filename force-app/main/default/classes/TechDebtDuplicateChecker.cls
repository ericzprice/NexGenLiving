public with sharing class TechDebtDuplicateChecker {
    public static void checkBeforeInsert(List<Technical_Debt_Item__c> newRecords) {
        Set<String> debtTypes = new Set<String>();

        for (Technical_Debt_Item__c rec : newRecords) {
            if (String.isNotBlank(rec.Debt_Type__c)) {
                debtTypes.add(rec.Debt_Type__c);
            }
        }

        List<Technical_Debt_Item__c> existingRecords = [
            SELECT Id, Component_Name__c, Debt_Type__c, Status__c
            FROM Technical_Debt_Item__c
            WHERE Status__c != 'Resolved'
            AND Debt_Type__c IN :debtTypes
        ];

        Set<String> existingKeys = new Set<String>();
        for (Technical_Debt_Item__c existing : existingRecords) {
            existingKeys.add(buildKey(existing.Component_Name__c, existing.Debt_Type__c));
        }

        for (Technical_Debt_Item__c rec : newRecords) {
            String newKey = buildKey(rec.Component_Name__c, rec.Debt_Type__c);
            if (existingKeys.contains(newKey)) {
                rec.addError('Duplicate technical debt item found. An open item already exists with the same Component Name and Debt Type.');
            }
        }
    }

    @TestVisible
    private static String buildKey(String componentName, String debtType) {
        String safeComponent = String.isNotBlank(componentName) ? componentName.toLowerCase().trim() : '';
        String safeDebtType = String.isNotBlank(debtType) ? debtType.toLowerCase().trim() : '';
        return safeComponent + '|' + safeDebtType;
    }
}