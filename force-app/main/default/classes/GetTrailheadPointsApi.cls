public inherited sharing class GetTrailheadPointsApi {
    public static TrailheadProfileStats get(String trailblazerId) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://profile.api.trailhead.com/graphql');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        request.setBody(getBody(trailblazerId));
        HttpResponse res = (new Http()).send(request);

        TrailheadProfileStats trailheadProfileStats = (TrailheadProfileStats) JSON.deserialize(
            res.getBody().replace('__typename', 'typename'),
            TrailheadProfileStats.class
        );

        if (trailheadProfileStats.errors != null && trailheadProfileStats.errors.size() > 0) {
            throw new GetTrailheadPointsApiException(trailheadProfileStats.errors[0].message);
        }

        return trailheadProfileStats;
    }

    private static String getBody(String trailblazerId) {
        return JSON.serialize(
            new Map<String, Object>{
                'operationName' => 'GetTrailheadRank',
                'variables' => new Map<String, Object>{
                    'queryProfile' => true,
                    'trailblazerId' => trailblazerId
                },
                'query' => 'fragment TrailheadRank on TrailheadRank {\n  __typename\n  title\n  requiredPointsSum\n  requiredBadgesCount\n  imageUrl\n}\n\nfragment PublicProfile on PublicProfile {\n  __typename\n  trailheadStats {\n    __typename\n    earnedPointsSum\n    earnedBadgesCount\n    completedTrailCount\n    rank {\n      ...TrailheadRank\n    }\n    nextRank {\n      ...TrailheadRank\n    }\n  }\n}\n\nquery GetTrailheadRank($trailblazerId: String, $queryProfile: Boolean!) {\n  profile(trailblazerId: $trailblazerId) @include(if: $queryProfile) {\n    ... on PublicProfile {\n      ...PublicProfile\n    }\n    ... on PrivateProfile {\n      __typename\n    }\n  }\n}\n'
            }
        );
    }

    public class TrailheadProfileStats {
        public Data data { get; set; }
        public List<Error> errors { get; set; }
    }

    public class Error {
        public String message { get; set; }
    }

    public class Data {
        public Profile profile { get; set; }
    }

    public class Profile {
        public String typename { get; set; }
        public TrailheadStats trailheadStats { get; set; }
    }

    public class TrailheadStats {
        public String typename { get; set; }
        public Integer earnedPointsSum { get; set; }
        public Integer earnedBadgesCount { get; set; }
        public Integer completedTrailCount { get; set; }
        public Rank rank { get; set; }
        public Rank nextRank { get; set; }
    }

    public class Rank {
        public String typename { get; set; }
        public String title { get; set; }
        public Integer requiredPointsSum { get; set; }
        public Integer requiredBadgesCount { get; set; }
        public String imageUrl { get; set; }
    }

    public class GetTrailheadPointsApiException extends Exception {
    }
}