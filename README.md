# Purpose
This repo highlights an issue that my arise when converting Visualforce to LWC and proposes a few paths forward.

# Issue Description
Visualforce has support for referencing custom labels on the fly at runtime(dynamic) and LWC does not. If you need to convert a visualforce page that uses dynamic custom label references, you need to get creative to make it happen. There are a few solutions that can be used to bridge the gap.

# The basics - Custom Label Referencing
Both visualforce and LWC allow for the referencing of custom labels. In visualforce, the following two approaches are most widely used:
### Visualforce
___
Markup
```html
<apex:page controller="ControllerClass">

    <!-- Approach #1 - Static Reference -->
    <p>{!$Label.label_1}</p>

    <!-- Approach #2 - Dynamic Reference -->
    <p>{!$Label[API_NAME_FOR_LABEL_2]}</p>

</apex:page>
```
Controller
```java
public with sharing class ControllerClass {

    public String API_NAME_FOR_LABEL_2 {get;set;}

    public ControllerClass(){
        // hard coded here but a normal use case would pull this value from record/setting data
        this.API_NAME_FOR_LABEL_2 = 'label_2';
    }
}
```
### LWC
Markup
```html
<template>
    <!-- Approach #1 - Static Reference -->
    {label.greeting}

    <!-- Approach #2 - Dynamic Reference -->
    <!-- 😞  DOES NOT EXIST 😞 -->
</template>
```
Javascript Controller
```javascript
import { LightningElement } from 'lwc';

// requires the label name to be statically named
import greeting from '@salesforce/label/c.greeting';

export default class LabelExample extends LightningElement {

    // Expose the labels to use in the template.
    label = { greeting };
}
```

As demonstrated above, both Visualforce and LWC support referencing custom labels when the custom label API name is known in advance.

# The Options - Dynamic Custom Labels for LWC
Unfortunately there is no straight forward way to enable LWC componnents to dynamically reference custom labels at runtime. But we do have some options. As is true with any solution design, there are trade-offs in the area of performance, scalability, and maintainability. That said, below is a list of the options as I see them along with the trade-offs that are relevant to each approach.

1. Import All Labels
   - Description - This approach is to create a LWC component that just imports all custom labels by name. The component would expose an API of some sort to allow other components to access labels by API name.
   - Pros
     - All labels would be imported and readily accessible when needed.
     - Hard references to each label would be tied to the code which helps admins know where and if the label is being used.
     - Translation functionality is preserved.
   - Cons
     - Not scalable for scenarios with large numbers of custom labels.
     - Code changes would be required to add/remove labels.
     - Keeping the component up to date would be almost a futile effort in some orgs.
     - Performance hits would result from importing large numbers of labels that may not even be needed.
2. Dynamic Visualforce
   - Description - Since Visualforce expression syntax allows for dynamic referencing of custom labels, [dynamic visualforce](https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_dynamic_vf_components_intro.htm) could be leveraged in order to resolve label names on the fly in Apex. All that would be needed is for the LWC to call an apex class which in turn instantiates a visualforce page with a controller. The page's apex controller could then interrogate the URL parameters and create `<apex:outputText>` for each label name in the URL and then create a JSON string of label name's to label values. The page content type would need to be set to `application/json` with the html and body tags turned off (as well as some other page attributes). The apex class that instantiated the page would just need to perform a `Pagereference.getContent().toString()` call to get the string representation of the page. That string could then be returned to the LWC which would allow the string to be parsed into a JSON object. The following links are examples of how that could be implemented.
     - <a target="_blank" href="https://github.com/robertStrunk/dynamic-custom-labels-LWC/blob/master/force-app/main/default/classes/LWCApexController.cls">LWC Import Method</>
     - <a target="_blank" href="https://github.com/robertStrunk/dynamic-custom-labels-LWC/blob/master/force-app/main/default/pages/Example_DynamicVF.page">Visualforce Page Markup</a>
     - <a target="_blank" href="https://github.com/robertStrunk/dynamic-custom-labels-LWC/blob/master/force-app/main/default/classes/DynamicVFController.cls">Visualforce Page Controller</a>
   - Pros
     - Allows the LWC to fetch the custom labels dynamically at runtime with a single server call.
     - Translation functionality is preserved.
   - Cons
     - There is a limit to length a URL can be (4096 chars).
     - Nonconventional/counterintuitive use of a VF page so it may be confusing to some devs.
3. Aura Wrapper
   - Description - HERE
   - Pros
     - One
     - Two
   - Cons
     - One
     - Two
4. Convert Labels to Settings
   - Description - HERE
   - Pros
     - One
     - Two
   - Cons
     - One
     - Two