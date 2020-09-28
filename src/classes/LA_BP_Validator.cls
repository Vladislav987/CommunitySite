public with sharing class LA_BP_Validator {


    public static Boolean isShareActionDone() {
        AsyncApexJob apexJob = LA_BP_DataSelector.getAsyncApexJobStatus();
        if (apexJob != null && apexJob.Status != 'Completed') {
            return false;
        }

        return true;
    }

}