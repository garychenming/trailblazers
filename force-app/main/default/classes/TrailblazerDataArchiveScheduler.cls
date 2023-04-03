/**
 * System.Schedule('Trailblazer Data Archive Job', '0 0 01 1 * ? *', new TrailblazerDataArchiveScheduler());
 * Runs at the 1st day of every month
 */
public without sharing class TrailblazerDataArchiveScheduler implements Schedulable {
    public TrailblazerDataArchiveScheduler() {
    }

    public void execute(SchedulableContext sc) {
        List<Trailblazer__c> trailblazers = new List<Trailblazer__c>();
        Date lastDayOfLastMonth = Date.today().addDays(-1);

        for (Trailblazer__c trailblazer : [
            SELECT Points__c, Badges__c, PointsData__c, BadgesData__c, Rank__c
            FROM Trailblazer__c
        ]) {
            try {
                trailblazer.PointsLastMonth__c = trailblazer.Points__c;
                trailblazer.BadgesLastMonth__c = trailblazer.Badges__c;
                trailblazer.RankLastMonth__c = trailblazer.Rank__c;

                // put last month points to PointsData__c
                List<ArchiveData> oldPointsData = String.isBlank(trailblazer.PointsData__c)
                    ? new List<ArchiveData>()
                    : (List<ArchiveData>) JSON.deserialize(
                          trailblazer.PointsData__c,
                          List<ArchiveData>.class
                      );

                oldPointsData.add(
                    new ArchiveData(lastDayOfLastMonth, trailblazer.PointsLastMonth__c)
                );
                trailblazer.PointsData__c = JSON.serialize(oldPointsData);

                // put last month badges to BadgesData__c
                List<ArchiveData> oldBadgesData = String.isBlank(trailblazer.BadgesData__c)
                    ? new List<ArchiveData>()
                    : (List<ArchiveData>) JSON.deserialize(
                          trailblazer.BadgesData__c,
                          List<ArchiveData>.class
                      );

                oldBadgesData.add(
                    new ArchiveData(lastDayOfLastMonth, trailblazer.BadgesLastMonth__c)
                );
                trailblazer.BadgesData__c = JSON.serialize(oldBadgesData);

                trailblazers.add(trailblazer);
            } catch (Exception ex) {
                insert new Log__c(
                    ApexCodeName__c = 'TrailblazerDataArchiveScheduler',
                    Data__c = ex.getMessage() + '------' + ex.getLineNumber()
                );
            }
        }

        update trailblazers;
    }
    private class ArchiveData {
        public ArchiveData(Date dataDate, Decimal count) {
            this.dataDate = dataDate;
            this.count = count;
        }

        public Date dataDate { get; set; }
        public Decimal count { get; set; }
    }
}