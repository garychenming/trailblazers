public inherited sharing class GetTrailheadPointsApi {
    public static TrailheadProfileStats get(String slug) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://profile.api.trailhead.com/graphql');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        request.setBody(getBody(slug));
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

    private static String getBody(String slug) {
        return JSON.serialize(
            new Map<String, Object>{
                'operationName' => 'GetTrailheadRank',
                'variables' => new Map<String, Object>{
                    'queryProfileById' => false,
                    'queryProfileBySlug' => true,
                    'slug' => slug
                },
                'query' => 'fragment TrailheadRank on TrailheadRank {\n  __typename\n  title\n  requiredPointsSum\n  requiredBadgesCount\n  imageUrl\n}\n\nfragment PublicProfile on PublicProfile {\n  __typename\n  trailheadStats {\n    __typename\n    earnedPointsSum\n    earnedBadgesCount\n    completedTrailCount\n    rank {\n      ...TrailheadRank\n    }\n    nextRank {\n      ...TrailheadRank\n    }\n  }\n}\n\nquery GetTrailheadRank($trailblazerId: String, $queryProfileById: Boolean!, $slug: String, $queryProfileBySlug: Boolean!) {\n  profileById: profile(trailblazerId: $trailblazerId) @include(if: $queryProfileById) {\n    ... on PublicProfile {\n      ...PublicProfile\n    }\n    ... on PrivateProfile {\n      __typename\n    }\n  }\n  profileBySlug: profile(slug: $slug) @include(if: $queryProfileBySlug) {\n    ... on PublicProfile {\n      ...PublicProfile\n    }\n    ... on PrivateProfile {\n      __typename\n    }\n  }\n}\n'
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
        public ProfileBySlug profileBySlug { get; set; }
    }

    public class ProfileBySlug {
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