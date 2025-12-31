@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales composite Data'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

@Analytics.dataCategory: #CUBE

define view entity ZI_CTS_MK_SALES_CUBE
  as select from ZI_CTS_MK_SALES
  association [1] to ZI_CTS_MK_BPA     as _BusinessPartner on $projection.Buyer = _BusinessPartner.BpId
  association [1] to ZI_CTS_MK_PRODUCT as _Product         on $projection.productId = _Product.ProductId
{

  key ZI_CTS_MK_SALES.OrderId,
      ZI_CTS_MK_SALES.OrderNo,
      ZI_CTS_MK_SALES.Buyer,
      ZI_CTS_MK_SALES.CreatedBy,
      ZI_CTS_MK_SALES.CreatedOn,
      /* Associations */
      ZI_CTS_MK_SALES._Items.product  as productId,
      @Semantics.amount.currencyCode: 'currencycode'
      @DefaultAggregation: #SUM
      ZI_CTS_MK_SALES._Items.amount   as grossAmount,
      ZI_CTS_MK_SALES._Items.currency as currencycode,
      @Semantics.quantity.unitOfMeasure: 'unitOfMeasure'
      @DefaultAggregation: #SUM
      ZI_CTS_MK_SALES._Items.qty      as quantity,
      ZI_CTS_MK_SALES._Items.uom      as unitOfMeasure,
      _BusinessPartner,
      _Product

}
