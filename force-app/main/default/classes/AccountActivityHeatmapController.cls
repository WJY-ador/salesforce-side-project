public with sharing class AccountActivityHeatmapController {

    public class ActivityWrapper {
        @AuraEnabled public String activityId;
        @AuraEnabled public String activityDate;
        @AuraEnabled public String subject;
        @AuraEnabled public String type;
        @AuraEnabled public String subtype;
        @AuraEnabled public String priority;
        @AuraEnabled public String status;
    }

    @AuraEnabled(cacheable=true)
    public static List<ActivityWrapper> getAccountActivities(Id accountId, Integer daysBack) {
        if (accountId == null) return new List<ActivityWrapper>();

        Integer days = 90;
        if (daysBack != null && daysBack > 0) {
            days = daysBack;
        }
        Date queryDate = Date.today().addDays(0 - days);

        List<ActivityWrapper> results = new List<ActivityWrapper>();

        for (Task t : [
            SELECT Id, Subject, Status, ActivityDate, Priority, TaskSubtype
            FROM Task
            WHERE WhatId = :accountId
              AND ActivityDate >= :queryDate
            LIMIT 1000
        ]) {
            ActivityWrapper w = new ActivityWrapper();
            w.activityId   = t.Id;
            w.activityDate = String.valueOf(t.ActivityDate);
            w.subject      = t.Subject;
            w.type         = 'Task';
            w.subtype      = t.TaskSubtype;
            w.priority     = t.Priority;
            w.status       = t.Status;
            results.add(w);
        }

        for (Event e : [
            SELECT Id, Subject, StartDateTime, Type
            FROM Event
            WHERE WhatId = :accountId
              AND DAY_ONLY(StartDateTime) >= :queryDate
            LIMIT 1000
        ]) {
            ActivityWrapper w = new ActivityWrapper();
            w.activityId   = e.Id;
            w.activityDate = String.valueOf(e.StartDateTime.date());
            w.subject      = e.Subject;
            w.type         = 'Event';
            w.subtype      = e.Type;
            w.priority     = null;
            w.status       = null;
            results.add(w);
        }

        return results;
    }
}
