# Purpose
This repo highlights an issue that may arise when converting Visualforce to LWC and proposes a few paths forward.

# Issue Description
Visualforce has support for referencing custom labels on the fly at runtime(dynamic) and LWC does not. If you need to convert a Visualforce page that uses dynamic custom label references, you need to get creative to make it happen. There are a few solutions that can be used to bridge the gap.

# The basics - Custom Label Referencing
Both Visualforce and LWC allow for the referencing of custom labels. In Visualforce, the following two approaches are most widely used:
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

As demonstrated above, both Visualforce and LWC support referencing custom labels when the custom label API name is known in advance. Only Visualforce supports referencing labels dynamically at runtime.

# The Options - Dynamic Custom Labels for LWC
Unfortunately there is no straight forward way to enable LWC components to dynamically reference custom labels at runtime. But we do have some options. As is true with any solution design, there are trade-offs in the area of performance, scalability, and maintainability. That said, below is a list of the options as I see them along with the trade-offs that are relevant to each approach.

1. **Import All Labels**
   - Description - This approach is to create a LWC component that just imports all custom labels by name. The component would expose an API of some sort to allow other components to access labels by API name.
   - Pros
     - Dynamic referencing achieved.
     - Hard references to each label would be tied to the code which helps admins know where and if the label is being used.
     - Translation functionality is preserved.
   - Cons
     - Not scalable for scenarios with large numbers of custom labels.
     - Code changes would be required to add/remove labels.
     - Keeping the component up to date would be almost a futile effort in some orgs.
     - Performance hits would result from importing large numbers of labels that may not even be needed.
2. **Dynamic Visualforce**
   - Description - Since Visualforce expression syntax allows for dynamic referencing of custom labels, [dynamic Visualforce](https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_dynamic_vf_components_intro.htm) could be leveraged in order to resolve label names on the fly in Apex. All that would be needed is for the LWC to call an apex class which in turn instantiates a Visualforce page with a controller. The page's apex controller could then interrogate the URL parameters and create `<apex:outputText>` components for each label name in the URL. All that would be needed next is to create a JSON string of label name's to label values. The page content type would need to be set to `application/json` with the html and body tags turned off (as well as some other page attributes). The apex class that instantiated the page would just need to perform a `Pagereference.getContent().toString()` call to get the string representation of the page. That string could then be returned to the LWC which would allow the string to be parsed into a JSON object. The following links are examples of how that could be implemented.
     - [LWC Import Method](https://github.com/robertStrunk/dynamic-custom-labels-LWC/blob/master/force-app/main/default/classes/LWCApexController.cls)
     - [Visualforce Page Markup](https://github.com/robertStrunk/dynamic-custom-labels-LWC/blob/master/force-app/main/default/pages/Example_DynamicVF.page)
     - [Visualforce Page Controller](https://github.com/robertStrunk/dynamic-custom-labels-LWC/blob/master/force-app/main/default/classes/DynamicVFController.cls)
   - Pros
     - Dynamic referencing achieved.
     - Translation functionality is preserved.
   - Cons
     - There is a limit to length a URL can be (4096 chars).
     - Nonconventional/counterintuitive use of a VF page so it may be confusing to some devs.
3. **Aura Wrapper**
   - Description - Aura components have a little more support when it comes to dynamically referencing custom labels. That support falls somewhere in between the levels of Visualforce and LWC. Unlike LWC, Aura does have a loose equivalent of Visualforce's global variable `$Label`. It comes in the form of the Global value provider `$Label`. This global value provider can be accessed in component markup via expression syntax `{!$Label.namespace.labelName}` or in the javascript via the Aura javascript API `$A.get("$Label.namespace.labelName")`. If, however, the label is not added as a dependency in the component definition then the `$A.get()` call will not return the desired value. To get around this you can instead use a `$A.getReference()` call and the Aura framework will go to the server to fetch the label value if it is not readily accessible in the client. If you have one or two labels that is not a big deal but as your need grows, so too does the cost. So the solution here would be to encapsulate the LWC component with an Aura component and wire them up in a way to allow the Aura component to serve the LWC component with label values.
   - Pros
     - Dynamic referencing achieved.
     - Translation functionality is preserved.
   - Cons
     - Not scalable with large quantities of labels.
     - Requires a server call per label (hence the scalability reference above)
4. **Convert Custom Labels to Record Data or Metadata**
   - Description - A solution could be crafted by converting the custom labels into record data, custom setting data, or custom metadata. To accomplish this you would just need to add a couple fields to your desired data structure. One field would be for the "API Name" of the label and the other would be for the "Value" of the label.
   - Pros
     - Dynamic referencing achieved (partially).
     - Would preserve the ability for text to be changed by admins in an org with no code changes needed.
   - Cons
     - Basically defeats the purpose of using custom labels in a lot of scenarios.
     - Loss of translation functionality.
     - Record data would need to be seeded in sandboxes on refresh.
     
I have implemented Option 2 and it can be referenced in this repo under [dynamic-custom-labels-LWC/force-app/main/default](https://github.com/robertStrunk/dynamic-custom-labels-LWC/tree/master/force-app/main/default)
