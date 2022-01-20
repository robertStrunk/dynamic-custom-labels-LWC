public with sharing class DynamicVFController {

    public String jsonStr {get;set;}

    public DynamicVFController() {

        Map<String, String> labelMap = new Map<String, String>();
        String labelStr = ApexPages.currentPage().getParameters().get('labels');

        if(NULL != labelStr){

            List<String> labelNames = new List<String>{labelStr};

            if(labelStr.contains(',')) labelNames = labelStr.split(',');

            for(String labelName : labelNames){
                try{
                    // create an <apex:outputText> component using dynamic visualforce
                    Component.Apex.OutputText cmp = new Component.Apex.OutputText();
                    cmp.expressions.value = '{!$label.' + labelName + '}';
                    labelMap.put(labelName, String.valueOf(cmp.value)); // cmp.value is the resolved expression of {!$label.labelName}
                }
                catch(Exception e){
                    System.debug(LoggingLevel.ERROR, 'Invalid Label API Name \"' + labelName + '\"');
                }
            }
        }

        jsonStr = JSON.serialize(labelMap);
    }
}