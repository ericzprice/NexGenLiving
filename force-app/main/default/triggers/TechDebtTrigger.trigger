trigger TechDebtTrigger on Technical_Debt_Item__c (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        TechDebtDuplicateChecker.checkBeforeInsert(Trigger.new);
    }
}