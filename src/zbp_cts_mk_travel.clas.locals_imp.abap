CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PUBLIC SECTION.

    METHODS precheck_reuse.


  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS additionalsave FOR MODIFY
      IMPORTING keys FOR ACTION travel~additionalsave.
    METHODS recalctotalprice FOR MODIFY
      IMPORTING keys FOR ACTION travel~recalctotalprice.

    METHODS calculatetotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~calculatetotalprice.
    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE travel.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE travel.

*    METHODS get_instance_features FOR INSTANCE FEATURES
*      IMPORTING keys REQUEST requested_features FOR travel RESULT result.

*    METHODS copytravel FOR MODIFY
*      IMPORTING keys FOR ACTION travel~copytravel.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Travel.

    METHODS earlynumbering_cba_Booking FOR NUMBERING
      IMPORTING entities FOR CREATE Travel\_Booking.


    TYPES: t_entity_create  TYPE TABLE FOR CREATE ZCTS_MK_TRavel,
           t_enitity_update TYPE TABLE FOR UPDATE ZCTS_MK_TRavel,
           t_entity_rep     TYPE TABLE FOR REPORTED ZCTS_MK_TRavel,
           t_entity_r       TYPE TABLE FOR FAILED ZCTS_MK_TRavel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA: entity        TYPE STRUCTURE FOR CREATE ZCTS_MK_TRavel,
          travel_id_max TYPE /dmo/travel_id.

    "Step-1 : Ensure Travel ID is not set for the record which is coming
    LOOP AT entities INTO entity WHERE TravelId IS NOT INITIAL.
      APPEND CORRESPONDING #( entity ) TO mapped-travel.
    ENDLOOP.

    DATA(entities_wo_travel_id) = entities.
    DELETE entities_wo_travel_id WHERE TravelId IS NOT INITIAL.

    "Step-2 : Get the Sequence from the SNRO
    TRY.

        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr       = '01'
            object            = CONV #( '/DMO/TRAVL' )
            quantity          = CONV #( lines( entities_wo_travel_id ) )
          IMPORTING
            number            = DATA(number_range_key)
            returncode        = DATA(number_range_return_code)
            returned_quantity = DATA(number_range_returned_quantity)
        ).

      CATCH cx_number_ranges INTO DATA(lx_number_range).
        "Step-3 : if there is an exception, we will throw the exception
        LOOP AT entities_wo_travel_id INTO entity.
          APPEND VALUE #( %cid = entity-%cid %key = entity-%key %msg = lx_number_range )
          TO reported-travel.
          APPEND VALUE #( %cid = entity-%cid %key = entity-%key )
         TO failed-travel.
        ENDLOOP.
        EXIT.
    ENDTRY.

    CASE  number_range_return_code.
      WHEN '1'.
        "Step-4 : Handle the Special cases where Number range exceed critical %
        LOOP AT entities_wo_travel_id INTO entity.
          APPEND VALUE #( %cid = entity-%cid
                          %key = entity-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                 textid = /dmo/cm_flight_messages=>number_range_depleted
                                 severity = if_abap_behv_message=>severity-warning )
                          )
          TO reported-travel.
        ENDLOOP.

      WHEN '2' OR '3'.
        "Step-5 : The number is return the last number, or exhausted  the
        LOOP AT entities_wo_travel_id INTO entity.
          APPEND VALUE #( %cid = entity-%cid
                          %key = entity-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                 textid = /dmo/cm_flight_messages=>not_sufficient_numbers
                                 severity = if_abap_behv_message=>severity-warning )
                          )
          TO reported-travel.
          APPEND VALUE #( %cid = entity-%cid
                          %key = entity-%key
                          %fail-cause = if_abap_behv=>cause-conflict
                          )
          TO failed-travel.
        ENDLOOP.
    ENDCASE.

    "Step-6 : Final check for all numbers
    ASSERT number_range_returned_quantity = lines( entities_wo_travel_id  ).


    "Step-7 : Loop over the incoming travel data and assign the numbers from number range and return MAPPED
    "         data which will go the the RAP framework

    travel_id_max = number_range_key - number_range_returned_quantity.
    LOOP AT entities_wo_travel_id INTO entity.

      travel_id_max += 1.
      entity-TravelId = travel_id_max.

      APPEND VALUE #(  %cid = entity-%cid
                       %key = entity-%key
                       %is_draft = entity-%is_draft
                       ) TO mapped-travel.
    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.

    DATA max_booking_id TYPE /dmo/booking_id VALUE '0'.

    " Get all the travel requests and their booking data
    READ ENTITIES OF ZCTS_MK_TRavel IN LOCAL MODE
    ENTITY Travel
    BY \_Booking
    FROM CORRESPONDING #( entities )
    LINK DATA(bookings).


    "Loop at Unique travel IDs
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel_group>)
           GROUP BY <travel_group>-TravelId.

      " 1️. Get highest BookingId from DB
      LOOP AT bookings INTO DATA(ls_booking)
           USING KEY entity
           WHERE source-TravelId = <travel_group>-TravelId.

        IF max_booking_id < ls_booking-target-BookingId.
          max_booking_id = ls_booking-target-BookingId.
        ENDIF.

      ENDLOOP.

      " 2️. Get highest BookingId from incoming request
      LOOP AT entities INTO DATA(ls_entity)
           USING KEY entity
           WHERE TravelId = <travel_group>-TravelId.

        LOOP AT ls_entity-%target INTO DATA(ls_target).
          IF max_booking_id < ls_target-BookingId.
            max_booking_id = ls_target-BookingId.
          ENDIF.
        ENDLOOP.

      ENDLOOP.

      " 3️. Assign new BookingIds
      LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel>)
           USING KEY entity
           WHERE TravelId = <travel_group>-TravelId.

        LOOP AT <travel>-%target ASSIGNING FIELD-SYMBOL(<booking>).

          APPEND CORRESPONDING #( <booking> )
            TO mapped-booking ASSIGNING FIELD-SYMBOL(<mapped_booking>).

          IF <mapped_booking>-BookingId IS INITIAL.
            max_booking_id += 10.
            <mapped_booking>-%is_draft = <booking>-%is_draft.
            <mapped_booking>-BookingId = max_booking_id.
          ENDIF.

        ENDLOOP.
      ENDLOOP.
    ENDLOOP.


    " OWN Style
