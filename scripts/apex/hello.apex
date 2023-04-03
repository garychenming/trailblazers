// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

// List<Trailblazer__c> trailblazers = [
//   SELECT Id, Name, ProfileUrl__c, TrailheadUserId__c
//   FROM Trailblazer__c
//   ORDER BY Name
// ];

// for (Trailblazer__c trailblazer : trailblazers) {
//   trailblazer.PointsData__c = '[]';
//   trailblazer.BadgesData__c = '[]';
//   String dataStr = callout(trailblazer.ProfileUrl__c);
//   String data = getData(dataStr);
//   String id = data.substringBetween('sobjects/User/', '\\\"');

//   System.debug(
//     trailblazer.Name +
//     '-------' +
//     id +
//     '----' +
//     (id == trailblazer.TrailheadUserId__c)
//   );
// }

// update trailblazers;

public static String getData(String dataStr) {
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

public static String callout(String url) {
  HttpRequest request = new HttpRequest();
  request.setEndpoint(url);
  request.setMethod('GET');
  HttpResponse response = (new Http()).send(request);
  return response.getBody();
}

String dataStr = callout('https://trailhead.salesforce.com/en/me/garychen');
String data = getData(dataStr);
String id = data.substringBetween('sobjects/User/', '\\\"');

System.debug('-------' + id);
