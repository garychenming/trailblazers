public with sharing class TrailblazerScheduler implements Schedulable {
    public TrailblazerScheduler() {
    }

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new TrailblazersReptile(null));

        for (CronTrigger job : [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Trailblazer Every 2 Minutes Job'
        ]) {
            System.abortJob(job.Id);
        }

        //Datetime now = Datetime.now();
        //System.Schedule('Trailblazer Hourly Job' + now, '0 0 1/1,0  * * ? *', new TrailblazerScheduler());
        Datetime now = Datetime.now().addMinutes(2);

        String jobTime =
            '' +
            now.second() +
            ' ' +
            now.minute() +
            ' ' +
            now.hour() +
            ' ' +
            now.day() +
            ' ' +
            now.month() +
            ' ? ' +
            now.year();

        System.Schedule('Trailblazer Every 2 Minutes Job', jobTime, new TrailblazerScheduler());
    }
}