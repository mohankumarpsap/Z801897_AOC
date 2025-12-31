@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'My Booking Supplement Processor Projection'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZCTS_MK_Boosuppl_Processor
  as projection on ZCTS_MK_Booksuppl
{
  key TravelId,
  key BookingId,
  key BookingSupplementId,
      SupplementId,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Price,
      CurrencyCode,
      LastChangedAt,
      /* Associations */
      _Booking : redirected to parent ZCTS_MK_Booking_Processor,
      _Travel : redirected to ZCTS_MK_Travel_Processor
}
