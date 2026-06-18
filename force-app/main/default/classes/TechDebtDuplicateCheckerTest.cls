@IsTest
private class TechDebtDuplicateCheckerTest {

    @IsTest
    static void blocksDuplicateOpenTechnicalDebtItem() {
        Technical_Debt_Item__c firstItem = new Technical_Debt_Item__c(
            Component_Name__c = 'Resident Intake Flow',
            Debt_Type__c = 'Flow',
            Related_Object__c = 'Contact',
            Severity__c = 'Critical',
            Status__c = 'New',
            Risk_Score__c = 95
        );
        insert firstItem;

        Technical_Debt_Item__c duplicateItem = new Technical_Debt_Item__c(
            Component_Name__c = 'Resident Intake Flow',
            Debt_Type__c = 'Flow',
            Related_Object__c = 'Contact',
            Severity__c = 'High',
            Status__c = 'New',
            Risk_Score__c = 80
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(duplicateItem, false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess(), 'Duplicate record should be blocked.');
        System.assert(
            result.getErrors()[0].getMessage().contains('Duplicate detected'),
            'Error message should mention duplicate detection.'
        );
    }

    @IsTest
    static void allowsResolvedPreviousItem() {
        Technical_Debt_Item__c resolvedItem = new Technical_Debt_Item__c(
            Component_Name__c = 'Old Report Cleanup',
            Debt_Type__c = 'Report',
            Related_Object__c = 'Account',
            Severity__c = 'Low',
            Status__c = 'Resolved',
            Risk_Score__c = 20
        );
        insert resolvedItem;

        Technical_Debt_Item__c newItem = new Technical_Debt_Item__c(
            Component_Name__c = 'Old Report Cleanup',
            Debt_Type__c = 'Report',
            Related_Object__c = 'Account',
            Severity__c = 'Medium',
            Status__c = 'New',
            Risk_Score__c = 40
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(newItem, false);
        Test.stopTest();

        System.assertEquals(true, result.isSuccess(), 'Resolved previous item should not block a new item.');
    }

    @IsTest
    static void invocableMethodReturnsDuplicateResult() {
        Technical_Debt_Item__c existingItem = new Technical_Debt_Item__c(
            Component_Name__c = 'Contact Validation Rule',
            Debt_Type__c = 'Validation Rule',
            Related_Object__c = 'Contact',
            Severity__c = 'High',
            Status__c = 'New',
            Risk_Score__c = 75
        );
        insert existingItem;

        TechDebtDuplicateChecker.InvocableRequest request = new TechDebtDuplicateChecker.InvocableRequest();
        request.componentName = 'Contact Validation Rule';
        request.debtType = 'Validation Rule';
        request.relatedObject = 'Contact';

        Test.startTest();
        List<TechDebtDuplicateChecker.InvocableResponse> responses =
            TechDebtDuplicateChecker.checkFromFlow(
                new List<TechDebtDuplicateChecker.InvocableRequest>{ request }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].isDuplicate);
        System.assertNotEquals(null, responses[0].duplicateId);
    }
}