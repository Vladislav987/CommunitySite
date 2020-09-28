/**
 * Created by IlliaLuhovyi on 4/27/2020.
 */
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export function showToastSuccess({cmp, title = 'Success', message, mode = 'pester'}) {
    eventCallToast(cmp, title, message, 'success', mode);
}

export function showToastError({cmp, title = 'Error', message, mode = 'pester'}) {
    eventCallToast(cmp, title, message, 'error', mode);
}

export function showToastInfo({cmp, title = 'Info', message, mode = 'pester'}) {
    eventCallToast(cmp, title, message, 'info', mode);
}

export function showToastWarning({cmp, title = 'Warning', message, mode = 'pester'}) {
    eventCallToast(cmp, title, message, 'warning', mode);
}

function eventCallToast(cmp, title, message, variant, mode) {

    if (!message || !message.length) {
        console.error("Message can't be blank");
        return;
    }

    const event = new ShowToastEvent({
        "title": title,
        "message": message,
        "variant": variant,
        "mode": mode
    });

    cmp.dispatchEvent(event);
}