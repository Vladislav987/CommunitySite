/**
 * Created by IlliaLuhovyi on 5/28/2020.
 */

public inherited sharing class Util_ApprovalProcess {
    public final String REQUEST_APPROVE = 'Approve';
    public final String REQUEST_REJECT = 'Reject';

    /**
     * @param recordId Id of current object
     *
     * @description Method for getting the TargetObjectId of current object which is placed in ProcessInstance
     *
     * @return Id of ProcessInstance object
     */
    public Id getProcessInstanceId(Id recordId) {
        return [SELECT Id FROM ProcessInstance WHERE TargetObjectId = :recordId].Id;
    }

    /**
     * @param recordId Id of current object
     *
     * @description Method for getting the Id of current object which is placed in ProcessInstanceWorkitem with a help of getProcessInstanceId method
     *
     * @return Id of ProcessInstanceWorkitem object
     */
    public Id getProcessInstanceWorkitemId(Id recordId) {
        return [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :getProcessInstanceId(recordId)].Id;
    }

    /**
     * @param recordId Id of current object
     *
     * @description Method for approving current object
     */
    public void approveRecord(Id recordId) {
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setWorkitemId(getProcessInstanceWorkitemId(recordId));
        req.setAction(REQUEST_APPROVE);
        requests.add(req);

        Approval.process(requests);
    }

    /**
     * @param recordId Id of current object
     *
     * @description Method for rejecting current object
     */
    public void rejectRecord(Id recordId) {
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setAction(REQUEST_REJECT);
        req.setWorkitemId(getProcessInstanceWorkitemId(recordId));
        req.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        requests.add(req);

        Approval.process(requests);
    }
}