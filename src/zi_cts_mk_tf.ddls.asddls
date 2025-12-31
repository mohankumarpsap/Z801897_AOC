@EndUserText.label: 'Table Function'
@ClientHandling.algorithm: #SESSION_VARIABLE
@ClientHandling.type: #CLIENT_DEPENDENT
@AccessControl.authorizationCheck: #NOT_REQUIRED
define table function ZI_CTS_MK_TF
returns
{
  client        : abap.clnt;
  company_name  : abap.char(256);
  total_sales   : abap.dec(15,2);
  currency_code : abap.cuky;
  customer_rank : abap.int4;

}
implemented by method
  zcl_cts_mk_amdp=>get_total_sales;