public with sharing class TechDebtEscalationScheduler implements Schedulable {

    private static final Map<String, String> ESCALATION_MAP = new Map<String, String>{
        'Low'    => 'Medium',
        'Medium' => 'High',
        'High'   => 'Critical'
    };

    public void execute(SchedulableContext ctx) {
        Date today = Date.today();

        List<Technical_Debt_Item__c> overdueItems = [
            SELECT Id, Severity__c, Status__c, Description__c, Target_Resolution_Date_c__c
            FROM Technical_Debt_Item__c
            WHERE Target_Resolution_Date_c__c < :today
              AND Status__c IN ('New', 'In Progress')
              AND Severity__c IN ('Low', 'Medium', 'High')
            LIMIT 200
        ];

        if (overdueItems.isEmpty()) return;

        List<Technical_Debt_Item__c> toUpdate = new List<Technical_Debt_Item__c>();
        String timestamp = String.valueOf(Datetime.now().format('yyyy-MM-dd HH:mm'));

        for (Technical_Debt_Item__c item : overdueItems) {
            String nextSeverity = ESCALATION_MAP.get(item.Severity__c);
            if (nextSeverity == null) continue;

            item.Severity__c = nextSeverity;
            item.Description__c = (item.Description__c != null ? item.Description__c : '')
                + '\n[AUTO-ESCALATED ' + timestamp + '] Severity raised to '
                + nextSeverity + ' — past target resolution date.';

            toUpdate.add(item);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}