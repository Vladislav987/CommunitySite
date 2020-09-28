/**
 * Created by MaxymMirona on 19.06.2020.
 */

({
    doOpenComponent : function (component, event, generateInvoice) {
        let modalBody;

        $A.createComponent(
            "c:GenerateInvoiceComponent",
            {recordId: component.get("v.recordId"), generateInvoice : generateInvoice},
            function (content, status) {
                if (status === "SUCCESS") {
                    modalBody = content;

                    component.find('overlayLib').showCustomModal({
                        header: generateInvoice ? "Generate Invoice" : "Generate Accrual",
                        body: modalBody,
                        showCloseButton: true
                    })
                }
            });
    }
});