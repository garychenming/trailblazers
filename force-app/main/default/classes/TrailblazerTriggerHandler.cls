public inherited sharing class TrailblazerTriggerHandler {
    public static void triggerHandler() {
        try {
            if (Trigger.isAfter && Trigger.isUpdate) {
                Map<Trailblazer__c, Trailblazer__c> needNotifyTrailblazers = new Map<Trailblazer__c, Trailblazer__c>();
                
                for (Trailblazer__c trailblazer : (List<Trailblazer__c>) Trigger.new) {
                    Trailblazer__c oldTrailblazer = (Trailblazer__c) Trigger.oldMap
                        .get(trailblazer.Id);

                    if (
                        oldTrailblazer.Badges__c != trailblazer.Badges__c ||
                        oldTrailblazer.Points__c != trailblazer.Points__c ||
                        oldTrailblazer.CertificationCount__c != trailblazer.CertificationCount__c
                    ) {
                        needNotifyTrailblazers.put(trailblazer, oldTrailblazer);
                    }
                }

                if(needNotifyTrailblazers.isEmpty()) {
                    return;
                }
                
                System.enqueueJob(new NotifySlack(needNotifyTrailblazers));
            }
        } catch (Exception ex) {
            insert new Log__c(
                ApexCodeName__c = 'TrailblazerTriggerHandler',
                Data__c = ex.getMessage() + ex.getLineNumber()
            );
        }
    }

    public class NotifySlack implements Queueable, Database.AllowsCallouts {
        Map<Trailblazer__c, Trailblazer__c> needNotifyTrailblazers;

        public NotifySlack(Map<Trailblazer__c, Trailblazer__c> needNotifyTrailblazers) {
            this.needNotifyTrailblazers = needNotifyTrailblazers;
        }

        public void execute(QueueableContext qc) {
            for(Trailblazer__c trailblazer : needNotifyTrailblazers.keySet()) {
                notifySlack(trailblazer, needNotifyTrailblazers.get(trailblazer));
            }
        }
    }

    private static void notifySlack(Trailblazer__c trailblazer, Trailblazer__c oldTrailblazer) {
        Integer points = trailblazer.Points__c != null ? Integer.valueOf(trailblazer.Points__c) : 0;
        Integer oldPoints = oldTrailblazer.Points__c != null
            ? Integer.valueOf(oldTrailblazer.Points__c)
            : 0;
        Integer badges = trailblazer.Badges__c != null ? Integer.valueOf(trailblazer.Badges__c) : 0;
        Integer oldBadges = oldTrailblazer.Badges__c != null
            ? Integer.valueOf(oldTrailblazer.Badges__c)
            : 0;
        Integer badgeCount = Integer.valueOf(badges - oldBadges);
        Integer pointsCount = Integer.valueOf(points - oldPoints);

        String name = trailblazer.Name;
        Decimal newPointsThisMonth = trailblazer.NewPoints__c;
        Decimal totalBadgesThisMonth = trailblazer.NewBadges__c;
        String profileUrl = trailblazer.ProfileUrl__c;
        Integer totalCertifications = (Integer)trailblazer.CertificationCount__c ?? 0;
        Integer newCertifications =
            (Integer)(trailblazer.CertificationCount__c - oldTrailblazer.CertificationCount__c);

        List<Map<String, Object>> attachments = new List<Map<String, Object>>();

        /**
         * {
                "blocks": [
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": "Danny Torrence left the following review for your property:"
                        }
                    },
                    {
                        "type": "image",
                        "title": {
                            "type": "plain_text",
                            "text": "Please enjoy this photo of a kitten"
                        },
                        "block_id": "image4",
                        "image_url": "https://pbs.twimg.com/profile_images/625633822235693056/lNGUneLX_400x400.jpg",
                        "alt_text": "An incredibly cute kitten."
                    },
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": "This is a section block with an accessory image."
                        },
                        "accessory": {
                            "type": "image",
                            "image_url": "https://pbs.twimg.com/profile_images/625633822235693056/lNGUneLX_400x400.jpg",
                            "alt_text": "cute cat"
                        }
                    }
                ]
            }
         */

        String badgesStr =
            'Name: <' +
            profileUrl +
            '|' +
            name +
            '>\n\nTotal Points: `' +
            points +
            '`\n Total Badges: `' +
            badges +
            '`\n New Points: `' +
            pointsCount +
            '`\n New Badges: `' +
            badgeCount +
            '`\n New Points This Month: `' +
            (Integer) newPointsThisMonth +
            '`\n New Badges This Month: `' +
            (Integer) totalBadgesThisMonth +
            '`' + '\n Total Certification Count: `' + totalCertifications+
            '`';

        List<Block> blocks = new List<Block>();

        TextBlock textBlock = new TextBlock();
        textBlock.type = 'section';
        TextObject textObject = new TextObject();
        textObject.type = 'mrkdwn';

        textBlock.text = textObject;
        blocks.add(textBlock);

        if (badgeCount != 0) {
            String[] urlParts = profileUrl.split('/');
            String trailheadUserSlug = urlParts[urlParts.size() - 1];

            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://profile.api.trailhead.com/graphql');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');

            request.setBody(getBody(trailheadUserSlug));
            HttpResponse res = (new Http()).send(request);

            TrailheadBadge trailheadBadge = (TrailheadBadge) JSON.deserialize(
                res.getBody().replace('__typename', 'typename'),
                TrailheadBadge.class
            );

            TextObject certificationText = new TextObject();
            certificationText.type = 'mrkdwn';
            certificationText.text =
                'New Badge: <' +
                trailheadBadge.data.profile.earnedAwards.edges[0].node.award.content.webUrl +
                '|' +
                trailheadBadge.data.profile.earnedAwards.edges[0].node.award.title +
                '>';

            Accessory accessory = new Accessory();
            accessory.type = 'image';
            accessory.image_url = trailheadBadge.data.profile.earnedAwards.edges[0].node.award.icon;
            accessory.alt_text = trailheadBadge.data.profile.earnedAwards.edges[0].node.award.title;

            AccessoryBlock newBadgeImageBlock = new AccessoryBlock();
            newBadgeImageBlock.type = 'section';
            newBadgeImageBlock.text = certificationText;
            newBadgeImageBlock.accessory = accessory;

            blocks.add(newBadgeImageBlock);
        }

        if (trailblazer.CertificationCount__c != oldTrailblazer.CertificationCount__c) {
            List<GetTrailheadPointsApi.Certification> certifications = (List<GetTrailheadPointsApi.Certification>) JSON.deserialize(
                trailblazer.CertificationsData__c,
                List<GetTrailheadPointsApi.Certification>.class
            );

            certifications.sort();

            TextObject certificationText = new TextObject();
            certificationText.type = 'mrkdwn';
            certificationText.text =
                'New Certification: <' +
                certifications[0].infoUrl +
                '|' +
                certifications[0].title +
                '>';

            Accessory accessory = new Accessory();
            accessory.type = 'image';
            accessory.image_url = certifications[0].logoUrl;
            accessory.alt_text = certifications[0].title;

            AccessoryBlock certificationBlock = new AccessoryBlock();
            certificationBlock.type = 'section';
            certificationBlock.text = certificationText;
            certificationBlock.accessory = accessory;

            blocks.add(certificationBlock);
        }

        textObject.text = badgesStr;

        String message = JSON.serialize(new Map<String, Object>{ 'blocks' => blocks });

        SlackUtil.sendNotificationToSlack(message);
    }

    private static String getBody(String slug) {
        return JSON.serialize(
            new Map<String, Object>{
                'operationName' => 'GetTrailheadBadges',
                'variables' => new Map<String, Object>{
                    'count' => 1,
                    'after' => null,
                    'filter' => null,
                    'hasSlug' => true,
                    'slug' => slug
                },
                'query' => 'fragment EarnedAward on EarnedAwardBase {\n  __typename\n  id\n  award {\n    __typename\n    id\n    title\n    type\n    icon\n    content {\n      __typename\n      webUrl\n      description\n    }\n  }\n}\n\nfragment EarnedAwardSelf on EarnedAwardSelf {\n  __typename\n  id\n  award {\n    __typename\n    id\n    title\n    type\n    icon\n    content {\n      __typename\n      webUrl\n      description\n    }\n  }\n  earnedAt\n  earnedPointsSum\n}\n\nfragment StatsBadgeCount on TrailheadProfileStats {\n  __typename\n  earnedBadgesCount\n  superbadgeCount\n}\n\nfragment ProfileBadges on PublicProfile {\n  __typename\n  trailheadStats {\n    ... on TrailheadProfileStats {\n      ...StatsBadgeCount\n    }\n  }\n  earnedAwards(first: $count, after: $after, awardType: $filter) {\n    edges {\n      node {\n        ... on EarnedAwardBase {\n          ...EarnedAward\n        }\n        ... on EarnedAwardSelf {\n          ...EarnedAwardSelf\n        }\n      }\n    }\n    pageInfo {\n      ...PageInfoBidirectional\n    }\n  }\n}\n\nfragment PageInfoBidirectional on PageInfo {\n  __typename\n  endCursor\n  hasNextPage\n  startCursor\n  hasPreviousPage\n}\n\nquery GetTrailheadBadges($slug: String, $hasSlug: Boolean!, $count: Int = 8, $after: String = null, $filter: AwardTypeFilter = null) {\n  profile(slug: $slug) @include(if: $hasSlug) {\n    __typename\n    ... on PublicProfile {\n      ...ProfileBadges\n    }\n  }\n}\n'
            }
        );
    }

    private virtual class Block {
        private String type { get; set; }
    }

    private class TextBlock extends Block {
        private TextObject text { get; set; }
    }

    private class TextObject {
        private String type { get; set; }
        private String text { get; set; }
    }

    private class ImageBlock extends Block {
        private String type { get; set; }
        private TitleObject title { get; set; }
        private String block_id { get; set; }
        private String image_url { get; set; }
        private String alt_text { get; set; }
    }

    private class TitleObject {
        private String type { get; set; }
        private String text { get; set; }
    }

    public class TrailheadBadge {
        public Data data { get; set; }
    }

    public class Data {
        public ProfileBySlug profile { get; set; }
    }

    public class ProfileBySlug {
        public String typename { get; set; }
        public TrailheadStats trailheadStats { get; set; }
        public EarnedAwards earnedAwards { get; set; }
    }

    public class TrailheadStats {
        public String typename { get; set; }
        public Integer earnedBadgesCount { get; set; }
        public Integer superbadgeCount { get; set; }
    }

    public class EarnedAwards {
        public List<Badge> edges { get; set; }
    }

    public class Badge {
        public Node node { get; set; }
    }

    public class Node {
        public String typename { get; set; }
        public String id { get; set; }
        public Award award { get; set; }
    }

    public class Award {
        public String typename { get; set; }
        public String id { get; set; }
        public String title { get; set; }
        public String type { get; set; }
        public String icon { get; set; }
        public Content content { get; set; }
    }

    public class Content {
        public String typename { get; set; }
        public String webUrl { get; set; }
        public String description { get; set; }
    }

    public class AccessoryBlock extends Block {
        public TextObject text { get; set; }
        public Accessory accessory { get; set; }
    }

    public class Accessory {
        public String type { get; set; }
        public String image_url { get; set; }
        public String alt_text { get; set; }
    }
}