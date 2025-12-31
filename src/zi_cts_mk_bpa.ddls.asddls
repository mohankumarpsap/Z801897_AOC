@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS Entity Business Partner'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_CTS_MK_BPA
  as select from zcts_mk_bpa
  association [1] to I_Country as _Country on $projection.CountryCode = _Country.Country
{
  key bp_id                                                           as BpId,
      bp_role                                                         as BpRole,
      company_name                                                    as CompanyName,
      street                                                          as Street,
      country                                                         as CountryCode,
      region                                                          as Region,
      city                                                            as City,
      _Country._Text[Language = $session.system_language].CountryName as CountryName
}
