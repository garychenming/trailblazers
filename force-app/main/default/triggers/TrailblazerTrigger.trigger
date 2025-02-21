trigger TrailblazerTrigger on Trailblazer__c (before insert, before update, after insert, after update, before delete, after delete) {
    TrailblazerTriggerHandler.triggerHandler();
}