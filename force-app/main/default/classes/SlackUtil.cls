public with sharing class SlackUtil {
    public SlackUtil() {
    }

    public static void sendNotificationToSlack(String message) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(
            'https://hooks.slack.com/services/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'
        );
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(message);
        HttpResponse response = (new Http()).send(request);
    }
}