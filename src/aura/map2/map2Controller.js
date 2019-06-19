({
    init: function (cmp, event, helper) {
        cmp.set('v.mapMarkers', [
            {
                location: {
                    Street: '1650 Simi Prakhovykh Street',
                    City: 'Kyiv',
                    State: 'Ukraine'
                },

                title: 'Our address',
                description: 'Ali-ua Shop'
            }
        ]);
        cmp.set('v.zoomLevel', 14);
    }
})