@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'My Travel Processor Projection'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZCTS_MK_Travel_Processor
  as projection on ZCTS_MK_TRavel
{

      //@ObjectModel.text.association: '_Agency'
      key TravelId,
      @ObjectModel.text.element: [ 'AgencyName' ]
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Agency', entity.element: 'AgencyID' }]
      AgencyId,
      @Semantics.text: true
      _Agency.Name       as AgencyName,
      @ObjectModel.text.element: [ 'CustomerName' ]
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Customer', entity.element: 'CustomerID' }]
      CustomerId,
      @Semantics.text: true
      _Customer.LastName as CustomerName,
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      CurrencyCode,
      Description,
      @ObjectModel.text.element: [ 'StatusText' ]
      @Consumption.valueHelpDefinition: [{ entity.name: 'ZCTS_MK_TRavel', entity.element: 'StatusText'}]
      OverallStatus,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      @Semantics.text: true
      StatusText,
      criticality,
      /* Associations */
      _Agency,
      _Booking : redirected to composition child ZCTS_MK_Booking_Processor,
      _Currency,
      _Customer,
      _OverallStatus
}
