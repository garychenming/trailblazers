public with sharing class SlackUtil {
    public SlackUtil() {
    }

    public static void sendNotificationToSlack(String message) {
        SlackSettings__c settings = SlackSettings__c.getInstance(UserInfo.getUserId());

        HttpRequest request = new HttpRequest();
        request.setEndpoint(settings.WebhookURL__c);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(message);
        HttpResponse response = (new Http()).send(request);
    }
}