*    DATA: max_booking_id TYPE /dmo/booking_id.
*
*    "1. Get all the travel requests and their booking data
*    READ ENTITIES OF ZCTS_MK_TRavel IN LOCAL MODE
*    ENTITY Travel
*    BY \_Booking
*    FROM CORRESPONDING #( entities )
*    LINK DATA(bookings).
*
*    "Loop at Unique travel IDs
*    LOOP AT entities  ASSIGNING FIELD-SYMBOL(<travel_group>) GROUP BY <travel_group>-TravelId.
*
*      "2. get the highest number of booking number which is already there ( in DB ).
*      LOOP AT bookings INTO DATA(ls_bookings) USING KEY entity
*      WHERE source-TravelId = <travel_group>-TravelId.
*        IF  max_booking_id < ls_bookings-target-BookingId.
*          max_booking_id = ls_bookings-target-BookingId.
*        ENDIF.
*      ENDLOOP.
*
*      "3. get the assigned booking number for incoming request
*      LOOP AT entities INTO DATA(ls_entity) USING KEY entity
*     WHERE TravelId = <travel_group>-TravelId.
*        LOOP AT ls_entity-%target INTO DATA(ls_target).
*          IF  max_booking_id < ls_target-BookingId.
*            max_booking_id = ls_target-BookingId.
*          ENDIF.
*        ENDLOOP.
*      ENDLOOP.
*      "4. loop over all the entries of travel with same travel ID
*      LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel>)
*       USING KEY entity WHERE TravelId = <travel_group>-TravelId.
*
*        "5. Assign new booking to the booking entity inside each travel
*        LOOP AT <travel>-%target ASSIGNING FIELD-SYMBOL(<booking_wo_travel>).
*          APPEND CORRESPONDING #( <booking_wo_travel> ) TO mapped-booking
*          ASSIGNING FIELD-SYMBOL(<mapped_booking>).
*
*          IF  <mapped_booking>-BookingId IS INITIAL.
*            max_booking_id += 10.
*            <mapped_booking>-BookingId  = max_booking_id.
*          ENDIF.
*
*        ENDLOOP.
*
*      ENDLOOP.
*    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

*  METHOD copyTravel.
*  ENDMETHOD.

