public without sharing class CustomLoginController {

    @AuraEnabled
    public static String login(String username, String password, String startUrl) {
        try {
            ApexPages.PageReference pageRef = Site.login(username, password, startUrl);
            if (pageRef != null) {
                return pageRef.getUrl();
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getCommunityBaseUrl() {
        return Site.getBaseUrl();
    }

    @AuraEnabled
    public static String getForgotPasswordUrl() {
        return Site.getBaseUrl() + '/ForgotPassword';
    }
}
