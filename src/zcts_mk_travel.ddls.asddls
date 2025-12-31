@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel Root by RAP BO'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZCTS_MK_TRavel
  as select from /dmo/travel_m
  // composition of child for travel viz booking
  composition [0..*] of ZCTS_MK_Booking          as _Booking

  // associations to related entities - Loose coupling to get dependency details
  association [1]    to /DMO/I_Agency               as _Agency     on $projection.AgencyId = _Agency.AgencyID
  association [1]    to /DMO/I_Customer             as _Customer   on $projection.CustomerId = _Customer.CustomerID
  association [1]    to I_Currency                  as _Currency   on $projection.CurrencyCode = _Currency.Currency
  association [1..1] to /DMO/I_Overall_Status_VH as _OverallStatus on $projection.OverallStatus = _OverallStatus.OverallStatus
{
  key travel_id       as TravelId,
      agency_id       as AgencyId,
      customer_id     as CustomerId,
      begin_date      as BeginDate,
      end_date        as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee     as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price     as TotalPrice,
      currency_code   as CurrencyCode,
      description     as Description,
      overall_status  as OverallStatus,
      // AUto generated fields for auditing
      @Semantics.user.createdBy: true
      created_by      as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at      as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by as LastChangedBy,
      --Local eTag field --OData eTag support
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt,


      case when $projection.OverallStatus = 'O' then 'Open'
           when $projection.OverallStatus = 'A' then 'Approved'
           when $projection.OverallStatus = 'R' then 'Rejected'
           when $projection.OverallStatus = 'X' then 'Canncelled'
           else 'Unknown Status'
      end             as StatusText,


      case when $projection.OverallStatus = 'O' then 0
        when $projection.OverallStatus = 'A' then 3
        when $projection.OverallStatus = 'R' then 2
        when $projection.OverallStatus = 'X' then 1
      end             as criticality,


      --Exposed associations
      _Booking,
      _Agency,
      _Customer,
      _Currency,
      _OverallStatus
}
