/**
 * Created by arthurvandevelde on 10/04/2024.
 */
@RestResource(UrlMapping='/SendJobApplication/*')
global with sharing class RestApiClassJobApplication {
    @HttpGet
    global static List<JobOpportunityWrapper> returnOpenJobOpportunities(){
        List<JobOpportunityWrapper> jobOpportunities = new List<JobOpportunityWrapper>();
        // Query open job opportunities
        List<Job_Opportunity__c> openJobs = [SELECT Id, Name FROM Job_Opportunity__c WHERE Is_Active__c = true];
        // Convert records to wrapper class
        for (Job_Opportunity__c job : openJobs) {
            JobOpportunityWrapper opportunityWrapper = new JobOpportunityWrapper();
            opportunityWrapper.id = job.Id;
            opportunityWrapper.name = job.Name;
            jobOpportunities.add(opportunityWrapper);
        }
        return jobOpportunities;
    }
    @HttpPost
    global static String createJobApplications(JobApplicationWrapper newJsonJobApplication){
        String firstName = newJsonJobApplication.first_name;
        String lastName = newJsonJobApplication.last_name;
        String email = newJsonJobApplication.email;
        String jobOppId = newJsonJobApplication.jobOppId;
        Job_Application__c jobApp = new Job_Application__c();
        jobApp.First_Name__c = firstName;
        jobApp.Last_Name__c  = lastName;
        jobApp.Email__c = email;
        jobApp.Job_Opportunity__c = jobOppId;

        try{
            insert jobApp;
            Id jobId = jobApp.Id;
            system.debug('Inserted Job Application Id: ' + jobId);

            String jobExternalId = [SELECT Id,External_Id__c from Job_Application__c where id =: jobId LIMIT 1].External_Id__c;
            system.debug('Inserted Job Application jobExternalId: ' + jobExternalId);
            return 'Succes, external_id = ' + jobExternalId;
        } catch(Exception e){
            system.debug(e.getMessage());
            return e.getMessage();
        }
    }
    global class JobApplicationWrapper {
        global String first_name { get; set; }
        global String last_name { get; set; }
        global String email { get; set; }
        global String jobOppId { get; set; }
    }
    global class JobOpportunityWrapper {
        global String id { get; set; }
        global String name { get; set; }
    }
}

