/**
 * Created by vladyslavkushney on 26.05.2020.
 */

import LightningDatatable from "lightning/datatable";
import columnImage from "./datatable_column_image.html";

export default class DatatableExtended extends LightningDatatable {
  static customTypes = {
    image: {
      template: columnImage,
      standardCellLayout: true,
      typeAttributes: ["altText"],
    }
  };
}