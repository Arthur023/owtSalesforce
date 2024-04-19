trigger JobApplicationTrigger on Job_Application__c (after insert, after update, before insert, before update ,
        after undelete , before delete , after delete) {
    TriggerDispatcher.Run(new JobApplicationTriggerHandler(), Trigger.operationType);
}