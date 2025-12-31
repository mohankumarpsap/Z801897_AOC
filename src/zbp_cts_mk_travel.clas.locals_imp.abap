CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Travel.

    METHODS earlynumbering_cba_Booking FOR NUMBERING
      IMPORTING entities FOR CREATE Travel\_Booking.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.

** Mohankumar

    DATA: lv_id TYPE string.
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
                       %key = entity-%key ) TO mapped-travel.
    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.

**    DATA max_booking_id TYPE /dmo/booking_id VALUE '0'.
**
**    " Get all the travel requests and their booking data
**    READ ENTITIES OF ZCTS_MK_TRavel IN LOCAL MODE
**    ENTITY Travel
**    BY \_Booking
**    FROM CORRESPONDING #( entities )
**    LINK DATA(bookings).
**
**
**    "Loop at Unique travel IDs
**    LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel_group>)
**           GROUP BY <travel_group>-TravelId.
**
**      " 1️. Get highest BookingId from DB
**      LOOP AT bookings INTO DATA(ls_booking)
**           USING KEY entity
**           WHERE source-TravelId = <travel_group>-TravelId.
**
**        IF max_booking_id < ls_booking-target-BookingId.
**          max_booking_id = ls_booking-target-BookingId.
**        ENDIF.
**
**      ENDLOOP.
**
**      " 2️. Get highest BookingId from incoming request
**      LOOP AT entities INTO DATA(ls_entity)
**           USING KEY entity
**           WHERE TravelId = <travel_group>-TravelId.
**
**        LOOP AT ls_entity-%target INTO DATA(ls_target).
**          IF max_booking_id < ls_target-BookingId.
**            max_booking_id = ls_target-BookingId.
**          ENDIF.
**        ENDLOOP.
**
**      ENDLOOP.
**
**      " 3️. Assign new BookingIds
**      LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel>)
**           USING KEY entity
**           WHERE TravelId = <travel_group>-TravelId.
**
**        LOOP AT <travel>-%target ASSIGNING FIELD-SYMBOL(<booking>).
**
**          APPEND CORRESPONDING #( <booking> )
**            TO mapped-booking ASSIGNING FIELD-SYMBOL(<mapped_booking>).
**
**          IF <mapped_booking>-BookingId IS INITIAL.
**            max_booking_id += 10.
**            <mapped_booking>-BookingId = max_booking_id.
**          ENDIF.
**
**        ENDLOOP.
**      ENDLOOP.
**    ENDLOOP.



    DATA: max_booking_id TYPE /dmo/booking_id.

    "1. Get all the travel requests and their booking data
    READ ENTITIES OF ZCTS_MK_TRavel IN LOCAL MODE
    ENTITY Travel
    BY \_Booking
    FROM CORRESPONDING #( entities )
    LINK DATA(bookings).

    "Loop at Unique travel IDs
    LOOP AT entities  ASSIGNING FIELD-SYMBOL(<travel_group>) GROUP BY <travel_group>-TravelId.

      "2. get the highest number of booking number which is already there ( in DB ).
      LOOP AT bookings INTO DATA(ls_bookings) USING KEY entity
      WHERE source-TravelId = <travel_group>-TravelId.
        IF  max_booking_id < ls_bookings-target-BookingId.
          max_booking_id = ls_bookings-target-BookingId.
        ENDIF.
      ENDLOOP.

      "3. get the assigned booking number for incoming request
      LOOP AT entities INTO DATA(ls_entity) USING KEY entity
     WHERE TravelId = <travel_group>-TravelId.
        LOOP AT ls_entity-%target INTO DATA(ls_target).
          IF  max_booking_id < ls_target-BookingId.
            max_booking_id = ls_target-BookingId.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
      "4. loop over all the entries of travel with same travel ID
      LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel>)
       USING KEY entity WHERE TravelId = <travel_group>-TravelId.

        "5. Assign new booking to the booking entity inside each travel
        LOOP AT <travel>-%target ASSIGNING FIELD-SYMBOL(<booking_wo_travel>).
          APPEND CORRESPONDING #( <booking_wo_travel> ) TO mapped-booking
          ASSIGNING FIELD-SYMBOL(<mapped_booking>).

          IF  <mapped_booking>-BookingId IS INITIAL.
            max_booking_id += 10.
            <mapped_booking>-BookingId  = max_booking_id.
          ENDIF.

        ENDLOOP.

      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
