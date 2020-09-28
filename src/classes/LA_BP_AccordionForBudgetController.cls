/**
 * Created by Yauheniy Malakhouskiy on 07-May-20.
 */

public with sharing class LA_BP_AccordionForBudgetController {

    @AuraEnabled
    public static void updateBudgetElement(Budget_Element__c budgetElement) {
        System.debug(budgetElement);
        if (budgetElement != null) {
            update budgetElement;
        }
    }

}