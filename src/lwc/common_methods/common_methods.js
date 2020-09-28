/**
 * Created by AndriiKovalenko on 27.05.2020.
 */


    /**
     * Created by AndriiKovalenko on 27.05.2020.
     */

    const getColumnForRelatedListTemplate = (fieldsList, fieldsTypes, records, customColumns = []) =>{

        let columns = Object.keys(fieldsList).map((key) => {
            if (customColumns.length > 0) {
                let indexCustomColumn = customColumns.findIndex(column => column.label === key);
                if (indexCustomColumn>-1){
                    return customColumns[indexCustomColumn];
                }
            }

            if (fieldsList[key] === 'Name') {
                return {
                    label: 'Name',
                    fieldName: 'linkName',
                    type: 'url',
                    typeAttributes: {label: {fieldName: 'Name'}, tooltip: { fieldName: "Name" }, target: '_blank'}
                };
            }

            switch (fieldsTypes[key]) {
                case 'CURRENCY':
                    return {
                        label: key,
                        fieldName: fieldsList[key],
                        type: 'currency',
                        editable: false,
                        typeAttributes: {currencyCode: 'USD', maximumSignificantDigits: 5},
                        cellAttributes: {alignment: 'left'}
                    }
                case 'PERCENT':
                case 'DOUBLE':
                    return {
                        label: key,
                        fieldName: fieldsList[key],
                        type: 'number',
                        editable: false,
                        cellAttributes: {alignment: 'center'}
                    }
                case 'DATE':
                case 'DATETIME':
                    return {
                        label: key,
                        fieldName: fieldsList[key],
                        type: 'date',
                        editable: false
                    }
                case 'REFERENCE':
                    for (var i = 0; i < records.length; i++) {
                        function getPropByString(obj, propString) {
                            if (!propString)
                                return obj;

                            var prop, props = propString.split('.');

                            for (var i = 0, iLen = props.length - 1; i < iLen; i++) {
                                prop = props[i];

                                var candidate = obj[prop];
                                if (candidate !== undefined) {
                                    obj = candidate;
                                } else {
                                    break;
                                }
                            }
                            return obj[props[i]];
                        }

                        let rec = records[i];
                        rec[fieldsList[key]] = getPropByString(rec, [fieldsList[key]].toString());
                    }
                    return {
                        label: key,
                        fieldName: fieldsList[key],
                        type: 'text',
                        editable: false
                    }
            }
            return {
                label: key,
                fieldName: fieldsList[key],
                type: 'text',
                editable: false
            }
        });
        return columns;
    }


    export { getColumnForRelatedListTemplate };