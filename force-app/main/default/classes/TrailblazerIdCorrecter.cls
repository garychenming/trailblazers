public inherited sharing class TrailblazerIdCorrecter {
    public static void correct(Trailblazer__c trailblazer) {
        String message;

        try {
            String dataStr = callout(trailblazer.ProfileUrl__c);
            String data = getData(dataStr);
            String id = data.substringBetween('sobjects/User/', '\\\"');
            message =
                id +
                '----' +
                trailblazer.TrailheadUserId__c +
                'id == trailblazer.TrailheadUserId__c: ' +
                (id == trailblazer.TrailheadUserId__c);

            // 如果通过 profile url 获取不到 id 说明这个 id 已经不存在了
            if (String.isBlank(id)) {
                trailblazer.IsActive__c = false;
                notifySlack(trailblazer, message);
            } else if (id != trailblazer.TrailheadUserId__c) {
                trailblazer.TrailheadUserId__c = id;
            }
        } catch (Exception ex) {
            trailblazer.IsActive__c = false;
            notifySlack(trailblazer, message + '\n\nError Message: ' + ex.getMessage());
        }
    }

    private static String getData(String dataStr) {
        if (dataStr.containsIgnoreCase('redirected')) {
            String newUrl = dataStr.substringBetween(
                    'You are being <a href=\"',
                    '\">redirected</a>'
                )
                .replaceAll('amp;', '');

            String newData = callout(newUrl);
            return getData(newData);
        } else {
            return dataStr;
        }
    }

    private static String callout(String url) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        HttpResponse response = (new Http()).send(request);
        return response.getBody();
    }

    private static void notifySlack(Trailblazer__c trailblazer, String errorMessage) {
        List<Map<String, Object>> attachments = new List<Map<String, Object>>();
        String data =
            'Name : `' +
            trailblazer.Name +
            '`\nProfile URL: ' +
            trailblazer.ProfileUrl__c +
            '\nTrailhead ID: `' +
            trailblazer.TrailheadUserId__c +
            '`\n\nMessage: ' +
            errorMessage;

        String message = JSON.serialize(
            new Map<String, Object>{ 'text' => data, 'attachments' => attachments }
        );
        SlackUtil.sendNotificationToSlack(message);
    }
}