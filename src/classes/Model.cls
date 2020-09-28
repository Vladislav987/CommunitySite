/**
 * Created by Lambru Dmytro on 21.03.2020.
 */

public inherited sharing class Model {

    public virtual inherited sharing class PicklistOption {

        public String optionLabel { get; set; }
        public String optionApiName { get; set; }
        public Boolean isSelected { get; set; }
    }

    public virtual inherited sharing class LightningResponse {

        /* Successful(TRUE) or not successful(FALSE) operation */
        @AuraEnabled public Boolean success { get; set; }
        /* Data in JSON string */
        @AuraEnabled public String data { get; set; }
        /* Code number */
        @AuraEnabled public Integer code { get; set; }
        /* Message text */
        @AuraEnabled public String message { get; set; }

    }
}