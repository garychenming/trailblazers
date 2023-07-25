public without sharing class TrailblazersReptile implements Queueable, Database.AllowsCallouts {
    private string trailblazerId;

    public TrailblazersReptile(String trailblazerId) {
        this.trailblazerId = trailblazerId;
    }

    public void execute(QueueableContext qc) {
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
                Id
            FROM Trailblazer__c
            WHERE IsActive__c = TRUE
            ORDER BY NAME
        ];

        for (Trailblazer__c trailblazer : trailblazers) {
            try {
                String[] urlParts = trailblazer.ProfileUrl__c.split('/');
                String trailheadUserSlug = urlParts[urlParts.size() - 1];

                GetTrailheadPointsApi.TrailheadProfileStats result = GetTrailheadPointsApi.get(
                    trailheadUserSlug
                );
                trailblazer.Points__c = result.data.profileBySlug.trailheadStats.earnedPointsSum;
                trailblazer.Badges__c = result.data.profileBySlug.trailheadStats.earnedBadgesCount;
                trailblazer.Rank__c = result.data.profileBySlug.trailheadStats.rank.title;
            } catch (GetTrailheadPointsApi.GetTrailheadPointsApiException ex) {
                TrailblazerIdCorrecter.correct(trailblazer);
            } catch (Exception ex) {
            }
        }

        update trailblazers;
    }
}