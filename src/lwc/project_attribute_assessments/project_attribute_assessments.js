/**
 * Created by VasylKhrystynych on 5/19/2020.
 */

import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getPicklistValuesByRecordType, getObjectInfo } from "lightning/uiObjectInfoApi";
import { getRecord } from "lightning/uiRecordApi";
import PROJECT_ATTRIBUTE from "@salesforce/schema/Project_attribute__c";
import PROJECT_ATTRIBUTE_PROJECT_FIELD from "@salesforce/schema/Project_attribute__c.Project__c";
import getProjectAssessmentsRelatedListInitData
  from "@salesforce/apex/ProjectAttributeController.getProjectAssessmentsRelatedListInitData";

export default class ProjectAttributeAssessments extends NavigationMixin(LightningElement) {

  @api recordId;
  @api objectApiName;

  @track selectedStatus;
  @track statuses;
  @track isLoading = true;
  @track records;
  @track filteredRecords = [];
  @track columns = [];
  @track cardIconName;

  defaultStatusLabelFilterCondition = "Deprecated";
  defaultStatusLabel = "All except Deprecated";
  editRecordId;
  PROJECT_ATTRIBUTE_LABEL_PLURAL;
  PROJECT_ATTRIBUTE_LABEL;
  ASSESSMENT_RECORD_TYPE_ID;
  ASSESSMENT_RECORD_TYPE_NAME;

  connectedCallback() {
    this.init();
  }

  @wire(getObjectInfo, { objectApiName: PROJECT_ATTRIBUTE })
  getCardIconName({ data }) {
    if (data) {
      let arr = data.themeInfo.iconUrl.split("/");
      let item = arr.pop().split("_")[0];
      let type = arr.pop();
      this.cardIconName = `${ type }:${ item }`;
    }
  }

  @wire(getRecord, {
    recordId: "$editRecordId",
    fields: [ PROJECT_ATTRIBUTE_PROJECT_FIELD ]
  }) testData({ data, error }) {
    if (data) {
      this.init();
    } else if (error) {
      this.showToast();
    }
  }

  @wire(getPicklistValuesByRecordType, {
    objectApiName: PROJECT_ATTRIBUTE,
    recordTypeId: "$ASSESSMENT_RECORD_TYPE_ID"
  })
  wiredValues({ error, data }) {
    if (data) {
      this.handleGetStatuses(data);
      this.handleFilterAssessment();
    } else {
      this.error = error;
    }
  }

  init() {
    getProjectAssessmentsRelatedListInitData({ projectId: this.recordId })
      .then(result => {
        this.handleGetData(result);
      })
      .catch(error => {
        this.showToast((!!error.body && !!error.body.message) ? error.body.message : 'Unknown error');
        console.log(JSON.stringify(error));
      })
      .finally(() => {
        this.isLoading = false;
      })
  }

  handleGetData(data) {
    let {
      dataTable,
      componentTitleInfo
    } = JSON.parse(JSON.stringify(data));

    this.setFiltersDefaultValue();
    this.getAssessments(dataTable);
    this.handleComponentTitleInfo(componentTitleInfo);
    if (this.statuses !== undefined) {
      this.handleFilterAssessment();
    }
  }

  get title() {
    return `${ this.PROJECT_ATTRIBUTE_LABEL_PLURAL } (${ this.ASSESSMENT_RECORD_TYPE_NAME }) (${ this.filteredRecords.length })`;
  }

  get isNotEmptyList() {
    return this.filteredRecords.length > 0;
  }

  handleComponentTitleInfo(componentTitleInfo) {
    let {
      projectAttributeLabelPlural,
      assessmentRecordTypeId,
      assessmentRecordTypeName, projectAttributeLabel
    } = componentTitleInfo;
    this.PROJECT_ATTRIBUTE_LABEL_PLURAL = projectAttributeLabelPlural;
    this.PROJECT_ATTRIBUTE_LABEL = projectAttributeLabel;
    this.ASSESSMENT_RECORD_TYPE_ID = assessmentRecordTypeId;
    this.ASSESSMENT_RECORD_TYPE_NAME = assessmentRecordTypeName;
  }

  setFiltersDefaultValue() {
    if (this.selectedStatus === undefined) {
      this.selectedStatus = "";
    }
  }

  handleGetStatuses({ picklistFieldValues: { Status__c: { values } } }) {
    let statuses = values.map(value => {
      let statusInList = {};
      statusInList.label = value.label;
      statusInList.value = value.value;
      return statusInList;
    });
    let initialStatuses = [ { label: this.defaultStatusLabel, value: "" } ];
    initialStatuses.push(...statuses);
    this.statuses = initialStatuses;
  }

