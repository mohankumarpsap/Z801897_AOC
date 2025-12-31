@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplements as child of composition tree'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZCTS_MK_Booksuppl
  as select from /dmo/booksuppl_m

  association        to parent ZCTS_MK_Booking as _Booking        on  $projection.BookingId = _Booking.BookingId
                                                                  and $projection.TravelId  = _Booking.TravelId

  association [0..1] to ZCTS_MK_TRavel         as _Travel         on  $projection.TravelId = _Travel.TravelId
  association [0..1] to /DMO/I_Supplement      as _Product        on  $projection.SupplementId = _Product.SupplementID
  association [0..1] to /DMO/I_SupplementText  as _SupplementText on  $projection.SupplementId = _SupplementText.SupplementID
{
  key travel_id             as TravelId,
  key booking_id            as BookingId,
  key booking_supplement_id as BookingSupplementId,
      supplement_id         as SupplementId,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,
      currency_code         as CurrencyCode,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      _Booking,
      _Travel,
      _Product,
      _SupplementText
}
