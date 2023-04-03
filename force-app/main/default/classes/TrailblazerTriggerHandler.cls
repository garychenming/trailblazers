public inherited sharing class TrailblazerTriggerHandler {
    public TrailblazerTriggerHandler() {
    }

    public static void triggerHandler() {
        try {
            if (Trigger.isAfter && Trigger.isUpdate) {
                for (Trailblazer__c trailblazer : (List<Trailblazer__c>) Trigger.new) {
                    Trailblazer__c oldTrailblazer = (Trailblazer__c) Trigger.oldMap
                        .get(trailblazer.Id);

                    if (
                        oldTrailblazer.Badges__c != trailblazer.Badges__c ||
                        oldTrailblazer.Points__c != trailblazer.Points__c
                    ) {
                        notifySlack(trailblazer, oldTrailblazer);
                    }
                }
            }
        } catch (Exception ex) {
            insert new Log__c(
                ApexCodeName__c = 'TrailblazerTriggerHandler',
                Data__c = ex.getMessage() + ex.getLineNumber()
            );
        }
    }

    private static void notifySlack(Trailblazer__c trailblazer, Trailblazer__c oldTrailblazer) {
        Integer points = trailblazer.Points__c != null ? Integer.valueOf(trailblazer.Points__c) : 0;
        Integer oldPoints = oldTrailblazer.Points__c != null
            ? Integer.valueOf(oldTrailblazer.Points__c)
            : 0;
        Integer badges = trailblazer.Badges__c != null ? Integer.valueOf(trailblazer.Badges__c) : 0;
        Integer oldBadges = oldTrailblazer.Badges__c != null
            ? Integer.valueOf(oldTrailblazer.Badges__c)
            : 0;
        Integer badgeCount = Integer.valueOf(badges - oldBadges);
        Integer pointsCount = Integer.valueOf(points - oldPoints);

        notifySlack(
            trailblazer.Name,
            points,
            badges,
            badgeCount,
            pointsCount,
            trailblazer.NewPoints__c,
            trailblazer.NewBadges__c,
            trailblazer.ProfileUrl__c
        );
    }

    @future(callout=true)
    private static void notifySlack(
        String name,
        Integer points,
        Integer badges,
        Integer badgeCount,
        Integer pointsCount,
        Decimal newPointsThisMonth,
        Decimal totalBadgesThisMonth,
        String profileUrl
    ) {
        List<Map<String, Object>> attachments = new List<Map<String, Object>>();

        String badgesStr =
            'Name: <' +
            profileUrl +
            '|' +
            name +
            '>\n\nTotal Points: `' +
            points +
            '`\n Total Badges: `' +
            badges +
            '`\n New Points: `' +
            pointsCount +
            '`\n New Badges: `' +
            badgeCount +
            '`\n New Points This Month: `' +
            (Integer) newPointsThisMonth +
            '`\n New Badges This Month: `' +
            (Integer) totalBadgesThisMonth +
            '`';
        String message = JSON.serialize(
            new Map<String, Object>{ 'text' => badgesStr, 'attachments' => attachments }
        );

        SlackUtil.sendNotificationToSlack(message);
    }
}