@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Analytics View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
//@Analytics.query: true
define view entity ZC_CTS_MK_SALES_ANA
  as select from ZI_CTS_MK_SALES_CUBE
{
      @AnalyticsDetails.query.axis: #ROWS
  key _BusinessPartner.CompanyName as CompanyName,
      @AnalyticsDetails.query.axis: #ROWS
  key _BusinessPartner.CountryName as Country,
      @DefaultAggregation: #SUM
      @Semantics.amount.currencyCode: 'currencycode'
      @AnalyticsDetails.query.axis: #COLUMNS
      grossAmount,
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.filter.selectionType: #SINGLE
      currencycode,
      @Semantics.quantity.unitOfMeasure: 'unitOfMeasure'
      @AnalyticsDetails.query.axis: #COLUMNS
      quantity,
      @AnalyticsDetails.query.axis: #ROWS
      unitOfMeasure
}
