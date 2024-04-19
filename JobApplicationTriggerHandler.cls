public class JobApplicationTriggerHandler  implements ITriggerHandler{
    public Boolean IsDisabled() {
        return false;
    }

    public void BeforeInsert(List<SObject> newItems) {
        JobApplicationTriggerHandlerHelper.addJobOpportunityAndExternalId(newItems);
        JobApplicationTriggerHandlerHelper.addExternalIdRandomNumber(newItems);
    }

    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {

    }

    public void BeforeDelete(Map<Id, SObject> oldItems) {
    }

    public void AfterInsert(Map<Id, SObject> newItems) {
        Map<Id, SObject> editableItems = new Map<Id, SObject>();
        // Iterate over the original map and clone each record
        for (Id recordId : newItems.keySet()) {
            SObject originalRecord = newItems.get(recordId);
            // Clone the record to obtain an editable copy
            SObject editableRecord = originalRecord.clone(false, true, false, false);
            // Add the editable copy to the new map
            editableItems.put(recordId, editableRecord);
        }

        List<Id> newJobApplicationsWithoutContactOrLead = JobApplicationTriggerHandlerHelper.checkAndCreateContact(editableItems);
        if(!newJobApplicationsWithoutContactOrLead.isEmpty()){
            JobApplicationTriggerHandlerHelper.createLeadForJobApplication(newJobApplicationsWithoutContactOrLead, editableItems);
        }
    }

    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }

    public void AfterDelete(Map<Id, SObject> oldItems) {
    }

    public void AfterUndelete(Map<Id, SObject> oldItems) {
    }
}