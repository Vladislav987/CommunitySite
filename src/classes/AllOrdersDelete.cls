/*
 * Created by Vladyslav Ponomarov
 */
public class AllOrdersDelete {
	private List<sObject> records{get;set;}
	private ApexPages.StandardSetController controller;

	public AllOrdersDelete(ApexPages.StandardSetController controller) {
		records = (List<sObject>)controller.getRecords();
		this.controller = controller;
	}

	public PageReference deleteRecords() {
		delete records;
		PageReference pageReference = controller.cancel();


		return pageReference;
	}
}