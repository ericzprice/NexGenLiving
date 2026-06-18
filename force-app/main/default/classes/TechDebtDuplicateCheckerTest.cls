@IsTest
private class TechDebtDuplicateCheckerTest {

    @IsTest
    static void preventsDuplicateOpenTechnicalDebtItems() {
        Technical_Debt_Item__c firstItem = new Technical_Debt_Item__c(
            Component_Name__c = 'Duplicate Test Flow',
            Debt_Type__c = 'Flow',
            Status__c = 'New'
        );
        insert firstItem;

        Technical_Debt_Item__c duplicateItem = new Technical_Debt_Item__c(
            Component_Name__c = 'Duplicate Test Flow',
            Debt_Type__c = 'Flow',
            Status__c = 'New'
        );

        Test.startTest();
        try {
            insert duplicateItem;
            System.assert(false, 'Expected duplicate insert to fail.');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Duplicate technical debt item found'),
                'Expected duplicate error message.'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void allowsDifferentDebtType() {
        insert new Technical_Debt_Item__c(
            Component_Name__c = 'Shared Component Name',
            Debt_Type__c = 'Flow',
            Status__c = 'New'
        );

        Technical_Debt_Item__c differentType = new Technical_Debt_Item__c(
            Component_Name__c = 'Shared Component Name',
            Debt_Type__c = 'Report',
            Status__c = 'New'
        );

        insert differentType;

        System.assertNotEquals(null, differentType.Id);
    }

    @IsTest
    static void allowsDuplicateWhenExistingIsResolved() {
        insert new Technical_Debt_Item__c(
            Component_Name__c = 'Resolved Duplicate Test',
            Debt_Type__c = 'Flow',
            Status__c = 'Resolved'
        );

        Technical_Debt_Item__c newOpenItem = new Technical_Debt_Item__c(
            Component_Name__c = 'Resolved Duplicate Test',
            Debt_Type__c = 'Flow',
            Status__c = 'New'
        );

        insert newOpenItem;

        System.assertNotEquals(null, newOpenItem.Id);
    }
}
