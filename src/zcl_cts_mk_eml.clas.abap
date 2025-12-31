CLASS zcl_cts_mk_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION..
*    DATA: lv_opr TYPE c VALUE 'R'. "Read execution
    DATA: lv_opr TYPE c VALUE 'C'. "Create
*    DATA: lv_opr TYPE c VALUE 'U'. "Update
*    DATA: lv_opr TYPE c VALUE 'D'. "Update
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_cts_mk_eml IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    " Implementation of the main method

    CASE lv_opr.
      WHEN 'R'.
        READ ENTITIES OF ZCTS_MK_TRavel
        ENTITY Travel
*        ALL FIELDS WITH
        FIELDS (
         TravelId
         AgencyId
         CustomerId
         BeginDate
         EndDate
         TotalPrice
         BookingFee
         CurrencyCode
         OverallStatus )
         WITH VALUE #(
        ( TravelId = '00000010' )
        ( TravelId = '00000012' )
        ( TravelId = '99110036' )
        )
        RESULT DATA(lt_results)
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported).


      WHEN 'C'.

        DATA(lv_desc) = 'New Travel Booking'.
        DATA(lv_agency) = '070046'.
        DATA(lv_customer) = '000022'.

        MODIFY ENTITIES OF ZCTS_MK_Travel
                ENTITY Travel
                CREATE FIELDS (
                 TravelId
                 AgencyId
                 CustomerId
                 BeginDate
                 EndDate
                 Description
                 OverallStatus )

                 WITH VALUE #(

                 (  %cid = '99110036' "Temp UniqueKey
                    travelId = '99110036'
                    AgencyId = lv_agency
                    CustomerId = lv_customer
                    BeginDate = cl_abap_context_info=>get_system_date(  )
                    EndDate = cl_abap_context_info=>get_system_date(  ) + 30
                    Description = lv_desc
                    OverallStatus = 'O'
                  )

                   ( %cid = '99110037' "Temp UniqueKey
                    travelId = '99110037'
                    AgencyId = lv_agency
                    CustomerId = lv_customer + '1'
                    BeginDate = cl_abap_context_info=>get_system_date(  )
                    EndDate = cl_abap_context_info=>get_system_date(  ) + 30
                    OverallStatus = 'A'
                  )

                 )
                 MAPPED DATA(lt_mapped)
                 FAILED lt_failed
                 REPORTED lt_reported.

        COMMIT ENTITIES. ""For CRUD Operands in DB, it must be specified.

      WHEN 'U'.


        lv_desc = 'New Travel Booking'.
        lv_agency = '070046'.
        lv_customer = '000022'.

        MODIFY ENTITIES OF zcts_mk_travel
        ENTITY Travel
        UPDATE FIELDS (
                       AgencyId
                       CustomerId
                       Description
                       OverallStatus )
        WITH VALUE #(
          ( travelId = '99110036'
            AgencyId = lv_agency
            CustomerId = lv_customer
            Description = 'Update EML Test-1'
            OverallStatus = 'R'
          )

          ( travelId = '99110037'
            AgencyId = lv_agency
            CustomerId = lv_customer + 2
            Description = 'Update EML Test-2'
            OverallStatus = 'A'
          )

        )
        MAPPED lt_mapped
        FAILED lt_failed
        REPORTED lt_reported.

        COMMIT ENTITIES.""For CRUD Operands in DB, it must be specified.


      WHEN 'D'.

        MODIFY ENTITIES OF zcts_mk_travel
        ENTITY Travel
        DELETE FROM VALUE #(
       ( travelId = '99110036' )
       ( travelId = '99110037' ) )
         MAPPED lt_mapped
         FAILED lt_failed
         REPORTED lt_reported.

        COMMIT ENTITIES. ""For CRUD Operands in DB, it must be specified.

    ENDCASE.


    out->write( lt_results ).
    out->write( lt_mapped ).
    out->write( lt_failed ).
    out->write( lt_reported ).

  ENDMETHOD.
ENDCLASS.
