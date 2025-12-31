CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS earlynumbering_cba_Bookingsupp FOR NUMBERING
      IMPORTING entities FOR CREATE Booking\_Bookingsupplement.

ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD earlynumbering_cba_Bookingsupp.

**    DATA max_id TYPE /dmo/booking_supplement_id VALUE '0'.
**
**    " Get all the travel requests and their booking data
**    READ ENTITIES OF ZCTS_MK_TRavel IN LOCAL MODE
**    ENTITY Booking
**    BY \_Bookingsupplement
**    FROM CORRESPONDING #( entities )
**    LINK DATA(booking_supplements).
**
**    LOOP AT entities ASSIGNING FIELD-SYMBOL(<group>)
**           GROUP BY <group>-%tky.
**
**      " 1️. Find highest ID from DB
**      LOOP AT booking_supplements INTO DATA(ls_db)
***        USING KEY entity
**           WHERE source-TravelId  = <group>-TravelId
**             AND source-BookingId = <group>-BookingId.
**
**        IF ls_db-target-BookingSupplementId > max_id.
**          max_id = ls_db-target-BookingSupplementId.
**        ENDIF.
**      ENDLOOP.
**
**      " 2️. Find highest ID from incoming request
**      LOOP AT entities INTO DATA(ls_entity)
***     USING KEY entity
**           WHERE TravelId  = <group>-TravelId
**             AND BookingId = <group>-BookingId.
**
**        LOOP AT ls_entity-%target INTO DATA(ls_target).
**          IF ls_target-BookingSupplementId > max_id.
**            max_id = ls_target-BookingSupplementId.
**          ENDIF.
**        ENDLOOP.
**      ENDLOOP.
**
**      " 3️. Assign new numbers
**      LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking>)
***      USING KEY entity
**           WHERE TravelId  = <group>-TravelId
**             AND BookingId = <group>-BookingId.
**
**        LOOP AT <booking>-%target ASSIGNING FIELD-SYMBOL(<booksupp_wo_id>).
**          APPEND CORRESPONDING #( <booksupp_wo_id> )
**            TO mapped-bookingsupplement ASSIGNING FIELD-SYMBOL(<mapped>).
**
**          IF <booksupp_wo_id>-BookingSupplementId IS INITIAL.
**            max_id = max_id + 1.
**            <mapped>-BookingSupplementId = max_id.
**          ENDIF.
**
**        ENDLOOP.
**      ENDLOOP.
**    ENDLOOP.

    DATA: max_booking_suppl_id TYPE /dmo/booking_supplement_id.

    "1. Get all the travel requests and their booking data
    READ ENTITIES OF ZCTS_MK_TRavel IN LOCAL MODE
    ENTITY Booking
    BY \_Bookingsupplement
    FROM CORRESPONDING #( entities )
    LINK DATA(booking_supplements).


    LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking_group>) GROUP BY <booking_group>-%tky.

      " Get highest bookingsupplement_id from bookings belonging to booking
      max_booking_suppl_id = REDUCE #(
        INIT max = CONV /dmo/booking_supplement_id( '0' )
        FOR booksuppl IN booking_supplements USING KEY entity
        WHERE ( source-TravelId  = <booking_group>-TravelId
            AND source-BookingId = <booking_group>-BookingId )
        NEXT max = COND /dmo/booking_supplement_id(
                     WHEN booksuppl-target-BookingSupplementId > max
                     THEN booksuppl-target-BookingSupplementId
                     ELSE max )
      ).

      " Get highest assigned bookingsupplement_id from incoming entities
      max_booking_suppl_id = REDUCE #(
        INIT max = max_booking_suppl_id
        FOR entity IN entities USING KEY entity
        WHERE ( TravelId  = <booking_group>-TravelId
            AND BookingId = <booking_group>-BookingId )
        FOR target IN entity-%target
        NEXT max = COND /dmo/booking_supplement_id(
                     WHEN target-BookingSupplementId > max
                     THEN target-BookingSupplementId
                     ELSE max )
      ).

      " Loop over all entries in entities with the same TravelId and BookingId
      LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking>)
           USING KEY entity
           WHERE TravelId  = <booking_group>-TravelId
             AND BookingId = <booking_group>-BookingId.

        " Assign new booking_supplement_ids
        LOOP AT <booking>-%target ASSIGNING FIELD-SYMBOL(<booksuppl_wo_numbers>).
          APPEND CORRESPONDING #( <booksuppl_wo_numbers> )
          TO mapped-bookingsupplement ASSIGNING FIELD-SYMBOL(<mapped_booksuppl>).

          IF <booksuppl_wo_numbers>-BookingSupplementId IS INITIAL.
            max_booking_suppl_id += 10.
            <mapped_booksuppl>-BookingSupplementId = max_booking_suppl_id.
          ENDIF.
        ENDLOOP.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