  getAssessments(dataTable) {
    let { recordsList, fieldsTypes, fieldsList } = dataTable;

    recordsList = recordsList.map(record => {
      record.linkName = `/${ record.Id }`;
      return record;
    });
    this.columns = this.getColumnsForRelatedList(fieldsList, fieldsTypes, recordsList);
    this.records = recordsList;
    this.filteredRecords = JSON.parse(JSON.stringify(recordsList));

  }

  /* Copied logic from other component */
  getColumnsForRelatedList(fieldsList, fieldsTypes, records) {

    let columns = Object.keys(fieldsList).map((key) => {
      if (fieldsList[key] === "Name") {
        return {
          label: "Name", fieldName: "linkName", type: "url",
          typeAttributes: { label: { fieldName: "Name" }, tooltip: { fieldName: "Name" }, target: "_blank" }
        };
      } else if (fieldsTypes[key] === "CURRENCY") {
        return {
          label: key,
          fieldName: fieldsList[key],
          type: "currency",
          editable: false,
          typeAttributes: { currencyCode: "USD", maximumSignificantDigits: 5 },
          cellAttributes: { alignment: "left" }
        };
      } else if (fieldsTypes[key] === "PERCENT" || fieldsTypes[key] === "DOUBLE") {
        return {
          label: key,
          fieldName: fieldsList[key],
          type: "number",
          editable: false,
          cellAttributes: { alignment: "center" }
        };
      } else if (fieldsTypes[key] === "DATE" || fieldsTypes[key] === "DATETIME") {
        return { label: key, fieldName: fieldsList[key], type: "date", editable: false };
      } else if (fieldsTypes[key] === "STRING" && key.includes("indicator")) {
        records = records.map(record => {
          try {
            let str = record[fieldsList[key]];
            let regexp = /(.*src=")(.*)(" alt=")(.*)(" border)/;
            let match = regexp.exec(str);
            record[`${ fieldsList[key] }.imageUrl`] = this.htmlDecode(match[2]);
            record[`${ fieldsList[key] }.altText`] = match[4];
          } catch (error) {
            console.log(error);
          }
          return record;
        });
        return {
          label: key,
          fieldName: `${ fieldsList[key] }.imageUrl`,
          type: "image",
          typeAttributes: { altText: { fieldName: `${ fieldsList[key] }.altText` } },
          editable: false
        };
      } else if (fieldsTypes[key] === "REFERENCE") {
        for (let i = 0; i < records.length; i++) {
          function getPropByString(obj, propString) {
            if (!propString)
              return obj;

            var prop, props = propString.split(".");

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
          rec[fieldsList[key]] = getPropByString(rec, [ fieldsList[key] ].toString());
        }
        return { label: key, fieldName: fieldsList[key], type: "text", editable: false };
      } else {
        return { label: key, fieldName: fieldsList[key], type: "text", editable: false };
      }
    });

    columns.push({
      type: "action",
      typeAttributes: { rowActions: this.getRowActions }
    });
    return columns;
  }

  getRowActions(row, doneCallback) {
    let action = [ { label: "Edit", name: "edit" } ];
    doneCallback(action);
  }

  handleStatusFilterChange(event) {
    this.selectedStatus = event.detail.value;
  }

  handleFilterAssessment() {
    let recordsBeforeFiltering = JSON.parse(JSON.stringify(this.records));

    let status = this.statuses
      .find(statusObj => statusObj.value === this.selectedStatus)
      .label;

    let filterCondition = {
      Status__c: status
    };

    for (const key in filterCondition) {
      if (filterCondition[key] !== this.defaultStatusLabel) {
        recordsBeforeFiltering = recordsBeforeFiltering.filter(record => record[key] === filterCondition[key]);
      } else {
        recordsBeforeFiltering = recordsBeforeFiltering.filter(record => record[key] !== this.defaultStatusLabelFilterCondition);
      }
    }

    this.filteredRecords = recordsBeforeFiltering;
  }

  handleRowAction(event) {
    const action = event.detail.action;
    const row = event.detail.row;
    switch (action.name) {
      case "edit":
        this.editRecordId = row.Id;
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: row.Id,
            objectApiName: PROJECT_ATTRIBUTE.objectApiName,
            actionName: "edit"
          }
        });
        break;
    }
  }

  handleCreateNewRecord() {
    const defaultValues = {};
    defaultValues[PROJECT_ATTRIBUTE_PROJECT_FIELD.fieldApiName] = this.recordId;

    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
      attributes: {
        objectApiName: PROJECT_ATTRIBUTE.objectApiName,
        actionName: "new"
      },
      state: {
        recordTypeId: this.ASSESSMENT_RECORD_TYPE_ID,
        defaultFieldValues: encodeDefaultFieldValues(defaultValues)
      }
    });
  }

  showToast(title = "Unknown error", message = "") {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: "error"
    });
    this.dispatchEvent(event);
  }

  htmlDecode(input) {
    let e = document.createElement('div');
    e.innerHTML = input;
    return e.childNodes.length === 0 ? "" : e.childNodes[0].nodeValue;
  }

}