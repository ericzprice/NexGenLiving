@isTest
private class TechDebtEscalationSchedulerTest {

    @TestSetup
    static void makeData() {
        List<Technical_Debt_Item__c> items = new List<Technical_Debt_Item__c>{
            new Technical_Debt_Item__c(
                Status__c = 'New',
                Severity__c = 'Low',
                Target_Resolution_Date_c__c = Date.today().addDays(-5)
            ),
            new Technical_Debt_Item__c(
                Status__c = 'In Progress',
                Severity__c = 'Medium',
                Target_Resolution_Date_c__c = Date.today().addDays(-1)
            ),
            new Technical_Debt_Item__c(
                Status__c = 'New',
                Severity__c = 'Critical',
                Target_Resolution_Date_c__c = Date.today().addDays(-3)
            ),
            new Technical_Debt_Item__c(
                Status__c = 'New',
                Severity__c = 'Low',
                Target_Resolution_Date_c__c = Date.today().addDays(10)
            )
        };
        insert items;
    }

    @isTest
    static void testEscalationLogic() {
        List<Technical_Debt_Item__c> inserted = [
            SELECT Id, Severity__c, Target_Resolution_Date_c__c
            FROM Technical_Debt_Item__c
            ORDER BY Target_Resolution_Date_c__c ASC
        ];

        Test.startTest();
        TechDebtEscalationScheduler scheduler = new TechDebtEscalationScheduler();
        scheduler.execute(null);
        Test.stopTest();

        Map<Id, Technical_Debt_Item__c> resultMap = new Map<Id, Technical_Debt_Item__c>([
            SELECT Id, Severity__c, Description__c
            FROM Technical_Debt_Item__c
        ]);

        // index 0 = -5 days, Low → Medium
        System.assertEquals('Medium', resultMap.get(inserted[0].Id).Severity__c, 'Should escalate Low to Medium');
        System.assert(resultMap.get(inserted[0].Id).Description__c.contains('AUTO-ESCALATED'), 'Description should contain escalation note');

        // index 1 = -3 days, Critical → unchanged
        System.assertEquals('Critical', resultMap.get(inserted[1].Id).Severity__c, 'Critical should stay Critical');

        // index 2 = -1 day, Medium → High
        System.assertEquals('High', resultMap.get(inserted[2].Id).Severity__c, 'Should escalate Medium to High');

        // index 3 = +10 days, Low → unchanged
        System.assertEquals('Low', resultMap.get(inserted[3].Id).Severity__c, 'Future-dated should stay Low');
    }

    @isTest
    static void testScheduling() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Nightly Escalation',
            '0 0 2 * * ?',
            new TechDebtEscalationScheduler()
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job should be scheduled successfully');
    }
}