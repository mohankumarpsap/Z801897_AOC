@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'My Booking Processor Projection'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZCTS_MK_Booking_Processor
  as projection on ZCTS_MK_Booking
{
  key TravelId,
  key BookingId,
      BookingDate,
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Customer', entity.element: 'CustomerID' }]
      CustomerId,
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Carrier', entity.element: 'AirlineID' }]
      CarrierId,
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Connection', entity.element: 'ConnectionID',
      additionalBinding: [{ localElement: 'CarrierId', element: 'AirlineID' }]}]
      ConnectionId,
      FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,
      @Semantics.text: true
      CurrencyCode,
      LastChangedAt,
      /* Associations */
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Booking_Status_VH', entity.element: 'BookingStatus' }]
      BookingStatus,
      //_BookingStatus,
      _Bookingsupplement : redirected to composition child ZCTS_MK_Boosuppl_Processor,
      _Carrier,
      _Connection,
      _Customer,
      _Travel            : redirected to parent ZCTS_MK_Travel_Processor
}
