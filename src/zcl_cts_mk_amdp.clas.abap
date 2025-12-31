CLASS zcl_cts_mk_amdp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES :if_amdp_marker_hdb,
      if_oo_adt_classrun.

    "Get Customer by Business Partner ID
    CLASS-METHODS : get_customer_by_id AMDP OPTIONS CDS SESSION CLIENT DEPENDENT
      IMPORTING VALUE(i_bp_id) TYPE zcts_mk_dte_id
      EXPORTING VALUE(e_res)   TYPE string.

    " add two numbers
    CLASS-METHODS : add_two_numbers AMDP OPTIONS CDS SESSION CLIENT DEPENDENT
      IMPORTING
        VALUE(a)      TYPE i
        VALUE(b)      TYPE i
      EXPORTING
        VALUE(result) TYPE i.

    "Calculate Product Price with Tax

    CLASS-METHODS : get_product_mrp AMDP OPTIONS CDS SESSION CLIENT DEPENDENT
      IMPORTING
        VALUE(i_tax) TYPE i
      EXPORTING
        VALUE(otab)  TYPE zcts_mk_tt_product_mrp.


    CLASS-METHODS get_total_sales FOR TABLE FUNCTION zi_cts_mk_tf.


  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_cts_mk_amdp IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    zcl_cts_mk_amdp=>get_product_mrp(
    EXPORTING i_tax = 18
    IMPORTING otab = DATA(lt_product_mrp) ).

    out->write( lt_product_mrp ).

    zcl_cts_mk_amdp=>add_two_numbers(
    EXPORTING
      a = 5
      b = 10
   IMPORTING result = DATA(lv_result) ).

    out->write( |The result of adding 5 and 10 is: { lv_result }| ).


    zcl_cts_mk_amdp=>get_customer_by_id(
            EXPORTING
            i_bp_id = '3E4C19099F0E1FE0B6FB1D8246685DC2'
            IMPORTING
            e_res   = DATA(lv_customer_name) ).

    out->write( |Customer Name for BP ID 3E4C19099F0E1FE0B6FB1D8246685DC2 is: { lv_customer_name }| ).

  ENDMETHOD.

  METHOD add_two_numbers BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY.

    DECLARE x integer;
    DECLARE y integer;


    x := a;
    y := b;

    result = :x + :y;


  ENDMETHOD.



  METHOD get_customer_by_id BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY USING zcts_mk_bpa.

    SELECT company_name  INTO e_res
  FROM zcts_mk_bpa
  WHERE bp_id = i_bp_id;

  ENDMETHOD.

  METHOD get_product_mrp BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY USING zcts_mk_product.

* Declare local variable
* get all the products and calculate MRP with tax
    DECLARE lv_count INTEGER;
    declare i INTEGER;
    DECLARE lv_mrp bigint;
    declare lv_price_d integer;


lt_prod = select * from ZCTS_MK_PRODUCT;

SELECT COUNT(*)
INTO lv_count
FROM :lt_prod;

for i in 1..:lv_count do

lv_price_d := :lt_prod.price[i] * ( 100 - :lt_prod.discount[i] ) / 100;
lv_mrp := :lv_price_d * ( 100 + :i_tax ) / 100;
if lv_mrp > 15000 then
lv_mrp := :lv_mrp * 0.90;
end if;

:otab.insert(
(
:lt_prod.name[i],
:lt_prod.category[i],
:lt_prod.price[i],
:lt_prod.currency[i],
:lt_prod.discount[i],
:lv_price_d,
:lv_mrp ),
i );
end for;

  ENDMETHOD.


  METHOD get_total_sales  BY DATABASE FUNCTION FOR HDB LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY USING  zcts_mk_bpa zcts_mk_so_hdr zcts_mk_so_item.

    RETURN select
    session_context('CLIENT') as client,
    bpa.company_name,
    sum (item.amount) AS total_sales,
    item.currency as currency_code,
    rank() over ( order by sum(item.amount) desc) as customer_rank
     from zcts_mk_bpa as bpa
    inner join zcts_mk_so_hdr as sls
    ON bpa.bp_id = sls.buyer
    inner join zcts_mk_so_item as item
    on sls.order_id = item.order_id
    group by  bpa.client,
              bpa.company_name,
              item.currency ;
*limit 3
  endmethod.

ENDCLASS.