*  METHOD get_instance_features.
*
*    READ ENTITIES OF ZCTS_MK_TRavel IN LOCAL MODE
*    ENTITY Travel
*    ALL FIELDS WITH CORRESPONDING #( keys )
*    RESULT DATA(lt_result).
*
*    READ TABLE lt_result INDEX 1 INTO DATA(ls_result).
*    IF ls_result-OverallStatus = 'X'.
*      DATA(lv_allow) = if_abap_behv=>fc-o-disabled.
*    ELSE.
*      lv_allow = if_abap_behv=>fc-o-enabled.
*    ENDIF.
*
*    result = VALUE #( FOR travel IN lt_result ( %tky = travel-%tky %assoc-_Booking = lv_allow ) ).
*
*  ENDMETHOD.

  METHOD AdditionalSave.
  ENDMETHOD.


  METHOD ReCalcTotalPrice.
    TYPES:BEGIN OF ty_amount_per_currencycode,
            amount        TYPE /dmo/total_price,
            currency_code TYPE /dmo/currency_code,
          END OF ty_amount_per_currencycode.

    DATA: amounts_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    " Read all relevant travel instances.
    READ ENTITIES OF ZCTS_MK_TRavel IN LOCAL MODE
    ENTITY Travel
    FIELDS (  BookingFee CurrencyCode )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DELETE travels WHERE currencycode IS INITIAL.

    " Read all associated bookings and add them to the total price.
    READ ENTITIES OF ZCTS_MK_TRavel IN LOCAL MODE
    ENTITY Travel BY \_Booking
    FIELDS (  FlightPrice CurrencyCode )
    WITH CORRESPONDING #( travels )
    RESULT DATA(bookings).

    " Read all associated booking supplements and add them to the total price.
    READ ENTITIES OF ZCTS_MK_TRavel IN LOCAL MODE
    ENTITY Booking BY \_Bookingsupplement
    FIELDS ( Price CurrencyCode )
    WITH CORRESPONDING #( bookings )
    RESULT DATA(bookingsupplements).


    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travels>).

      amounts_per_currencycode = VALUE #( (
      amount =  <travels>-BookingFee
      currency_code = <travels>-CurrencyCode ) ).

      LOOP AT bookings ASSIGNING FIELD-SYMBOL(<bookings>)
      WHERE TravelId = <travels>-TravelId.
        " Set the start for the calculation by adding the booking fee
        COLLECT VALUE ty_amount_per_currencycode(
        amount =  <bookings>-FlightPrice
        currency_code = <bookings>-CurrencyCode )
        INTO amounts_per_currencycode.

        LOOP AT bookingsupplements ASSIGNING FIELD-SYMBOL(<supplements>)
        WHERE TravelId = <bookings>-TravelId
          AND BookingId = <bookings>-BookingId.

          COLLECT VALUE ty_amount_per_currencycode(
          amount = <supplements>-Price
          currency_code = <supplements>-CurrencyCode )
          INTO amounts_per_currencycode.

        ENDLOOP.
      ENDLOOP.


      DELETE amounts_per_currencycode WHERE currency_code IS INITIAL.

      LOOP AT amounts_per_currencycode ASSIGNING FIELD-SYMBOL(<amounts_per_currencycode>).
        CLEAR <travels>-TotalPrice.
        " If needed do a Currency Conversion
        IF <amounts_per_currencycode>-currency_code = <travels>-CurrencyCode.
          <travels>-TotalPrice += <amounts_per_currencycode>-amount.

        ELSE.

          /dmo/cl_flight_amdp=>convert_currency(
            EXPORTING
              iv_amount               =  <amounts_per_currencycode>-amount
              iv_currency_code_source =  <amounts_per_currencycode>-currency_code
              iv_currency_code_target =  <travels>-CurrencyCode
              iv_exchange_rate_date   =  CONV #( cl_abap_context_info=>get_system_date(  ) )
          IMPORTING
            ev_amount               = DATA(total_booking_price_per_curr)
          ).

          <travels>-TotalPrice += total_booking_price_per_curr.

        ENDIF.

      ENDLOOP.

    ENDLOOP.


    " write back the modified total_price of travels
    MODIFY ENTITIES OF ZCTS_MK_TRavel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( TotalPrice )
    WITH CORRESPONDING #( travels )
    MAPPED DATA(lt_mapped)
    FAILED DATA(lt_failed)
    REPORTED DATA(lt_reported).

  ENDMETHOD.

  METHOD calculateTotalPrice.

    MODIFY ENTITIES OF ZCTS_MK_TRavel IN LOCAL MODE
    ENTITY Travel
    EXECUTE ReCalcTotalPrice
    FROM CORRESPONDING #( keys ) .

  ENDMETHOD.

  METHOD precheck_create.
  ENDMETHOD.

  METHOD precheck_update.
  ENDMETHOD.

  METHOD precheck_reuse.



  ENDMETHOD.

ENDCLASS.
