public with sharing class KakaoMapController {
    @AuraEnabled(cacheable=true)
    public static String getApiKey() {
        KakaoConfig__mdt config = [
            SELECT API_Key__c
            FROM KakaoConfig__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
        return config.API_Key__c;
    }
}
