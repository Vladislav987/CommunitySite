/**
 * Created by Lambru Dmytro on 20.03.2020.
 */

class LightningUtil {

    constructor() {
        this.DEBUG_MODE = true;
    }

    /**
     * @description: method to send request to server using Promise object
     * @param cmp {Object}: component object
     * @param apexMethodName {String}: server-side method name
     * @param apexParams {Object}: params for server-side method e.g. {param1: 'some string', param2: ['some', 'array']}
     * @returns {Promise}
     */
    sendPromiseRequest(cmp, apexMethodName, apexParams) {

        return new Promise((resolve, reject) => {
            if (!apexMethodName) {
                reject(new Error('No method name supplied'));
            }

            const action = cmp.get('c.' + apexMethodName);

            if ($A.util.isObject(apexParams) && Object.keys(apexParams).length !== 0) {
                action.setParams(apexParams);
            }

            action.setCallback(cmp, (response) => {
                if (response.getState() === "SUCCESS") {
                    resolve(response.getReturnValue());
                }
                else if (response.getState() === "INCOMPLETE") {
                    reject(new Error('Response status is "INCOMPLETE"'));
                }
                else if (response.getState() === "ERROR") {
                    reject(response.getError());
                }
            });

            $A.enqueueAction(action);
        });
    }

    /**
     * @description To show toast
     * @param title
     * @param message
     * @param type - success | info | error | warning
     * @param mode - dismissible | pester | sticky
     * @param duration - Length of time the toast is visible for, in milliseconds. Can be greater 5000 only.
     * @param key - name of action icon
     */
    showToast(title, message = '', type = 'success', mode = 'dismissible', duration = 5000, key = 'action_icon_name') {
        let toastEvent = $A.get("e.force:showToast");
        if (!message) message = ' ';
        toastEvent.setParams({ title, message, type, mode, duration, key });
        toastEvent.fire();
    }

    /**
     * @description show a toast on a system error (with code if necessary)
     * @param code {Number}
     */
    showCriticalErrorToast(code = undefined) {
        let toastEvent = $A.get("e.force:showToast");

        let params = {
            title: 'System error!',
            message: 'Please let us know about it',
            type: 'error',
            mode: 'sticky'
        };

        if (!$A.util.isUndefinedOrNull(code)) {
            params['messageTemplate'] = 'Please let us know about it, error code: {0}';
            params['messageTemplateData'] = [code.toString()];
        }

        toastEvent.setParams(params);
        toastEvent.fire();
    }

    /**
     * @description to handle errors from a promise catch
     * @param error {Object}
     */
    handleErrorInPromiseCatch(error) {
        this.showCriticalErrorToast();

        if (this.DEBUG_MODE && !$A.util.isEmpty(error)) {
            console.log('ERROR STRING: ' + JSON.stringify(error));
            console.error('ERROR', Object.assign({}, error));
        }
    }

    /**
     * @description: break all references to an entity and its nested entities
     * @param cloningEntity
     * @returns {Object}
     */
    cloneAndBreakAllReferences(cloningEntity) {
        return JSON.parse(JSON.stringify(cloningEntity));
    }
}

window.$LightningUtil = new LightningUtil();