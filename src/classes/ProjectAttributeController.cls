/**
 * Created by Lambru Dmytro on 20.03.2020.
 */

public without sharing class ProjectAttributeController {

    private static ProjectAttributeService service = new ProjectAttributeService();

    @AuraEnabled
    public static LightningResponse getMasterWithSpecializationsOptionsByProjectId(Id projectId) {
        LightningResponse response = new LightningResponse();

        try {
            ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = service.getCurrentMasterWithSpecializationsOptionsByProjectId(projectId);
            System.debug(masterPicklistOptionList);
            response.setResult(JSON.serialize(masterPicklistOptionList));
        } catch (ProjectAttributeException exc) {
            response.setError(exc.errorCode, exc.getErrorMsg());
        } catch (Exception exc) {
            response.setError(Util.trackException(true, exc, ProjectAttributeController.class));
        }

        return response;
    }

    @AuraEnabled
    public static LightningResponse changeProjectAttributes(Id projectId, String beforeChangesJsonMasterPicklistOptionList, String changedJsonMasterPicklistOptionList) {
        LightningResponse response = new LightningResponse();

        try {
            if (service.hasSomeoneMadeChangesToAttributes(projectId, beforeChangesJsonMasterPicklistOptionList)) {
                response.setError(ProjectAttributeException.ERROR_CODE_ATTRIBUTES_ALREADY_CHANGED);
            } else {
                ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = (ProjectAttributeService.MasterPicklistOption[]) JSON.deserialize(changedJsonMasterPicklistOptionList, ProjectAttributeService.MasterPicklistOption[].class);
                service.changeProjectAttributes(projectId, masterPicklistOptionList);
                response.success = true;
            }
        } catch (Exception exc) {
            response.setError(Util.trackException(true, exc, ProjectAttributeController.class));
        }

        return response;
    }

    @AuraEnabled
    public static ProjectAssessmentsRelatedListInfo getProjectAssessmentsRelatedListInitData(Id projectId) {
        try {
            return new ProjectAssessmentsRelatedListInfo(
                    service.getProjectAssessmentsForRelatedList(projectId),
                    service.getProjectAssessmentsComponentTitleInfo());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ProjectAssessmentsRelatedListInfo {
        @AuraEnabled
        public ProjectAttributeService.ProjectAssessmentsComponentTitleInfo componentTitleInfo { get; set; }
        @AuraEnabled
        public ProjectAttributeService.ProjectAssessmentsDataTableWrapper dataTable { get; set; }
        public ProjectAssessmentsRelatedListInfo(
                ProjectAttributeService.ProjectAssessmentsDataTableWrapper dataTable,
                ProjectAttributeService.ProjectAssessmentsComponentTitleInfo componentTitleInfo) {
            this.dataTable = dataTable;
            this.componentTitleInfo = componentTitleInfo;
        }
    }

    public class LightningResponse extends Model.LightningResponse {
        /* For success response with JSON data  */
        public void setResult(String data) {
            this.data = data;
            this.success = true;
        }

        /* For error response with error code number */
        public void setError(Integer code) {
            this.code = code;
            this.success = false;
        }

        /* For error response - set message */
        public void setError(String message) {
            this.message = message;
            this.success = false;
        }

        /* For error response with message and error code number */
        public void setError(Integer code, String message) {
            this.code = code;
            this.message = message;
            this.success = false;
        }
    }
}