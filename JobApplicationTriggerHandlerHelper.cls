/**
 * Created by arthurvandevelde on 10/04/2024.
 * Helper class for Job Application Trigger Handler.
 */

public with sharing class JobApplicationTriggerHandlerHelper {
    /**
     * Adds Job Opportunity and External Id to new job applications.
     * @param newItems List of new job applications.
     */
    public static void addJobOpportunityAndExternalId(List<SObject> newItems){
        // Get the ID of the direct job application
        Id directJobApplicationId = [SELECT Id FROM Job_Opportunity__c WHERE Job_Opportunity_Number__c = 'JO-0000' LIMIT 1].Id;

        // Loop through new job applications
        for(Job_Application__c singleJobApplication : (List<Job_Application__c>) newItems){
            // If Job Opportunity is not assigned, set it to direct job application
            if(singleJobApplication.Job_Opportunity__c == null){
                singleJobApplication.Job_Opportunity__c = directJobApplicationId;
                singleJobApplication.External_Id__c = directJobApplicationId + '_' + singleJobApplication.Email__c;
            } else {
                // Otherwise, set External Id based on Job Opportunity and Email
                singleJobApplication.External_Id__c =  singleJobApplication.Job_Opportunity__c + '_'+ singleJobApplication.Email__c;
            }
        }
    }

    /**
     * Adds random External Id numbers to new job applications.
     * @param newItems List of new job applications.
     */
    public static void addExternalIdRandomNumber(List<SObject> newItems){
        for(Job_Application__c singleJobApplication:(List<Job_Application__c>) newItems){
            singleJobApplication.External_Id_Random_Number__c = RandomIdGenerator.generateRandomString(15);
        }
    }

    /**
     * Checks if contacts or leads exist with job application emails and updates job applications accordingly.
     * If no contact or lead exist then return that Job Application ID in a list
     * @param newItems Map of new job applications.
     * @return List of job application IDs with emails not found in existing contacts or leads.
     */
    public static List<Id> checkAndCreateContact(Map<Id, SObject> newItems){
        Set<String> emailSet = new Set<String>();
        List<Id> newJobApplicationsWithEmailNotInResults = new List<Id>();
        Map<String,SObject> newItemsMapEmailKey = new Map<String,SObject>();
        List<Error_Log__c> errorLogListToInsert = new List<Error_Log__c>();

        newItemsMapEmailKey = buildSobjectMap('Email__c', newItems);

        // Collect all email addresses from the new items
        for(SObject record : newItems.values()) {
            emailSet.add((String)record.get('Email__c'));
        }

        // Execute SOSL query to find existing contacts and leads with the given email addresses
        String[] searchTerms = new List<String>(emailSet);
        String searchTermString = String.join(searchTerms, ' OR ');

        List<List<SObject>> searchResults = [FIND :searchTermString IN EMAIL FIELDS RETURNING Contact(Id, Email), Lead(Id, Email)];

        Contact[] existingContacts = (Contact[])searchResults[0];
        Lead[] existingLeads = (Lead[])searchResults[1];

        List<Job_Application__c> jobsToUpdateLeadContact = new List<Job_Application__c>();

        // Create a set to store email addresses of existing contacts and leads
        // Add Contact and Leads to Job Applications
        Set<String> existingEmails = new Set<String>();
        for (Contact singleCon : existingContacts) {
            existingEmails.add(singleCon.Email);
            Job_Application__c job = (Job_Application__c) newItemsMapEmailKey.get(singleCon.Email);
            if(job != null){
                job.Contact__c = singleCon.Id;
                jobsToUpdateLeadContact.add(job);
            }
        }
        for (Lead singleLead : existingLeads) {
            existingEmails.add(singleLead.Email);
            Job_Application__c job = (Job_Application__c) newItemsMapEmailKey.get(singleLead.Email);
            if(job != null){
                job.Lead__c = singleLead.Id;
                jobsToUpdateLeadContact.add(job);
            }
        }
        if(!jobsToUpdateLeadContact.isEmpty()){
            try{
                update jobsToUpdateLeadContact;
            } catch(DMLException e){
                system.debug('Error while updating contacts and leads to Job_Applications.');
                system.debug('Message: '+ e.getMessage());
                errorLogListToInsert.add(ErrorLog.createErrorLog('JobApplicationTriggerHandlerHelper.checkAndCreateContact','Update: jobsToUpdateLeadContact',75,'update jobsToUpdateLeadContact failed',e.getMessage()));
            }
        }

        // Add new items to the result list if their email address wasn't found in SOSL query results
        for (SObject newItem : newItems.values()) {
            String newJobApplicationEmail = (String) newItem.get('Email__c');
            if (!existingEmails.contains(newJobApplicationEmail)) {
                newJobApplicationsWithEmailNotInResults.add(newItem.Id);
            }
        }

        if(!errorLogListToInsert.isEmpty()){
            try{
                insert (List<SObject>) errorLogListToInsert;
            } catch(Exception e){
                System.debug('Failed to insert Error_Log__c.');
            }
        }
        return newJobApplicationsWithEmailNotInResults;
    }

    /**
     * Creates leads for job applications and updates job applications with lead IDs.
     * @param jobApplications List of job application IDs.
     * @param newItems Map of new job applications.
     */
    public static void createLeadForJobApplication(List<Id> jobApplications, Map<Id,SObject> newItems){
        List<Lead> leadsToAdd = new List<Lead>();
        List<Error_Log__c> errorLogListToInsert = new List<Error_Log__c>();
        Map<Id, Id> jobApplicationLeadMap = new Map<Id, Id>();
        List<Job_Application__c> jobApplicationsToUpdate = new List<Job_Application__c>();
        for (Id jobId : newItems.keySet()) {
            if (jobApplications.contains(jobId)) {
                Job_Application__c singleJob = (Job_Application__c) newItems.get(jobId);
                Lead leadToAdd = new Lead(
                        Email = singleJob.Email__c,

                        FirstName = singleJob.First_Name__c,
                        LastName = singleJob.Last_Name__c,
                        Company = 'Job Application'
                );
                leadsToAdd.add(leadToAdd);
                jobApplicationLeadMap.put(jobId, null);
            }
        }

        // Insert the lead records to obtain their IDs
        List<Database.SaveResult> leadInsertResults = Database.insert(leadsToAdd, false);

        // Iterate through the results to check for successful insertions
        for(Integer i = 0; i < leadInsertResults.size(); i++) {
            if(leadInsertResults[i].isSuccess()) {
                jobApplicationLeadMap.put(jobApplications[i], leadsToAdd[i].Id);
            } else {
                for(Database.Error err : leadInsertResults[i].getErrors()) {
                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                    String errorMessage = 'Status code: ' + err.getStatusCode() + ': ' +err.getMessage();
                    errorLogListToInsert.add(ErrorLog.createErrorLog('JobApplicationTriggerHandlerHelper.createLeadForJobApplication','createLeadForJobApplication',115,'leadsToAdd failed to add a Lead',errorMessage));
                }
            }
        }
        // Update the Lead__c lookup field on newItems with the correctly inserted lead IDs
        for (Id jobId : jobApplicationLeadMap.keySet()) {
            Id leadId = jobApplicationLeadMap.get(jobId);
            if (leadId != null) {
                // Update the Lead__c lookup field on the newItems record
                SObject newItem = newItems.get(jobId);
                newItem.put('Lead__c', leadId);
                newItem.put('id',jobId);
                jobApplicationsToUpdate.add((Job_Application__c) newItem);
            }
        }

        // Perform DML operation to update newItems
        try{
            update jobApplicationsToUpdate;
        } catch(Exception e){
            errorLogListToInsert.add(ErrorLog.createErrorLog('JobApplicationTriggerHandlerHelper.createLeadForJobApplication','jobApplications',146,'update jobApplications failed',e.getMessage()));
        }
       if(!errorLogListToInsert.isEmpty()){
           try{
               insert (List<SObject>) errorLogListToInsert;
           } catch(Exception e){
               System.debug('Failed to insert Error_Log__c.');
           }
       }
    }

    /**
     * Builds a map with specified field as the key and SObject as the value.
     * @param mapIdField Field to use as the key.
     * @param sObjectMap Map of SObjects.
     * @return Map with field values as keys and corresponding SObjects.
     */
    public static Map<String, SObject> buildSobjectMap(String mapIdField, Map<Id, SObject> sObjectMap){
        Map<String, SObject> newsObjectMap = new Map<String, SObject>();
        for (Id recordId : sObjectMap.keySet()) {
            SObject sObjectRecord = sObjectMap.get(recordId);
            if (sObjectRecord.get(mapIdField) != null) {
                String fieldValueString = String.valueOf(sObjectRecord.get(mapIdField));
                newsObjectMap.put(fieldValueString, sObjectRecord);
                sObjectRecord.put('Id', recordId);
            }
        }
        return newsObjectMap;
    }
}
