public without sharing class TrailblazersReptile implements Queueable, Database.AllowsCallouts {
    private string trailblazerId;

    public TrailblazersReptile(String trailblazerId) {
        this.trailblazerId = trailblazerId;
    }

    public void execute(QueueableContext qc) {
        Integer elevenOClock = Datetime.now().hour();

        List<Trailblazer__c> trailblazers = [
            SELECT
                Name,
                Points__c,
                Rank__c,
                Badges__c,
                TrailheadUserId__c,
                ProfileUrl__c,
                IsCharketEmployee__c,
                IsActive__c,
                CertificationCount__c
            FROM Trailblazer__c
            WHERE IsActive__c = TRUE
            ORDER BY NAME
        ];

        List<String> errorMessages = new List<String>();

        for (Trailblazer__c trailblazer : trailblazers) {
            try {
                String[] urlParts = trailblazer.ProfileUrl__c.split('/');
                String trailheadUserSlug = urlParts[urlParts.size() - 1];

                GetTrailheadPointsApi.TrailheadProfileStats result = GetTrailheadPointsApi.get(
                    trailheadUserSlug
                );

                if (result.data.profileBySlug.typename == 'PrivateProfile' && elevenOClock == 11) {
                    errorMessages.add('PrivateProfile: ' + trailblazer);
                    continue;
                }

                trailblazer.Points__c = result.data.profileBySlug.trailheadStats.earnedPointsSum;
                trailblazer.Badges__c = result.data.profileBySlug.trailheadStats.earnedBadgesCount;
                trailblazer.Rank__c = result.data.profileBySlug.trailheadStats.rank.title;

                GetTrailheadPointsApi.GetCertificationResult getCertificationResult = GetTrailheadPointsApi.getCertifications(
                    trailheadUserSlug
                );

                if (
                    trailblazer.CertificationCount__c ==
                    getCertificationResult.data.profile.credential.certifications.size()
                ) {
                    continue;
                }

                trailblazer.CertificationCount__c = getCertificationResult.data.profile.credential.certifications.size();
                trailblazer.CertificationsData__c = JSON.serialize(
                    getCertificationResult.data.profile.credential.certifications
                );
            } catch (GetTrailheadPointsApi.GetTrailheadPointsApiException ex) {
                if (
                    ex.getMessage() == 'Read timed out' ||
                    ex.getMessage() == 'This request cannot be completed' ||
                    ex.getMessage() == 'Too many requests. Please try again after some time.' ||
                    ex.getMessage() == 'Failed to retrieve this field'
                ) {
                    continue;
                }

                errorMessages.add(ex.getMessage());
                // TrailblazerIdCorrecter.correct(trailblazer);
            } catch (Exception ex) {
                if (
                    ex.getMessage() == 'Read timed out' ||
                    ex.getMessage() == 'This request cannot be completed' ||
                    ex.getMessage() == 'Too many requests. Please try again after some time.' ||
                    ex.getMessage() == 'Failed to retrieve this field'
                ) {
                    continue;
                }

                errorMessages.add(
                    ex.getMessage() +
                    '----' +
                    ex.getLineNumber() +
                    '---' +
                    trailblazer
                );
            }
        }

        if (errorMessages.size() > 0) {
            String message = JSON.serialize(
                new Map<String, Object>{
                    'text' => JSON.serialize(errorMessages),
                    'attachments' => new List<Map<String, Object>>()
                }
            );
            SlackUtil.sendNotificationToSlack(message);
        }

        update trailblazers;
    }
}