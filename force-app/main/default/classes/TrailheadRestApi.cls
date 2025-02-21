@RestResource(urlMapping='/trailhead/*')
global without sharing class TrailheadRestApi {
    @HttpPost
    global static void doPost() {
        try {
            String param = RestContext.request.params.get('text');

            String result;

            if (param == 'points' || param == 'p') {
                result = getPointRanks();
            } else if (param == 'badges' || param == 'b') {
                result = getBadgeRanks();
            } else if (param == 'last month' || param == 'l') {
                result = getLastMonthRanks();
            } else if (param == 'all' || param == 'a') {
                result = getMonthRanks();
            } else {
                result = getBadgeRanks();
            }

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(result);
        } catch (Exception ex) {
        }
    }

    private static String getPointRanks() {
        return formats(
            [
                SELECT
                    ProfileUrl__c,
                    Name,
                    Points__c,
                    Rank__c,
                    Badges__c,
                    NewPoints__c,
                    CertificationCount__c,
                    NewBadges__c
                FROM Trailblazer__c
                WHERE IsCharketEmployee__c = TRUE AND NewPoints__c > 0
                ORDER BY NewPoints__c DESC, NewBadges__c DESC
            ]
        );
    }

    private static String getBadgeRanks() {
        return formats(
            [
                SELECT
                    ProfileUrl__c,
                    Name,
                    Points__c,
                    Rank__c,
                    Badges__c,
                    NewPoints__c,
                    CertificationCount__c,
                    NewBadges__c
                FROM Trailblazer__c
                WHERE IsCharketEmployee__c = TRUE AND NewBadges__c > 0
                ORDER BY NewBadges__c DESC, NewPoints__c DESC
            ]
        );
    }

    private static String getMonthRanks() {
        return formats(
            [
                SELECT
                    ProfileUrl__c,
                    Name,
                    Points__c,
                    Rank__c,
                    Badges__c,
                    NewPoints__c,
                    CertificationCount__c,
                    NewBadges__c
                FROM Trailblazer__c
                WHERE IsCharketEmployee__c = TRUE
                ORDER BY Name
            ]
        );
    }

    private static String getLastMonthRanks() {
        List<Trailblazer> trailblazers = new List<Trailblazer>();

        for (Trailblazer__c t : [
            SELECT Id, Name, RankLastMonth__c, BadgesLastMonth__c, PointsLastMonth__c
            FROM Trailblazer__c
            WHERE IsCharketEmployee__c = TRUE
            ORDER BY Name
        ]) {
            trailblazers.add(new Trailblazer(t));
        }

        return JSON.serialize(trailblazers);
    }

    private static String formats(List<Trailblazer__c> trailblazers) {
        String result = '';
        Integer totalBadges = 0;
        Integer totalPoints = 0;

        for (Trailblazer__c trailblazer : trailblazers) {
            result += format(trailblazer, trailblazers.indexOf(trailblazer));
            totalBadges += (Integer) trailblazer.NewBadges__c;
            totalPoints += (Integer) trailblazer.NewPoints__c;
        }

        result +=
            '\nTotal Count: ' +
            trailblazers.size() +
            '\n' +
            'Total Badges: ' +
            totalBadges +
            '\n' +
            'Total Points: ' +
            totalPoints;

        return result;
    }

    private static String format(Trailblazer__c trailblazer, Integer index) {
        return (index + 1) +
            '. Points: `' +
            trailblazer.Points__c +
            '` Badges: `' +
            trailblazer.Badges__c +
            '` New Points: `' +
            (Integer) trailblazer.NewPoints__c +
            '` New Badges: `' +
            (Integer) trailblazer.NewBadges__c +
            '` Rank: `' +
            trailblazer.Rank__c +
            '` Certs: `' +
            trailblazer.CertificationCount__c +
            '` Name: <' +
            trailblazer.ProfileUrl__c +
            '|' +
            trailblazer.Name +
            '>\n\n';
    }

    private class Trailblazer {
        private Trailblazer(Trailblazer__c t) {
            this.name = t.Name;
            this.rankLastMonth = t.RankLastMonth__c;
            this.badgesLastMonth = (Integer) t.BadgesLastMonth__c;
            this.pointsLastMonth = (Integer) t.PointsLastMonth__c;
        }

        private String name { get; set; }
        private String rankLastMonth { get; set; }
        private Integer badgesLastMonth { get; set; }
        private Integer pointsLastMonth { get; set; }
    }
}