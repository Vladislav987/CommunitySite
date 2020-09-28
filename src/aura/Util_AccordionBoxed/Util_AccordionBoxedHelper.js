/**
 * Created by Lambru Dmytro on 23.03.2020.
 */

({
    openOrCloseAccordion: function (cmp, buttonElement) {
        const isOpen = cmp.get('v.isOpen');
        const panel = buttonElement.nextElementSibling;

        if (isOpen) {
            $A.util.addClass(buttonElement, 'uab_active');
            $A.util.addClass(panel, 'uab_active');
            panel.style.maxHeight = panel.scrollHeight + "px";
        }
        else {
            $A.util.removeClass(buttonElement, 'uab_active');
            $A.util.removeClass(panel, 'uab_active');
            panel.style.maxHeight = null;
        }
    },
});