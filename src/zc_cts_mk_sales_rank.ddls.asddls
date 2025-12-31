@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Rank TF'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZC_CTS_MK_SALES_RANK
  as select from ZI_CTS_MK_TF
{
  key company_name,
  total_sales,
  currency_code,
  customer_rank
}
