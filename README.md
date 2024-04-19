# OWT Salesforce code

## Overview

This project is designed to handle job applications through Salesforce. It consists of trigger logic, handler classes, and a REST API endpoint to manage job application data efficiently.

## Project Structure

- **Trigger:** `JobApplicationTrigger`
  - This trigger initiates the processing of job applications when certain events occur in Salesforce.

- **Class:** `JobApplicationTriggerHandler`
  - This class contains the main logic for handling job application events triggered by `JobApplicationTrigger`.

- **Helper Class:** `JobApplicationTriggerHandlerHelper`
  - The helper class provides additional support and functions for the main trigger handler.

- **REST API Endpoint:** `RestApiClassJobApplication`
  - This endpoint facilitates interaction with job application data via RESTful APIs.


