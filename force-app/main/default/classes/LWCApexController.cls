public with sharing class LWCApexController {

    @AuraEnabled
    public static string getLabels(){

        Pagereference labelPage = Page.Example_DynamicVF;
        labelPage.getParameters().put('lang', 'en_US');
        labelPage.getParameters().put('labels', 'SP_CC_1,SP_CC_email');
        return labelPage.getContent().toString();
    }
}
