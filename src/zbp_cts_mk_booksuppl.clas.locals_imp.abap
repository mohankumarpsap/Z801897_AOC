CLASS lhc_BookingSupplement DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR BookingSupplement RESULT result.
    METHODS calculatetotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR bookingsupplement~calculatetotalprice.

ENDCLASS.

CLASS lhc_BookingSupplement IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD calculateTotalPrice.

    DATA: travel_ids TYPE TABLE OF /DMO/I_Travel_M WITH UNIQUE HASHED KEY key COMPONENTS travel_id.

    travel_ids = CORRESPONDING #( keys DISCARDING DUPLICATES MAPPING travel_id = TravelId ).

    MODIFY ENTITIES OF ZCTS_MK_TRavel IN LOCAL MODE
    ENTITY Travel
    EXECUTE ReCalcTotalPrice
    FROM CORRESPONDING #( travel_ids )
    MAPPED DATA(mapped)
    FAILED DATA(failed)
    REPORTED DATA(lt_reported).


  ENDMETHOD.

ENDCLASS.
