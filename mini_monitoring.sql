/* Formatted on 23/05/2025 10:02:07 (QP5 v5.391) */
SET SERVEROUT ON
SET SERVEROUTPUT ON
SET HEAD OFF
SET FEEDBACK OFF
SET LINESIZE 2000
SET TRIMSPOOL ON
SET TRIMOUT ON
SET WRAP OFF
SET TERMOUT OFF
SET PAGESIZE 0

SPOOL ON
SPOOL /sources/logs/avaloq_db_monitoring_${FDB_NAME}..log
-- SPOOL c:\temp\monitoring\avaloq_db_monitoring_${FDB_NAME}..log



ALTER SESSION SET CURRENT_SCHEMA = k;

SET DEFINE OFF;

DECLARE
    is_prod                         BOOLEAN := FALSE;
    is_pre                          BOOLEAN := FALSE;

    --data types
    SUBTYPE tDocId IS NUMBER;

    SUBTYPE tDocTypeId IS NUMBER;

    SUBTYPE tPrcqTypeId IS NUMBER;

    SUBTYPE tMsgId IS NUMBER;

    SUBTYPE tMsgStatusId IS NUMBER;

    SUBTYPE tMsgDocId IS NUMBER;

    SUBTYPE tMsgDocTypeId IS NUMBER;

    SUBTYPE tPrcqId IS NUMBER (9);

    SUBTYPE tPrcqName IS VARCHAR2 (200);

    SUBTYPE tBuId IS NUMBER (9);

    SUBTYPE tIsTreated IS BOOLEAN;

    SUBTYPE tMailIdxId IS NUMBER;

    SUBTYPE tMailIdxDocId IS NUMBER;

    SUBTYPE tMailIdxDocTypeId IS NUMBER;

    SUBTYPE tMailIdxStatusId IS NUMBER;

    SUBTYPE tMainId IS NUMBER;

    TYPE tPrcqErr IS RECORD
    (
        doc_id                  tDocId,
        doc_type_id             tDocTypeId,
        prcq_type_id            tPrcqTypeId,
        msg_id                  tMsgId,
        msg_status_id           tMsgStatusId,
        msg_doc_id              tMsgDocId,
        msg_doc_type_id         tMsgDocTypeId,
        prcq_id                 tPrcqId,
        prcq_name               tPrcqName,
        bu_id                   tBuId,
        mail_idx_id             tMailIdxId,
        mail_idx_doc_id         tMailIdxDocId,
        mail_idx_doc_type_id    tMailIdxDocTypeId,
        mail_idx_status_id      tMailIdxStatusId,
        is_treated              tIsTreated,
        main_id                 tMainId
    );

    TYPE tArrayPrcqErr IS TABLE OF tPrcqErr;

    TYPE tNumberList IS TABLE OF NUMBER
        INDEX BY BINARY_INTEGER;


    l_bu_list                       tNumberList;
    l_order_bu_id                   NUMBER;
    l_order_bu_name                 VARCHAR2 (50);

    l_ligne_fx_option_cisg          VARCHAR2 (3000);
    fx_option_cisg_count            NUMBER := 0;

    vPrcqErrList                    tArrayPrcqErr := tArrayPrcqErr ();
    vRec                            tPrcqErr;
    vCurPrcqId                      NUMBER;
    vLastPrcqId                     NUMBER;
    vLastPrcqName                   VARCHAR2 (200);
    vLastPrcqRecCnt                 NUMBER;
    vUntreatedRecCnt                NUMBER := 1; -- need this init to enter loop the first time

    --const
    c_none_p               CONSTANT NUMBER := 0;
    c_major_p              CONSTANT NUMBER := 1;
    c_blocking_p           CONSTANT NUMBER := 2;
    c_sys_blocking_p       CONSTANT NUMBER := 3;
    c_none                 CONSTANT VARCHAR2 (20) := 'None';
    c_major                CONSTANT VARCHAR2 (20) := 'Major';
    c_blocking             CONSTANT VARCHAR2 (20) := 'Blocking';
    c_sys_blocking         CONSTANT VARCHAR2 (20) := 'System blocking';
    c_ok                   CONSTANT VARCHAR2 (20) := 'OK';
    c_nok                  CONSTANT VARCHAR2 (20) := 'NOK';
    c_documentation_path   CONSTANT VARCHAR2 (250)
        := '\\bdl-lu.oi.bdl.lu\bludata\IT\Commun\Monitoring\Documentation_Files\' ;

    --this is just an apostrophe to fix the syntax coloring in notepad++'

    g_email_dbg                     VARCHAR (200)
        := 'relman@blu.bank';
    c_email_avapre         CONSTANT VARCHAR (200)
        := 'relman@blu.bank' ;

    --variables
    l_temp                          CLOB;
    l_boundary                      VARCHAR2 (255);
    p_to                            VARCHAR2 (4000);
    p_to_rm_test                    VARCHAR2 (1000);
    p_to_night                      VARCHAR2 (4000);
    l_to                            VARCHAR2 (4000);
    i                               NUMBER;
    l_cur                           NUMBER;
    p_from                          VARCHAR2 (255);
    p_subject                       VARCHAR2 (255);
    p_text                          VARCHAR2 (255);
    p_html_prepool                  VARCHAR2 (2000);
    p_html_pool                     CLOB;
    p_smtp_hostname                 VARCHAR2 (255);
    p_smtp_portnum                  VARCHAR2 (255);
    l_mail_stex                     VARCHAR2 (255);
    l_mail_stex_bond                VARCHAR2 (255);
    l_mail_stex_fund                VARCHAR2 (255);
    l_mail_stex_fund_market         VARCHAR2 (255);
    l_mail_stex_struct              VARCHAR2 (255);
    l_mail_stex_equity              VARCHAR2 (255);
    l_mail_stex_fund_blbe           VARCHAR2 (255);
    l_mail_stex_fix                 VARCHAR2 (255);
    l_mail_prcq_all_btlu            VARCHAR2 (255);
    l_mail_prcq_stex_lu             VARCHAR2 (255);
    l_mail_prcq_stex_btbe           VARCHAR2 (255);
    l_mail_prcq_secevt              VARCHAR2 (255);
    l_mail_prcq_secevt_inprc        VARCHAR2 (255);
    l_mail_prcq_secevt_corpac       VARCHAR2 (255);
    l_mail_prcq_settle_lu           VARCHAR2 (255);
    l_mail_prcq_settle_btbe         VARCHAR2 (255);
    l_mail_prcq_cust                VARCHAR2 (255);
    l_mail_prcq_fx                  VARCHAR2 (255);
    l_mail_prcq_prop                VARCHAR2 (255);
    l_mail_prcq_pay                 VARCHAR2 (255);
    l_mail_prcq_mail                VARCHAR2 (255);
    l_mail_exploit                  VARCHAR2 (255);
    l_mail_operateurs               VARCHAR2 (255);
    l_mail_prcq_secdb               VARCHAR2 (255);
    l_mail_prcq_secur               VARCHAR2 (255);
    l_mail_lock                     CLOB;
    l_mail_lock_cnt                 NUMBER := 0;
    l_mail_msg_fitax                VARCHAR2 (255);
    l_mail_pay_wfp                  VARCHAR2 (255);
    l_mail_pay_BTB                  VARCHAR2 (255);
    l_mail_pay_BTL                  VARCHAR2 (255);
    l_mail_pay_dflt                 VARCHAR2 (255);
    l_mail_market                   VARCHAR2 (255);
    l_mail_market_it                VARCHAR2 (255);
    l_mail_market_it_light          VARCHAR2 (255);
    l_mail_market_secdb             VARCHAR2 (255);
    l_mail_market_treasury          VARCHAR2 (255);
    l_mail_market_rates             VARCHAR2 (255);
    l_mail_sec_settle               VARCHAR2 (255);
    l_mail_pbs_projects             VARCHAR2 (255);
    l_mail_settle_on_hold           VARCHAR2 (255);
    l_mail_btbe_dflt                VARCHAR2 (255);
    l_mail_btlu_dflt                VARCHAR2 (255);
    l_mail_btgb_dflt                VARCHAR2 (255);
    l_mail_cisg_dflt                VARCHAR2 (255);
    l_mail_cisg_msg                 VARCHAR2 (255);
    l_mail_cisg_mmkt_task           VARCHAR2 (255);
    l_mail_cisg_fxopt               VARCHAR2 (255);
    l_mail_cisg_prcq_all            VARCHAR2 (255);
    l_mail_msg_bdl                  VARCHAR2 (255);
    l_mail_cisg_hourly_report       VARCHAR2 (255);
    l_mail_finacc                   VARCHAR2 (255);
    l_mail_treasury                 VARCHAR2 (255);
    l_mail_fina_it                  VARCHAR2 (255);
    l_mail_asset_eval               VARCHAR2 (255);
    l_mail_it_middleware            VARCHAR2 (255);
    l_mail_reporting_team           VARCHAR2 (255);
    l_mail_afp                      VARCHAR2 (255);
    l_mail_oprisk                   VARCHAR2 (255);
    l_mail_msg_trd_1_2              VARCHAR2 (255);
    l_mail_msg_trd_3_4              VARCHAR2 (255);
    l_mail_mobile                   VARCHAR2 (255);
    l_teams                         VARCHAR2 (255);
    l_mail_tax_compliance           VARCHAR2 (255);
    l_mail_cbs_transac              VARCHAR2 (255);
    l_mail_secdb                    VARCHAR2 (255);
    l_mail_client_reporting         VARCHAR2 (255);
    l_mail_multiline                VARCHAR2 (255);
    l_mail_dba                      VARCHAR2 (255);
    l_mail_cbs_finance              VARCHAR2 (255);
    l_mail_fmcs                     VARCHAR2 (255);
    l_mail_treasury_sttl            VARCHAR2 (255);
    l_mail_fund_sttl                VARCHAR2 (255);
    l_mail_fmcs_treasury            VARCHAR2 (255);
    l_mail_awp                      VARCHAR2 (255);
    l_mail_desk_multiasset          VARCHAR2 (255);
    l_mail_support_trading          VARCHAR2 (255);
    l_warning_for                   VARCHAR2 (255);
    l_desk                          VARCHAR2 (255);
    l_netw                          NUMBER;
    l_offset                        NUMBER;
    l_ammount                       NUMBER;
    l_connection                    UTL_SMTP.connection;
    l_idx                           NUMBER;
    l_cnt_loop                      NUMBER;
    l_nr                            NUMBER;
    l_nr_bl                         NUMBER;
    l_nr2                           NUMBER;
    l_nr3                           NUMBER;
    l_nr4                           NUMBER;
    l_nr5                           NUMBER;
    l_nr_bond                       NUMBER;
    l_nr_fund                       NUMBER;
    l_nr_fund_bllu                  NUMBER;
    l_nr_equities                   NUMBER;
    l_nr_wait_ack                   NUMBER;
    l_nr_error                      NUMBER;
    l_nr_wait_mt509                 NUMBER;
    l_nr_wait_fix                   NUMBER;
    l_nr_wait_fx_4eyes              NUMBER;
    l_sl                            NUMBER;
    l_text                          CLOB;
    l_text2                         CLOB;
    l_text3                         CLOB;
    l_text4                         CLOB;
    l_text5                         CLOB;
    l_text_netw                     CLOB;
    l_text_meta_msg                 CLOB;
    l_text_wait_ack                 CLOB;
    l_text_error                    CLOB;
    l_text_wait_mt509               CLOB;
    l_text_wait_fix                 CLOB;
    l_date                          DATE;
    l_exp_today                     DATE;
    l_db_name                       VARCHAR2 (50);
    l_status                        VARCHAR2 (10);
    l_severity                      NUMBER;
    l_prcq_severity                 NUMBER;
    l_interval_count                NUMBER;

    g_severity_avail                NUMBER;
    g_severity_resp                 NUMBER;
    g_severity_sys                  NUMBER;
    g_severity_euro                 NUMBER;
    g_severity_asia                 NUMBER;

    g_execution_id                  VARCHAR2 (50);
    g_last_test_ts                  NUMBER;
    g_active_section                VARCHAR2 (50);
    g_active_header                 VARCHAR2 (200) := '';
    g_active_subheader              VARCHAR2 (200) := '';
    c_section_avail                 VARCHAR2 (50) := 'avail';
    c_section_resp                  VARCHAR2 (50) := 'resp';
    c_section_sys                   VARCHAR2 (50) := 'sys';
    c_section_euro                  VARCHAR2 (50) := 'euro';
    c_section_asia                  VARCHAR2 (50) := 'asia';
    c_severity_avail_ph             VARCHAR2 (50)
                                        := 'g_severity_avail_placeholder';
    c_severity_resp_ph              VARCHAR2 (50)
                                        := 'g_severity_resp_placeholder';
    c_severity_sys_ph               VARCHAR2 (50)
                                        := 'g_severity_sys_placeholder';
    c_severity_euro_ph              VARCHAR2 (50)
                                        := 'g_severity_euro_placeholder';
    c_severity_asia_ph              VARCHAR2 (50)
                                        := 'g_severity_asia_placeholder';

    l_body_html                     CLOB;
    l_html_temp                     CLOB;
    l_html_temp2                    CLOB;
    l_json_temp                     CLOB := '';
    l_time                          TIMESTAMP;
    l_timestamp                     DATE;
    l_comment                       VARCHAR2 (45) := '';
    l_t                             VARCHAR2 (30);
    l_timecheck                     VARCHAR2 (30);
    l_ref_atrx_seq_nr               NUMBER;
    l_seq_nr                        NUMBER;
    --for release 3.1 if we use the db check only for 3.3 should be changed
    l_sec_user_column               VARCHAR2 (200);
    l_count                         NUMBER;
    l_cnt_15_low_prio_stex          NUMBER;
    l_query                         VARCHAR2 (2000);
    l_sec_user_mail                 VARCHAR2 (255);
    l_sec_user_count                NUMBER := 0;
    l_obj_not_bu_count              NUMBER;
    l_obj_not_bu                    CLOB := '';
    l_execution_time                DATE;
    l_notappended                   BOOLEAN := TRUE;
    l_high_prio                     BOOLEAN := FALSE;
    l_adpt_15_mins                  DATE;
    l_adpt_1_min                    DATE;
    l_override_mail                 VARCHAR2 (1000) := '';
    l_is_override                   BOOLEAN := FALSE;
    l_condition                     BOOLEAN := FALSE;

    TYPE array_cnt_waiting IS TABLE OF NUMBER;

    TYPE array_last IS TABLE OF VARCHAR2 (200);

    TYPE array_cnt_prc_last_15 IS TABLE OF NUMBER;

    TYPE array_cnt_prio IS TABLE OF NUMBER;

    TYPE array_meta_msg2 IS TABLE OF VARCHAR2 (200);

    l_array_cnt_waiting             array_cnt_waiting := array_cnt_waiting ();
    l_array_last                    array_last := array_last ();
    l_array_cnt_prc_last_15         array_cnt_prc_last_15
                                        := array_cnt_prc_last_15 ();
    l_array_cnt_prio                array_cnt_prio := array_cnt_prio ();
    l_array_meta_msg2               array_meta_msg2 := array_meta_msg2 ();

    l_cnt_error_msg_queue           NUMBER := 0;
    j                               NUMBER;

    ---------------------------------
    --Summary: Get current day 
    --Parameters:none
    --Author:THOADA3
    --Date:02/07/2025
    ---------------------------------
    FUNCTION get_current_day
        RETURN DATE
    IS
    BEGIN
        RETURN lookup_ddic#.date_('today');
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN TRUNC (SYSDATE);
    END get_current_day;

    ---------------------------------
    --Summary: Get yesterdays date or last fridays date if current weekday is monday, does not consider holidays
    --Parameters:none
    --Author:CHRBEC
    --Date:21/01/2014
    ---------------------------------
    FUNCTION get_previous_day (i_days_in_past NUMBER:= 1)
        RETURN DATE
    IS
    BEGIN
        RETURN lookup_ddic#.date_ ('today -' || i_days_in_past || 'v');
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN TRUNC (SYSDATE - 1);
    END get_previous_day;

    ---------------------------------
    --Summary:
    --Parameters:none
    --Author:NICMAL2
    --Date:04/05/2020
    ---------------------------------
    FUNCTION get_previous_day_b (i_days_in_past NUMBER:= 1)
        RETURN DATE
    IS
    BEGIN
        RETURN lookup_ddic#.date_ ('today -' || i_days_in_past || 'b');
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN TRUNC (SYSDATE - 1);
    END get_previous_day_b;

    ---------------------------------
    -- Check if day given in parameter is day off or not, depending of the country
    --Parameters:none
    --Author:NICMAL2
    --Date:11/09/2014
    ---------------------------------
    FUNCTION is_day_off (i_country_id NUMBER, i_date DATE)
        RETURN BOOLEAN
    IS
        l_day_off   NUMBER;
    BEGIN
        SELECT COUNT (*)
          INTO l_day_off
          FROM country_day_off
         WHERE country_id = i_country_id AND day = TRUNC (i_date);

        IF l_day_off > 0
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN FALSE;
    END is_day_off;

    ---------------------------------
    --Summary:Check if a given date is a holiday for a given business unit - ignoring the is_bank_day status
    --Parameters:date and bu to check
    --Author:CHRBEC
    --Date:09/04/2014
    ---------------------------------
    FUNCTION is_holiday (i_date DATE, i_bu NUMBER)
        RETURN BOOLEAN
    IS
        l_cnt      NUMBER;
        l_result   BOOLEAN;
    BEGIN
        SELECT COUNT (*)
          INTO l_cnt
          FROM country_day_off d, obj_bp_bu bu, obj_bp bp
         WHERE     bu.obj_id = bp.obj_id
               AND d.country_id = bp.country_domi_id
               AND day = i_date
               AND bu.obj_id = i_bu;

        IF l_cnt > 0
        THEN
            l_result := TRUE;
        ELSE
            l_result := FALSE;
        END IF;

        RETURN l_result;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN TRUE;
    END is_holiday;


    ---------------------------------
    --Summary:Check if a given date is a bank day off (25/12 or 01/01)
    --Parameters:date to check
    --Author:CHRBEC
    --Date:11/02/2015
    ---------------------------------
    FUNCTION is_bank_day_off (i_date DATE)
        RETURN BOOLEAN
    IS
        l_cnt      NUMBER;
        l_result   BOOLEAN;
    BEGIN
        SELECT COUNT (*)
          INTO l_cnt
          FROM country_day_off
         WHERE     country_id = 2015
               AND day = TRUNC (i_date)
               AND is_bank_day IS NULL;

        IF l_cnt > 0
        THEN
            l_result := TRUE;
        ELSE
            l_result := FALSE;
        END IF;

        RETURN l_result;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN FALSE;
    END is_bank_day_off;


    ---------------------------------
    --Summary: Get the date of the next value date - skip weekends and holidays
    --Parameters:none
    --Author:CHRBEC
    --Date:10/03/2014
    ---------------------------------
    FUNCTION get_next_day
        RETURN DATE
    IS
    BEGIN
        RETURN lookup_ddic#.date_ ('today +1v');
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN TRUNC (SYSDATE + 1);
    END get_next_day;

    -------------------------------------------------------------------------------
    --function: get the user that performed the last action on the order passed in parameter.
    --         returns null if no real user is found.
    -------------------------------------------------------------------------------
    FUNCTION getMailOfUserWhoMadeLastAction (p_doc_id NUMBER)
        RETURN VARCHAR2
    IS
        l_ora_user   VARCHAR2 (10);
    BEGIN
        SELECT (SELECT oracle_user
                  FROM k.sec_user
                 WHERE id = sec_user_id)    ora_user
          INTO l_ora_user
          FROM k.trans
         WHERE (seq_nr, doc_id) IN
                   (  SELECT MAX (t.seq_nr), t.doc_id
                        FROM k.trans t, k.sec_user s
                       WHERE     t.doc_id = p_doc_id
                             AND t.sec_user_id = s.id
                             AND s.user_type_id = 1
                    GROUP BY t.doc_id);

        IF l_ora_user NOT LIKE '%SGP'
        THEN
            IF is_prod
            THEN
                RETURN l_ora_user || '@blu.bank';
            ELSE
                RETURN 'relman@blu.bank';
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN TOO_MANY_ROWS
        THEN
            RETURN NULL;
        WHEN NO_DATA_FOUND
        THEN
            RETURN NULL;
    END getMailOfUserWhoMadeLastAction;

    -------------------------------------------------------------------------------
    --function: get the BU name corresponding the id passed in parameter
    -------------------------------------------------------------------------------
    FUNCTION getBuName (i_bu_id NUMBER)
        RETURN VARCHAR2
    IS
        l_bu   VARCHAR2 (10);
    BEGIN
        SELECT key_val
          INTO l_bu
          FROM obj_bp_bu obp, obj_rel_key ork
         WHERE     ork.obj_id = obp.obj_id
               AND (obj_key_id = 7032 OR obp.obj_id = -1)
               AND obp.obj_id = i_bu_id;

        RETURN l_bu;
    END getBuName;


    -------------------------------------------------------------------------------
    --function: get the bu_id for a given order id
    -------------------------------------------------------------------------------
    FUNCTION getOrderBu (i_order_id NUMBER)
        RETURN NUMBER
    IS
        l_bu_id   NUMBER;
    BEGIN
        SELECT bp_imed_id
          INTO l_bu_id
          FROM doc
         WHERE id = i_order_id;

        RETURN l_bu_id;
    END getOrderBu;

    -------------------------------------------------------------------------------
    --function. append mailing recipients for a given team and a given bu list
    -------------------------------------------------------------------------------
    FUNCTION appendMails (i_mail_string   VARCHAR2,
                          i_bu_list       tNumberList,
                          i_team          VARCHAR2)
        RETURN VARCHAR2
    IS
        l_has_bllu      BOOLEAN := FALSE;
        l_has_blbe      BOOLEAN := FALSE;
        l_has_btlu      BOOLEAN := FALSE;
        l_has_btbe      BOOLEAN := FALSE;
        l_has_cisg      BOOLEAN := FALSE;
        l_bu_id         NUMBER;
        l_mail_string   VARCHAR2 (2000);
    BEGIN
        l_mail_string := i_mail_string;

        --loop through list
        FOR idx IN 1 .. i_bu_list.COUNT
        LOOP
            l_bu_id := i_bu_list (idx);

            IF l_bu_id = 3
            THEN
                l_has_bllu := TRUE;
            ELSIF l_bu_id = 7
            THEN
                l_has_blbe := TRUE;
            ELSIF l_bu_id = 10
            THEN
                l_has_btbe := TRUE;
            ELSIF l_bu_id = 11
            THEN
                l_has_btlu := TRUE;
            ELSIF l_bu_id = 8
            THEN
                l_has_cisg := TRUE;
            END IF;
        END LOOP;


        --add mails according to concerned team
        CASE i_team
            WHEN 'STEX'
            THEN
                IF     (l_has_bllu OR l_has_blbe)
                   AND NOT is_holiday (TRUNC (SYSDATE), 3)
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_stex;
                END IF;

                IF l_has_btbe
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_btbe_dflt;
                END IF;

                IF l_has_btlu
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_btlu_dflt;
                END IF;

                IF l_has_cisg
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_cisg_dflt;
                END IF;
            WHEN 'STEX_BOND'
            THEN
                IF l_has_bllu OR l_has_blbe
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_stex_bond;
                END IF;

                IF l_has_btbe
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_btbe_dflt;
                END IF;

                IF l_has_btlu
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_btlu_dflt;
                END IF;

                IF l_has_cisg
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_cisg_dflt;
                END IF;
            WHEN 'STEX_FUND_MARKET'
            THEN
                IF l_has_blbe
                THEN
                    l_mail_string :=
                        l_mail_string || ';' || l_mail_stex_fund_blbe;
                END IF;

                IF l_has_btbe
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_btbe_dflt;
                END IF;

                IF l_has_btlu
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_btlu_dflt;
                END IF;

                IF l_has_cisg
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_cisg_dflt;
                END IF;
            WHEN 'STEX_FUND'
            THEN
                IF l_has_blbe
                THEN
                    l_mail_string :=
                        l_mail_string || ';' || l_mail_stex_fund_blbe;
                END IF;

                IF l_has_btbe
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_btbe_dflt;
                END IF;

                IF l_has_btlu
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_btlu_dflt;
                END IF;

                IF l_has_cisg
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_cisg_dflt;
                END IF;
            WHEN 'STEX_FUND_MARKET_BLLU'
            THEN
                IF NOT is_holiday (TRUNC (SYSDATE), 3)
                THEN
                    l_mail_string :=
                        l_mail_string || ';' || l_mail_stex_fund_market;
                END IF;
            WHEN 'STEX_FUND_BLLU'
            THEN
                IF NOT is_holiday (TRUNC (SYSDATE), 3)
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_stex_fund;
                END IF;
            WHEN 'PAY_WFP'
            THEN
                IF l_has_bllu OR l_has_blbe
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_pay_wfp;
                END IF;

                IF l_has_btbe
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_btbe_dflt;
                END IF;

                IF l_has_btlu
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_btlu_dflt;
                END IF;

                IF l_has_cisg
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_cisg_dflt;
                END IF;
            WHEN 'SETTLE_ON_HOLD'
            THEN
                IF l_has_bllu OR l_has_blbe
                THEN
                    l_mail_string :=
                        l_mail_string || ';' || l_mail_settle_on_hold;
                END IF;

                IF l_has_btbe
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_btbe_dflt;
                END IF;

                IF l_has_btlu
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_btlu_dflt;
                END IF;

                IF l_has_cisg
                THEN
                    l_mail_string := l_mail_string || ';' || l_mail_cisg_dflt;
                END IF;
        END CASE;


        RETURN l_mail_string;
    END appendMails;

    -------------------------------------------------------------------------------
    --function: get mail by team and bu
    -------------------------------------------------------------------------------
    FUNCTION getMailByBu (i_team VARCHAR, i_bu_id NUMBER)
        RETURN VARCHAR2
    IS
        l_mail   VARCHAR2 (200);
    BEGIN
        --SETTLE TEAM
        IF (i_bu_id = 10)
        THEN
            CASE i_team
                WHEN 'CUSTSETTLE'
                THEN
                    l_mail := l_mail_prcq_settle_btbe;
                WHEN 'SETTLE'
                THEN
                    l_mail := l_mail_prcq_settle_btbe;
                WHEN 'STEX'
                THEN
                    l_mail := l_mail_prcq_stex_btbe;
                WHEN 'SECEVT'
                THEN
                    l_mail := l_mail_prcq_secevt;
                WHEN 'PAY'
                THEN
                    l_mail := l_mail_pay_BTB;
                WHEN 'INCOME'
                THEN
                    l_mail := l_mail_prcq_secevt_inprc;
                WHEN 'CORPORATE'
                THEN
                    l_mail := l_mail_prcq_secevt_corpac;
                WHEN 'CUST'
                THEN
                    l_mail := l_mail_prcq_cust;
                WHEN 'MARKET'
                THEN
                    l_mail := l_mail_prcq_fx;
                WHEN 'CUSTDB'
                THEN
                    l_mail := l_mail_prcq_prop;
            END CASE;
        ELSIF (i_bu_id = 11)
        THEN
            CASE i_team
                WHEN 'SECEVT'
                THEN
                    l_mail := l_mail_prcq_secevt;
                WHEN 'PAY'
                THEN
                    l_mail := l_mail_pay_BTL;
                WHEN 'INCOME'
                THEN
                    l_mail := l_mail_prcq_secevt_inprc;
                WHEN 'CORPORATE'
                THEN
                    l_mail := l_mail_prcq_secevt_corpac;
                WHEN 'CUST'
                THEN
                    l_mail := l_mail_prcq_cust;
                WHEN 'MARKET'
                THEN
                    l_mail := l_mail_prcq_fx;
                WHEN 'CUSTDB'
                THEN
                    l_mail := l_mail_prcq_prop;
                ELSE
                    l_mail := l_mail_prcq_all_btlu;
            END CASE;
        ELSIF (i_bu_id = 8)
        THEN
            l_mail := l_mail_cisg_prcq_all;
        ELSIF (i_bu_id = 15)
        THEN
            l_mail := l_mail_btgb_dflt;
        ELSE
            CASE i_team
                WHEN 'CUSTSETTLE'
                THEN
                    l_mail := l_mail_prcq_cust;
                WHEN 'SETTLE'
                THEN
                    l_mail := l_mail_prcq_settle_lu;
                WHEN 'STEX'
                THEN
                    l_mail := l_mail_prcq_stex_lu;
                WHEN 'SECEVT'
                THEN
                    l_mail := l_mail_prcq_secevt;
                WHEN 'PAY'
                THEN
                    l_mail := l_mail_pay_dflt;
                WHEN 'INCOME'
                THEN
                    l_mail := l_mail_prcq_secevt_inprc;
                WHEN 'CORPORATE'
                THEN
                    l_mail := l_mail_prcq_secevt_corpac;
                WHEN 'CUST'
                THEN
                    l_mail := l_mail_prcq_cust;
                WHEN 'MARKET'
                THEN
                    l_mail := l_mail_prcq_fx;
                WHEN 'CUSTDB'
                THEN
                    l_mail := l_mail_prcq_prop;
            END CASE;
        END IF;

        RETURN l_mail;
    END getMailByBu;

    -------------------------------------------------------------------------------
    --function: get the MetaTyp name corresponding the id passed in parameter
    --         returns null if no corresponding meta_typ is found.
    -------------------------------------------------------------------------------
    FUNCTION getMetaTypName (meta_type_id NUMBER)
        RETURN VARCHAR2
    IS
        l_meta_type   VARCHAR2 (40);
    BEGIN
        SELECT intl_id
          INTO l_meta_type
          FROM k.meta_typ
         WHERE id = meta_type_id;

        RETURN l_meta_type;
    EXCEPTION
        WHEN TOO_MANY_ROWS
        THEN
            RETURN NULL;
        WHEN NO_DATA_FOUND
        THEN
            RETURN NULL;
    END getMetaTypName;

    -------------------------------------------------------------------------------
    --function: get the MetaMsg name corresponding the id passed in parameter
    --         returns null if no corresponding msg_status is found.
    -------------------------------------------------------------------------------
    FUNCTION getMsgStatusName (msg_status_id NUMBER)
        RETURN VARCHAR2
    IS
        l_msg_status   VARCHAR2 (40);
    BEGIN
        SELECT intl_id
          INTO l_msg_status
          FROM k.code_msg_status
         WHERE id = msg_status_id;

        RETURN l_msg_status;
    EXCEPTION
        WHEN TOO_MANY_ROWS
        THEN
            RETURN NULL;
        WHEN NO_DATA_FOUND
        THEN
            RETURN NULL;
    END getMsgStatusName;



    FUNCTION setDesk (i_desk          VARCHAR2,
                      i_text_desk     CLOB,
                      i_order_bu_id   NUMBER:= 3)
        RETURN CLOB
    IS
        l_res   CLOB;
    BEGIN
        --if BDL is not concerned - no desk information
        IF i_order_bu_id IN (3, 7)
        THEN
            IF     UPPER (i_desk) = UPPER ('equities')
               AND (   INSTR (i_text_desk, 'Equities') = 0
                    OR i_text_desk IS NULL)
            THEN
                IF (i_text_desk IS NULL)
                THEN
                    l_res := i_text_desk || '- Equities Desk: ';
                ELSE
                    l_res := i_text_desk || ' <br/>- Equities Desk: ';
                END IF;
            ELSIF     UPPER (i_desk) = UPPER ('Funds')
                  AND (   INSTR (i_text_desk, 'Funds') = 0
                       OR i_text_desk IS NULL)
                  AND i_order_bu_id = 3
            THEN
                IF (i_text_desk IS NULL)
                THEN
                    l_res := i_text_desk || '- Fund Desk: ';
                ELSE
                    l_res := i_text_desk || ' <br/>- Fund Desk: ';
                END IF;
            ELSIF     UPPER (i_desk) = UPPER ('bond')
                  AND (   INSTR (i_text_desk, 'Bonds') = 0
                       OR i_text_desk IS NULL)
            THEN
                IF (i_text_desk IS NULL)
                THEN
                    l_res := i_text_desk || '- Bond Desk: ';
                ELSE
                    l_res := i_text_desk || ' <br/>- Bond Desk: ';
                END IF;
            ELSE
                IF i_text_desk IS NOT NULL
                THEN
                    l_res := i_text_desk || ',';
                ELSE
                    l_res := i_text_desk;
                END IF;
            END IF;
        ELSE
            IF i_text_desk IS NOT NULL
            THEN
                l_res := i_text_desk || ' <br/>';
            ELSE
                l_res := i_text_desk;
            END IF;
        END IF;

        RETURN l_res;
    END setDesk;

    -------------------------------------------------------------------------------
    --function: get the list with append delimiter and text in param if not already in the list
    -------------------------------------------------------------------------------
    FUNCTION upsert_mails (origin_list      VARCHAR2,
                           delimiter        VARCHAR2,
                           text_to_append   VARCHAR2)
        RETURN VARCHAR2
    IS
    BEGIN
        IF     (text_to_append IS NOT NULL)
           AND (   (INSTR (origin_list, text_to_append) = 0)
                OR (INSTR (origin_list, text_to_append) IS NULL))
        THEN
            IF (origin_list IS NULL) OR (origin_list = '')
            THEN
                RETURN text_to_append;
            ELSE
                RETURN origin_list || delimiter || text_to_append;
            END IF;
        ELSE
            RETURN origin_list;
        END IF;
    END upsert_mails;



    FUNCTION remove_mail(i_email_list VARCHAR2, i_email VARCHAR2)
                 RETURN VARCHAR2
             IS
                 l_email_list VARCHAR2(4000);
                l_email VARCHAR2(4000);
                l_result VARCHAR2(4000);
                l_pos INTEGER;
                l_start INTEGER := 1;
    BEGIN
             l_email_list:= i_email_list;
             if substr(i_email_list, -1) != ';' then
                l_email_list := i_email_list || ';';
            end if;
            loop
                l_pos := instr(l_email_list,';',l_Start);
                exit when l_pos = 0;

                l_email := trim(substr(l_email_list, l_start,l_pos-l_start));
                if lower(l_email) != lower(trim(i_email)) then
                   if l_result is not null then
                        l_result := l_result || ';';
                    end if;
                    l_result := l_result || l_email;
                end if;

                l_start := l_pos + 1;
            end loop;
            return l_result;
    END remove_mail;

    -------------------------------------------------------------------------------
    --procedure: append varchar2 au clob html
    -------------------------------------------------------------------------------
    PROCEDURE html_append (i_html VARCHAR2)
    IS
    BEGIN
        l_html_temp := l_html_temp || i_html;
    END html_append;

    -------------------------------------------------------------------------------
    --procedure: append varchar2 au clob html
    -------------------------------------------------------------------------------
    PROCEDURE json_append (i_json VARCHAR2)
    IS
    BEGIN
        -- l_json_temp := l_json_temp || i_json || chr(10);
        l_json_temp := l_json_temp || i_json || CHR (10);
    END json_append;

    -------------------------------------------------------------------------------
    --function: generate HTML sub header (varchar2)  with text param
    -------------------------------------------------------------------------------
    PROCEDURE write_subheader (i_hdr VARCHAR2)
    IS
    BEGIN
        g_active_subheader := i_hdr;

        html_append (
               '<tr height=13 style=''height:9.75pt''>
        <td height=13 colspan=5 class=xl74 style=''height:9.75pt;mso-ignore:colspan''></td>
        <tr height=13 style=''mso-height-source:userset;height:9.75pt''>
        <td height=13 class=xl74 style=''height:9.75pt''></td>
        <td class=xl75>'
            || i_hdr
            || '</td>
        <td colspan=3 class=xl76 style=''mso-ignore:colspan''></td>
        <td colspan=3 class=xl76 style=''mso-ignore:colspan''></td>
     </tr>');
    END write_subheader;


    -------------------------------------------------------------------------------
    --function: generate HTML header (varchar2)  with text param
    -------------------------------------------------------------------------------
    PROCEDURE write_header (i_hdr VARCHAR2, i_hdr_severity_var VARCHAR2)
    IS
    BEGIN
        g_active_header := i_hdr;
        g_active_subheader := '';

        html_append (
               '<tr height=13 style=''height:9.75pt''>
          <td height=13 colspan=5 class=xl74 style=''height:9.75pt;mso-ignore:colspan''></td>
            </tr>
            <tr height=13 style=''mso-height-source:userset;height:9.75pt''>
            <td height=13 class=xl72 width=67 style=''width:50pt''></td>
          <td class=xl72 width=67 style=''height:9.75pt;width:50pt''>'
            || i_hdr
            || ' - '
            || i_hdr_severity_var
            || '</td>
          <td class=xl72 width=67 style=''width:50pt''></td>
          <td class=xl72 width=67 style=''width:50pt''></td>
          <td class=xl72 width=67 style=''width:50pt''></td>
          <td class=xl72 width=67 style=''width:50pt''></td>
          <td class=xl72 width=67 style=''width:50pt''></td>
         </tr> ');
    END write_header;

    -------------------------------------------------------------------------------
    --function: retourne le temps entre 2 timestamp sous la forme
    -- x days, x hours, x minutes and x seconds
    -------------------------------------------------------------------------------
    FUNCTION timestamp_diff (start_time_in   TIMESTAMP,
                             end_time_in     TIMESTAMP,
                             long_display    BOOLEAN:= TRUE)
        RETURN VARCHAR2
    IS
        l_days           NUMBER;
        l_hours          NUMBER;
        l_minutes        NUMBER;
        l_seconds        NUMBER;
        l_milliseconds   NUMBER;
    BEGIN
        SELECT EXTRACT (DAY FROM end_time_in - start_time_in),
               EXTRACT (HOUR FROM end_time_in - start_time_in),
               EXTRACT (MINUTE FROM end_time_in - start_time_in),
               EXTRACT (SECOND FROM end_time_in - start_time_in)
          INTO l_days,
               l_hours,
               l_minutes,
               l_seconds
          FROM DUAL;

        IF long_display
        THEN
            IF (l_days != 0)
            THEN
                RETURN    l_days
                       || ' days, '
                       || l_hours
                       || ' hours, '
                       || l_minutes
                       || ' minutes and '
                       || FLOOR (l_seconds)
                       || ' seconds';
            ELSIF (l_hours != 0)
            THEN
                RETURN    l_hours
                       || ' hours, '
                       || l_minutes
                       || ' minutes and '
                       || FLOOR (l_seconds)
                       || ' seconds';
            ELSE
                RETURN    l_minutes
                       || ' minutes and '
                       || FLOOR (l_seconds)
                       || ' seconds';
            END IF;
        ELSE
            IF (l_days != 0)
            THEN
                RETURN    l_days
                       || ' d '
                       || l_hours
                       || ' h '
                       || l_minutes
                       || ' min '
                       || FLOOR (l_seconds)
                       || ' sec';
            ELSIF (l_hours != 0)
            THEN
                RETURN    l_hours
                       || ' h '
                       || l_minutes
                       || ' min '
                       || FLOOR (l_seconds)
                       || ' sec';
            ELSE
                RETURN l_minutes || ' min ' || FLOOR (l_seconds) || ' sec';
            END IF;
        END IF;
    END;

    -------------------------------------------------------------------------------
    --function: eval result against the expected value given the eval_type provided ; returns c_ok or c_nok
    -------------------------------------------------------------------------------
    FUNCTION eval_check_result (i_result      VARCHAR2,
                                i_expected    VARCHAR2,
                                i_severity    NUMBER,
                                i_eval_type   VARCHAR2:= '=')
        RETURN VARCHAR2
    IS
        l_return   VARCHAR2 (50) := '0';
    BEGIN
        IF i_eval_type = '='
        THEN
            IF i_result = i_expected
            THEN
                RETURN c_ok;
            END IF;
        ELSIF i_eval_type = '>='
        THEN
            IF TO_NUMBER (i_result) >= TO_NUMBER (i_expected)
            THEN
                RETURN c_ok;
            END IF;
        ELSIF i_eval_type = '<='
        THEN
            IF TO_NUMBER (i_result) <= TO_NUMBER (i_expected)
            THEN
                RETURN c_ok;
            END IF;
        ELSIF i_eval_type = '<'
        THEN
            IF TO_NUMBER (i_result) < TO_NUMBER (i_expected)
            THEN
                RETURN c_ok;
            END IF;
        ELSIF i_eval_type = '>'
        THEN
            IF i_result > i_expected
            THEN
                RETURN c_ok;
            END IF;
        ELSIF i_eval_type = 'in'
        THEN
            IF TO_NUMBER (i_result) BETWEEN TO_NUMBER (
                                                SUBSTR (
                                                    i_expected,
                                                      INSTR (i_expected, '[')
                                                    + 1,
                                                      INSTR (i_expected, ';')
                                                    - INSTR (i_expected, '[')
                                                    - 1))
                                        AND TO_NUMBER (
                                                SUBSTR (
                                                    i_expected,
                                                      INSTR (i_expected, ';')
                                                    + 1,
                                                      INSTR (i_expected, ']')
                                                    - INSTR (i_expected, ';')
                                                    - 1))
            THEN
                RETURN c_ok;
            END IF;
        ELSIF i_eval_type = '!='
        THEN
            IF i_result != i_expected
            THEN
                RETURN c_ok;
            END IF;
        END IF;

        IF l_return = '0'
        THEN
            RETURN c_nok;
        END IF;
    END eval_check_result;

    -------------------------------------------------------------------------------
    --procedure: updates global severity variable, which stored the highest severity found for checks that failed
    -------------------------------------------------------------------------------
    PROCEDURE update_global_severity (i_severity NUMBER)
    IS
    BEGIN
        IF l_severity < i_severity
        THEN
            l_severity := i_severity;
        END IF;
    END update_global_severity;

    -------------------------------------------------------------------------------
    --procedure: updates severity for current section ; retin the highest severity found for checks that failed
    -------------------------------------------------------------------------------
    PROCEDURE update_section_severity (i_severity NUMBER)
    IS
    BEGIN
        --contribute to section severity level
        CASE g_active_section
            WHEN c_section_avail
            THEN
                IF g_severity_avail < i_severity
                THEN
                    g_severity_avail := i_severity;
                END IF;
            WHEN c_section_resp
            THEN
                IF g_severity_resp < i_severity
                THEN
                    g_severity_resp := i_severity;
                END IF;
            WHEN c_section_sys
            THEN
                IF g_severity_sys < i_severity
                THEN
                    g_severity_sys := i_severity;
                END IF;
            WHEN c_section_euro
            THEN
                IF g_severity_euro < i_severity
                THEN
                    g_severity_euro := i_severity;
                END IF;
            WHEN c_section_asia
            THEN
                IF g_severity_asia < i_severity
                THEN
                    g_severity_asia := i_severity;
                END IF;
            ELSE
                NULL;
        END CASE;
    END update_section_severity;


    -------------------------------------------------------------------------------
    --procedure: writes a check result in HTML in the mail's body
    -------------------------------------------------------------------------------
    PROCEDURE write_query_html (i_check          VARCHAR2,
                                i_check_result   VARCHAR2,
                                i_result         VARCHAR2,
                                i_expected       VARCHAR2,
                                i_severity       NUMBER,
                                i_eval_type      VARCHAR2,
                                i_doc_link       VARCHAR2,
                                l_start_ts       NUMBER,
                                l_end_ts         NUMBER,
                                l_duration_ms    NUMBER)
    IS
        l_sev_str         VARCHAR2 (50) := c_none;
        l_color           VARCHAR2 (50) := 'xl77';
        l_documentation   VARCHAR2 (3000) := '';
        l_result_str      VARCHAR2 (3000) := '';
    BEGIN
        CASE i_severity
            WHEN c_none_p
            THEN
                l_sev_str := c_none;
                l_color := 'xl77';
            WHEN c_major_p
            THEN
                l_sev_str := c_major;
                l_color := 'xl79';
            WHEN c_blocking_p
            THEN
                l_sev_str := c_blocking;
                l_color := 'xl80';
            WHEN c_sys_blocking_p
            THEN
                l_sev_str := c_sys_blocking;
                l_color := 'xl78';
            ELSE
                l_sev_str := c_none;
                l_color := 'xl77';
        END CASE;

        IF i_check_result = c_nok
        THEN
            l_result_str :=
                '<td class=' || l_color || '>' || c_nok || '</td>';

            IF i_severity != c_none_p
            THEN
                l_status := c_nok;
            END IF;

            IF i_doc_link != 'none'
            THEN
                l_documentation :=
                       '<a href="'
                    || c_documentation_path
                    || i_doc_link
                    || '.html">Documentation<a/>';
            END IF;
        ELSE
            l_result_str := '<td class=xl77>' || c_ok || '</td>';
        END IF;

        html_append (
               '<tr height=13 style=''mso-height-source:userset;height:9.75pt''>
                                    <td height=13 class=xl74 style=''height:9.75pt''></td>
                                    <td class=xl74>'
            || i_check
            || '</td>
                                    <td class=xl74>'
            || i_result
            || '</td>
                                    '
            || l_result_str
            || '
                                    <td class=xl74><center>'
            || l_sev_str
            || '</center></td>
                                    <td class=xl74>('
            || i_eval_type
            || ' '
            || i_expected
            || ')</td>
                                    <td class=xl74>'
            || l_documentation
            || '</td>
                                    <td class=xl74>'
            || timestamp_diff (l_time, SYSTIMESTAMP, FALSE)
            || '</td> ');
    END write_query_html;


    -------------------------------------------------------------------------------
    --function: return current timestamp as a number with millisecond precision
    -------------------------------------------------------------------------------
    FUNCTION current_timestamp_ms
        RETURN NUMBER
    IS
        out_result   NUMBER;
    BEGIN
        SELECT     EXTRACT (
                       DAY FROM (  SYS_EXTRACT_UTC (LOCALTIMESTAMP)
                                 - TO_TIMESTAMP ('1970-01-01', 'YYYY-MM-DD')))
                 * 86400000
               + TO_NUMBER (
                     TO_CHAR (SYS_EXTRACT_UTC (LOCALTIMESTAMP), 'SSSSSFF3'))
          INTO out_result
          FROM DUAL;

        RETURN out_result;
    END current_timestamp_ms;


    -------------------------------------------------------------------------------
    --procedure: writes a check result in JSON output
    -------------------------------------------------------------------------------
    PROCEDURE write_query_json (i_check          VARCHAR2,
                                i_check_result   VARCHAR2,
                                i_check_name     VARCHAR2,
                                i_result         VARCHAR2,
                                i_expected       VARCHAR2,
                                i_severity       NUMBER,
                                i_eval_type      VARCHAR2,
                                i_doc_link       VARCHAR2,
                                l_start_ts       NUMBER,
                                l_end_ts         NUMBER,
                                l_duration_ms    NUMBER)
    IS
        l_temp      VARCHAR2 (2000);
        l_sev_str   VARCHAR2 (50);
    BEGIN
        l_temp := '{"@timestamp":"' || l_end_ts || '"';
        l_temp :=
            l_temp || ', "service.name":"' || 'avaloq-db-monitoring' || '"';

        IF is_prod
        THEN
            l_temp := l_temp || ', "service.environment":"PRD"';
        ELSIF is_pre
        THEN
            l_temp := l_temp || ', "service.environment":"PRE"';
        ELSIF l_db_name LIKE '%AVAINT%'
        THEN
            l_temp := l_temp || ', "service.environment":"INT"';
        ELSE
            l_temp := l_temp || ', "service.environment":"DEV"';
        END IF;

        l_temp := l_temp || ', "event.action":"db-monitoring-test"';
        l_temp := l_temp || ', "event.kind":"state"';
        l_temp := l_temp || ', "event.start":' || l_start_ts;
        l_temp := l_temp || ', "event.end":' || l_end_ts;
        l_temp := l_temp || ', "event.duration":' || l_duration_ms * 1000000; -- in nanoseconds
        l_temp := l_temp || ', "event.severity":' || i_severity;

        CASE i_severity
            WHEN c_none_p
            THEN
                l_sev_str := c_none;
            WHEN c_major_p
            THEN
                l_sev_str := c_major;
            WHEN c_blocking_p
            THEN
                l_sev_str := c_blocking;
            WHEN c_sys_blocking_p
            THEN
                l_sev_str := c_sys_blocking;
            ELSE
                l_sev_str := c_none;
        END CASE;

        --dbms_output.put_line('sebp.products.avaloq_db_monitoring.severity_text : ' || l_sev_str);


        l_temp :=
               l_temp
            || ', "sebp.products.avaloq_db_monitoring.severity_text":'
            || '"'
            || l_sev_str
            || '"';


        IF i_check_result = 'OK'
        THEN
            l_temp := l_temp || ', "event.outcome":"success"';
        ELSIF i_check_result = 'NOK'
        THEN
            l_temp := l_temp || ', "event.outcome":"failure"';
        ELSE
            l_temp := l_temp || ', "event.outcome":"unknown"';
        END IF;

        /*
        if i_doc_link != 'none' then
            -- TODO escape backslash (and double quotes)
            l_temp := l_temp || ', "event.reference":"' || c_documentation_path || i_doc_link || '.html"';
        end if;
        */

        l_temp :=
               l_temp
            || ', "sebp.products.avaloq_db_monitoring.run_id": "'
            || g_execution_id
            || '"';
        l_temp :=
               l_temp
            || ', "sebp.products.avaloq_db_monitoring.test_name":"'
            || i_check
            || '"';
        l_temp :=
               l_temp
            || ', "sebp.products.avaloq_db_monitoring.section":"'
            || g_active_section
            || '"';
        l_temp :=
               l_temp
            || ', "sebp.products.avaloq_db_monitoring.header":"'
            || g_active_header
            || '"';
        l_temp :=
               l_temp
            || ', "sebp.products.avaloq_db_monitoring.sub_header":"'
            || g_active_subheader
            || '"';
        l_temp :=
               l_temp
            || ', "sebp.products.avaloq_db_monitoring.returned_value":"'
            || i_result
            || '"';
        l_temp :=
               l_temp
            || ', "sebp.products.avaloq_db_monitoring.expected_value":"'
            || i_expected
            || '"';
        l_temp :=
               l_temp
            || ', "sebp.products.avaloq_db_monitoring.eval_type":"'
            || i_eval_type
            || '"';
        l_temp :=
               l_temp
            || ', "sebp.products.avaloq_db_monitoring.database":"'
            || l_db_name
            || '"';
        l_temp :=
               l_temp
            || ', "sebp.products.avaloq_db_monitoring.uc4_job_id":"'
            || '12345678'
            || '"';
        l_temp :=
               l_temp
            || ', "data_stream.dataset":"'
            ||  'avaloq_db_monitoring'
            || '"';

         l_temp :=
               l_temp
            || ', "sebp.products.avaloq_db_monitoring.check_name":"'
            || i_check_name
            || '"';

        l_temp := l_temp || '}';
        json_append (l_temp);
    END write_query_json;

    -------------------------------------------------------------------------------
    --procedure: compute and write a check result in outputs (mail/html and JSON)
    --    i_check :        check description
    --    i_result :        value to evaluate
    --    i_expected :     expected value
    --    i_severity :    importance of the check
    --    i_mail :         mail for link to generate email
    --    i_eval_type :    comparasion type between result and expected value (= by defaut)
    -------------------------------------------------------------------------------
    PROCEDURE write_query (i_check       VARCHAR2,
                           i_result      VARCHAR2,
                           i_expected    VARCHAR2,
                           i_severity    NUMBER,
                           i_eval_type   VARCHAR2:= '=',
                           i_doc_link    VARCHAR2:= 'default')
    IS
        l_check_result    VARCHAR2 (50) := '0';
        l_sev_str         VARCHAR2 (50) := c_none;
        l_color           VARCHAR2 (50) := 'xl77';
        l_documentation   VARCHAR2 (3000) := '';
        l_start_ts        NUMBER;
        l_end_ts          NUMBER;
        l_duration_ms     NUMBER;
    BEGIN
        l_check_result :=
            eval_check_result (i_result,
                               i_expected,
                               i_severity,
                               i_eval_type);

        l_start_ts := g_last_test_ts;
        l_end_ts := current_timestamp_ms;
        l_duration_ms := l_end_ts - l_start_ts;

        write_query_html (i_check,
                          l_check_result,
                          i_result,
                          i_expected,
                          i_severity,
                          i_eval_type,
                          i_doc_link,
                          l_start_ts,
                          l_end_ts,
                          l_duration_ms);

        write_query_json (i_check,
                          l_check_result,
                          i_doc_link,
                          i_result,
                          i_expected,
                          i_severity,
                          i_eval_type,
                          i_doc_link,
                          l_start_ts,
                          l_end_ts,
                          l_duration_ms);

        --global severity

        --dbms_output.put_line(i_severity || ' ' || i_check);


        IF l_check_result <> c_ok
        THEN
            update_global_severity (i_severity);
            --section severity
            update_section_severity (i_severity);
        END IF;


        -- prepare for next test duration metrics
        g_last_test_ts := l_end_ts;
    END write_query;

    ---------------------------------
    --Summary: Write information message as a row in HTML table
    ---------------------------------
    FUNCTION write_msg (i_msg VARCHAR2)
        RETURN VARCHAR2
    IS
    BEGIN
        RETURN    '<tr height=13 style=''mso-height-source:userset;height:5.75pt''>
                            <td height=13 class=xl74 style=''height:5.75pt''></td>
                            <td class=xl74>'
               || i_msg
               || '</td>
                            <td class=xl74></td>
                            <td ></td>
                            <td class=xl74><center></center></td>
                            <td class=xl74></td>
                            <td class=xl74></td> ';
    END write_msg;

    ---------------------------------
    --Summary:Get number of minutes between 2 timestamps (absolute)
    --Parameters:timestamp 1 and timestamp 2
    --Author:CHRBEC
    --Date:12/03/2014
    ---------------------------------
    FUNCTION timestamp_diff_minutes (i_timestamp_1   TIMESTAMP,
                                     i_timestamp_2   TIMESTAMP)
        RETURN NUMBER
    IS
        l_min_diff   NUMBER;
    BEGIN
        SELECT   ABS (
                     (  EXTRACT (DAY FROM i_timestamp_2 - i_timestamp_1)
                      * 24
                      * 60))
               + ABS (
                     (EXTRACT (HOUR FROM i_timestamp_2 - i_timestamp_1) * 60))
               + ABS ((EXTRACT (MINUTE FROM i_timestamp_2 - i_timestamp_1)))
          INTO l_min_diff
          FROM DUAL;

        RETURN l_min_diff;
    END timestamp_diff_minutes;

    ---------------------------------
    --Summary: return the number of seconds for a given INTERVAL
    --Parameters: interval_count is the '1' in numtodsinterval(1, 'HOUR')
    --            interval_unit is the 'HOUR' in numtodsinterval(1, 'HOUR')
    -- (had to do this because I didn't find a way to pass an INTERVAL as parameter)
    --Author:PAUCEL0
    --Date:17/01/2020
    ---------------------------------
    FUNCTION interval_to_seconds (interval_count   NUMBER,
                                  interval_unit    VARCHAR2)
        RETURN NUMBER
    IS
        l_inter_to_seconds   NUMBER;
    BEGIN
        SELECT ROUND (
                       EXTRACT (
                           DAY FROM (NUMTODSINTERVAL (interval_count,
                                                      interval_unit)))
                     * 86400
                   +   EXTRACT (
                           HOUR FROM (NUMTODSINTERVAL (interval_count,
                                                       interval_unit)))
                     * 3600
                   +   EXTRACT (
                           MINUTE FROM (NUMTODSINTERVAL (interval_count,
                                                         interval_unit)))
                     * 60
                   + EXTRACT (
                         SECOND FROM (NUMTODSINTERVAL (interval_count,
                                                       interval_unit))))
          INTO l_inter_to_seconds
          FROM DUAL;

        RETURN l_inter_to_seconds;
    END interval_to_seconds;

    ---------------------------------
    --Summary:Checks if the sysdate is between 8pm and midnight
    --Parameters:none
    --Author:CHRBEC
    --Date:11/02/2015
    ---------------------------------
    FUNCTION is_night
        RETURN BOOLEAN
    IS
    BEGIN
        IF SYSDATE BETWEEN TO_DATE (
                                  TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy')
                               || ' 00:01',
                               'ddmmyyyy HH24:MI')
                       AND TO_DATE (
                                  TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy')
                               || ' 22:00',
                               'ddmmyyyy HH24:MI')
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END is_night;

    ---------------------------------
    --Summary:Checks if today is friday
    --Parameters:none
    --Author:CHRBEC
    --Date:11/02/2015
    ---------------------------------
    FUNCTION is_friday (i_date DATE:= NULL)
        RETURN BOOLEAN
    IS
        l_today   VARCHAR2 (50);
    BEGIN
        l_today := TRIM (TO_CHAR (COALESCE (i_date, SYSDATE), 'DAY'));

        IF l_today IN ('FRIDAY', 'VENDREDI')
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END is_friday;

    ---------------------------------
    --Summary:Checks if today is thursday
    --Parameters:none
    --Author:CHRBEC
    --Date:16/02/2015
    ---------------------------------
    FUNCTION is_thursday (i_date DATE:= NULL)
        RETURN BOOLEAN
    IS
        l_today   VARCHAR2 (50);
    BEGIN
        l_today := TRIM (TO_CHAR (COALESCE (i_date, SYSDATE), 'DAY'));

        IF l_today IN ('THURSDAY', 'JEUDI')
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END is_thursday;

    ---------------------------------
    --Summary:Checks if today is saturday
    --Parameters:none
    --Author:CHRBEC
    --Date:11/02/2015
    ---------------------------------
    FUNCTION is_saturday (i_date DATE:= NULL)
        RETURN BOOLEAN
    IS
        l_today   VARCHAR2 (50);
    BEGIN
        l_today := TRIM (TO_CHAR (COALESCE (i_date, SYSDATE), 'DAY'));

        IF l_today IN ('SATURDAY', 'SAMEDI')
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END is_saturday;

    ---------------------------------
    --Summary:Checks if today is sunday
    --Parameters:none
    --Author:CHRBEC
    --Date:11/02/2015
    ---------------------------------
    FUNCTION is_sunday (i_date DATE:= NULL)
        RETURN BOOLEAN
    IS
        l_today   VARCHAR2 (50);
    BEGIN
        l_today := TRIM (TO_CHAR (COALESCE (i_date, SYSDATE), 'DAY'));

        IF l_today IN ('SUNDAY', 'DIMANCHE')
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END is_sunday;

    ---------------------------------
    --Summary:Combined is_saturday and is_sunday check
    --Parameters:none
    --Author:CHRBEC
    --Date:11/02/2015
    ---------------------------------
    FUNCTION is_weekend (i_date DATE:= NULL)
        RETURN BOOLEAN
    IS
    BEGIN
        RETURN is_saturday (i_date) OR is_sunday (i_date);
    END is_weekend;


    ---------------------------------
    --Summary:Check if the next eod is planned for a future date - meaning that it has already been done for a specific bu
    --Parameters: bu_id
    --Author:ADRGUS
    --Date:19/11/2024
    ---------------------------------
    FUNCTION is_day_switch_done (l_bu_id NUMBER)
        RETURN BOOLEAN
    IS
        l_next_eod_date   DATE;
    BEGIN
        SELECT TRUNC (eod_next_run)
          INTO l_next_eod_date
          FROM base
         WHERE BU_ID = l_bu_id;

        IF is_weekend OR is_bank_day_off (TRUNC (SYSDATE))
        THEN
            RETURN FALSE;
        ELSE
            IF l_next_eod_date > TRUNC (SYSDATE)
            THEN
                RETURN TRUE;
            ELSE
                RETURN FALSE;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN FALSE;
    END is_day_switch_done;


    -------------------------------------------------------------------------------
    --procedure: send mail    param :  p_to, p_subject, p_html_pool, l_html_temp
    -------------------------------------------------------------------------------
    PROCEDURE send_mail (i_to              VARCHAR2,
                         i_subject         VARCHAR2,
                         i_html_pool       CLOB,
                         i_html_temp       CLOB,
                         i_is_override     BOOLEAN,
                         i_override_mail   VARCHAR2)
    IS
        l_to_temp   VARCHAR2 (4000);
        l_substr_pos_start NUMBER;
        l_substr_pos_end   NUMBER;
        l_to_rcpt   VARCHAR2 (4002);
    BEGIN
        --check if execution time is outside of usual monitoring periods (01:15 - 20:00 (server time) on weekdays)
        --if so, replace recipient with default AM + Operations mails

        IF is_night OR is_weekend
        THEN
            IF i_is_override
            THEN
                l_to_temp := upsert_mails (p_to_night, ';', i_override_mail);
            ELSE
                l_to_temp := p_to_night;
            END IF;
        ELSE
            l_to_temp := i_to;
        END IF;

       if is_prod and l_severity = c_sys_blocking_p then
          l_to_temp := upsert_mails(l_to_temp, ';', l_mail_operateurs);
       end if;
        IF   INSTR(i_subject,c_sys_blocking) > 0
        then
        l_to_temp := upsert_mails(l_to_temp, ';', 'dg.informatique.appman.rm@blu.bank');
        end if;
        IF (INSTR(i_subject,c_blocking)>0 and l_db_name LIKE 'AVALIV%')
           then
            l_to_temp := upsert_mails(l_to_temp, ';', 'dg.informatique.appman.rm@blu.bank');
        end if;

        if l_severity = c_none_p then
            l_to_temp := remove_mail(l_to_temp,'dg.informatique.appman.rm@blu.bank');
        end if;

        p_smtp_hostname := 'smtp.oi.bdl.lu';
        p_smtp_portnum := '25';
        p_from := 'it.monitoring@blu.bank';
        l_boundary := 'a1b2c3d4e3f2g1';
        l_temp := NULL;

        l_connection :=
            UTL_SMTP.open_connection (p_smtp_hostname, p_smtp_portnum);
        UTL_SMTP.helo (l_connection, p_smtp_hostname);
        UTL_SMTP.mail (l_connection, p_from);

        ---------- MAIL TESTING OVERWRITE
        -- Unquote and change this to overwrite all the email recipients
        -- l_to_temp := 'pierre.guyot@blu.bank';
        -- l_to_temp := '';

        -- Add the recipients to the mail 
        i := 1;
        l_to_rcpt := ';' || l_to_temp || ';';
        WHILE INSTR(l_to_rcpt, ';', 1, i + 1) > 0
        LOOP
            l_substr_pos_start := INSTR(l_to_rcpt, ';', 1, i) + 1;
            l_substr_pos_end   := INSTR(l_to_rcpt, ';', 1, i + 1);
            l_to := SUBSTR(l_to_rcpt, l_substr_pos_start, l_substr_pos_end - l_substr_pos_start);
            i := i + 1;
            UTL_SMTP.rcpt (l_connection, l_to);
        END LOOP;


        l_temp := l_temp || 'MIME-Version: 1.0' || CHR (13) || CHR (10);
        l_temp := l_temp || 'To: ' || l_to_temp || CHR (13) || CHR (10);
        l_temp := l_temp || 'From: ' || p_from || CHR (13) || CHR (10);
        l_temp := l_temp || 'Subject: ' || i_subject || CHR (13) || CHR (10);
        l_temp := l_temp || 'Reply-To: ' || p_from || CHR (13) || CHR (10);
        l_temp :=
               l_temp
            || 'Content-Type: multipart/alternative; boundary='
            || CHR (34)
            || l_boundary
            || CHR (34)
            || CHR (13)
            || CHR (10);

        ----------------------------------------------------
        -- Write the headers
        DBMS_LOB.createtemporary (l_body_html, FALSE, 10);
        DBMS_LOB.write (l_body_html,
                        LENGTH (l_temp),
                        1,
                        l_temp);

        ----------------------------------------------------
        -- Write the text boundary
        l_offset := DBMS_LOB.getlength (l_body_html) + 1;
        l_temp := '--' || l_boundary || CHR (13) || CHR (10);
        l_temp :=
               l_temp
            || 'content-type: text/plain; charset=us-ascii'
            || CHR (13)
            || CHR (10)
            || CHR (13)
            || CHR (10);
        DBMS_LOB.write (l_body_html,
                        LENGTH (l_temp),
                        l_offset,
                        l_temp);

        ----------------------------------------------------
        -- Write the plain text portion of the email
        l_offset := DBMS_LOB.getlength (l_body_html) + 1;

        ----------------------------------------------------
        -- Write the HTML boundary
        l_temp :=
               CHR (13)
            || CHR (10)
            || CHR (13)
            || CHR (10)
            || '--'
            || l_boundary
            || CHR (13)
            || CHR (10);
        l_temp :=
               l_temp
            || 'content-type: text/html;'
            || CHR (13)
            || CHR (10)
            || CHR (13)
            || CHR (10);
        l_offset := DBMS_LOB.getlength (l_body_html) + 1;
        DBMS_LOB.write (l_body_html,
                        LENGTH (l_temp),
                        l_offset,
                        l_temp);

        ----------------------------------------------------
        -- Write the HTML portion of the message
        --dbms_lob.writeappend(l_body_html, length(i_html_pool), i_html_pool);
        --dbms_lob.APPEND(l_body_html, i_html_temp);
        l_body_html := l_body_html || i_html_pool || i_html_temp;

        ----------------------------------------------------
        -- Write the final html boundary
        l_temp :=
            CHR (13) || CHR (10) || '--' || l_boundary || '--' || CHR (13);
        l_offset := DBMS_LOB.getlength (l_body_html) + 1;
        DBMS_LOB.write (l_body_html,
                        LENGTH (l_temp),
                        l_offset,
                        l_temp);

        ----------------------------------------------------
        -- Send the email in 1900 byte chunks to UTL_SMTP
        l_offset := 1;
        l_ammount := 1900;
        UTL_SMTP.open_data (l_connection);

        WHILE l_offset < DBMS_LOB.getlength (l_body_html)
        LOOP
            UTL_SMTP.write_data (
                l_connection,
                DBMS_LOB.SUBSTR (l_body_html, l_ammount, l_offset));
            l_offset := l_offset + l_ammount;
            l_ammount :=
                LEAST (1900, DBMS_LOB.getlength (l_body_html) - l_ammount);
        END LOOP;

        UTL_SMTP.close_data (l_connection);
        UTL_SMTP.quit (l_connection);
        DBMS_LOB.freetemporary (l_body_html);
    END send_mail;


    PROCEDURE write_json_to_spool
    IS
        l_buffer     VARCHAR2 (10000);
        l_position   INTEGER := 1;
        l_linesize   INTEGER;
    BEGIN
        DBMS_OUTPUT.enable (1000000);            -- temporary 1 MB buffer size

        -- Loop through the CLOB content and output to spool file
        WHILE l_position < DBMS_LOB.getlength (l_json_temp)
        LOOP
            -- l_linesize := instr(l_json_temp, chr(10), l_position);
            l_linesize :=
                INSTR (l_json_temp, CHR (10), l_position) - l_position;
            --dbms_output.put_line('position=' || l_position || ' ; linesize=' || l_linesize);
            DBMS_LOB.read (l_json_temp,
                           l_linesize,
                           l_position,
                           l_buffer);
            DBMS_OUTPUT.put_line (l_buffer);
            l_position := l_position + l_linesize + 1;
        END LOOP;


        DBMS_OUTPUT.enable (10000); -- revert buffer size back to normal (10k)
    END write_json_to_spool;

    ---------------------------------
    --Summary:Handle an exception during the execution of a given check
    --Parameters:name of the check that failed, the errormessage and the stack trace of the error
    --Author:CHRBEC
    --Date:
    ---------------------------------
    PROCEDURE handle_check_exception (i_checkname   VARCHAR2,
                                      i_sqlerrm     CLOB,
                                      i_trace       CLOB)
    IS
    BEGIN
        write_query (i_checkname,
                     'Err',
                     SUBSTR (i_sqlerrm, 0, 100),
                     c_blocking_p,
                     '=',
                     '#');
    END handle_check_exception;

    ---------------------------------
    --Summary:Parse a tag from the EUR rates block in an FX rates xml message
    --Parameters:message content, name of the tag to parse, (optional) max length of the tag value
    --Author:CHRBEC
    --Date:12/03/2014
    ---------------------------------
    FUNCTION parse_cur_xml_tag_value (i_xml              CLOB,
                                      i_tag_name         VARCHAR2,
                                      i_val_max_length   NUMBER:= 32,
                                      i_id_tag_name      VARCHAR2:= 'EUR=')
        RETURN VARCHAR2
    IS
        l_xml_eur   CLOB;
        l_idx1      NUMBER;
        l_idx2      NUMBER;
    BEGIN
        l_idx1 := INSTR (i_xml, '<RIC>' || i_id_tag_name || '</RIC>') + 11;
        l_idx2 := INSTR (i_xml, '</Row>', l_idx1);

        l_xml_eur := SUBSTR (i_xml, l_idx1, l_idx2 - l_idx1);

        RETURN REGEXP_SUBSTR (
                   l_xml_eur,
                      '<'
                   || i_tag_name
                   || '>(.{1,'
                   || i_val_max_length
                   || '})</'
                   || i_tag_name
                   || '>',
                   1,
                   1,
                   'in',
                   1);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END parse_cur_xml_tag_value;

    ---------------------------------
    --Summary:Parse a tag in an FX rates xml message
    --Parameters:message content, name of the tag to parse, (optional) max length of the tag value
    --Author:THOADA3
    --Date:02/07/2025
    ---------------------------------
    FUNCTION parse_cur_xml_tag_multi_value (i_xml              CLOB,
                                      i_tag_name         VARCHAR2,
                                      i_val_max_length   NUMBER:= 32,
                                      i_id_tag_name      VARCHAR2:= 'EUR=')
        RETURN VARCHAR2
    IS
    BEGIN

        RETURN REGEXP_SUBSTR (
                   i_xml,
                      '<'
                   || i_tag_name
                   || '>(.{1,'
                   || i_val_max_length
                   || '})</'
                   || i_tag_name
                   || '>',
                   1,
                   1,
                   'in',
                   1);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END parse_cur_xml_tag_multi_value;


    ---------------------------------
    --Summary:Generic check to verify that trade_dates in rates messages are up-to-date
    --Parameters:Name of the check - used for documentation link, rate name - used for in report and warning,
    --tag name - identifier for the specific rate type, start and end of message injection window
    --(Optional) msg type with MMKT_RATES as default value
    --Author:CHRBEC
    --Date:17/07/2014
    ---------------------------------
    PROCEDURE check_generic_rates_update (
        i_check_name           VARCHAR2,
        i_rate_name            VARCHAR2,
        i_tag_name             VARCHAR2,
        i_sop                  DATE,
        i_eop                  DATE,
        i_msg_type             VARCHAR2:= 'MMKT_RATES',
        i_previous_date        BOOLEAN:= FALSE,
        i_previous_date_calc   VARCHAR2:= 'V',
        i_country_id           NUMBER:= 0,
        i_days_in_past         NUMBER:= 1)
    IS
        l_cnt            NUMBER;
        l_test_date      DATE;
        l_xml            CLOB;
        l_compare_date   DATE;
        l_day            VARCHAR (20);
        l_days_in_past   NUMBER;
        l_max            NUMBER;
    BEGIN
        --generic check is in server timezone
        session#.open_session (i_bu_id => -1);

        IF i_previous_date
        THEN
            IF i_country_id != 0
            THEN
                IF is_day_off (i_country_id,
                               get_previous_day (i_days_in_past))
                THEN
                    l_days_in_past := i_days_in_past + 1;

                    IF is_day_off (i_country_id,
                                   get_previous_day (l_days_in_past))
                    THEN
                        l_days_in_past := l_days_in_past + 1;
                    END IF;
                ELSE
                    l_days_in_past := i_days_in_past;
                END IF;
            ELSE
                l_days_in_past := i_days_in_past;
            END IF;

            IF i_previous_date_calc = 'V'
            THEN
                l_compare_date := get_previous_day (l_days_in_past);
            ELSIF i_previous_date_calc = 'B'
            THEN
                l_compare_date := get_previous_day_b (l_days_in_past);
            ELSIF i_previous_date_calc = 'X'
            THEN
                l_compare_date := SYSDATE - l_days_in_past;
            ELSE
                l_compare_date := get_previous_day (l_days_in_past);
            END IF;
        ELSE
            l_compare_date := i_sop;
        END IF;


        SELECT TRIM (TO_CHAR (today, 'DAY'))
          INTO l_day
          FROM k.base
         WHERE ROWNUM = 1;

        IF    (TO_DATE (SYSDATE) - TO_DATE (i_sop) <= 1)
           OR (    l_day = 'MONDAY'
               AND (TO_DATE (SYSDATE) - TO_DATE (i_sop)) <= 3)
        THEN
            l_max := 1000000;
        ELSE
            l_max := 3000000;
        END IF;

          -- Check if message has been received
          SELECT COUNT (*)
            INTO l_cnt
            FROM msg_extl_in mi, msg m
           WHERE     mi.id = m.id
                 AND m.netw_id = 116
                 AND m.msg_status_id = 6
                 AND mi.msg_type IN (i_msg_type)
                 AND mi.timestamp > i_sop
                 AND mi.timestamp < i_eop
                 AND text LIKE '%<RIC>' || i_tag_name || '</RIC>%'
                 AND mi.id >= (SELECT MAX (id) - l_max FROM msg)            --
                 AND ROWNUM = 1
        ORDER BY m.timestamp DESC;

        IF l_cnt > 0
        THEN
            --get rate message content and pars trade date of a given identifier element
            FOR c
                IN (SELECT *
                      FROM (  SELECT text
                                FROM msg_extl_in mi, msg m
                               WHERE     mi.id = m.id
                                     AND m.netw_id = 116
                                     AND m.msg_status_id = 6
                                     AND mi.msg_type IN (i_msg_type)
                                     AND mi.timestamp > i_sop
                                     AND mi.timestamp < i_eop
                                     AND text LIKE
                                                '%<RIC>'
                                             || i_tag_name
                                             || '</RIC>%'
                                     AND mi.id >=
                                         (SELECT MAX (id) - l_max FROM msg)
                            ORDER BY m.timestamp DESC)
                     WHERE ROWNUM = 1)
            LOOP
                l_xml := c.text;
            END LOOP;

            l_test_date :=
                TO_DATE (parse_cur_xml_tag_value (l_xml,
                                                  'Trade_Date',
                                                  12,
                                                  i_tag_name),
                         'YYYY/MM/DD');

            --Check with blocking severity
            write_query (i_rate_name || ' up-to-date',
                         TO_CHAR (l_test_date, 'DD/MM/YYYY'),
                         TO_CHAR (l_compare_date, 'DD/MM/YYYY'),
                         c_blocking_p,
                         '=',
                         i_check_name);

            --Warning to market team
            IF TO_CHAR (l_test_date, 'DD/MM/YYYY') !=
               TO_CHAR (l_compare_date, 'DD/MM/YYYY')
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_to := upsert_mails (p_to, ';', l_mail_market_secdb);

                IF i_check_name LIKE 'cisg%'
                THEN
                    p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                END IF;

                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : '
                    || i_rate_name
                    || ' rates not up-to-date: '
                    || TO_CHAR (l_test_date, 'DD/MM/YYYY')
                    || '</b><br/>'
                    || p_html_pool;
            END IF;
        ELSE
            --if no message received, display N/A check result with severity major, no warning - since presence check will create warning
            write_query (i_rate_name || ' up-to-date',
                         'N/A',
                         TO_CHAR (l_compare_date, 'DD/MM/YYYY'),
                         c_major_p,
                         '=',
                         i_check_name);
            p_html_pool :=
                   '<br/><b>WARNING for MARKET TEAM : '
                || i_rate_name
                || ' rates date could not be validated!</b><br/>'
                || p_html_pool;
            p_to := upsert_mails (p_to, ';', l_mail_market_it);
            p_to := upsert_mails (p_to, ';', l_mail_market_secdb);

            IF i_check_name LIKE 'cisg%'
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            handle_check_exception (i_rate_name || ' up-to-date',
                                    SQLERRM,
                                    DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    END check_generic_rates_update;



    ---------------------------------
    --Summary:Generic check to verify that trade_dates in rates messages are up-to-date in whole XML FILE
    --Parameters:Name of the check - used for documentation link, rate name - used for in report and warning,
    --tag name - identifier for the specific rate type, start and end of message injection window
    --(Optional) msg type with MMKT_RATES as default value
    --Author:NICMAL2
    --Date:13/04/2015
    ---------------------------------
    PROCEDURE check_generic_rates_update_all (i_check_name   VARCHAR2,
                                              i_rate_name    VARCHAR2,
                                              i_tag_name     VARCHAR2,
                                              i_sop          DATE,
                                              i_eop          DATE,
                                              i_msg_type     VARCHAR2)
    IS
        l_cnt         NUMBER;
        l_test_date   DATE;
        l_xml         CLOB;
    BEGIN
          -- Check if message has been received
          SELECT COUNT (*)
            INTO l_cnt
            FROM msg_extl_in mi, msg m
           WHERE     mi.id = m.id
                 AND m.netw_id = 116
                 AND m.msg_status_id = 6
                 AND mi.msg_type IN (i_msg_type)
                 AND mi.timestamp > i_sop
                 AND mi.timestamp < i_eop
                 AND text LIKE '%<RIC>' || i_tag_name || '</RIC>%'
                 AND mi.id >= (SELECT MAX (id) - 1000000 FROM msg)
                 AND ROWNUM = 1
        ORDER BY m.timestamp DESC;


        IF l_cnt > 0
        THEN
            FOR c
                IN (SELECT *
                      FROM (  SELECT text
                                FROM msg_extl_in mi, msg m
                               WHERE     mi.id = m.id
                                     AND m.netw_id = 116
                                     AND m.msg_status_id = 6
                                     AND mi.msg_type IN (i_msg_type)
                                     AND mi.timestamp > i_sop
                                     AND mi.timestamp < i_eop
                                     AND text LIKE
                                                '%<RIC>'
                                             || i_tag_name
                                             || '</RIC>%'
                                     AND mi.id >=
                                         (SELECT MAX (id) - 1000000 FROM msg)
                            ORDER BY m.timestamp DESC)
                     WHERE ROWNUM = 1)
            LOOP
                l_xml := c.text;
            END LOOP;


            --Check with blocking severity
            write_query (i_rate_name || ' up-to-date',
                         TO_CHAR (TRUNC (i_eop), 'DD/MM/YYYY'),
                         TO_CHAR (i_sop, 'DD/MM/YYYY'),
                         c_blocking_p,
                         '=',
                         i_check_name);

            --Warning to market team
            IF INSTR (l_xml, TO_CHAR (TRUNC (i_eop), 'YYYY/MM/DD')) <= 0
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_to := upsert_mails (p_to, ';', l_mail_market_secdb);

                IF i_check_name LIKE 'cisg%'
                THEN
                    p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                END IF;

                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : '
                    || i_rate_name
                    || ' rates not up-to-date: '
                    || TO_CHAR (TRUNC (i_eop), 'DD/MM/YYYY')
                    || '</b><br/>'
                    || p_html_pool;
            END IF;
        ELSE
            --if no message received, display N/A check result with severity major, no warning - since presence check will create warning
            write_query (i_rate_name || ' up-to-date',
                         'N/A',
                         TO_CHAR (SYSDATE, 'DD/MM/YYYY'),
                         c_major_p,
                         '=',
                         i_check_name);
            p_html_pool :=
                   '<br/><b>WARNING for MARKET TEAM : '
                || i_rate_name
                || ' rates date could not be validated!</b><br/>'
                || p_html_pool;
            p_to := upsert_mails (p_to, ';', l_mail_market_it);
            p_to := upsert_mails (p_to, ';', l_mail_market_secdb);

            IF i_check_name LIKE 'cisg%'
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            handle_check_exception (i_rate_name || ' up-to-date',
                                    SQLERRM,
                                    DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    END check_generic_rates_update_all;

    ---------------------------------
    --Summary:Return mail based on environment
    --Parameters:production mail
    --Author:CHRBEC7
    --Date:04/07/2016
    ---------------------------------
    FUNCTION assign_mail (i_mail VARCHAR2)
        RETURN VARCHAR2
    IS
    BEGIN
        IF is_prod
        THEN
            RETURN i_mail;
        ELSIF is_pre
        THEN
            IF i_mail = 'dg.afp@blu.bank'
            THEN
                RETURN i_mail;
            ELSIF REGEXP_LIKE (i_mail, 'it.cbs.taxcompl.support@blu.bank')
            THEN
                RETURN 'it.cbs.taxcompl.support@blu.bank;#ComplCoordDataProj@blu.bank';
            ELSIF REGEXP_LIKE (i_mail, 'paymon.follow@blu.bank')
            THEN
                RETURN 'paymon.follow@blu.bank';
            ELSE
                RETURN c_email_avapre;
            END IF;
        ELSE
            RETURN g_email_dbg;
        END IF;
    END assign_mail;

    ---------------------------------
    --Summary:Function to decode the numeric severity variable into a literal representation
    --Parameters:severity number
    --Author:CHRBEC
    --Date:18/07/2016
    ---------------------------------
    FUNCTION decode_severity (i_severity_num NUMBER)
        RETURN VARCHAR2
    IS
        l_severity_char   VARCHAR2 (50);
    BEGIN
        CASE i_severity_num
            WHEN c_none_p
            THEN
                l_severity_char := 'OK';
            WHEN c_major_p
            THEN
                l_severity_char := c_major;
            WHEN c_blocking_p
            THEN
                l_severity_char := c_blocking;
            WHEN c_sys_blocking_p
            THEN
                l_severity_char := c_sys_blocking;
            ELSE
                l_severity_char := 'OK';
        END CASE;

        RETURN l_severity_char;
    END decode_severity;

    ---------------------------------
    --Summary:replace the previously entered placeholders in the html doc with the actual section severity
    --Parameters: none
    --Author:CHRBEC7
    --Date:
    ---------------------------------
    PROCEDURE replace_section_severity
    IS
    BEGIN
        l_html_temp :=
            REPLACE (l_html_temp,
                     c_severity_avail_ph,
                     decode_severity (g_severity_avail));
        l_html_temp :=
            REPLACE (l_html_temp,
                     c_severity_resp_ph,
                     decode_severity (g_severity_resp));
        l_html_temp :=
            REPLACE (l_html_temp,
                     c_severity_sys_ph,
                     decode_severity (g_severity_sys));
        l_html_temp :=
            REPLACE (l_html_temp,
                     c_severity_euro_ph,
                     decode_severity (g_severity_euro));
        l_html_temp :=
            REPLACE (l_html_temp,
                     c_severity_asia_ph,
                     decode_severity (g_severity_asia));
    END replace_section_severity;

    ---------------------------------
    --Summary: Check for Finance - BGP 926 timeouts
    --Parameters:none
    --Author:ADRMEN
    --Date:27/09/2022
    ---------------------------------
    FUNCTION cond_check_timeout_bgp926
        RETURN BOOLEAN
    IS
        l_cond   BOOLEAN := FALSE;
    BEGIN
        IF (SYSDATE BETWEEN TO_DATE (
                                   TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy')
                                || ' 08:00',
                                'ddmmyyyy HH24:MI')
                        AND TO_DATE (
                                   TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy')
                                || ' 08:20',
                                'ddmmyyyy HH24:MI'))
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END cond_check_timeout_bgp926;

    PROCEDURE check_timeout_bgp926
    IS
        c_check_name    VARCHAR2 (100) := 'nb_timeout_bgp926 (last 24 hours)';
        c_check_title   VARCHAR2 (100) := 'nb BGP 926 timeouts';
        l_cnt_wait      NUMBER;
    BEGIN
        SELECT COUNT (*)
          INTO l_cnt_wait
          FROM k.LOG
         WHERE ctx LIKE '[PKP_WAIT#]%' AND timestamp >= SYSDATE - 1;

        IF l_cnt_wait > 150
        THEN
            p_html_pool :=
                   '<br/><b>WARNING for Finance TEAM : '
                || l_cnt_wait
                || ' timeouts on BGP 926 in the last 24 hours  </b> <br/>'
                || p_html_pool;
            p_to := p_to || ';' || l_mail_cbs_finance;
        END IF;

        write_query (c_check_title,
                     TO_CHAR (l_cnt_wait),
                     '150',
                     c_blocking_p,
                     '<=',
                     c_check_name);
    EXCEPTION
        WHEN OTHERS
        THEN
            handle_check_exception (c_check_title,
                                    SQLERRM,
                                    DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    END check_timeout_bgp926;
----------------------------------------------------
----------------------------------------------------
-----------------------MAIN-------------------------
----------------------------------------------------
----------------------------------------------------
BEGIN
    DBMS_APPLICATION_INFO.SET_MODULE ('MINI_MONITOR_DB', NULL);
    DBMS_APPLICATION_INFO.SET_ACTION ('INIT');

    l_time := SYSTIMESTAMP;

    --DATABASE
    --select upper(name) into l_db_name from v$database;
    sys.DBMS_SYSTEM.get_env ('FDB_NAME', l_db_name);

    IF l_db_name LIKE 'AVALIV%'
    THEN
        is_prod := TRUE;
    ELSIF l_db_name LIKE 'AVAPRE' or l_db_name LIKE 'AVAMICC'
    THEN
        is_pre := TRUE;
    ELSE
        is_prod := FALSE;
        is_pre := FALSE;
    END IF;


    -- generate a unique ID for this execution (ex: 'AVAMON_AVALIV_1707311689452')
    g_execution_id := 'AVAMON_' || l_db_name || '_' || current_timestamp_ms;
    -- for end of 1st test's computation of execution time
    g_last_test_ts := current_timestamp_ms;

    p_to :=
        assign_mail (
            'relman@blu.bank;zabbix.errors@blu.bank;itsm@blu.bank');
    p_to_rm_test := assign_mail ('nicmal2@blu.bank');
    p_to_night :=
        assign_mail (
            'dg.informatique.AppMan.rm@blu.bank;zabbix.errors@blu.bank;relman@blu.bank');

    l_mail_stex := assign_mail ('&fund_desk_fund_trad@blu.bank');
    l_mail_stex_bond := assign_mail ('&fund_desk_fund_trad@blu.bank');
    l_mail_stex_fund := assign_mail ('&fund_desk_fund_trad@blu.bank');
    l_mail_stex_fund_market := assign_mail ('&fund_desk_fund_trad@blu.bank');
    l_mail_stex_fund_blbe := assign_mail ('madavaloq@blu.bank');
    l_mail_stex_struct := assign_mail ('&fund_desk_fund_trad@blu.bank');
    l_mail_stex_equity := assign_mail ('&fund_desk_fund_trad@blu.bank');
    l_mail_stex_fix :=
        assign_mail ('madavaloq@blu.bank;pbs.projects@blu.bank');
    l_mail_prcq_all_btlu :=
        assign_mail (
            'jeanchristophe.lemond@banquetransatlantique.lu;ldbtleodavaloq@banquetransatlantique.lu');
    l_mail_prcq_stex_lu :=
        assign_mail (
            'anomey2@blu.bank;gabmen1@blu.bank;securities.settlement@blu.bank;danilo.cardone@blu.bank');
    l_mail_prcq_stex_btbe := assign_mail ('btb.eod@blu.bank');
    l_mail_prcq_secevt :=
        assign_mail (
            'cps.corp.actions@blu.bank;corporate.actions@blu.bank;herfay6@blu.bank');
    l_mail_prcq_secevt_inprc :=
        assign_mail ('cps.corp.actions@blu.bank;herfay6@blu.bank');
    l_mail_prcq_secevt_corpac :=
        assign_mail ('corporate.actions@blu.bank;herfay6@blu.bank');
    l_mail_prcq_settle_lu :=
        assign_mail (
            'anomey2@blu.bank;treasury.settlement@blu.bank;securities.settlement@blu.bank;danilo.cardone@blu.bank');
    l_mail_prcq_settle_btbe :=
        assign_mail ('backofficebtb@banquetransatlantique.be');
    l_mail_prcq_cust :=
        assign_mail (
            'lucspa7@blu.bank;lena.duarte@blu.bank;corinne.engelberg@blu.bank;armdum7@blu.bank');
    l_mail_prcq_fx :=
        assign_mail (
            'arnpoe1@blu.bank;forex@blu.bank;treasury.desk@blu.bank');
    l_mail_prcq_prop :=
        assign_mail (
            'op.client.data.mgmt.pb@blu.bank;op.client.data.mgmt.pbs@blu.bank');
    l_mail_prcq_pay :=
        assign_mail ('dorsin9@blu.bank;dg.informatique.dev.cupase@blu.bank');
    l_mail_prcq_mail :=
        assign_mail (
            'alertes.reporting@blu.bank;pbs.projects@blu.bank;support.crep@blu.bank');
    l_mail_prcq_secdb :=
        assign_mail ('dg.operations.securities.database@blu.bank');
    l_mail_prcq_secur :=
        assign_mail (
            '#access_management_&_bcp@blu.bank;op.client.data.mgmt.pb@blu.bank;op.client.data.mgmt.pbs@blu.bank');
    l_mail_pay_wfp :=
        assign_mail ('paymon.follow@blu.bank');
    l_mail_pay_dflt := assign_mail ('paymon.follow@blu.bank');
    l_mail_pay_btb := assign_mail ('btb.eod@blu.bank');
    l_mail_pay_btl :=
        assign_mail ('jeanchristophe.lemond@banquetransatlantique.lu');
    l_mail_market_it :=
        assign_mail (
            'it.sdm@blu.bank;mqa@blu.bank;jerome.delabouglise@blu.bank;it.cbs.ops@blu.bank');
    l_mail_market_it_light :=
        assign_mail (
            'mqa@blu.bank;jerome.delabouglise@blu.bank;it.cbs.ops@blu.bank');
    l_mail_market_secdb :=
        assign_mail ('herve.fayolle@blu.bank;securitiesdatabase@blu.bank');
    l_mail_market := assign_mail ('dg.informatique.dev.market@blu.bank');
    l_mail_market_treasury := assign_mail ('treasury.desk@blu.bank');
    l_mail_market_rates :=
        assign_mail (
            'it.sdm@blu.bank;xavgra2@blu.bank;mqa@blu.bank;matper0@blu.bank;dg.marches.change@blu.bank;markets.control@blu.bank');
    l_mail_sec_settle := assign_mail ('securities.settlement@blu.bank');
    l_mail_pbs_projects := assign_mail ('pbs.projects@blu.bank');
    l_mail_settle_on_hold := assign_mail ('paymon.follow@blu.bank');
    l_mail_btbe_dflt :=
        assign_mail ('backofficebtb@banquetransatlantique.be');
    l_mail_btlu_dflt :=
        assign_mail (
            'jeanchristophe.lemond@banquetransatlantique.lu;ldbtleodavaloq@banquetransatlantique.lu');
    l_mail_btgb_dflt :=
        assign_mail (
            'aurelie.diaz@banquetransatlantique.com;riskldn@banquetransatlantique.com');
    l_mail_cisg_dflt :=
        assign_mail (
            'opsprojectctrl@cic.asia;avaloq@cic.asia;ops_cab@cic.asia');
    l_mail_cisg_msg :=
        assign_mail (
            'opsprojectctrl@cic.asia;avaloq@cic.asia;ops_cab@cic.asia');
    l_mail_cisg_fxopt := assign_mail ('act@singapore.cic.fr');
    l_mail_cisg_mmkt_task :=
        assign_mail (
            'elaine.li@singapore.cic.fr;reena.chin@singapore.cic.fr;estee.lim@singapore.cic.fr;stella.giam@singapore.cic.fr');
    l_mail_cisg_hourly_report := assign_mail ('avaloq@cic.asia');
    l_mail_cisg_prcq_all :=
        assign_mail (
            'opsprojectctrl@cic.asia;avaloq@cic.asia;ops_cab@cic.asia');
    l_mail_msg_bdl :=
        assign_mail (
            'dg.informatique.dev.cupase@blu.bank;bl.cartes@blu.bank;paymon.follow@blu.bank');
    l_mail_msg_fitax :=
        assign_mail ('it.cbs.financereport.int@blu.bank;jeakie9@blu.bank');
    l_mail_fina_it := assign_mail ('it.cbs.financereport.int@blu.bank');
    l_mail_finacc :=
        assign_mail (
            'financial.accounting@blu.bank;markets.control@blu.bank');
    l_mail_treasury :=
        assign_mail ('treasury.settlement@blu.bank;markets.control@blu.bank');
    l_mail_asset_eval :=
        assign_mail ('nicolas.folny@blu.bank;tom.blasius@blu.bank');
    l_mail_it_middleware :=
        assign_mail ('mqa@blu.bank;jerome.delabouglise@blu.bank');
    l_mail_reporting_team :=
        assign_mail ('alertes.reporting@blu.bank;support.crep@blu.bank');
    l_mail_exploit :=
        assign_mail ('exploitation@blu.bank');
    l_mail_operateurs :=
        assign_mail ('operateurs@blu.bank');
    l_mail_afp := assign_mail ('dg.afp@blu.bank');
    l_mail_oprisk := assign_mail ('risk.op.incident@blu.bank');
    l_mail_msg_trd_1_2 :=
        assign_mail (
            'madavaloq@blu.bank;funddesk.fundtrading@blu.bank;it.sdm@blu.bank;securities.settlement@blu.bank;it.cbs.ops@blu.bank');
    l_mail_msg_trd_3_4 :=
        assign_mail (
            'it.sdm@blu.bank;it.cbs.ops@blu.bank;securities.settlement@blu.bank;Anouk.WEWER-MEYERS@blu.bank');
    l_mail_mobile := assign_mail ('#IT-FrontSolutions-MB@blu.bank');
    l_mail_tax_compliance :=
        assign_mail (
            'it.cbs.taxcompl.support@blu.bank;#ComplCoordDataProj@blu.bank');
    l_mail_cbs_transac := assign_mail ('it.cbs.transactionsmarket@blu.bank');
    l_mail_secdb := assign_mail ('securitiesdatabase@blu.bank');
    l_mail_client_reporting := assign_mail ('support.crep@blu.bank');
    l_mail_multiline := assign_mail ('multiline@blu.bank');
    l_mail_dba := assign_mail ('dg.it.ai.SyDaSt@blu.bank');
    l_mail_cbs_finance := assign_mail ('it.cbs.finance@blu.bank');
    l_mail_fmcs :=
        assign_mail (
            'Anouk.WEWER-MEYERS@blu.bank;Danilo.CARDONE@blu.bank;samuel.almeida-barroso@blu.bank;Olivier.BRIALMONT@blu.bank;daniel.marques-ferreira@blu.bank');
    l_mail_treasury_sttl := assign_mail ('treasury.settlement@blu.bank');
    l_mail_fund_sttl := assign_mail ('fund.settlements@blu.bank');
    l_mail_fmcs_treasury :=
        assign_mail (
            'Anouk.WEWER-MEYERS@blu.bank;daniel.marques-ferreira@blu.bank');
    l_mail_awp :=
        assign_mail (
            'romain.hory@blu.bank;benjamin.ducellier@blu.bank;pierre.calvi@blu.bank');
    l_mail_desk_multiasset := assign_mail ('desk.multiasset@blu.bank');
    l_mail_support_trading := assign_mail ('support.trading@blu.bank');

    l_warning_for := '';
    l_mail_lock := '';
    p_subject := '';
    p_text := '';
    p_html_prepool := '';
    p_html_pool := ' ';
    l_status := c_ok;
    l_severity := c_none_p;
    l_prcq_severity := c_none_p;
    l_idx := 0;
    l_cnt_loop := 0;

    --subsection severities
    g_severity_avail := c_none_p;
    g_severity_resp := c_none_p;
    g_severity_sys := c_none_p;
    g_severity_euro := c_none_p;
    g_severity_asia := c_none_p;

    k.session#.open_session;

    --Define a timestamp at the beginning of the execution to perform first execution of the day checks
    --Prevents problems due to variations in script execution time
    l_execution_time := SYSDATE;

    -- test if this the first execution of the day (before 7h30)
    IF SYSDATE BETWEEN TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:00',
                           'ddmmyyyy HH24:MI')
                   AND TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:40',
                           'ddmmyyyy HH24:MI')
    THEN
        SELECT TRIM (TO_CHAR (today, 'DAY'))
          INTO l_t
          FROM k.base
         WHERE ROWNUM = 1;

        IF ((l_t = 'LUNDI') OR (l_t = 'MONDAY'))
        THEN
            --get back up to 18:39 from 2 days back
            l_timestamp := SYSDATE - NUMTODSINTERVAL (3645, 'MINUTE');
            l_comment := 'Monitoring PRCQ for this week-end';
            l_timecheck := '2 days back from 18:39';
        ELSE
            --get back up to 18:39 from last night
            l_timestamp := SYSDATE - NUMTODSINTERVAL (765, 'MINUTE');
            l_comment := 'Monitoring PRCQ for this night';
            l_timecheck := 'last night from 18:39';
        END IF;
    ELSE
        l_timestamp := SYSDATE - NUMTODSINTERVAL (30, 'MINUTE');
        l_timecheck := 'last 30 min';
    END IF;



    html_append (
           '
        <html xmlns="http://www.w3.org/TR/REC-html40">

        <head>

        <style type="text/css">
        tr
            {mso-height-source:auto;}
        col
            {mso-width-source:auto;}
        br
            {mso-data-placement:same-cell;}
        .style34
            {color:red;
            font-size:11.0pt;
            font-weight:400;
            font-style:normal;
            text-decoration:none;
            font-family:Calibri, sans-serif;
            mso-font-charset:0;
            mso-style-name:Avertissement;
            mso-style-id:11;}
        .style0
            {mso-number-format:General;
            text-align:general;
            vertical-align:bottom;
            white-space:nowrap;
            mso-rotate:0;
            mso-background-source:auto;
            mso-pattern:auto;
            color:black;
            font-size:11.0pt;
            font-weight:400;
            font-style:normal;
            text-decoration:none;
            font-family:Calibri, sans-serif;
            mso-font-charset:0;
            border:none;
            mso-protection:locked visible;
            mso-style-name:Normal;
            mso-style-id:0;}
        .style26
            {background:#C6EFCE;
            mso-pattern:black none;
            color:#006100;
            font-size:11.0pt;
            font-weight:400;
            font-style:normal;
            text-decoration:none;
            font-family:Calibri, sans-serif;
            mso-font-charset:0;
            mso-style-name:Satisfaisant;
            mso-style-id:26;}
        td
            {mso-style-parent:style0;
           padding-top:1px;
            padding-right:1px;
            padding-left:1px;
            mso-ignore:padding;
            color:black;
            font-size:11.0pt;
            font-weight:400;
            font-style:normal;
            text-decoration:none;
            font-family:Calibri, sans-serif;
            mso-font-charset:0;
            mso-number-format:General;
            text-align:general;
            vertical-align:bottom;
            border:none;
            mso-background-source:auto;
            mso-pattern:auto;
            mso-protection:locked visible;
            white-space:nowrap;
            mso-rotate:0;}
        .xl65
            {mso-style-parent:style0;
            background:#538ED5;
            mso-pattern:black none;}
        .xl66
            {mso-style-parent:style0;
            color:white;
            background:#538ED5;
            mso-pattern:black none;}
        .xl67
            {mso-style-parent:style26;
            color:#006100;
            text-align:center;
            background:#C6EFCE;
            mso-pattern:black none;}
        .xl68
            {mso-style-parent:style34;
            color:white;
            text-align:center;
            background:red;
            mso-pattern:black none;}
        .xl69
            {mso-style-parent:style0;
            color:white;
            background:#17375D;
            mso-pattern:black none;}
        .xl70
            {mso-style-parent:style0;
            background:#17375D;
            mso-pattern:black none;}
        .xl71
            {mso-style-parent:style0;
            background:white;
            mso-pattern:black none;}
        .xl72
            {mso-style-parent:style0;
            color:white;
            font-size:8.0pt;
            font-family:Helvetica;
            mso-generic-font-family:auto;
            mso-font-charset:0;
            background:#17375D;
            mso-pattern:black none;}
        .xl74
            {mso-style-parent:style0;
            font-size:8.0pt;
            font-family:Helvetica;
            mso-generic-font-family:auto;
            mso-font-charset:0;}
        .xl75
            {mso-style-parent:style0;
            color:white;
            font-size:8.0pt;
            font-family:Helvetica;
            mso-generic-font-family:auto;
            mso-font-charset:0;
            background:#538ED5;
            mso-pattern:black none;}
        .xl76
            {mso-style-parent:style0;
            font-size:8.0pt;
            font-family:Helvetica;
           mso-generic-font-family:auto;
            mso-font-charset:0;
            background:#538ED5;
            mso-pattern:black none;}
        .xl77
            {mso-style-parent:style26;
            color:#006100;
            font-size:8.0pt;
            font-family:Helvetica;
            mso-generic-font-family:auto;
            mso-font-charset:0;
            text-align:center;
            background:#C6EFCE;
            mso-pattern:black none;}
        .xl78
            {mso-style-parent:style34;
            color:white;
            font-size:8.0pt;
            font-family:Helvetica;
            mso-generic-font-family:auto;
            mso-font-charset:0;
            text-align:center;
            background:red;
            mso-pattern:black none;}
        .xl79
            {mso-style-parent:style26;
            color:#006100;
            font-size:8.0pt;
            font-family:Helvetica;
            mso-generic-font-family:auto;
            mso-font-charset:0;
            text-align:center;
            background:yellow;
            mso-pattern:black none;}
        .xl80
            {mso-style-parent:style26;
            color:white;
            font-size:8.0pt;
            font-family:Helvetica;
            mso-generic-font-family:auto;
            mso-font-charset:0;
            text-align:center;
            background:#F79646;
            mso-pattern:black none;}

        </style>

        </head>

        <body link=blue vlink=purple class=xl74>

        <table border=0 cellpadding=0 cellspacing=0 width=335 style=''border-collapse:

         collapse;table-layout:fixed;width:250pt''>

         <col class=xl74 >
         <tr height=13 style=''mso-height-source:userset;height:9.75pt''>
          <td height=13 class=xl72 width=67 style=''height:9.75pt;width:50pt''>'
        || l_db_name
        || '</td>
              <td class=xl72 width=67 style=''width:50pt''>'
        || l_comment
        || '</td>
              <td class=xl72 width=67 style=''width:50pt''></td>
              <td class=xl72 width=67 style=''width:50pt''></td>
              <td class=xl72 width=67 style=''width:50pt''></td>
              <td class=xl72 width=67 style=''width:50pt''></td>
              <td class=xl72 width=67 style=''width:50pt''></td>
             </tr>');

    ---------
    --START SECTION AVAILABILITY
    ---------
    write_header ('Availability checks', c_severity_avail_ph);
    g_active_section := c_section_avail;



    SELECT session_level INTO l_sl FROM base_main;

    write_query ('Session level',
                 l_sl,
                 '5',
                 c_sys_blocking_p,
                 '=',
                 'session_level');


    --Session level
    FOR c IN (  SELECT bu_id, today, next_today
                  FROM k.base
              ORDER BY bu_id ASC)
    LOOP
        --Bank date
        IF is_saturday
        THEN
            l_date := SYSDATE + 2;
        ELSIF is_sunday
        THEN
            l_date := SYSDATE + 1;
        ELSIF is_friday AND is_day_switch_done (c.bu_id)
        THEN                    --consider friday night after bank date switch
            l_date := SYSDATE + 3;
        ELSE
            IF is_day_switch_done (c.bu_id)
            THEN                       --consider night after bank date switch
                l_date := SYSDATE + 1;
            ELSE
                l_date := SYSDATE;
            END IF;
        END IF;

        IF is_bank_day_off (l_date)
        THEN    --consider that date after bank date switch might be a holiday
            l_date := l_date + 1;
        END IF;

        IF (c.bu_id IS NULL)
        THEN
            SELECT TO_CHAR (today, 'dd/mm/yyyy') INTO l_text FROM k.base;
        ELSE
            SELECT TO_CHAR (today, 'dd/mm/yyyy')
              INTO l_text
              FROM k.base
             WHERE bu_id = c.bu_id;
        END IF;

        IF (c.bu_id IS NULL)
        THEN
            write_query ('Bank date',
                         l_text,
                         TO_CHAR (l_date, 'dd/mm/yyyy'),
                         c_sys_blocking_p,
                         '=',
                         'bu_bank_date');
        ELSE
            write_query ('BU ' || c.bu_id || ' Bank date',
                         l_text,
                         TO_CHAR (l_date, 'dd/mm/yyyy'),
                         c_sys_blocking_p,
                         '=',
                         'bu_bank_date');
        END IF;

        l_exp_today := l_date; --keep expected today date to calculate corresponding next_today

        --Next today (calculate based on expected today date)
        IF is_friday (l_exp_today)
        THEN
            l_date := l_exp_today + 3;                          --skip weekend
        ELSE
            l_date := l_exp_today + 1;
        END IF;

        IF is_bank_day_off (l_date)
        THEN                     --consider that next_today might be a holiday
            IF is_friday (l_date)
            THEN                           --if next day is Friday and holiday
                l_date := l_date + 3;                           --skip weekend
            ELSE
                l_date := l_date + 1;
            END IF;
        END IF;


        IF (c.bu_id IS NULL)
        THEN
            SELECT TO_CHAR (next_today, 'dd/mm/yyyy') INTO l_text FROM k.base;
        ELSE
            SELECT TO_CHAR (next_today, 'dd/mm/yyyy')
              INTO l_text
              FROM k.base
             WHERE bu_id = c.bu_id;
        END IF;

        IF (c.bu_id IS NULL)
        THEN
            write_query ('Next today',
                         l_text,
                         TO_CHAR (l_date, 'dd/mm/yyyy'),
                         c_blocking_p,
                         '=',
                         'next_today');
        ELSE
            write_query ('BU ' || c.bu_id || ' Next today',
                         l_text,
                         TO_CHAR (l_date, 'dd/mm/yyyy'),
                         c_blocking_p,
                         '=',
                         'next_today');
        END IF;

        --EOD STATUS
        SELECT eod_status
          INTO l_text
          FROM k.sec_dept
         WHERE bu_id = c.bu_id;
        -- For new BUs, this value has been initialized with null.
        -- You have to wait the first EOD to get the right value.
        IF(l_text IS NULL) THEN
            l_text:='null';
            write_query ('BU ' || c.bu_id || ' EOD Status',
                    l_text,
                    'null',
                    c_sys_blocking_p,
                    '=',
                    'eod_status');
        ELSE
            write_query ('BU ' || c.bu_id || ' EOD Status',
                    l_text,
                    '-',
                    c_sys_blocking_p,
                    '=',
                    'eod_status');
        END IF;
    END LOOP;

    ---------------------------------
    --Summary:Check if all BUs have same Next_Today
    --Author:ADRGUS
    --Date:21/11/2024
    ---------------------------------
    BEGIN
        --open global session
        session#.open_session ();

        --avoid executing check between European and Asian BDS
        IF (   SYSDATE <
               TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:30',
                        'ddmmyyyy HH24:MI')
            OR SYSDATE >
               TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 22:30',
                        'ddmmyyyy HH24:MI'))
        THEN
            --count differences in base table
            SELECT COUNT (*)
              INTO l_nr
              FROM base
             WHERE next_today != (SELECT next_today
                                    FROM base
                                   WHERE bu_id = 6);

            --get bu_ids
            l_text := '';

            IF l_nr > 0
            THEN
                FOR ent IN (SELECT *
                              FROM base
                             WHERE next_today != (SELECT next_today
                                                    FROM base
                                                   WHERE bu_id = 6))
                LOOP
                    --Don't add comma for first entry
                    IF l_text != ''
                    THEN
                        l_text := l_text || ', ';
                    END IF;

                    l_text :=
                           l_text
                        || 'BU: '
                        || ent.bu_id
                        || ' Next Today: '
                        || ent.next_today;
                END LOOP;

                --add warning
                p_html_prepool :=
                       '<b>WARNING : Business Unit(s) have different "Next Today" date :</b><br/>'
                    || l_text
                    || p_html_prepool;
            END IF;

            --add check-status
            write_query ('BU with different Next_Today',
                         TO_CHAR (l_nr),
                         '0',
                         c_blocking_p,
                         '=',
                         'next_today');
        END IF;
    END;


    -------
    --START SECTION RESPONSE
    -------
    write_header ('Response Time checks', c_severity_resp_ph);
    g_active_section := c_section_resp;

    l_text :=
           l_text
        || '<br/><b>WARNING for AWP: the PKP queue is blocked.</b><br/>';
    l_text :=
           l_text
        || ' Please check additionnal information in BDL-11180 or ITC-1926<br/>';

    --PKP Backlog Queue
    SELECT COUNT (*) INTO l_nr FROM k.pkp_svc_pos_serpil_queue;
     IF l_db_name LIKE 'AVALIV%'
     THEN
        IF l_nr >= 10000 AND l_nr < 20000
        THEN
            p_html_pool := l_text || p_html_pool;
            write_query ('Backlog in PKP Queue',
                        TO_CHAR (l_nr),
                        '10000',
                        c_blocking_p,
                        '<=',
                        'pkp_backlog');
        ELSIF l_nr >= 20000
        THEN
            p_html_pool := l_text || p_html_pool;
            p_to := p_to || ';' || l_mail_awp;
            write_query ('Backlog in PKP Queue',
                        TO_CHAR (l_nr),
                        '20000',
                        c_sys_blocking_p,
                        '<=',
                        'pkp_backlog');
        ELSE
            write_query ('Backlog in PKP Queue',
                        TO_CHAR (l_nr),
                        '20000',
                        c_none_p,
                        '<=',
                        'pkp_backlog');
        END IF;
    ELSE
         write_query ('Backlog in PKP Queue',
                        TO_CHAR (l_nr),
                        '20000',
                        c_none_p,
                        '<=',
                        'pkp_backlog');
    END IF;


    ---------------------------------
    --Summary: Check if an user have locked a FIX order
    --Parameters:
    --Author:PIEGUY0
    --Date:27/10/2025
    ---------------------------------

    l_condition := FALSE;
    l_text := '<br/><b>WARNING for MARKET TEAM : The following orders have been locked :</b><br/>';
    FOR c in (
        SELECT ORDER_LOCK, ID_MESSAGE, ORDER_TIMESTAMP, usr.name AS USERNAME
        FROM (
            SELECT 
                TO_NUMBER(REGEXP_SUBSTR(msg_in.text,'11=(\d*)', 1, 1, '', 1)) AS ORDER_LOCK,
                msg_in.id as ID_MESSAGE,
                msg.TIMESTAMP as  ORDER_TIMESTAMP
            FROM (k.msg msg INNER JOIN k.msg_extl_in msg_in ON msg.ID = msg_in.ID)
                WHERE msg_in.timestamp > SYSDATE - 1/24/2
                AND msg.HDL_ATTEMPT_CNT > 100
                AND msg_in.netw_id = 83
                AND msg_in.text LIKE '%448=TRADINGSCREEN%'
                AND msg_in.text LIKE '%35=8%') view_1 
        INNER JOIN k.doc doc ON view_1.ORDER_LOCK = doc.id
        INNER JOIN k.sec_user usr ON doc.INS_BY_SEC_USER_ID = usr.id)
    LOOP
        l_condition := TRUE;
        l_text := l_text || '<b>Order Lock :</b> '  || TO_CHAR(c.ORDER_LOCK);
        l_text := l_text || ' <b>ID Message :</b> ' || TO_CHAR(c.ID_MESSAGE);
        l_text := l_text || ' <b>Timestamp :</b> '  || TO_CHAR(c.ORDER_TIMESTAMP);
        l_text := l_text || ' <b>User :</b> '       || TO_CHAR(c.USERNAME);
        l_text := l_text || '<br/>';
    END LOOP;
    
    IF l_condition
    THEN
        p_to := upsert_mails (p_to, ';', l_mail_cbs_transac);
        p_to := upsert_mails (p_to, ';', l_mail_sec_settle);
    
        p_html_pool := l_text || p_html_pool;
    END IF;


    --Object transition backlog
    SELECT COUNT (*)
      INTO l_nr
      FROM k.trans_obj
     WHERE trans_seq_nr >= 1e37;

    write_query ('Backlog on TRANS_OBJ',
                 TO_CHAR (l_nr),
                 '100',
                 c_none_p,
                 '<=',
                 'trans_obj_backlog');


    --Backlog in MSG_IN_SEQ queue count
    SELECT COUNT (*)
      INTO l_nr
      FROM k.msg_in
     WHERE     q_name = 'MSG_IN_SEQ'
           AND enq_time > TRUNC (SYSDATE)
           AND deq_time IS NULL;

    write_query ('Backlog in MSG_IN_SEQ (# of msg)',
                 TO_CHAR (l_nr),
                 '50',
                 c_none_p,
                 '<=',
                 'none');

    --Backlog in MSG_IN_SEQ queue delay
    SELECT CASE
               WHEN COALESCE (EXTRACT (MINUTE FROM SYSDATE - MAX (enq_time)),
                              0) <
                    0
               THEN
                   COALESCE (
                           EXTRACT (
                               HOUR FROM   SYSDATE
                                         - MIN (enq_time - INTERVAL '1' HOUR))
                         * 60
                       + EXTRACT (
                             MINUTE FROM   SYSDATE
                                         - MIN (enq_time - INTERVAL '1' HOUR)),
                       0)
               ELSE
                   COALESCE (
                         EXTRACT (HOUR FROM SYSDATE - MIN (enq_time)) * 60
                       + EXTRACT (MINUTE FROM SYSDATE - MIN (enq_time)),
                       0)
           END
      INTO l_nr
      FROM k.msg_in
     WHERE     q_name = 'MSG_IN_SEQ'
           AND enq_time > TRUNC (SYSDATE)
           AND deq_time IS NULL
           AND retry_count = 0;

    write_query ('MaxDelay in MSG_IN_SEQ (in min)',
                 TO_CHAR (l_nr),
                 '15',
                 c_blocking_p,
                 '<=',
                 'msg_in_seq_delay');

    ---------------------------------
    --Summary:If MaxDelay in MSG_IN_SEQ > 30 min, send a warning to FMCS
    --Author:ADRGUS
    --Date:10/12/2024
    ---------------------------------
    BEGIN
        l_text := '';

        IF l_nr > 30
        THEN
            l_text :=
                   l_text
                || '<br/><b>WARNING for FMCS: The following queue(s) have accumulated more than 30 minutes of max delay in msg treatment:</b><br/>';
            l_text :=
                   l_text
                || ' - Queue : MSG_IN_SEQ is blocked since '
                || TO_CHAR (l_nr)
                || ' minutes <br/>';

            p_html_pool := l_text || p_html_pool;
            p_to := p_to || ';' || l_mail_fmcs;
            p_to := p_to || ';' || l_mail_treasury_sttl;
            p_to := p_to || ';' || l_mail_fund_sttl;
            p_to := p_to || ';' || l_mail_sec_settle;
        END IF;
    END;

    --Alert on long dequeue time -- except on TRD_5 wich handles 541 and 543, that are slow to process.
    l_nr := 0;
    l_nr2 := 0;
    l_nr3 := 0;
    l_nr4 := 0;
    l_nr5 := 0;
    l_text := '';
    l_text2 := '';
    l_text3 := '';
    l_text4 := '';
    l_text5 := '';
    j := 1;
    l_cnt_15_low_prio_stex := 0;


    --timezone day light saving https://stackoverflow.com/questions/29271224/how-to-handle-day-light-saving-in-oracle-database
    IF TO_CHAR (SYSTIMESTAMP, 'tzr') = '+01:00'
    THEN
        l_adpt_15_mins := SYSDATE - 1 / 24 / 4 + 1 / 24;
        l_adpt_1_min := SYSDATE - 1 / 24 / 60 + 1 / 24;
    ELSE
        l_adpt_15_mins := SYSDATE - 1 / 24 / 4;
        l_adpt_1_min := SYSDATE - 1 / 24 / 60;
    END IF;

    --if is_prod then

    FOR c
        IN (  SELECT CASE
                         WHEN TO_CHAR (SYSTIMESTAMP, 'tzr') = '+01:00'
                         THEN
                             NVL (
                                     EXTRACT (
                                         DAY FROM   SYSDATE
                                                  - MIN (
                                                          enq_time
                                                        - INTERVAL '1' HOUR))
                                   * 24
                                   * 60
                                 +   EXTRACT (
                                         HOUR FROM   SYSDATE
                                                   - MIN (
                                                           enq_time
                                                         - INTERVAL '1' HOUR))
                                   * 60
                                 + EXTRACT (
                                       MINUTE FROM   SYSDATE
                                                   - MIN (
                                                           enq_time
                                                         - INTERVAL '1' HOUR)),
                                 0)
                         ELSE
                             NVL (
                                     EXTRACT (
                                         DAY FROM   SYSDATE
                                                  - MIN (
                                                          enq_time
                                                        - INTERVAL '1' HOUR))
                                   * 24
                                   * 60
                                 +   EXTRACT (
                                         HOUR FROM SYSDATE - MIN (enq_time))
                                   * 60
                                 + EXTRACT (
                                       MINUTE FROM SYSDATE - MIN (enq_time)),
                                 0)
                     END    AS time,
                     q_name,
                     priority
                FROM k.msg_in mi
               WHERE     deq_time IS NULL
                     AND q_NAME <> 'MSG_IN_SEQ_TRD_5'
                     AND mi.user_data.id <> 1311881401
            GROUP BY q_name, priority)
    LOOP
        IF c.time > 5
        THEN
            IF c.q_name IN
                   ('MSG_IN_SEQ_TRD_3',
                    'MSG_IN_SEQ_TRD_4',
                    'MSG_IN_SEQ_TRD_6')
            THEN
                IF c.priority > 5
                THEN
                    SELECT COUNT (*)
                      INTO l_cnt_15_low_prio_stex
                      FROM msg_extl_in mei_sub, msg_in mi_sub, meta_msg mm
                     WHERE     mei_sub.id = mi_sub.user_data.id
                           AND mm.id(+) = mei_sub.meta_msg_id
                           AND mi_sub.enq_time BETWEEN TRUNC (SYSDATE) - 10
                                                   AND l_adpt_1_min -- not considering messages arrived less than one minute before
                           AND mi_sub.deq_time > l_adpt_15_mins
                           AND mi_sub.q_name = c.q_name
                           AND mi_sub.priority > 6;

                    IF l_nr = 0 AND l_cnt_15_low_prio_stex = 0
                    THEN
                        l_text :=
                               l_text
                            || '<br/><b>WARNING STEX FIX: The following queue(s) have accumulated more than 5 minutes of max delay in msg treatment:</b><br/>';
                        l_text :=
                               l_text
                            || 'Queue : '
                            || c.q_name
                            || ' is blocked since '
                            || c.time
                            || ' minutes on LOW PRIORITY msg ( market exec details ). - <br/>';
                        l_nr := l_nr + 1;
                    END IF;
                ELSE
                    l_text :=
                           l_text
                        || '<br/><b>WARNING STEX FIX: The following queue(s) have accumulated more than 5 minutes of max delay in msg treatment:</b><br/>';
                    l_text :=
                           l_text
                        || 'Queue : '
                        || c.q_name
                        || ' has max delay of '
                        || c.time
                        || ' minutes on HIGH PRIORITY msg ( client trades ). - <br/>';
                    l_nr := l_nr + 1;
                END IF;
            ELSIF c.q_name IN ('MSG_IN_SEQ_TRD', 'MSG_IN_SEQ_TRD_2')
            THEN
                IF l_nr2 = 0
                THEN
                    l_text2 :=
                           l_text2
                        || '<br/><b>WARNING for MAD: The following queue(s) have accumulated more than 5 minutes of max delay in msg treatment:</b><br/>';
                END IF;

                IF c.priority > 6
                THEN
                    l_text2 :=
                           l_text2
                        || 'Queue : '
                        || c.q_name
                        || ' has max delay of '
                        || c.time
                        || ' minutes on LOW PRIORITY msg. - <br/>';
                ELSE
                    l_text2 :=
                           l_text2
                        || 'Queue : '
                        || c.q_name
                        || ' has max delay of '
                        || c.time
                        || ' minutes on HIGH PRIORITY msg. - <br/>';
                END IF;

                l_nr2 := l_nr2 + 1;
            ELSIF c.q_name = 'MSG_IN_SVC_TRX' AND c.priority = 5
            THEN
                IF c.time > 6000
                THEN
                    IF l_nr4 = 0
                    THEN
                        l_text4 :=
                               l_text4
                            || '<br/><b>WARNING for AM team : The following queue(s) have accumulated more than 6000 minutes of max delay in msg treatment:</b><br/>';
                    END IF;

                    l_text4 :=
                           l_text4
                        || 'Queue : '
                        || c.q_name
                        || ' has max delay of '
                        || c.time
                        || ' minutes on HIGH PRIORITY msg. - <br/>';
                    l_nr4 := l_nr4 + 1;
                END IF;
            ELSE
                IF l_nr3 = 0
                THEN
                    l_text3 :=
                           l_text3
                        || '<br/><b>WARNING for AM team : The following queue(s) have accumulated more than 5 minutes of max delay in msg treatment:</b><br/>';
                END IF;

                IF c.priority > 6
                THEN
                    l_text3 :=
                           l_text3
                        || 'Queue : '
                        || c.q_name
                        || ' has max delay of '
                        || c.time
                        || ' minutes on LOW PRIORITY msg. - <br/>';
                ELSE
                    l_text3 :=
                           l_text3
                        || 'Queue : '
                        || c.q_name
                        || ' has max delay of '
                        || c.time
                        || ' minutes on HIGH PRIORITY msg. - <br/>';
                END IF;

                l_nr3 := l_nr3 + 1;
            END IF;
        END IF;
    END LOOP;

    IF l_nr > 0
    THEN
        --TRD3_4_6
        p_html_pool := l_text || p_html_pool;
        p_to := p_to || ';' || l_mail_stex_fix;
        p_to := p_to || ';' || l_mail_msg_trd_3_4;
    END IF;

    IF l_nr2 > 0
    THEN
        --TRD1_2
        p_html_pool := l_text2 || p_html_pool;
        p_to := p_to || ';' || l_mail_msg_trd_1_2;
    END IF;

    IF l_nr3 > 0
    THEN
        --AM
        p_html_pool := l_text3 || p_html_pool;
    END IF;

    IF l_nr4 > 0
    THEN
        --AM
        p_html_pool := l_text4 || p_html_pool;
    END IF;

    write_query ('# of Queues with dequeue time > 5 min ',
                 TO_CHAR (l_nr + l_nr2 + l_nr3 + l_nr4),
                 '0',
                 c_major_p,
                 '=',
                 'long_dequeue_time');

    --same query without prio to avoid wrong alert issue on Blocked Queue Monitoring
    FOR c
        IN (  SELECT CASE
                         WHEN TO_CHAR (SYSTIMESTAMP, 'tzr') = '+01:00'
                         THEN
                             NVL (
                                     EXTRACT (
                                         DAY FROM   SYSDATE
                                                  - MIN (
                                                          enq_time
                                                        - INTERVAL '1' HOUR))
                                   * 24
                                   * 60
                                 +   EXTRACT (
                                         HOUR FROM   SYSDATE
                                                   - MIN (
                                                           enq_time
                                                         - INTERVAL '1' HOUR))
                                   * 60
                                 + EXTRACT (
                                       MINUTE FROM   SYSDATE
                                                   - MIN (
                                                           enq_time
                                                         - INTERVAL '1' HOUR)),
                                 0)
                         ELSE
                             NVL (
                                     EXTRACT (
                                         DAY FROM   SYSDATE
                                                  - MIN (
                                                          enq_time
                                                        - INTERVAL '1' HOUR))
                                   * 24
                                   * 60
                                 +   EXTRACT (
                                         HOUR FROM SYSDATE - MIN (enq_time))
                                   * 60
                                 + EXTRACT (
                                       MINUTE FROM SYSDATE - MIN (enq_time)),
                                 0)
                     END    AS time,
                     q_name
                FROM k.msg_in mi
               WHERE     deq_time IS NULL
                     AND q_NAME <> 'MSG_IN_SEQ_TRD_5'
                     AND mi.user_data.id <> 1311881401
            GROUP BY q_name)
    LOOP
        IF c.time > 5
        THEN
            FOR l_meta_msg
                IN (-- Bundles
                    SELECT waiting.*,
                           (SELECT COUNT (*)
                              FROM msg mei_sub, msg_in mi_sub
                             WHERE     mei_sub.msg_chunk_nr =
                                       mi_sub.user_data.id
                                   AND mi_sub.enq_time >
                                       TRUNC (SYSDATE) - 10
                                   AND mi_sub.deq_time >
                                       l_adpt_15_mins
                                   AND mi_sub.q_name =
                                       waiting.q_name
                                   AND mei_sub.meta_msg_id(+) =
                                       waiting.meta_msg_id
                                   AND mi_sub.priority =
                                       waiting.prio)                      cnt_prc_last_15,
                           (SELECT CASE
                                       WHEN TO_CHAR (SYSTIMESTAMP, 'tzr') =
                                            '+01:00'
                                       THEN
                                           TO_CHAR (
                                                 MAX (mi_sub.deq_time)
                                               - INTERVAL '1' HOUR,
                                               'HH24:MI:SS')
                                       ELSE
                                           TO_CHAR (MAX (mi_sub.deq_time),
                                                    'HH24:MI:SS')
                                   END
                              FROM msg mei_sub, msg_in mi_sub
                             WHERE     mei_sub.msg_chunk_nr =
                                       mi_sub.user_data.id
                                   AND mi_sub.enq_time > TRUNC (SYSDATE) - 10
                                   AND mi_sub.deq_time > l_adpt_15_mins
                                   AND mi_sub.q_name = waiting.q_name
                                   AND mei_sub.meta_msg_id(+) =
                                       waiting.meta_msg_id
                                   AND mi_sub.priority = waiting.prio)    LAST
                      FROM (  SELECT mi.q_name,
                                     mm.id           meta_msg_id,
                                     mm.intl_id      "META_MSG",
                                     mi.priority     prio,
                                     COUNT (*)       cnt_waiting
                                FROM msg m, msg_in mi, meta_msg mm
                               WHERE     m.msg_chunk_nr = mi.user_data.id
                                     AND mi.enq_time > TRUNC (SYSDATE) - 10
                                     AND mi.deq_time IS NULL
                                     AND mi.q_name = c.q_name
                                     AND mm.id(+) = m.meta_msg_id
                            GROUP BY mi.q_name,
                                     mm.id,
                                     mm.intl_id,
                                     mi.priority) waiting
                    UNION
                    --Messages
                    SELECT waiting.*,
                           (SELECT COUNT (*)     cnt_prc
                              FROM msg_extl_in  mei_sub,
                                   msg_in       mi_sub,
                                   meta_msg     mm
                             WHERE     mei_sub.id = mi_sub.user_data.id
                                   AND mm.id(+) = mei_sub.meta_msg_id
                                   AND mi_sub.enq_time BETWEEN   TRUNC (
                                                                     SYSDATE)
                                                               - 10
                                                           AND l_adpt_1_min -- not considering messages arrived less than one minute before
                                   AND mi_sub.deq_time > l_adpt_15_mins
                                   AND mi_sub.q_name = waiting.q_name
                                   AND COALESCE (mm.intl_id,
                                                 mei_sub.msg_type,
                                                 'NULL') =
                                       waiting.meta_msg
                                   AND mi_sub.priority = waiting.prio)
                               cnt_prc_last_15,
                           (SELECT CASE
                                       WHEN TO_CHAR (SYSTIMESTAMP, 'tzr') =
                                            '+01:00'
                                       THEN
                                           TO_CHAR (
                                                 MAX (mi_sub.deq_time)
                                               - INTERVAL '1' HOUR,
                                               'HH24:MI:SS')
                                       ELSE
                                           TO_CHAR (MAX (mi_sub.deq_time),
                                                    'HH24:MI:SS')
                                   END
                              FROM msg_extl_in  mei_sub,
                                   msg_in       mi_sub,
                                   meta_msg     mm
                             WHERE     mei_sub.id = mi_sub.user_data.id
                                   AND mm.id(+) = mei_sub.meta_msg_id
                                   AND mi_sub.enq_time > TRUNC (SYSDATE) - 10
                                   AND mi_sub.deq_time > l_adpt_15_mins
                                   AND mi_sub.q_name = waiting.q_name
                                   AND COALESCE (mm.intl_id,
                                                 mei_sub.msg_type,
                                                 'NULL') =
                                       waiting.meta_msg
                                   AND mi_sub.priority = waiting.prio)
                               LAST
                      FROM (  SELECT mi.q_name,
                                     mm.id                meta_msg_id,
                                     COALESCE (mm.intl_id,
                                               mei.msg_type,
                                               'NULL')    "META_MSG",
                                     mi.priority          prio,
                                     COUNT (*)            cnt_waiting
                                FROM msg_extl_in mei, msg_in mi, meta_msg mm
                               WHERE     mei.id = mi.user_data.id
                                     AND mi.enq_time > TRUNC (SYSDATE) - 10
                                     AND mi.deq_time IS NULL
                                     AND mi.q_name = c.q_name
                                     AND mm.id(+) = mei.meta_msg_id
                            GROUP BY mi.q_name,
                                     mm.id,
                                     COALESCE (mm.intl_id,
                                               mei.msg_type,
                                               'NULL'),
                                     mi.priority) waiting)
            LOOP
                l_array_cnt_waiting.EXTEND ();
                l_array_cnt_waiting (j) := l_meta_msg.cnt_waiting;
                l_array_last.EXTEND ();
                l_array_last (j) := l_meta_msg.LAST;
                l_array_cnt_prc_last_15.EXTEND ();
                l_array_cnt_prc_last_15 (j) := l_meta_msg.cnt_prc_last_15;
                l_array_cnt_prio.EXTEND ();
                l_array_cnt_prio (j) := l_meta_msg.prio;
                l_array_meta_msg2.EXTEND ();
                l_array_meta_msg2 (j) := l_meta_msg.meta_msg;

                IF     l_meta_msg.cnt_prc_last_15 = 0
                   AND l_meta_msg.cnt_waiting > 0
                THEN
                    l_cnt_error_msg_queue := l_cnt_error_msg_queue + 1;
                END IF;

                j := j + 1;
            END LOOP;

            IF l_cnt_error_msg_queue = j - 1 AND c.time >= 15
            THEN
                IF c.q_name IN ('MSG_IN_SVC_TRX')
                THEN
                    IF c.time < 6000
                    THEN
                        write_query (
                               'MSG Queue Blocked > 15 min: '
                            || c.q_name
                            || ' '
                            || c.time
                            || ' mins : ',
                            0,
                            0,
                            c_none_p,
                            '!=',
                            'msg_queue_blocked');
                    ELSE
                        write_query (
                               'MSG Queue Blocked > 15 min: '
                            || c.q_name
                            || ' '
                            || c.time
                            || ' mins : ',
                            0,
                            0,
                            c_blocking_p,
                            '!=',
                            'msg_queue_blocked');
                    END IF;
                ELSIF    c.q_name = 'MSG_IN_BDL_SEQ'
                      OR c.q_name = 'MSG_IN_BDL_PRL'
                THEN
                    write_query (
                           'MSG Queue Blocked > 15 min: '
                        || c.q_name
                        || ' '
                        || c.time
                        || ' mins : ',
                        0,
                        0,
                        c_blocking_p,
                        '!=',
                        'msg_queue_blocked');
                ELSE
                    write_query (
                           'MSG Queue Blocked > 15 min: '
                        || c.q_name
                        || ' '
                        || c.time
                        || ' mins : ',
                        0,
                        0,
                        c_sys_blocking_p,
                        '!=',
                        'msg_queue_blocked');

                    IF c.q_name IN ('MSG_IN_SEQ_TRD_1', 'MSG_IN_SEQ_TRD_2', 'MSG_IN_SEQ_TRD_3', 'MSG_IN_SEQ_TRD_4', 'MSG_IN_SEQ_TRD_6')
                    THEN
                        l_nr5 := 1; -- See below for p_html_pool and p_to change
                        l_text5 := c.q_name || ', ' || l_text5;
                    END IF;
                END IF;
            ELSIF l_cnt_error_msg_queue = j - 1
            THEN
                IF c.q_name IN ('MSG_IN_SVC_TRX')
                THEN
                    write_query (
                           'MSG Queue Blocked > 5 min: '
                        || c.q_name
                        || ' '
                        || c.time
                        || ' mins : ',
                        0,
                        0,
                        c_none_p,
                        '!=',
                        'msg_queue_blocked');
                ELSE
                    write_query (
                           'MSG Queue Blocked > 5 min: '
                        || c.q_name
                        || ' '
                        || c.time
                        || ' mins : ',
                        0,
                        0,
                        c_blocking_p,
                        '!=',
                        'msg_queue_blocked');
                END IF;
            ELSE
                IF c.q_name IN ('MSG_IN_SVC_TRX') AND c.time < 6000
                THEN
                    write_query (
                           'MSG Queue Delay: '
                        || c.q_name
                        || ' '
                        || c.time
                        || ' mins : ',
                        0,
                        0,
                        c_none_p,
                        '!=',
                        'msg_queue_blocked');
                ELSE
                    write_query (
                           'MSG Queue Delay: '
                        || c.q_name
                        || ' '
                        || c.time
                        || ' mins : ',
                        0,
                        0,
                        c_major_p,
                        '!=',
                        'msg_queue_blocked');
                END IF;
            END IF;

            FOR k IN 1 .. j - 1
            LOOP
                html_append (
                    write_msg (
                           '&nbsp;&nbsp;&nbsp;->'
                        || l_array_meta_msg2 (k)
                        || ' - prio:'
                        || l_array_cnt_prio (k)
                        || ' - in_wait:'
                        || l_array_cnt_waiting (k)
                        || ' - prc_15min:'
                        || l_array_cnt_prc_last_15 (k)
                        || ' - last:'
                        || l_array_last (k)));
            END LOOP;

            -- reset arrays and variables for next delayed/blocked queue
            l_array_cnt_waiting := array_cnt_waiting ();
            l_array_last := array_last ();
            l_array_cnt_prc_last_15 := array_cnt_prc_last_15 ();
            l_array_cnt_prio := array_cnt_prio ();
            l_array_meta_msg2 := array_meta_msg2 ();
            j := 1;
            l_cnt_error_msg_queue := 0;
        END IF;
    END LOOP;

    -- if MSG_IN_SEQ_TRD_X is sys blocking
    IF l_nr5 != 0
    THEN
        p_html_pool := '<br/><b>WARNING for TRADING team : The following queue(s) have accumulated more than 15 minutes of max delay in msg treatment:</b><br/>' || p_html_pool;
        l_text5 := RTRIM(l_text5, ', '); -- remove right trailling comma and space
        p_html_pool := l_text5 || '<br/>' || p_html_pool;
        p_to := p_to || ';' || l_mail_desk_multiasset || ';' || l_mail_support_trading;
    END IF;


    /*elsif is_pre then
                for c in ( select  case when  TO_CHAR(SYSTIMESTAMP, 'tzr') = '+01:00'
                            then nvl(extract( day from sysdate-min(enq_time - interval '1' hour) )*24*60 + extract( hour from sysdate-min(enq_time - interval '1' hour) )*60 + extract( minute from sysdate-min(enq_time - interval '1' hour) ) , 0)
                            else nvl(extract( day from sysdate-min(enq_time - interval '1' hour) )*24*60 + extract( hour from sysdate-min(enq_time))*60 + extract( minute from sysdate-min(enq_time)), 0)
                            end AS time,
                            q_name,
                            priority
                    from    k.msg_in
                    where      deq_time is null
                        and q_NAME <> 'MSG_IN_SEQ_TRD_5'
                        and state <> 1
                        and retry_count <> 1
                    group by q_name, priority)
        loop
            if c.time > 5 then

                if c.q_name in ('MSG_IN_SEQ_TRD_3', 'MSG_IN_SEQ_TRD_4', 'MSG_IN_SEQ_TRD_6') then

                    if l_nr = 0 then
                        l_text:= l_text|| '<br/><b>WARNING STEX FIX: The following queue(s) have accumulated more than 5 minutes of max delay in msg treatment:</b><br/>';
                    end if;

                    if c.priority > 6 then
                        l_text:= l_text||'Queue : ' || c.q_name || ' has max delay of ' || c.time || ' minutes on LOW PRIORITY msg ( market exec details ). - <br/>';
                    else
                        l_text:= l_text||'Queue : ' || c.q_name || ' has max delay of ' || c.time || ' minutes on HIGH PRIORITY msg ( client trades ). - <br/>';
                    end if;

                    l_nr :=  l_nr + 1;

                elsif c.q_name in ('MSG_IN_SEQ_TRD', 'MSG_IN_SEQ_TRD_2') then


                    if l_nr2 = 0 then
                        l_text2:= l_text2||'<br/><b>WARNING for MAD: The following queue(s) have accumulated more than 5 minutes of max delay in msg treatment:</b><br/>';
                    end if;

                    if c.priority > 6 then
                        l_text2:= l_text2||'Queue : ' || c.q_name || ' has max delay of ' || c.time || ' minutes on LOW PRIORITY msg. - <br/>';
                    else
                        l_text2:= l_text2||'Queue : ' || c.q_name || ' has max delay of ' || c.time || ' minutes on HIGH PRIORITY msg. - <br/>';
                    end if;

                    l_nr2 :=  l_nr2 + 1;

                else

                    if l_nr3 = 0 then
                        l_text3:= l_text3||'<br/><b>WARNING for AM team : The following queue(s) have accumulated more than 5 minutes of max delay in msg treatment:</b><br/>';
                    end if;

                    if c.priority > 6 then
                        l_text3:= l_text3||'Queue : ' || c.q_name || ' has max delay of ' || c.time || ' minutes on LOW PRIORITY msg. - <br/>';
                    else
                        l_text3:= l_text3||'Queue : ' || c.q_name || ' has max delay of ' || c.time || ' minutes on HIGH PRIORITY msg. - <br/>';
                    end if;

                    l_nr3 :=  l_nr3 + 1;

                end if;
            end if;
        end loop;

        if l_nr > 0 then
            --TRD3_4_6
            p_html_pool:= l_text || p_html_pool;
            p_to := p_to || ';' || l_mail_stex_fix;
            p_to := p_to || ';' || l_mail_msg_trd_3_4;

        end if;

        if l_nr2 > 0 then
            --TRD1_2
            p_html_pool:= l_text2 || p_html_pool;
            p_to := p_to || ';' || l_mail_msg_trd_1_2;
        end if;

        if l_nr3 > 0 then
            --AM
            p_html_pool:= l_text3 || p_html_pool;
        end if;

        write_query('# of Queues with dequeue time > 5 min ', to_char(l_nr+l_nr2+l_nr3), '0', c_major_p, '=', 'long_dequeue_time');

        --same query without prio to avoid wrong alert issue on Blocked Queue Monitoring
        for c in ( select  case when  TO_CHAR(SYSTIMESTAMP, 'tzr') = '+01:00'
                            then nvl(extract( day from sysdate-min(enq_time - interval '1' hour) )*24*60 + extract( hour from sysdate-min(enq_time - interval '1' hour) )*60 + extract( minute from sysdate-min(enq_time - interval '1' hour) ) , 0)
                            else nvl(extract( day from sysdate-min(enq_time - interval '1' hour) )*24*60 + extract( hour from sysdate-min(enq_time))*60 + extract( minute from sysdate-min(enq_time)), 0)
                            end AS time,
                            q_name
                    from    k.msg_in
                    where      deq_time is null
                        and q_NAME <> 'MSG_IN_SEQ_TRD_5'
                        and state <> 1
                        and retry_count <> 1
                    group by q_name)
        loop
            if c.time > 5 then
                for l_meta_msg in (
                    -- Bundles
                     select waiting.*,
                        (SELECT  count(*)
                            FROM    msg mei_sub, msg_in mi_sub
                            where   mei_sub.msg_chunk_nr = mi_sub.user_data.id
                                and mi_sub.enq_time > trunc(sysdate)-10
                                and mi_sub.deq_time > l_adpt_15_mins
                                and mi_sub.q_name = waiting.q_name
                                and mei_sub.meta_msg_id (+) = waiting.meta_msg_id
                                and mi_sub.priority = waiting.prio
                                and mi_sub.state <> 1
                                and mi_sub.retry_count <> 1
                          ) cnt_prc_last_15,
                        (SELECT  case when TO_CHAR(SYSTIMESTAMP, 'tzr') = '+01:00'
                                        then to_char(max(mi_sub.deq_time) - interval '1' hour, 'HH24:MI:SS')
                                        else to_char(max(mi_sub.deq_time), 'HH24:MI:SS')
                                    end
                            FROM    msg mei_sub, msg_in mi_sub
                            where   mei_sub.msg_chunk_nr = mi_sub.user_data.id
                                and mi_sub.enq_time > trunc(sysdate)-10
                                and mi_sub.deq_time > l_adpt_15_mins
                                and mi_sub.q_name = waiting.q_name
                                and mei_sub.meta_msg_id (+) = waiting.meta_msg_id
                                and mi_sub.priority = waiting.prio
                                and mi_sub.state <> 1
                                and mi_sub.retry_count <> 1
                          )  last
                    from (
                        SELECT  mi.q_name, mm.id meta_msg_id, mm.intl_id "META_MSG", mi.priority prio, count(*) cnt_waiting
                        FROM    msg m, msg_in mi, meta_msg mm
                        where   m.msg_chunk_nr = mi.user_data.id
                            and mi.enq_time > trunc(sysdate)-10
                            and mi.deq_time is null
                            and mi.q_name = c.q_name
                            and mm.id (+) = m.meta_msg_id
                            and mi.state <> 1
                            and mi.retry_count <> 1
                        group by mi.q_name, mm.id, mm.intl_id, mi.priority
                    )waiting
                    union
                    --Messages
                    select waiting.*,
                        (SELECT  count(*) cnt_prc
                            FROM    msg_extl_in mei_sub, msg_in mi_sub, meta_msg mm
                            where   mei_sub.id = mi_sub.user_data.id
                                and mm.id (+) = mei_sub.meta_msg_id
                                and mi_sub.enq_time between trunc(sysdate)-10 and sysdate -1/24/60 -- not considering messages arrived less than one minute before
                                and mi_sub.deq_time > l_adpt_15_mins
                                and mi_sub.q_name = waiting.q_name
                                and coalesce(mm.intl_id, mei_sub.msg_type, 'NULL') = waiting.meta_msg
                                and mi_sub.priority = waiting.prio
                                and mi_sub.state <> 1
                                and mi_sub.retry_count <> 1
                          ) cnt_prc_last_15
                          ,(
                        SELECT
                        case when TO_CHAR(SYSTIMESTAMP, 'tzr') = '+01:00'
                                        then to_char(max(mi_sub.deq_time) - interval '1' hour, 'HH24:MI:SS')
                                        else to_char(max(mi_sub.deq_time), 'HH24:MI:SS')
                                    end
                            FROM    msg_extl_in mei_sub, msg_in mi_sub, meta_msg mm
                            where   mei_sub.id = mi_sub.user_data.id
                                and mm.id (+) = mei_sub.meta_msg_id
                                and mi_sub.enq_time > trunc(sysdate)-10
                                and mi_sub.deq_time > l_adpt_15_mins
                                and mi_sub.q_name = waiting.q_name
                                and coalesce(mm.intl_id, mei_sub.msg_type, 'NULL') = waiting.meta_msg
                                and mi_sub.priority = waiting.prio
                                and mi_sub.state <> 1
                                and mi_sub.retry_count <> 1
                          ) last
                    from (
                         SELECT  mi.q_name, mm.id meta_msg_id, coalesce(mm.intl_id, mei.msg_type, 'NULL') "META_MSG", mi.priority prio, count(*) cnt_waiting
                        FROM    msg_extl_in mei, msg_in mi, meta_msg mm
                        where   mei.id = mi.user_data.id
                            and mi.enq_time > trunc(sysdate)-10
                            and mi.deq_time is null
                            and mi.q_name = c.q_name
                            and mm.id (+) = mei.meta_msg_id
                            and mi.state <> 1
                            and mi.retry_count <> 1
                        group by mi.q_name, mm.id, coalesce(mm.intl_id, mei.msg_type, 'NULL'), mi.priority
                    )waiting
                ) loop

                    l_array_cnt_waiting.extend();
                    l_array_cnt_waiting(j):= l_meta_msg.cnt_waiting;
                    l_array_last.extend();
                    l_array_last(j):= l_meta_msg.last;
                    l_array_cnt_prc_last_15.extend();
                    l_array_cnt_prc_last_15(j):= l_meta_msg.cnt_prc_last_15;
                    l_array_cnt_prio.extend();
                    l_array_cnt_prio(j):= l_meta_msg.prio;
                    l_array_meta_msg2.extend();
                    l_array_meta_msg2(j):= l_meta_msg.meta_msg;
                    if l_meta_msg.cnt_prc_last_15 = 0 and l_meta_msg.cnt_waiting > 0 then
                        l_cnt_error_msg_queue := l_cnt_error_msg_queue + 1;
                    end if;
                    j := j + 1;
                end loop;
                if l_cnt_error_msg_queue = j-1 and c.time >=15 then
                    write_query('MSG Queue Blocked > 15 min: ' || c.q_name || ' '  || c.time || ' mins : ', 0,0, c_sys_blocking_p,'!=','msg_queue_blocked');
                elsif l_cnt_error_msg_queue = j-1 then
                    write_query('MSG Queue Blocked > 5 min: ' || c.q_name || ' '  || c.time || ' mins : ', 0,0, c_blocking_p,'!=','msg_queue_blocked');
                else
                    write_query('MSG Queue Delay: ' || c.q_name || ' '  || c.time || ' mins : ', 0,0, c_major_p,'!=','msg_queue_blocked');
                end if;
                for k in 1 ..j-1 loop
                    html_append(write_msg('&nbsp;&nbsp;&nbsp;->' || l_array_meta_msg2(k) || ' - prio:'  || l_array_cnt_prio(k) || ' - in_wait:' || l_array_cnt_waiting(k) || ' - prc_15min:' || l_array_cnt_prc_last_15(k) || ' - last:' || l_array_last(k)));
                end loop;
                -- reset arrays and variables for next delayed/blocked queue
                l_array_cnt_waiting := array_cnt_waiting();
                l_array_last := array_last();
                l_array_cnt_prc_last_15 := array_cnt_prc_last_15();
                l_array_cnt_prio := array_cnt_prio();
                l_array_meta_msg2 := array_meta_msg2();
                j:=1;
                l_cnt_error_msg_queue := 0;
            end if;
        end loop;

    end if;

    */

    ---------------------------------
    --Summary:Checks if MaxDelay in MSG_IN_FIX_DOC_NEW is > 10 min
    --Author:ADRGUS
    --Date:08/04/2025
    ---------------------------------
    SELECT CASE
               WHEN COALESCE (EXTRACT (MINUTE FROM SYSDATE - MAX (enq_time)),
                              0) <
                    0
               THEN
                   COALESCE (
                           EXTRACT (
                               HOUR FROM   SYSDATE
                                         - MIN (enq_time - INTERVAL '1' HOUR))
                         * 60
                       + EXTRACT (
                             MINUTE FROM   SYSDATE
                                         - MIN (enq_time - INTERVAL '1' HOUR)),
                       0)
               ELSE
                   COALESCE (
                         EXTRACT (HOUR FROM SYSDATE - MIN (enq_time)) * 60
                       + EXTRACT (MINUTE FROM SYSDATE - MIN (enq_time)),
                       0)
           END
      INTO l_nr
      FROM k.msg_in
     WHERE     q_name = 'MSG_IN_FIX_DOC_NEW'
           AND enq_time > TRUNC (SYSDATE)
           AND deq_time IS NULL
           AND retry_count = 0;

    write_query ('MaxDelay in MSG_IN_FIX_DOC_NEW (in min)',
                 TO_CHAR (l_nr),
                 '10',
                 c_major_p,
                 '<=',
                 'msg_in_fix_doc_delay');

    -- Sending a warning to cbs transac if delay on queue above 10 min
    l_text := '';

    IF l_nr > 10
    THEN
        l_text :=
            '<br/><b>WARNING for CBS-Transaction TEAM : The following queue has accumulated more than 10 minutes of max delay in msg treatment:</b><br/>';
        l_text :=
               l_text
            || ' - Queue : MSG_IN_FIX_DOC_NEW has max delay of '
            || TO_CHAR (l_nr)
            || ' minutes <br/>';

        p_html_pool := l_text || p_html_pool;
        p_to := p_to || ';' || l_mail_cbs_transac;
    END IF;

    ---------------------------------
    --Summary:Checks if MaxDelay in MSG_IN_SWIFT_MT502 is > 10 min
    --Author:ADRGUS
    --Date:08/04/2025
    ---------------------------------
    SELECT CASE
               WHEN COALESCE (EXTRACT (MINUTE FROM SYSDATE - MAX (enq_time)),
                              0) <
                    0
               THEN
                   COALESCE (
                           EXTRACT (
                               HOUR FROM   SYSDATE
                                         - MIN (enq_time - INTERVAL '1' HOUR))
                         * 60
                       + EXTRACT (
                             MINUTE FROM   SYSDATE
                                         - MIN (enq_time - INTERVAL '1' HOUR)),
                       0)
               ELSE
                   COALESCE (
                         EXTRACT (HOUR FROM SYSDATE - MIN (enq_time)) * 60
                       + EXTRACT (MINUTE FROM SYSDATE - MIN (enq_time)),
                       0)
           END
      INTO l_nr
      FROM k.msg_in
     WHERE     q_name = 'MSG_IN_SWIFT_MT502'
           AND enq_time > TRUNC (SYSDATE)
           AND deq_time IS NULL
           AND retry_count = 0;

    write_query ('MaxDelay in MSG_IN_SWIFT_MT502 (in min)',
                 TO_CHAR (l_nr),
                 '10',
                 c_major_p,
                 '<=',
                 'msg_in_swift_mt502_delay');

    -- Sending a warning to cbs transac if delay on queue above 10 min
    l_text := '';

    IF l_nr > 10
    THEN
        l_text :=
            '<br/><b>WARNING for CBS-Transaction TEAM : The following queue has accumulated more than 10 minutes of max delay in msg treatment:</b><br/>';
        l_text :=
               l_text
            || ' - Queue : MSG_IN_SWIFT_MT502 has max delay of '
            || TO_CHAR (l_nr)
            || ' minutes <br/>';

        p_html_pool := l_text || p_html_pool;
        p_to := p_to || ';' || l_mail_cbs_transac;
    END IF;

    -- Msg that should be send (via a prcq 800 entry) but are not present in msg_extl_out
    -- this alert has been put in place since incident of 05/06/2019 where MT543 and MT541 where not send (prcq 800 entry not created) for unknown reason.
    IF     CURRENT_DATE >
           TO_DATE (TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 07:30',
                    'ddmmyyyy HH24:MI')
       AND CURRENT_DATE <
           TO_DATE (TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 19:00',
                    'ddmmyyyy HH24:MI')
       AND NOT is_weekend
    THEN
        l_nr := 0;
        l_text := '';

        FOR c
            IN (SELECT (SELECT name
                          FROM wfc_status
                         WHERE (meta_typ_id, id) =
                               (SELECT meta_typ_id, wfc_status_id
                                  FROM doc
                                 WHERE id = msg.doc_id))    doc_wfc_status,
                       (SELECT name
                          FROM meta_msg
                         WHERE id = meta_msg_id)            meta_msg_name,
                       (SELECT name
                          FROM code_msg_status
                         WHERE id = msg_status_id)          msg_status_name,
                       id                                   msg_id,
                       meta_msg_id,
                       dir,
                       netw_id,
                       timestamp,
                       msg_status_id,
                       send_date_plan,
                       bu_id,
                       doc_id
                  FROM msg
                 WHERE     timestamp > SYSDATE - INTERVAL '1' DAY
                       AND timestamp + INTERVAL '30' MINUTE < SYSDATE --msg inserted from at least 30min
                       AND dir = 'o'
                       AND netw_id = 6                                 --swift
                       AND send_date_plan < SYSDATE
                       AND rcv_bp_clear_nr != 'EBAPFRPA' --exclude SEPA INTERIM msg that are not send via SWIFT but throught file generation via JOB ISET021 BLLU SWIFT BDL FILEACT SEPA DIR PART CYCLE2
                       AND meta_msg_id NOT IN (1651, 1653) --swift_mt202, swift_mt210
                       AND msg_status_id NOT IN (1,            --Ready to send
                                                 3,             --Sent and Ack
                                                 20, --Message should not be sent out
                                                 10,               --discarded
                                                 -1)
                       AND (SELECT wfc_status_id
                              FROM doc
                             WHERE id = msg.doc_id) NOT IN (410, --410 # Ready for Verification
                                                            420,   --420 # Run
                                                            210, --210 # On hold
                                                            460, --460 # Rejected
                                                            465, --465 # Ready for Cancellation
                                                            710, --710 # Wait for aggregation
                                                            201, --201 # Replaced order
                                                            601, --601 # Waiting 4 Credit Check
                                                            820, --820 # Error Risk Client
                                                            -1)
                       AND NOT EXISTS
                               (SELECT *
                                  FROM prcq
                                 WHERE     id = msg.doc_id
                                       AND prcq_id = 879  --Book on value date
                                       AND timestamp_start IS NULL
                                       AND timestamp_prc IS NULL) -- exclude order where prcq book has not run yet
                       AND NOT EXISTS
                               (SELECT *
                                  FROM msg_extl_out o
                                 WHERE o.id = msg.id))
        LOOP
            IF l_nr = 0
            THEN
                l_text :=
                       l_text
                    || '<br/><b>WARNING AM TEAM: The following SWIFT out msg(s) were created at least 30 min ago and are NOT send :</b><br/>';
            END IF;

            l_nr := l_nr + 1;

            l_text :=
                   l_text
                || 'BU_ID : '
                || c.bu_id
                || ' , DOC_ID : '
                || c.doc_id
                || ' , DOC_STATUS : '
                || c.doc_wfc_status
                || ' , MSG_ID : '
                || c.msg_id
                || ' , MSG_STATUS : '
                || c.msg_status_name
                || ' , META_MSG : '
                || c.meta_msg_name
                || '.<br/>';

            IF c.bu_id = 11
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_btlu_dflt);
            END IF;
        END LOOP;

        IF l_nr > 0
        THEN
            p_html_pool := l_text || p_html_pool;
        END IF;

        write_query ('# of SWIFT out not send',
                     TO_CHAR (l_nr),
                     '0',
                     c_none_p,
                     '=',
                     'swift_out_not_send');
    END IF;



    DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_ATRX');

    --BGP 926
    IF cond_check_timeout_bgp926
    THEN
        check_timeout_bgp926;
    END IF;

    -- ATRX
    SELECT MAX (atrx_seq_nr) INTO l_ref_atrx_seq_nr FROM atrx;

    SELECT atrx#.atrx#to_atrx_seq_nr (3) INTO l_seq_nr FROM DUAL;

    write_query (
        'ATRX: be_evt',
        l_seq_nr,
           '['
        || TO_CHAR (l_ref_atrx_seq_nr - 30)
        || ';'
        || TO_CHAR (l_ref_atrx_seq_nr)
        || ']',
        c_major_p,
        'in',
        'atrx');

    SELECT atrx#.atrx#to_atrx_seq_nr (5) INTO l_seq_nr FROM DUAL;

    write_query (
        'ATRX: be_recalc',
        l_seq_nr,
           '['
        || TO_CHAR (l_ref_atrx_seq_nr - 1000)
        || ';'
        || TO_CHAR (l_ref_atrx_seq_nr)
        || ']',
        c_major_p,
        'in',
        'atrx');

    SELECT atrx#.atrx#to_atrx_seq_nr (20, 5) INTO l_seq_nr FROM DUAL;

    write_query (
        'ATRX: serpil_bbat',
        l_seq_nr,
           '['
        || TO_CHAR (l_ref_atrx_seq_nr - 300)
        || ';'
        || TO_CHAR (l_ref_atrx_seq_nr)
        || ']',
        c_major_p,
        'in',
        'atrx');

    SELECT atrx#.atrx#to_atrx_seq_nr (10, 5) INTO l_seq_nr FROM DUAL;

    write_query (
        'ATRX: serpil_realtime',
        l_seq_nr,
           '['
        || TO_CHAR (l_ref_atrx_seq_nr - 1000)
        || ';'
        || TO_CHAR (l_ref_atrx_seq_nr)
        || ']',
        c_major_p,
        'in',
        'atrx');

    SELECT atrx#.atrx#to_atrx_seq_nr (11, 5) INTO l_seq_nr FROM DUAL;

    write_query (
        'ATRX: serpil_curr',
        l_seq_nr,
           '['
        || TO_CHAR (l_ref_atrx_seq_nr - 300)
        || ';'
        || TO_CHAR (l_ref_atrx_seq_nr)
        || ']',
        c_major_p,
        'in',
        'atrx');

    SELECT atrx#.atrx#to_atrx_seq_nr (12, 5) INTO l_seq_nr FROM DUAL;

    write_query (
        'ATRX: serpil_hist',
        l_seq_nr,
           '['
        || TO_CHAR (l_ref_atrx_seq_nr - 4000)
        || ';'
        || TO_CHAR (l_ref_atrx_seq_nr)
        || ']',
        c_major_p,
        'in',
        'atrx');

    SELECT atrx#.atrx#to_atrx_seq_nr (26, 5) INTO l_seq_nr FROM DUAL;

    write_query (
        'ATRX: pos_serpil_hist',
        l_seq_nr,
           '['
        || TO_CHAR (l_ref_atrx_seq_nr - 1000)
        || ';'
        || TO_CHAR (l_ref_atrx_seq_nr)
        || ']',
        c_major_p,
        'in',
        'atrx');

    FOR c
        IN (  SELECT severity,
                     subscr,
                     delay_dur,
                     ROUND (
                           EXTRACT (DAY FROM (delay_dur)) * 86400
                         + EXTRACT (HOUR FROM (delay_dur)) * 3600
                         + EXTRACT (MINUTE FROM (delay_dur)) * 60
                         + EXTRACT (SECOND FROM (delay_dur)))    delay_dur_seconds
                FROM be_moni_atrx_subscr_v
               WHERE     delay_dur > NUMTODSINTERVAL (1, 'HOUR')
                     AND (sub IS NULL OR sub NOT LIKE '%task_afs_trans_evt%')
            ORDER BY severity, delay_dur DESC)
    LOOP
        l_interval_count := 24;

        --Alert should trigger on subscr with delay > 24 hours
        --special cases for these two, we get the hours since the last execution of the item during system reorg (garbcol) + 7 days (168 hourz) + 1 hour (acceptance window, because the timing in not precise)
        --if system reorg is running interval_count will keep on growing and no alert will trigger, we cap it at 10 days (240 hours) here
        IF    UPPER (c.subscr) LIKE UPPER ('atrx_baseline')
           OR UPPER (c.subscr) LIKE UPPER ('be_evt_version')
        THEN
            SELECT LEAST (
                       GREATEST (
                           l_interval_count,
                               EXTRACT (
                                   DAY FROM (SYSDATE - MAX (start_time)))
                             * 24
                           + EXTRACT (HOUR FROM (SYSDATE - MAX (start_time)))
                           +   EXTRACT (
                                   MINUTE FROM (SYSDATE - MAX (start_time)))
                             / 60
                           + 168
                           + 1),
                       240)
              INTO l_interval_count
              FROM k.GARBCOL_ITEM_RUN g
             WHERE garbcol_item_id IN (21)                     --atrx#.garbcol
                                           AND garbcol_status_id = 3; --Processed
        END IF;

        --special cases for these two, we get the hours since the last execution of the item during system reorg (garbcol) + 1 hour (acceptance window, because the timing in not precise)
        --if system reorg is running interval_count will keep on growing and no alert will trigger, we cap it at 3 days (72 hours) here
        --post 4.9 upgrade: changed behavior, not all backlog is cleaned during garbcol (might be due to pending pillar adjust or to backlog on aging part of garbcol or simply changed behaviour)
        --27.11.2020 -> adding additional 25 hours to acceptable backlog
        --14.12.2020 -> adding additional 24 hours to acceptable backlog
        --05.04.2022 -> adding additional 30 hours + cap at 4 days (96 hours)
        IF UPPER (c.subscr) LIKE UPPER ('serpil_garbcol')
        THEN
            SELECT LEAST (
                       GREATEST (
                           l_interval_count,
                               EXTRACT (
                                   DAY FROM (SYSDATE - MAX (start_time)))
                             * 24
                           + EXTRACT (HOUR FROM (SYSDATE - MAX (start_time)))
                           +   EXTRACT (
                                   MINUTE FROM (SYSDATE - MAX (start_time)))
                             / 60
                           + 80),
                       96)
              INTO l_interval_count
              FROM k.GARBCOL_ITEM_RUN g
             WHERE garbcol_item_id IN (19)                   --serpil#.garbcol
                                           AND garbcol_status_id = 3; --Processed
        END IF;

        IF UPPER (c.subscr) LIKE UPPER ('be_aud_log')
        THEN
            SELECT LEAST (
                       GREATEST (
                           l_interval_count,
                               EXTRACT (
                                   DAY FROM (SYSDATE - MAX (start_time)))
                             * 24
                           + EXTRACT (HOUR FROM (SYSDATE - MAX (start_time)))
                           +   EXTRACT (
                                   MINUTE FROM (SYSDATE - MAX (start_time)))
                             / 60
                           + 1),
                       72)
              INTO l_interval_count
              FROM k.GARBCOL_ITEM_RUN g
             WHERE garbcol_item_id IN (20)                       --be#.garbcol
                                           AND garbcol_status_id = 3; --Processed
        END IF;

        write_query ('ATRX: ' || c.subscr || ' ' || c.severity,
                     c.delay_dur_seconds,
                     interval_to_seconds (l_interval_count, 'HOUR'),
                     c_major_p,
                     '<',
                     'atrx_monitor');
    END LOOP;


    ---------
    --START SECTION SYSTEM
    ---------
    write_header ('System checks', c_severity_sys_ph);
    g_active_section := c_section_sys;

    --sub section GENERAL INFO
    write_subheader ('General Info');

    ---------------------------------
    --Check if any obj_id under 20 is not a Business Unit
    ---------------------------------
    BEGIN
        SELECT COUNT (*)
          INTO l_obj_not_bu_count
          FROM obj
         WHERE     id < 20
               AND id NOT IN (SELECT obj_id FROM obj_bp_bu)
               AND id NOT IN (0,
                              12,
                              13,
                              14);

        IF l_obj_not_bu_count > 0
        THEN
            FOR ent IN (SELECT *
                          FROM obj
                         WHERE     id < 20
                               AND id NOT IN (SELECT obj_id FROM obj_bp_bu)
                               AND id NOT IN (0,
                                              12,
                                              13,
                                              14))
            LOOP
                l_obj_not_bu := l_obj_not_bu || 'OBJ_ID: ' || ent.id || '; ';
            END LOOP;
        END IF;
    END;

    write_query ('BU ID claimed',
                 l_obj_not_bu_count,
                 '0',
                 c_sys_blocking_p,
                 '=',
                 'bu_id_claimed');

    --Check if any BU is in error
    DBMS_APPLICATION_INFO.SET_ACTION ('STANDARD_CHECK_1');

    DECLARE
        l_nr        NUMBER;
        l_bu_list   VARCHAR2 (250);
    BEGIN
        IF l_execution_time <
           TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:40',
                    'ddmmyyyy HH24:MI')
        THEN
            SELECT COUNT (*)
              INTO l_nr
              FROM base
             WHERE eod_err IS NOT NULL;

            write_query ('BU EOD Error',
                         l_nr,
                         '0',
                         c_blocking_p,
                         '=',
                         'bu_eod_err');
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            write_query ('BU EOD Error',
                         1,
                         '0',
                         c_blocking_p,
                         '=',
                         'bu_eod_err'); -- OOOOOOOOOOOOOOPS: append || sqlerrm;
    END;

    --Is prod
    SELECT val
      INTO l_text
      FROM k.base_par_item_all_v
     WHERE     intl_id = 'is_prod'
           AND base_par_id = (SELECT DISTINCT id
                                FROM base_par
                               WHERE intl_id = 'avq.instn');

    IF l_db_name LIKE 'AVALIV%'
    THEN
        write_query ('Base param : is_prod',
                     l_text,
                     '+',
                     c_sys_blocking_p,
                     '=',
                     'bp_is_prod');
    ELSE
        write_query ('Base param : is_prod',
                     l_text,
                     '-',
                     c_sys_blocking_p,
                     '=',
                     'bp_is_prod');
    END IF;

    --Prod list
    SELECT NVL (val, 'NULL')
      INTO l_text
      FROM k.base_par_item_all_v
     WHERE intl_id = 'prod_list';

    IF l_db_name LIKE 'AVALIV%'
    THEN
        write_query ('Base param : prod_list',
                     l_text,
                     'avaliv',
                     c_sys_blocking_p,
                     '=',
                     'bp_prod_list');
    ELSE
        write_query ('Base param : prod_list',
                     l_text,
                     'NULL',
                     c_sys_blocking_p,
                     '=',
                     'bp_prod_list');
    END IF;

    --BBAT
    SELECT val
      INTO l_text
      FROM k.base_par_item_all_v
     WHERE intl_id = 'calc_bbat_serpil';

    write_query ('Base Param : Calc BBAT Serpil',
                 l_text,
                 '+',
                 c_sys_blocking_p,
                 '=',
                 'bp_calc_bbat_serpil');

    --date override
    SELECT NVL (val, 'NULL')
      INTO l_text
      FROM k.base_par_item_all_v
     WHERE intl_id = 'bank_date_ovr';

    write_query ('Base Param : Bank date override',
                 l_text,
                 'NULL',
                 c_sys_blocking_p,
                 '=',
                 'bp_bank_date_ovr');

    --docsdisplay_url
    DECLARE
        CURSOR c3 IS
            SELECT SUBSTR (val, 1, 30) val, NVL (bu_id, -1) bu
              FROM k.base_par_item_all_v
             WHERE intl_id = 'docsdisplay_url';
    BEGIN
        FOR rec3 IN c3
        LOOP
            IF l_db_name LIKE 'AVALIV%'
            THEN
                IF rec3.bu = 3
                THEN
                    write_query ('Base Param : Docsdisplay URL (3)',
                                 rec3.val,
                                 'https://docsdisplay.bllu.prd.a',
                                 c_sys_blocking_p,
                                 '=',
                                 'docsdisplay');
                ELSIF rec3.bu = 7
                THEN
                    write_query ('Base Param : Docsdisplay URL (7)',
                                 rec3.val,
                                 'https://docsdisplay.blbe.prd.a',
                                 c_sys_blocking_p,
                                 '=',
                                 'docsdisplay');
                ELSIF rec3.bu = 8
                THEN
                    write_query ('Base Param : Docsdisplay URL (8)',
                                 rec3.val,
                                 'https://docsdisplay.cisg.prd.a',
                                 c_sys_blocking_p,
                                 '=',
                                 'docsdisplay');
                ELSIF rec3.bu = 10
                THEN
                    write_query ('Base Param : Docsdisplay URL (10)',
                                 rec3.val,
                                 'https://docsdisplay.btbe.prd.a',
                                 c_sys_blocking_p,
                                 '=',
                                 'docsdisplay');
                ELSIF rec3.bu = 11
                THEN
                    write_query ('Base Param : Docsdisplay URL (11)',
                                 rec3.val,
                                 'https://docsdisplay.btlu.prd.a',
                                 c_sys_blocking_p,
                                 '=',
                                 'docsdisplay');
                END IF;
            ELSIF l_db_name LIKE 'AVAPRE%' or l_db_name like 'AVAMICC%'
            THEN
                IF rec3.bu = 3
                THEN
                    write_query ('Base Param : Docsdisplay URL (3)',
                                 rec3.val,
                                 'https://docsdisplay.bllu.pre.a',
                                 c_sys_blocking_p,
                                 '=',
                                 'docsdisplay');
                ELSIF rec3.bu = 7
                THEN
                    write_query ('Base Param : Docsdisplay URL (7)',
                                 rec3.val,
                                 'https://docsdisplay.blbe.pre.a',
                                 c_sys_blocking_p,
                                 '=',
                                 'docsdisplay');
                ELSIF rec3.bu = 8
                THEN
                    write_query ('Base Param : Docsdisplay URL (8)',
                                 rec3.val,
                                 'https://docsdisplay.cisg.pre.a',
                                 c_sys_blocking_p,
                                 '=',
                                 'docsdisplay');
                ELSIF rec3.bu = 10
                THEN
                    write_query ('Base Param : Docsdisplay URL (10)',
                                 rec3.val,
                                 'https://docsdisplay.btbe.pre.a',
                                 c_sys_blocking_p,
                                 '=',
                                 'docsdisplay');
                ELSIF rec3.bu = 11
                THEN
                    write_query ('Base Param : Docsdisplay URL (11)',
                                 rec3.val,
                                 'https://docsdisplay.btlu.pre.a',
                                 c_sys_blocking_p,
                                 '=',
                                 'docsdisplay');
                END IF;
            END IF;
        END LOOP;
    END;

    DBMS_APPLICATION_INFO.SET_ACTION ('STANDARD_CHECK_2');

    --l_country_day_off
    SELECT COUNT (*)
      INTO l_nr
      FROM (SELECT DISTINCT country_id, day
              FROM obj_bp_bu bu, obj_bp bp, country_day_off d
             WHERE     bu.obj_id = bp.obj_id
                   AND d.country_id = bp.country_domi_id
                   AND d.day > TRUNC (SYSDATE)
                   AND ((is_bank_day = '-') OR (is_bank_day IS NULL))
                   AND EXISTS
                           ( (SELECT DISTINCT bu2.obj_id
                                FROM obj_bp_bu bu2)
                            MINUS
                            (SELECT DISTINCT bu1.obj_id
                               FROM obj_bp_bu        bu1,
                                    obj_bp           bp1,
                                    country_day_off  d1
                              WHERE     bu1.obj_id = bp1.obj_id
                                    AND bp1.country_domi_id = d1.country_id
                                    AND d1.day = d.day
                                    AND (   d1.is_bank_day IS NULL
                                         OR d1.is_bank_day = '-'))));

    write_query ('Country Day Off',
                 TO_CHAR (l_nr),
                 TO_CHAR (l_nr),
                 c_major_p,
                 '=',
                 'country_day_off');

    DECLARE
        CURSOR c2 IS
              SELECT country, COUNT (*) tot
                FROM (SELECT DISTINCT
                             (SELECT name
                                FROM obj_name_intl n
                               WHERE n.obj_id = d.country_id)    country,
                             d.day
                        FROM obj_bp_bu bu, obj_bp bp, country_day_off d
                       WHERE     bu.obj_id = bp.obj_id
                             AND d.country_id = bp.country_domi_id
                             AND d.day > TRUNC (SYSDATE)
                             AND ((is_bank_day = '-') OR (is_bank_day IS NULL))
                             AND EXISTS
                                     ( (SELECT DISTINCT bu2.obj_id
                                          FROM obj_bp_bu bu2)
                                      MINUS
                                      (SELECT DISTINCT bu1.obj_id
                                         FROM obj_bp_bu      bu1,
                                              obj_bp         bp1,
                                              country_day_off d1
                                        WHERE     bu1.obj_id = bp1.obj_id
                                              AND bp1.country_domi_id =
                                                  d1.country_id
                                              AND d1.day = d.day
                                              AND (   d1.is_bank_day IS NULL
                                                   OR d1.is_bank_day = '-'))))
            GROUP BY country
            ORDER BY country;

        CURSOR c3 IS
              SELECT country, MIN (day) d
                FROM (SELECT DISTINCT
                             (SELECT name
                                FROM obj_name_intl n
                               WHERE n.obj_id = d.country_id)    country,
                             d.day
                        FROM obj_bp_bu bu, obj_bp bp, country_day_off d
                       WHERE     bu.obj_id = bp.obj_id
                             AND d.country_id = bp.country_domi_id
                             AND d.day > TRUNC (SYSDATE)
                             AND ((is_bank_day = '-') OR (is_bank_day IS NULL))
                             AND EXISTS
                                     ( (SELECT DISTINCT bu2.obj_id
                                          FROM obj_bp_bu bu2)
                                      MINUS
                                      (SELECT DISTINCT bu1.obj_id
                                         FROM obj_bp_bu      bu1,
                                              obj_bp         bp1,
                                              country_day_off d1
                                        WHERE     bu1.obj_id = bp1.obj_id
                                              AND bp1.country_domi_id =
                                                  d1.country_id
                                              AND d1.day = d.day
                                              AND (   d1.is_bank_day IS NULL
                                                   OR d1.is_bank_day = '-'))))
            GROUP BY country
            ORDER BY d;
    BEGIN
        l_text := '';
        l_nr := c_major_p;

        FOR rec3 IN c3
        LOOP
            IF c3%ROWCOUNT = 1
            THEN
                l_text :=
                    '<b>WARNING : Business Units will meet problem on Bank Day Switch :</b><br/>';
            END IF;

            IF rec3.d < SYSDATE - 10
            THEN
                l_nr := c_blocking_p;
            END IF;

            l_text :=
                   l_text
                || 'On '
                || TO_CHAR (rec3.d, 'dd/MON/yyyy')
                || ' for '
                || rec3.country
                || '<br/>';
        END LOOP;

        p_html_prepool := l_text || '<br/>' || p_html_prepool;

        FOR rec2 IN c2
        LOOP
            --write_query('-> '||rec2.country, to_char(rec2.tot),0, l_nr);
            write_query ('-> ' || rec2.country,
                         TO_CHAR (rec2.tot),
                         TO_CHAR (rec2.tot),
                         l_nr);
        END LOOP;
    END;

    --Compare country day off with euroland -- added 21/05/2013

    DECLARE
        l_less_than_2_weeks   BOOLEAN := FALSE;
    BEGIN
        l_nr := 0;
        l_text := '';
        l_text2 := '';

        --BU off but not euroland
         FOR l_ent
            IN (  SELECT DISTINCT
                         (SELECT k.nc$sec_qry#.nc$get_obj (country_id)
                            FROM DUAL)   country,
                         c2.day
                    FROM country_day_off c2, obj_bp_bu bu, obj_bp bp
                   WHERE     c2.country_id = bp.country_domi_id
                         AND bp.obj_id = bu.obj_id
                         AND bp.ref_curry_id = 2549
                         AND c2.day NOT IN (SELECT day
                                              FROM country_day_off c
                                             WHERE c.country_id = 2103)
                         AND day > TRUNC (SYSDATE)
                ORDER BY 2, 1)
         LOOP
            IF l_ent.day > SYSDATE - 1 AND l_ent.day < SYSDATE + 14
            THEN
                l_less_than_2_weeks := TRUE;
            END IF;

            l_nr := l_nr + 1;

            IF l_nr < 21
            THEN
                l_text :=
                       l_text
                    || l_ent.country
                    || '('
                    || l_ent.day
                    || ')'
                    || '; ';
                l_text2 :=
                       l_text2
                    || l_ent.country
                    || '('
                    || l_ent.day
                    || ')'
                    || '<br/> ';
            END IF;
        END LOOP;

        IF l_nr > 0
        THEN
            IF l_less_than_2_weeks
            THEN
                --warning and blocking
                write_query ('Country Day Off - BU but not Euro',
                             l_nr,
                             0,
                             c_blocking_p,
                             '=',
                             'country_day_off_bu_not_euro');
                l_text2 :=
                       '<b>WARNING for AM : Country Day Off - BU but not Euro :</b><br/>'
                    || l_text2;
                p_html_prepool := l_text2 || '<br/>' || p_html_prepool;
            ELSE
                --only major
                write_query ('Country Day Off - BU but not Euro',
                             l_nr,
                             0,
                             c_major_p,
                             '=',
                             'country_day_off_bu_not_euro');
                l_text2 :=
                       '<b>WARNING for AM : Country Day Off - BU but not Euro :</b><br/>'
                    || l_text2;
                p_html_prepool := l_text2 || '<br/>' || p_html_prepool;
            END IF;

            IF is_prod
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_exploit);
                p_to := upsert_mails (p_to, ';', l_mail_operateurs);
            END IF;
        END IF;
    END;

    DBMS_APPLICATION_INFO.SET_ACTION ('STANDARD_CHECK_3');

    DECLARE
        l_less_than_2_weeks   BOOLEAN := FALSE;
    BEGIN
        l_nr := 0;
        l_text := '';
        l_text2 := '';

        --euroland off but not BU
        FOR l_ent
            IN (  SELECT DISTINCT
                         (SELECT name
                            FROM obj_name_intl
                           WHERE obj_id = bp2.country_domi_id)    country,
                         c2.day
                    FROM country_day_off c2, obj_bp_bu bu2, obj_bp bp2
                   WHERE     c2.country_id = 2103
                         AND (c2.day, bu2.obj_id) NOT IN
                                 (SELECT c.day, bu.obj_id
                                    FROM country_day_off c,
                                         obj_bp_bu      bu,
                                         obj_bp         bp
                                   WHERE     c.country_id = bp.country_domi_id
                                         AND bp.obj_id = bu.obj_id
                                         AND bp.ref_curry_id = 2549)
                         AND bp2.ref_curry_id = 2549
                         AND bu2.obj_id = bp2.obj_id
                         AND day > TRUNC (SYSDATE)
                ORDER BY 2, 1)
        LOOP
            IF l_ent.day > SYSDATE - 1 AND l_ent.day < SYSDATE + 14
            THEN
                l_less_than_2_weeks := TRUE;
            END IF;

            l_nr := l_nr + 1;

            IF l_nr < 21
            THEN
                l_text :=
                       l_text
                    || l_ent.country
                    || '('
                    || l_ent.day
                    || ')'
                    || '; ';
                l_text2 :=
                       l_text2
                    || l_ent.country
                    || '('
                    || l_ent.day
                    || ')'
                    || '<br/> ';
            END IF;
        END LOOP;

        IF l_nr > 0
        THEN
            IF l_less_than_2_weeks
            THEN
                --warning and blocking
                write_query ('Country Day Off - Euro but not BU',
                             l_nr,
                             0,
                             c_blocking_p,
                             '=',
                             'country_day_off_euro_not_bu');
                l_text2 :=
                       '<b>WARNING for AM : Country Day Off - Euro but not BU :</b><br/>'
                    || l_text2;
                p_html_prepool := l_text2 || '<br/>' || p_html_prepool;
            ELSE
                --only major
                write_query ('Country Day Off - Euro but not BU',
                             l_nr,
                             0,
                             c_major_p,
                             '=',
                             'country_day_off_euro_not_bu');
                l_text2 :=
                       '<b>WARNING for AM : Country Day Off - Euro but not BU :</b><br/>'
                    || l_text2;
                p_html_prepool := l_text2 || '<br/>' || p_html_prepool;
            END IF;

            IF is_prod
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_exploit);
                p_to := upsert_mails (p_to, ';', l_mail_operateurs);
            END IF;
        END IF;
    END;


    DBMS_APPLICATION_INFO.SET_ACTION ('STANDARD_CHECK_5');

    --Check request from Michael D. and Jordan P., because of a problem on the mobile app where a calendar value was missing ( mail from 2018.12.17).
    --Cards calendar from SIX, defines monthly period and related account debit date.
    SELECT COUNT (*)
      INTO l_nr
      FROM nc$card_caldr c, nc$card_caldr before, nc$card_caldr after
     WHERE     c.SOP <= TRUNC (SYSDATE)
           AND TRUNC (SYSDATE) <= c.EOP                       --period current
           AND c.SOP - 1 = before.EOP                         -- period before
           AND c.EOP + 1 = after.SOP                           -- period after
           AND c.SOP IS NOT NULL
           AND c.EOP IS NOT NULL
           AND c.debit_date IS NOT NULL
           AND c.SOP < c.EOP
           AND c.EOP < c.debit_date
           AND c.debit_date - c.EOP BETWEEN 9 AND 13 --should be 12 days but in case of bank holiday in the period, can be 9 or 13 days.
           AND before.SOP IS NOT NULL
           AND before.EOP IS NOT NULL
           AND before.debit_date IS NOT NULL
           AND before.SOP < before.EOP
           AND before.EOP < before.debit_date
           AND before.debit_date - before.EOP BETWEEN 9 AND 13 --should be 12 days but in case of bank holiday in the period, can be 9 or 13 days.
           AND after.SOP IS NOT NULL
           AND after.EOP IS NOT NULL
           AND after.debit_date IS NOT NULL
           AND after.SOP < after.EOP
           AND after.EOP < after.debit_date
           AND after.debit_date - after.EOP BETWEEN 9 AND 13; --should be 12 days but in case of bank holiday in the period, can be 9 or 13 days.

    IF l_nr < 1
    THEN
        p_to := p_to || ';' || l_mail_exploit || ';' || l_mail_mobile;
        p_html_pool :=
               '<br/><b>WARNING for EXPLOIT AND MOBILE TEAM : Cards SIX calendar is missing informations.</b><br/>'
            || p_html_pool;

        IF is_prod
        THEN
            p_to := upsert_mails (p_to, ';', l_mail_exploit);
            p_to := upsert_mails (p_to, ';', l_mail_operateurs);
        END IF;
    END IF;

    write_query ('Cards Calendar (SIX)',
                 TO_CHAR (l_nr),
                 '1',
                 c_major_p,
                 '=',
                 'cards_calendar');



    --Session max
    SELECT VALUE
      INTO l_text
      FROM v$parameter
     WHERE name = 'processes';

    write_query ('Max session number',
                 l_text,
                 '2000',
                 c_major_p,
                 '>=',
                 'max_session');


    -- Oracle invalids
    SELECT COUNT (*)
      INTO l_text
      FROM dba_objects
     WHERE     status = 'INVALID'
           AND object_name NOT LIKE '%MDB$TM%'
           AND object_name NOT LIKE 'TM%'
           AND owner NOT IN ('ORBIUMTM', 'OPS$ORBTMTECH');

    write_query ('Oracle invalids',
                 l_text,
                 '0',
                 c_sys_blocking_p,
                 '=',
                 'inv_ora');

    -- Avaloq invalids
    SELECT COUNT (*)
      INTO l_text
      FROM k.src
     WHERE     (src_status_id NOT IN (1, 5) OR src_action_err IS NOT NULL)
           AND name NOT LIKE '%MDB$TM%'
           AND name NOT LIKE 'CRED2';

    write_query ('Avaloq invalids',
                 l_text,
                 '0',
                 c_sys_blocking_p,
                 '=',
                 'inv_ava');

    -- Rules invalids
    SELECT COUNT (fail)
      INTO l_text
      FROM (SELECT fail
              FROM (  SELECT rule_ld_id,
                             stmt,
                             MAX (timestamp)
                                 KEEP (DENSE_RANK LAST ORDER BY timestamp)
                                 timestamp,
                             MAX (fail)
                                 KEEP (DENSE_RANK LAST ORDER BY timestamp)
                                 fail
                        FROM rule_ld_log
                    GROUP BY rule_ld_id, stmt) s
             WHERE s.timestamp < SYSDATE - 1 / 24 / 6);

    write_query ('Rules invalids',
                 l_text,
                 '0',
                 c_sys_blocking_p,
                 '=',
                 'inv_rule');

    -- TM invalids
    SELECT COUNT (*)
      INTO l_text
      FROM avq_inv_v
     WHERE name LIKE '%MDB$TM%' AND name NOT LIKE '%MDB$TM_AVQFUNC%';

    write_query ('TM invalids',
                 l_text,
                 '0',
                 c_none_p,
                 '=',
                 'none');

    -- Today Installed changes
    SELECT COUNT (*)
      INTO l_text
      FROM x.install_chg_v
     WHERE timestp >= TRUNC (SYSDATE);

    -- test if this the first execution of the day (before 7h35)
    IF l_execution_time <
       TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:40',
                'ddmmyyyy HH24:MI')
    THEN
        write_query ('Installed changes',
                     l_text,
                     '0',
                     c_major_p,
                     '=',
                     'inst_changes');
    ELSE
        write_query ('Installed changes',
                     l_text,
                     '0',
                     c_none_p,
                     '=',
                     'inst_changes');
    END IF;

    -- Today install logs
    SELECT COUNT (*)
      INTO l_text
      FROM k.install_log
     WHERE     time_stamp >= TRUNC (SYSDATE)
           AND text NOT LIKE '-------------%'
           AND LOWER (text) NOT LIKE '%virtual user%'
           AND text NOT LIKE '%script stopping and starting web BGPs'
           AND text NOT LIKE 'TOTAL RULES LOADED%'
           AND text NOT LIKE '=========================%'
           AND text NOT LIKE 'KPI-RULE-LOADING%'
           AND text NOT LIKE '            FAILED%'
           AND text NOT LIKE ''
           AND text NOT LIKE 'RULE LOADING STATISTIC%'
           AND text NOT LIKE
                   'OK:      BASE_PARAM SET ''avq.ctx_action''.''calc_global_order_by'':= ''%';

    write_query ('Install logs',
                 l_text,
                 '0',
                 c_major_p,
                 '=',
                 'install_logs');

    -- Today compilation
    SELECT COUNT (*)
      INTO l_text
      FROM src_action
     WHERE src_action_start > l_timestamp;

    write_query ('Src. action (' || l_timecheck || ')',
                 l_text,
                 '0',
                 c_blocking_p,
                 '=',
                 'src_action');


    -- Today transactional orders
    SELECT COUNT (*)
      INTO l_text
      FROM k.doc d
     WHERE     timestamp >= TRUNC (SYSDATE)
           AND meta_typ_id < 100
           AND d.aging_id IN
                   (SELECT id
                      FROM k.aging
                     WHERE     aging_entity_id = 9
                           AND aging_status_id = 20
                           AND (   (    TO_CHAR (period_start, 'YYYY') >=
                                        TO_CHAR (SYSDATE, 'YYYY')
                                    AND TO_CHAR (period_start, 'MM') >=
                                        TO_CHAR (SYSDATE, 'MM'))
                                OR (    period_start IS NULL
                                    AND period_end IS NULL)));

    write_query ('Orders with booking',
                 l_text,
                 '60000',
                 c_none_p,
                 '<=',
                 'doc_with_booking');

    -- Today data orders
    SELECT COUNT (*)
      INTO l_text
      FROM k.doc d
     WHERE     timestamp >= TRUNC (SYSDATE)
           AND meta_typ_id > 100
           AND d.aging_id IN
                   (SELECT id
                      FROM k.aging
                     WHERE     aging_entity_id = 9
                           AND aging_status_id = 20
                           AND (   (    TO_CHAR (period_start, 'YYYY') >=
                                        TO_CHAR (SYSDATE, 'YYYY')
                                    AND TO_CHAR (period_start, 'MM') >=
                                        TO_CHAR (SYSDATE, 'MM'))
                                OR (    period_start IS NULL
                                    AND period_end IS NULL)));

    write_query ('Orders w/o booking',
                 l_text,
                 '25000',
                 c_none_p,
                 '<=',
                 'doc_without_booking');

    -- Today logs
    SELECT COUNT (*)
      INTO l_count
      FROM (  SELECT s.id, COUNT (*) tot
                FROM k.LOG l, k.sec_user s
               WHERE     l.timestamp >
                         (SYSDATE - NUMTODSINTERVAL (15, 'MINUTE'))
                     AND l.sec_user_id = s.id
                     AND s.ref_obj_id IS NOT NULL
            GROUP BY s.id)
     WHERE tot > 1000;

    write_query ('User writing > 1000 logs (15 last minutes)',
                 l_count,
                 '0',
                 c_blocking_p,
                 '<=',
                 'user_logs');



    --##############  temporary ###############
    --CHECK SDD orders - QC 28975 -- QC 29420 -- droped the "wfc_status_id = 240 --Wait For Execution" criteria on Nelson Pires demand.
    -- should be executed around 16h00
    IF     l_execution_time >
           TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 15:55',
                    'ddmmyyyy HH24:MI')
       AND l_execution_time <
           TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 16:10',
                    'ddmmyyyy HH24:MI')
    THEN
        l_nr := NULL;

        --le vendredi il faut checker le lundi au lieu du +1
        l_date := get_next_day;

        SELECT COUNT (amount)
          INTO l_nr
          FROM doc_pay_v
         WHERE     id IN (SELECT id
                            FROM doc
                           WHERE medium_id = 2087                 --medium SDD
                                                 )
               AND dispo_bank_id = 616428
               AND trx_date = l_date;


        IF l_nr > 0
        THEN
            l_nr := NULL;

              SELECT SUM (amount)     total
                INTO l_nr
                FROM doc_pay_v
               WHERE     id IN (SELECT id
                                  FROM doc
                                 WHERE medium_id = 2087           --medium SDD
                                                       )
                     AND dispo_bank_id = 616428
                     AND trx_date = l_date
            GROUP BY trx_date;
        ELSE
            l_nr := NULL;
        END IF;

        IF l_nr IS NOT NULL
        THEN
            IF is_prod
            THEN
                p_to :=
                       p_to
                    || ';treasury.settlement@blu.bank;paymon.follow@blu.bank';
            ELSE
                p_to := p_to || ';';
            END IF;

            p_html_pool :=
                   '<br/><b>WARNING for TREASURY_SETTLE TEAM : Sortie SECB SWISS EURO CLEARING BANK FRANKFURT BP 1759183. Amount: '
                || l_nr
                || ' EUR valeur '
                || TO_CHAR (l_date, 'dd/mm/yyyy')
                || '</b><br/>'
                || p_html_pool;
        END IF;
    END IF;

    l_nr := 0;
    l_text := '';

    FOR cur
        IN (  SELECT DISTINCT (userhost)     userhost
                FROM dba_audit_trail
               WHERE     (    comment_text LIKE '%DBLINK%'
                          AND comment_text NOT LIKE '%seceaspr%')
                     AND TIMESTAMP > SYSDATE - 1 / 24 * 4
                     AND action_name = 'LOGON'
                     AND userhost NOT IN ('cl9hadmin', 'cl9radmin')
                     AND username NOT IN ('NC$MSGHISPR')
            ORDER BY userhost ASC)
    LOOP
        l_nr := l_nr + 1;
        l_text := cur.userhost || ', ' || l_text;
    END LOOP;

    l_text := SUBSTR (l_text, 0, LENGTH (l_text) - 2);

    IF l_nr > 0
    THEN
        p_html_pool :=
               '<br/><b>WARNING for AM TEAM: Logon DBlink (last 4 hours)</b> <br/>'
            || l_text
            || ' <br/>'
            || p_html_pool;
    END IF;


    write_query ('Logon DBlink (last 24 hours)',
                 l_nr || '',
                 '0',
                 c_none_p,
                 '=',
                 'db_link');


    /*-- Tablespace
    l_nr:=0;
    l_text:='';

     for cur in (select tablespace_name, used_percent
                        from dba_tablespace_usage_metrics
                        where used_percent > 95
                        and tablespace_name not like '%MIG%'
                        and tablespace_name not in ('TEST_SPACE_AVALIV')
                        )

    loop
        l_nr:=l_nr+1;

        l_text:=cur.tablespace_name ||'(' || cur.used_percent || ' %) - '||l_text;
    end loop;

     if l_nr>0 then
        p_html_pool := '<br/><b>WARNING for AM TEAM: High Tablespace usage</b> <br/>' || l_text || ' <br/>' || p_html_pool;
        p_to := p_to ||';' || l_mail_dba;

    end if;

    write_query('High Tablespace usage', l_nr||'','0', c_sys_blocking_p, '=', 'tablespace');
    */

    --Client Call AWS
    l_nr := 0;

    IF is_prod
    THEN
        SELECT COUNT (*)
          INTO l_nr
          FROM k.LOG
         WHERE     ctx LIKE '%AWS Client call ping failed%'
               AND timestamp >= SYSDATE - 1 / 24 / 4; --last 15 min for AVALIV

        IF l_nr > 0
        THEN
            p_html_pool :=
                   '<br/><b>WARNING for AM TEAM: Timeout on Client Call AWS</b> <br/>
                OPERATORS TEAM : Please contact garde RM if this warning appears in two consecutive monitorings<br/>'
                || p_html_pool;
            p_to := p_to || ';' || l_mail_dba;

            IF is_prod
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_operateurs);
            END IF;
        END IF;
    ELSE
        SELECT COUNT (*)
          INTO l_nr
          FROM k.LOG
         WHERE     ctx LIKE '%AWS Client call ping failed%'
               AND timestamp >= SYSDATE - 1 / 6;     --last 4 hours for AVAPRE

        IF l_nr > 0
        THEN
            p_html_pool :=
                   '<br/><b>WARNING for AM TEAM: Timeout on Client Call AWS</b> <br/>'
                || p_html_pool;
            p_to := p_to || ';' || l_mail_dba;

            IF is_prod
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_operateurs);
            END IF;
        END IF;
    END IF;

    write_query ('Nr timeout client call AWS',
                 l_nr || '',
                 '0',
                 c_sys_blocking_p,
                 '=',
                 'Timeout_AWS');

    ---------------------------------
    --Summary:Checks for any AWS preconditions violated (eg bad parameter)
    --Author:ADRGUS
    --Date:28/07/2825
    --------------------------------- 
    if is_prod then
        select count(*) into l_nr from k.log
        where ctx like '%require.Precondition violated%aws_type%'
        and timestamp >= sysdate - 1/24/4;        --last 15 min for AVALIV
            
        if l_nr>0 then
            p_html_pool := '<br/><b>WARNING for AFP TEAM: AWS Preconditions Violated</b> <br/>' || p_html_pool;
            p_to := p_to ||';' || l_mail_afp;
        end if;
    else
        select count(*) into l_nr from k.log
        where ctx like '%require.Precondition violated%aws_type%'
        and timestamp >= trunc(sysdate);          --last day for other env
            
        if l_nr>0 then
            p_html_pool := '<br/><b>WARNING for AFP TEAM: AWS Preconditions Violated</b> <br/>' || p_html_pool;
            p_to := p_to ||';' || l_mail_afp;
        end if;
    end if;
    write_query('AWS Preconditions Violated', l_nr||'','0', c_major_p, '=', 'Precondition_Violated_AWS');

    --Check count of objects to be recalculated by OBJ010 and OBJ050
    DECLARE
        c_check_name    VARCHAR2 (100) := 'check_obj_recalc';
        c_check_title   VARCHAR2 (100)
            := 'Check count of objects to be recalculated by OBJ010 and OBJ050';
        l_cnt_1         NUMBER;
        l_cnt_2         NUMBER;
        c_max           NUMBER := 10000;
    BEGIN
        -- should be executed around 17h45
        IF     l_execution_time >
               TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 17:30',
                        'ddmmyyyy HH24:MI')
           AND l_execution_time <
               TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:05',
                        'ddmmyyyy HH24:MI')
        THEN
            l_nr := NULL;

            SELECT COUNT (DISTINCT (obj_id))
              INTO l_cnt_1
              FROM (WITH
                        b
                        AS
                            (SELECT b.today
                               FROM base b
                              WHERE b.bu_id = 3)
                        SELECT /*+ USE_HASH(OBC OC2) */
                               obc.obj_id
                          FROM obj_cont obc, obj_class2 oc2, b
                         WHERE     oc2.obj_id = obc.obj_id
                               AND oc2.ins_time >= TRUNC (CURRENT_DATE)
                               AND obc.bu_id = 3
                               AND (   obc.close_date IS NULL
                                    OR obc.close_date >= b.today)
                        UNION ALL
                        SELECT obc.obj_id
                          FROM obj_cont obc, doc d, b
                         WHERE     d.bp_1_id = obc.bp_id
                               AND d.timestamp >= TRUNC (CURRENT_DATE)
                               AND d.bp_imed_id = 3
                               AND d.meta_typ_id = 105
                               AND (   obc.close_date IS NULL
                                    OR obc.close_date >= b.today));


            SELECT SUM (total)
              INTO l_cnt_2
              FROM (SELECT COUNT (DISTINCT (obj_id))     total
                      FROM (SELECT /*+ USE_HASH(OBC OC2) */
                                   obc.obj_id
                              FROM obj_cont obc, obj_class2 oc2, base b
                             WHERE     oc2.obj_id = obc.obj_id
                                   AND oc2.ins_time >= TRUNC (CURRENT_DATE)
                                   AND b.bu_id =
                                       SYS_CONTEXT ('AAA_MESI', 'BU_ID')
                                   AND (   obc.close_date IS NULL
                                        OR obc.close_date >= b.today)
                            UNION ALL
                            SELECT /*+ USE_HASH(OBC OC2) */
                                   obc.obj_id
                              FROM obj_cont    obc,
                                   obj_bp      bp,
                                   obj_class2  oc2,
                                   base        b
                             WHERE     oc2.obj_id = bp.obj_id
                                   AND obc.bp_id = bp.obj_id
                                   AND oc2.ins_time >= TRUNC (CURRENT_DATE)
                                   AND b.bu_id =
                                       SYS_CONTEXT ('AAA_MESI', 'BU_ID')
                                   AND (   obc.close_date IS NULL
                                        OR obc.close_date >= b.today)
                            UNION ALL
                            SELECT obc.obj_id
                              FROM doc                d,
                                   obj_cont           obc,
                                   obj_bp             obp,
                                   obj_bp_person_rel  bp_pers_rel
                             WHERE     d.meta_typ_id = 125
                                   AND d.timestamp >= TRUNC (CURRENT_DATE)
                                   AND d.obj_id = bp_pers_rel.rel_person_id
                                   AND bp_pers_rel.obj_id = obp.obj_id
                                   AND obp.obj_id = obc.bp_id
                            UNION ALL
                            SELECT cont.obj_id
                              FROM obj_class2   class2,
                                   obj_cont     cont,
                                   obj_bp       bp,
                                   obj_country  cntry,
                                   base         b
                             WHERE     class2.obj_classif_id = 544
                                   AND cntry.obj_id = class2.obj_id
                                   AND bp.country_tax_id = cntry.obj_id
                                   AND cont.bp_id = bp.obj_id
                                   AND class2.ins_time >=
                                       TRUNC (CURRENT_DATE)
                                   AND b.bu_id =
                                       SYS_CONTEXT ('AAA_MESI', 'BU_ID')
                                   AND (   cont.close_date IS NULL
                                        OR cont.close_date >= b.today)));

            write_query ('Obj Superclass Recalc',
                         l_cnt_1 + l_cnt_2 || '',
                         c_max,
                         c_major_p,
                         '<',
                         c_check_name);

            IF (l_cnt_1 + l_cnt_2 > c_max)
            THEN
                p_html_pool :=
                       '<br/><b>WARNING for OPERATORS TEAM : "OBJ050 BLLU RECALC PHYSICAL CONT SUPERCLASS" must recalc '
                    || l_cnt_1
                    || ' orders.</b><br/>'
                    || p_html_pool;
                p_html_pool :=
                       '<br/><b>WARNING for OPERATORS TEAM : "OBJ010 BLLU RECALC CONT SUPERCLASS" must recalc '
                    || l_cnt_2
                    || ' orders.</b><br/>'
                    || p_html_pool;

                IF is_prod
                THEN
                    p_to := upsert_mails (p_to, ';', l_mail_exploit);
                    p_to := upsert_mails (p_to, ';', l_mail_operateurs);
                END IF;
            END IF;
        END IF;
    END;

    DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_BGP_PRCQs');
    --BGPs, PRCQs and messages
    write_subheader ('BGPs, PRCQs and messages');

    --PRCQs in error
    SELECT COUNT (v.id)
      INTO l_text
      FROM k.obj_prcq pr, k.obj o, k.obj_prcq_v v
     WHERE     pr.obj_id = o.id
           AND o.id = v.id
           AND (valid IS NULL OR valid = '*' OR close_date IS NOT NULL)
           AND obj_id NOT IN (801,
                              802,
                              806,
                              807,
                              809,
                              819,
                              820,
                              822,
                              826,
                              830,
                              831,
                              832,
                              838,
                              839,
                              844,
                              850,
                              851,
                              852,
                              856,
                              859,
                              861,
                              862,
                              864,
                              865,
                              866,
                              867,
                              868,
                              871,
                              872,
                              873,
                              877,
                              879,
                              883,
                              884,
                              885,
                              897,
                              901,
                              857,
                              858,
                              894,
                              544,
                              587,
                              588,
                              593);

    write_query ('PRCQs in error',
                 l_text,
                 '0',
                 c_blocking_p,
                 '=',
                 'prcq_error');

    IF l_text <> '0'
    THEN
        FOR o
            IN (  SELECT v.id, v.name
                    FROM k.obj_prcq pr, k.obj o, k.obj_prcq_v v
                   WHERE     pr.obj_id = o.id
                         AND o.id = v.id
                         AND (   valid IS NULL
                              OR valid = '*'
                              OR close_date IS NOT NULL)
                         AND obj_id NOT IN (801,
                                            802,
                                            806,
                                            807,
                                            809,
                                            819,
                                            820,
                                            822,
                                            826,
                                            830,
                                            831,
                                            832,
                                            838,
                                            839,
                                            844,
                                            850,
                                            851,
                                            852,
                                            856,
                                            859,
                                            861,
                                            862,
                                            864,
                                            865,
                                            866,
                                            867,
                                            868,
                                            871,
                                            872,
                                            873,
                                            877,
                                            879,
                                            883,
                                            884,
                                            885,
                                            897,
                                            901,
                                            857,
                                            858,
                                            894,
                                            544,
                                            587,
                                            588,
                                            593)
                ORDER BY id)
        LOOP
            write_query ('->' || o.id || ' ' || o.name,
                         'Broken',
                         'NULL',
                         c_blocking_p,
                         '=',
                         'prcq_error');
        END LOOP;
    END IF;


    --load query in table, get all prcq in err in the timestamp interval (with info on doc and msg related)
    FOR rec
        IN (SELECT ROWNUM,
                   main_id,
                   prcq_id,
                   prcq_name,
                   prcq_type_id,
                   bu_id,
                   doc_id,
                   doc_type_id,
                   msg_id,
                   msg_status_id,
                   msg_doc_id,
                   msg_doc_type_id,
                   mail_idx_doc_id,
                   mail_idx_id,
                   mail_idx_doc_type_id,
                   mail_status_id
              FROM (--PRCQ FOR MSG
                    SELECT p.id                main_id,
                           p.prcq_id,
                           pv.name             prcq_name,
                           pv.prcq_type_id,
                           p.bu_id,
                           p.id                prcq_doc_id,
                           NULL                doc_id,
                           NULL                doc_type_id,
                           m.id                msg_id,
                           m.msg_status_id     msg_status_id,
                           m.doc_id            msg_doc_id,
                           dd.meta_typ_id      msg_doc_type_id,
                           NULL                mail_idx_doc_id,
                           NULL                mail_idx_id,
                           NULL                mail_idx_doc_type_id,
                           NULL                mail_status_id
                      FROM k.prcq        p,
                           k.obj_prcq_v  pv,
                           k.msg         m,
                           doc           dd
                     WHERE     p.prcq_status_id = 9
                           AND p.timestamp_ins > l_timestamp --last 30 mins (considering night and weekend)
                           AND p.prcq_id = pv.id
                           AND p.id = m.id(+)
                           AND m.doc_id = dd.id(+)
                           AND p.prcq_id != 833 --propagation problems are handled in last select
                           AND p.prcq_id IN
                                   (SELECT id
                                      FROM obj
                                     WHERE     id IN
                                                   (SELECT obj_id
                                                      FROM obj_prcq)
                                           AND obj_sub_type_id = 81) --only messages
                           AND m.id IS NOT NULL --only messages that exists in table msg
                    UNION
                    --PRCQ FOR DOCS and others with the exception of msg
                    SELECT p.id                    main_id,
                           p.prcq_id,
                           pv.name                 prcq_name,
                           pv.prcq_type_id,
                           p.bu_id,
                           p.id                    prcq_doc_id,
                           d.id                    doc_id,
                           d.meta_typ_id           doc_type_id,
                           NULL                    msg_id,
                           NULL                    msg_status_id,
                           NULL                    msg_doc_id,
                           NULL                    msg_doc_type_id,
                           midx.doc_id             mail_idx_doc_id,
                           midx.id                 mail_idx_id,
                           MIDXDOC.META_TYP_ID     mail_idx_doc_type_id,
                           midx.mail_status_id     mail_status_id
                      FROM k.prcq        p,
                           k.obj_prcq_v  pv,
                           k.doc         d,
                           K.MAIL_IDX    midx,
                           doc           midxdoc
                     WHERE     p.prcq_status_id = 9
                           AND p.timestamp_ins > l_timestamp --last 30 mins (considering night and weekend)
                           AND p.prcq_id = pv.id
                           AND p.id = d.id(+)
                           AND p.id = midx.prcq_id(+)
                           AND midx.doc_id = MIDXDOC.ID(+)
                           AND p.prcq_id != 833 --propagation problems are handled in last select
                           AND p.prcq_id NOT IN
                                   (SELECT id
                                      FROM obj
                                     WHERE     id IN
                                                   (SELECT obj_id
                                                      FROM obj_prcq)
                                           AND obj_sub_type_id = 81) --no messages
                    UNION
                    SELECT p1.id                    main_id,
                           p1.prcq_id,
                           pv1.name                 prcq_name,
                           pv1.prcq_type_id,
                           p1.bu_id,
                           p1.id                    prcq_doc_id,
                           d1.id                    doc_id,
                           d1.meta_typ_id           doc_type_id,
                           m1.id                    msg_id,
                           m1.msg_status_id         msg_status_id,
                           m1.doc_id                msg_doc_id,
                           dd1.meta_typ_id          msg_doc_type_id,
                           midx1.doc_id             mail_idx_doc_id,
                           midx1.id                 mail_idx_id,
                           MIDXDOC1.META_TYP_ID     mail_idx_doc_type_id,
                           midx1.mail_status_id     mail_status_id
                      FROM k.prcq        p1,
                           k.obj_prcq_v  pv1,
                           k.doc         d1,
                           k.msg         m1,
                           k.doc         dd1,
                           K.MAIL_IDX    midx1,
                           doc           midxdoc1
                     WHERE     p1.prcq_status_id = 9
                           AND p1.timestamp_ins > TRUNC (SYSDATE)    --all day
                           AND p1.prcq_id = pv1.id
                           AND p1.id = d1.id(+)
                           AND p1.id = m1.id(+)
                           AND m1.doc_id = dd1.id(+)
                           AND p1.id = midx1.prcq_id(+)
                           AND midx1.doc_id = MIDXDOC1.ID(+)
                           AND p1.prcq_id = 833    --only propagation problems
                           AND d1.wfc_status_id != 90 --only as long as problem is not resolved
                    ORDER BY prcq_id DESC, bu_id DESC, main_id DESC))
    LOOP
        vRec.doc_id := rec.doc_id;
        vRec.doc_type_id := rec.doc_type_id;
        vRec.prcq_type_id := rec.prcq_type_id;
        vRec.msg_id := rec.msg_id;
        vRec.msg_status_id := rec.msg_status_id;
        vRec.msg_doc_id := rec.msg_doc_id;
        vRec.msg_doc_type_id := rec.msg_doc_type_id;
        vRec.prcq_id := rec.prcq_id;
        vRec.prcq_name := rec.prcq_name;
        vRec.bu_id := rec.bu_id;
        vRec.is_treated := FALSE;
        --added for mailings
        vRec.mail_idx_id := rec.mail_idx_id;
        vRec.mail_idx_doc_id := rec.mail_idx_doc_id;
        vRec.mail_idx_doc_type_id := rec.mail_idx_doc_type_id;
        vRec.mail_idx_status_id := rec.mail_status_id;
        vRec.main_id := rec.main_id;

        vPrcqErrList.EXTEND;
        vPrcqErrList (rec.ROWNUM) := vRec;
    END LOOP;

    DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_PRCQs');

    l_prcq_severity := c_none_p;

    --check vPrcqErrList is not empty
    IF vPrcqErrList.FIRST IS NOT NULL
    THEN
        -- display resume of failed prcq
        write_query ('PRCQ entries failed (' || l_timecheck || ')',
                     TO_CHAR (vPrcqErrList.LAST),
                     '0',
                     l_prcq_severity,
                     '=',
                     'prcq_error');
        vCurPrcqId := vPrcqErrList (vPrcqErrList.FIRST).prcq_id;

        --loop while all table records aren't treated
        WHILE vUntreatedRecCnt > 0
        LOOP
            vUntreatedRecCnt := 0;                                     --reset
            vLastPrcqRecCnt := 0;
            l_text := '';
            l_warning_for := '';
            l_prcq_severity := c_none_p;
            l_count := 0;

            --run through table
            FOR i IN vPrcqErrList.FIRST .. vPrcqErrList.LAST
            LOOP
                --treat current type of prcq (table ordered by prcq_id)
                IF     (vCurPrcqId = vPrcqErrList (i).prcq_id)
                   AND (vPrcqErrList (i).is_treated = FALSE)
                THEN
                    vLastPrcqRecCnt := vLastPrcqRecCnt + 1;

                    --Special treatment for mailings
                    IF vPrcqErrList (i).prcq_id IN (818, 815)
                    THEN
                        -- exclude mailing problems here (shows wrong count), reported in seperate check on mailings
                        -- only when mail_idx in error status
                        IF vPrcqErrList (i).mail_idx_status_id IN (111,
                                                                   107,
                                                                   101,
                                                                   104)
                        THEN
                            IF vPrcqErrList (i).prcq_id = 818
                            THEN
                                l_count := l_count + 1;

                                IF l_count <= 100
                                THEN
                                    l_text :=
                                        upsert_mails (
                                            l_text,
                                            ', ',
                                               vPrcqErrList (i).mail_idx_doc_id
                                            || ' ('
                                            || getMetaTypName (
                                                   vPrcqErrList (i).mail_idx_doc_type_id)
                                            || '-'
                                            || getBuName (
                                                   vPrcqErrList (i).bu_id)
                                            || ', mail:'
                                            || vPrcqErrList (i).mail_idx_id
                                            || ')');
                                ELSIF l_count = 101
                                THEN
                                    l_text := l_text || '... and more';
                                END IF;
                            ELSE                                         --815
                                l_count := l_count + 1;

                                IF l_count <= 100
                                THEN
                                    l_text :=
                                        upsert_mails (
                                            l_text,
                                            ', ',
                                               'mail_id:'
                                            || vPrcqErrList (i).mail_idx_id
                                            || '-'
                                            || getBuName (
                                                   vPrcqErrList (i).bu_id));
                                ELSIF l_count = 101
                                THEN
                                    l_text := l_text || '... and more';
                                END IF;
                            END IF;

                            --always alert reporting team concerning errors on mailing prqcs
                            --if email not already in list
                            p_to :=
                                upsert_mails (p_to, ';', l_mail_prcq_mail);
                            l_warning_for :=
                                upsert_mails (l_warning_for,
                                              ', ',
                                              'REPORTING TEAM');
                        END IF;
                    ELSE
                        IF vPrcqErrList (i).doc_id IS NOT NULL
                        THEN
                            l_text :=
                                upsert_mails (
                                    l_text,
                                    ', ',
                                       vPrcqErrList (i).doc_id
                                    || ' ('
                                    || getMetaTypName (
                                           vPrcqErrList (i).doc_type_id)
                                    || '-'
                                    || getBuName (vPrcqErrList (i).bu_id)
                                    || ')');
                        ELSE
                            IF vPrcqErrList (i).msg_doc_id IS NOT NULL
                            THEN
                                l_text :=
                                    upsert_mails (
                                        l_text,
                                        ', ',
                                           vPrcqErrList (i).msg_doc_id
                                        || ' ('
                                        || getMetaTypName (
                                               vPrcqErrList (i).msg_doc_type_id)
                                        || '-'
                                        || getBuName (vPrcqErrList (i).bu_id)
                                        || ',msg:'
                                        || vPrcqErrList (i).msg_id
                                        || ')');
                            ELSE
                                l_text :=
                                    upsert_mails (
                                        l_text,
                                        ', ',
                                           'no_doc ('
                                        || getMsgStatusName (
                                               vPrcqErrList (i).msg_status_id)
                                        || '-'
                                        || getBuName (vPrcqErrList (i).bu_id)
                                        || ',msg:'
                                        || vPrcqErrList (i).msg_id
                                        || ')');
                            END IF;
                        END IF;

                        IF    UPPER (
                                  getMetaTypName (
                                      vPrcqErrList (i).msg_doc_type_id)) =
                              UPPER ('inpay')
                           OR UPPER (
                                  getMetaTypName (
                                      vPrcqErrList (i).msg_doc_type_id)) =
                              UPPER ('pay')
                        THEN
                            p_to :=
                                upsert_mails (
                                    p_to,
                                    ';',
                                    getMailByBu ('PAY',
                                                 vPrcqErrList (i).bu_id));
                            l_warning_for :=
                                upsert_mails (l_warning_for,
                                              ', ',
                                              'PAY TEAM');
                        END IF;
                    END IF;



                    --build warning and mailing list
                    --check if order is of a certain type ( ex: mass settle 218)
                    IF COALESCE (vPrcqErrList (i).doc_type_id,
                                 vPrcqErrList (i).msg_doc_type_id) =
                       218
                    THEN
                        --do generic treatment whatever the prcq in error
                        p_to :=
                            upsert_mails (
                                p_to,
                                ';',
                                getMailByBu ('CUSTSETTLE',
                                             vPrcqErrList (i).bu_id));
                        l_warning_for :=
                            upsert_mails (l_warning_for, ', ', 'CUST TEAM');
                    ELSE
                        --do dispatch to special treatment
                        IF vPrcqErrList (i).prcq_id IN (869,
                                                        888,
                                                        892,
                                                        890,
                                                        874)
                        THEN                                      -- Stex only
                            l_prcq_severity := c_major_p;
                            p_to :=
                                upsert_mails (
                                    p_to,
                                    ';',
                                    getMailByBu ('STEX',
                                                 vPrcqErrList (i).bu_id));
                            l_warning_for :=
                                upsert_mails (l_warning_for,
                                              ', ',
                                              'STEX TEAM');
                        ELSIF vPrcqErrList (i).prcq_id IN (886, 887, 895)
                        THEN                                    -- Secevt only
                            l_prcq_severity := c_major_p;
                            --append the user who made last action on this order to the destination list, if no real user found, then send to secevt mailing list
                            p_to :=
                                upsert_mails (
                                    p_to,
                                    ';',
                                    COALESCE (
                                        getMailOfUserWhoMadeLastAction (
                                            COALESCE (
                                                vPrcqErrList (i).doc_id,
                                                vPrcqErrList (i).msg_doc_id)),
                                        l_mail_prcq_secevt));
                            l_warning_for :=
                                upsert_mails (
                                    l_warning_for,
                                    ', ',
                                    getMailOfUserWhoMadeLastAction (
                                        COALESCE (
                                            vPrcqErrList (i).doc_type_id,
                                            vPrcqErrList (i).msg_doc_type_id)));

                            --check if the order is of type 'Dividend Cash' or 'Interest' or 'Redemption'
                            IF COALESCE (vPrcqErrList (i).doc_type_id,
                                         vPrcqErrList (i).msg_doc_type_id) IN
                                   (386, 387, 390)
                            THEN
                                p_to :=
                                    upsert_mails (
                                        p_to,
                                        ';',
                                        getMailByBu ('INCOME',
                                                     vPrcqErrList (i).bu_id));
                                l_warning_for :=
                                    upsert_mails (l_warning_for,
                                                  ', ',
                                                  'INCOME PROCESSING TEAM');
                            ELSE
                                p_to :=
                                    upsert_mails (
                                        p_to,
                                        ';',
                                        getMailByBu ('CORPORATE',
                                                     vPrcqErrList (i).bu_id));
                                l_warning_for :=
                                    upsert_mails (l_warning_for,
                                                  ', ',
                                                  'CORPORATE ACTION TEAM');
                            END IF;
                        ELSIF vPrcqErrList (i).prcq_id IN (810,
                                                           811,
                                                           812,
                                                           819,
                                                           854,
                                                           855,
                                                           898)
                        THEN                                 -- Settle problem
                            l_prcq_severity := c_major_p;
                            --warn last user + settle team
                            p_to :=
                                upsert_mails (
                                    p_to,
                                    ';',
                                    getMailOfUserWhoMadeLastAction (
                                        COALESCE (
                                            vPrcqErrList (i).doc_type_id,
                                            vPrcqErrList (i).msg_doc_type_id)));
                            l_warning_for :=
                                upsert_mails (
                                    l_warning_for,
                                    ', ',
                                    getMailOfUserWhoMadeLastAction (
                                        COALESCE (
                                            vPrcqErrList (i).doc_type_id,
                                            vPrcqErrList (i).msg_doc_type_id)));
                            p_to :=
                                upsert_mails (
                                    p_to,
                                    ';',
                                    getMailByBu ('SETTLE',
                                                 vPrcqErrList (i).bu_id));
                            l_warning_for :=
                                upsert_mails (l_warning_for,
                                              ', ',
                                              'SETTLE TEAM');
                        ELSIF vPrcqErrList (i).prcq_id IN (797)
                        THEN                                 -- Settle problem
                            l_prcq_severity := c_major_p;
                            --warn last user + settle team
                            p_to :=
                                upsert_mails (
                                    p_to,
                                    ';',
                                    getMailOfUserWhoMadeLastAction (
                                        COALESCE (
                                            vPrcqErrList (i).doc_type_id,
                                            vPrcqErrList (i).msg_doc_type_id)));
                            l_warning_for :=
                                upsert_mails (
                                    l_warning_for,
                                    ', ',
                                    getMailOfUserWhoMadeLastAction (
                                        COALESCE (
                                            vPrcqErrList (i).doc_type_id,
                                            vPrcqErrList (i).msg_doc_type_id)));

                            IF vPrcqErrList (i).doc_type_id IN (140042)
                            THEN
                                p_to :=
                                    upsert_mails (
                                        p_to,
                                        ';',
                                        getMailByBu ('CUST',
                                                     vPrcqErrList (i).bu_id));
                                l_warning_for :=
                                    upsert_mails (l_warning_for,
                                                  ', ',
                                                  'CUST TEAM');
                            ELSE
                                p_to :=
                                    upsert_mails (
                                        p_to,
                                        ';',
                                        getMailByBu ('SETTLE',
                                                     vPrcqErrList (i).bu_id));
                                l_warning_for :=
                                    upsert_mails (l_warning_for,
                                                  ', ',
                                                  'SETTLE TEAM');
                            END IF;
                        ELSIF vPrcqErrList (i).prcq_id IN (800)
                        THEN                               -- Message formater
                            --check if msg is not in status discarded
                            IF (vPrcqErrList (i).msg_status_id != 10)
                            THEN
                                l_prcq_severity := c_major_p;
                                p_to :=
                                    upsert_mails (
                                        p_to,
                                        ';',
                                        getMailByBu ('SETTLE',
                                                     vPrcqErrList (i).bu_id));
                                l_warning_for :=
                                    upsert_mails (l_warning_for,
                                                  ', ',
                                                  'SETTLE TEAM');
                            END IF;
                        ELSIF vPrcqErrList (i).prcq_id IN (798)
                        THEN                                             -- FX
                            l_prcq_severity := c_major_p;
                            p_to :=
                                upsert_mails (
                                    p_to,
                                    ';',
                                    getMailByBu ('MARKET',
                                                 vPrcqErrList (i).bu_id));
                            l_warning_for :=
                                upsert_mails (l_warning_for,
                                              ', ',
                                              'MARKET TEAM');
                        ELSIF vPrcqErrList (i).prcq_id IN (863)
                        THEN                          -- matching confirmation
                            l_prcq_severity := c_major_p;
                            p_to :=
                                upsert_mails (
                                    p_to,
                                    ';',
                                    getMailByBu ('MARKET',
                                                 vPrcqErrList (i).bu_id));
                            l_warning_for :=
                                upsert_mails (l_warning_for,
                                              ', ',
                                              'MARKET TEAM');
                        ELSIF vPrcqErrList (i).prcq_id IN (833)
                        THEN                            -- propagation problem
                            l_prcq_severity := c_major_p;

                            l_warning_for :=
                                upsert_mails (l_warning_for,
                                              ', ',
                                              'CUST DB TEAM');
                        ELSIF     vPrcqErrList (i).prcq_id IN (815, 818)
                              AND vPrcqErrList (i).mail_idx_status_id NOT IN
                                      (111,
                                       107,
                                       101,
                                       104)
                        THEN                                        --Mailings
                            l_prcq_severity := c_major_p;
                        ELSE
                            NULL;                    --no on top error warning
                        END IF;
                    END IF;

                    --set record as treated and remember
                    vPrcqErrList (i).is_treated := TRUE;
                    vLastPrcqId := vPrcqErrList (i).prcq_id;
                    vLastPrcqName := vPrcqErrList (i).prcq_name;
                --debug
                /*DBMS_OUTPUT.put_line(    'processing_prcq:'    ||vCurPrcqId||
                                        ',doc_id:'           ||vPrcqErrList(i).doc_id||
                                        ', doc_type_id:'     ||vPrcqErrList(i).doc_type_id||
                                        ', msg_id:'         ||vPrcqErrList(i).msg_id||
                                        ', msg_netw_id:'    ||vPrcqErrList(i).msg_netw_id||
                                        ', msg_doc_id:'     ||vPrcqErrList(i).msg_doc_id||
                                        ', msg_doc_type_id:'||vPrcqErrList(i).msg_doc_type_id||
                                        ', prcq_id:'        ||vPrcqErrList(i).prcq_id||
                                        ', prcq_name:'        ||vPrcqErrList(i).prcq_name||
                                        ', bu_id:'          ||vPrcqErrList(i).bu_id);*/

                ELSIF     (vPrcqErrList (i).prcq_id != vCurPrcqId)
                      AND (vPrcqErrList (i).is_treated = FALSE)
                THEN
                    -- count untreated records
                    vUntreatedRecCnt := vUntreatedRecCnt + 1;
                    -- set next prcq_id to iterate on
                    vCurPrcqId := vPrcqErrList (i).prcq_id;
                    EXIT;
                END IF;
            END LOOP;

            --generate one of these warning message for each type of monitored prcq (prcq_id)
            IF LENGTH (vLastPrcqRecCnt) > 0
            THEN
                IF LENGTH (l_warning_for) > 0
                THEN
                    p_html_pool := l_text || '<br/>' || p_html_pool;
                    p_html_pool :=
                           '<br/><b>WARNING for '
                        || l_warning_for
                        || ' : '
                        || vLastPrcqRecCnt
                        || ' error(s) for PRCQ '
                        || vLastPrcqName
                        || ' on order(s): </b><br/>'
                        || p_html_pool;
                END IF;

                write_query ('->' || vLastPrcqId || ' ' || vLastPrcqName,
                             vLastPrcqRecCnt,
                             '0',
                             l_prcq_severity,
                             '=',
                             'none');
            END IF;
        END LOOP;
    ELSE
        -- display resume of no failed prcq
        write_query ('PRCQ entries failed (' || l_timecheck || ')',
                     '0',
                     '0',
                     l_prcq_severity,
                     '=',
                     'prcq_entries_failed');
    END IF;

      ---------------------------------
      --Summary:Sends an alert if process queue "Matching of confirmations" is longer than 15 min.
      --Author:ADRGUS
      --Date:23/12/2024
      ---------------------------------
      SELECT ROUND (
                   (  CAST (timestamp_start AS DATE)
                    - CAST (timestamp_ins AS DATE))
                 * 24
                 * 60)
        INTO l_nr
        FROM k.prcq
       WHERE prcq_id IN (863) AND ERR IS NULL AND timestamp_start IS NOT NULL
    ORDER BY timestamp_ins DESC
       FETCH FIRST 1 ROW ONLY;

    write_query (
        'Latest delay on queue "Matching of Confirmations" (in min) ',
        l_nr,
        '15',
        c_major_p,
        '<=',
        'delay_queue_moc');

    --Generate Warning for FMCS Team
    IF (l_nr > 15)
    THEN
        l_text :=
            '<br/><b>WARNING for FMCS Team : The following queue(s) have accumulated more than 15 minutes of max delay :</b><br/>';
        l_text :=
               l_text
            || ' - Queue : "Matching of Confirmations" has currently a delay of '
            || TO_CHAR (l_nr)
            || ' minutes <br/>';
        p_html_pool := l_text || p_html_pool;
        p_to := p_to || ';' || l_mail_fmcs_treasury;
        p_to := p_to || ';' || l_mail_treasury_sttl;
    END IF;


      -- Wrong Booking Date due to Prcq shift time (00:00 --> 01:00)
      SELECT COUNT (*)
        INTO l_nr
        FROM k.prcq p
       WHERE     prcq_id = 879
             AND EXTRACT (HOUR FROM date_prc) = 1
             AND timestamp_start IS NULL
             AND timestamp_prc IS NULL
    ORDER BY date_prc DESC;

    write_query ('PRCQ w/ wrong Booking Date',
                 TO_CHAR (l_nr),
                 '0',
                 c_none_p,
                 '=',
                 'prcq_wrong_booking_date');

    --Propagation errors --> if status NoLock, do a try lock on the GUI to unlock the BP
    BEGIN
        l_nr := 0;
        l_text := '';
        l_teams := 'Cust DB Team';


        FOR l_prop
            IN (SELECT DISTINCT doc_id, doc.bp_imed_id bu_id
                  FROM k.bp_prop, k.doc
                 WHERE person_prop_status = 4 AND bp_prop.doc_id = doc.id)
        LOOP
            l_nr := l_nr + 1;

            IF l_nr = 1
            THEN                              --no separator for first element
                l_text :=
                       ''
                    || l_prop.doc_id
                    || ' ('
                    || getBuName (l_prop.bu_id)
                    || ')';
            ELSIF l_nr <= 10
            THEN                                   --not more than 10 messages
                IF MOD (l_nr, 5) = 0
                THEN                               --linebreak every 5 entries
                    l_text :=
                           l_text
                        || ', '
                        || l_prop.doc_id
                        || ' ('
                        || getBuName (l_prop.bu_id)
                        || ')'
                        || CHR (10);
                ELSE
                    l_text :=
                           l_text
                        || ', '
                        || l_prop.doc_id
                        || ' ('
                        || getBuName (l_prop.bu_id)
                        || ')';
                END IF;
            ELSIF l_nr = 11
            THEN                               --if more than 11 -> add 3 dots
                l_text := l_text || '...more';
            END IF;

            --btlu
            IF l_prop.bu_id = 11
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_btlu_dflt);
                l_teams := 'BTLU Team, AM Team';
            END IF;
        END LOOP;

        IF l_nr > 0
        THEN
            p_html_pool :=
                   '<br/><b>WARNING for '
                || l_teams
                || ' : '
                || l_nr
                || ' Propagation error(s): </b>'
                || l_text
                || '<br/>'
                || p_html_pool;

        END IF;

        IF     (   (SYSDATE BETWEEN TO_DATE (
                                           TO_CHAR (TRUNC (SYSDATE),
                                                    'ddmmyyyy')
                                        || ' 08:00',
                                        'ddmmyyyy HH24:MI')
                                AND TO_DATE (
                                           TO_CHAR (TRUNC (SYSDATE),
                                                    'ddmmyyyy')
                                        || ' 08:20',
                                        'ddmmyyyy HH24:MI'))
                OR (SYSDATE BETWEEN TO_DATE (
                                           TO_CHAR (TRUNC (SYSDATE),
                                                    'ddmmyyyy')
                                        || ' 12:00',
                                        'ddmmyyyy HH24:MI')
                                AND TO_DATE (
                                           TO_CHAR (TRUNC (SYSDATE),
                                                    'ddmmyyyy')
                                        || ' 12:20',
                                        'ddmmyyyy HH24:MI'))
                OR (SYSDATE BETWEEN TO_DATE (
                                           TO_CHAR (TRUNC (SYSDATE),
                                                    'ddmmyyyy')
                                        || ' 16:00',
                                        'ddmmyyyy HH24:MI')
                                AND TO_DATE (
                                           TO_CHAR (TRUNC (SYSDATE),
                                                    'ddmmyyyy')
                                        || ' 16:20',
                                        'ddmmyyyy HH24:MI')))
           AND NOT is_weekend
        THEN
            write_query ('Propagation errors',
                         l_nr,
                         '0',
                         c_major_p,
                         '=',
                         'propagation_errors');
        ELSE
            write_query ('Propagation errors',
                         l_nr,
                         '0',
                         c_none_p,
                         '=',
                         'propagation_errors');
        END IF;
    END;

    DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_BGP_IN_ERROR');

    -- BGP in error
    SELECT COUNT (*)
      INTO l_text
      FROM k.obj_bgp_v v
     WHERE     (session_level_id = '0' OR disabled = 'Y')
           AND bgp IS NOT NULL
           AND bgp_id NOT IN (921,
                              599,
                              581,
                              531,
                              590,
                              530,
                              529,
                              602,
                              604,
                              584,
                              586) -- 530 and 529 temprary until the Minor release december 2019 / 584 and 586 during 2023-01 MEP 942 has no SID
           AND NOT EXISTS
                   (SELECT bgp_id
                      FROM k.obj_bgp_v b
                     WHERE     b.bgp_id = v.bgp_id
                           AND valid = '+'
                           AND session_level_id <> '0'
                           AND (disabled = 'N' OR disabled IS NULL));

    IF l_text <> '0'
    THEN
        SELECT COUNT (*)
          INTO l_text
          FROM k.obj_bgp_v v
         WHERE     (session_level_id = '0' OR disabled = 'Y')
               AND bgp IS NOT NULL
               AND bgp_id NOT IN (921,
                                  599,
                                  581,
                                  531,
                                  590,
                                  530,
                                  529,
                                  602,
                                  604)
               AND NOT EXISTS
                       (SELECT bgp_id
                          FROM k.obj_bgp_v b
                         WHERE     b.bgp_id = v.bgp_id
                               AND valid = '+'
                               AND session_level_id <> '0'
                               AND (disabled = 'N' OR disabled IS NULL));
    END IF;

    write_query ('BGPs in error',
                 l_text,
                 '0',
                 c_sys_blocking_p,
                 '=',
                 'bgp_error');

    IF l_text <> '0'
    THEN
        FOR o IN (  SELECT DISTINCT bgp, name
                      FROM k.obj_bgp_v v
                     WHERE    session_level_id = '0'
                           OR     (disabled = 'Y' AND valid = '+')
                              AND bgp IS NOT NULL
                              AND bgp_id NOT IN (921,
                                                 599,
                                                 581,
                                                 531,
                                                 590,
                                                 530,
                                                 529,
                                                 602,
                                                 604,
                                                 584,
                                                 586)
                  ORDER BY bgp)
        LOOP
            write_query ('->' || o.bgp || ' ' || o.name,
                         'disabled',
                         'NULL',
                         c_sys_blocking_p,
                         '=',
                         'none');
            p_html_pool :=
                   '<br/><b>WARNING for AM Team : '
                || o.bgp
                || ' '
                || o.name
                || ' BGP disabled</b>'
                || p_html_pool;

            IF is_prod
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_exploit);
                p_to := upsert_mails (p_to, ';', l_mail_operateurs);
            END IF;
        END LOOP;
    END IF;

    IF is_day_off (2015, TRUNC (SYSDATE))
    THEN
        l_nr := 1;
    ELSE
        l_nr := 0;
    END IF;

    -- BGP w/o SID
    -- 12/06/2017 deactivate 996 (launched every 5 minutes)
    SELECT COUNT (*)
      INTO l_text
      FROM k.obj_bgp_v
     WHERE     (disabled IS NULL OR disabled = 'N')
           AND valid = '+'
           AND sid IS NULL
           AND bgp_id NOT IN (921,
                              599,
                              996,
                              942)
           AND NOT (    bgp = '985.1'
                    AND NOT SYSDATE BETWEEN TO_DATE (
                                                   TO_CHAR (TRUNC (SYSDATE),
                                                            'ddmmyyyy')
                                                || ' 06:30',
                                                'ddmmyyyy HH24:MI')
                                        AND TO_DATE (
                                                   TO_CHAR (TRUNC (SYSDATE),
                                                            'ddmmyyyy')
                                                || ' 16:30',
                                                'ddmmyyyy HH24:MI'))
           AND NOT (    bgp LIKE '918%'
                    AND NOT SYSDATE BETWEEN TO_DATE (
                                                   TO_CHAR (TRUNC (SYSDATE),
                                                            'ddmmyyyy')
                                                || ' 06:30',
                                                'ddmmyyyy HH24:MI')
                                        AND TO_DATE (
                                                   TO_CHAR (TRUNC (SYSDATE),
                                                            'ddmmyyyy')
                                                || ' 19:30',
                                                'ddmmyyyy HH24:MI'))
           AND NOT (bgp_id IN (918, 985) AND l_nr = 1); --ignore Sofie and Isabel on Lux holiday

    write_query ('BGPs w/o SID',
                 l_text,
                 '0',
                 c_none_p,
                 '=',
                 'bgp_without_sid');

    IF l_text <> '0'
    THEN
        -- 12/06/2017 deactivate 996 (launched every 5 minutes)
        FOR o
            IN (  SELECT DISTINCT bgp, name, last_heartbeat
                    FROM k.obj_bgp_v
                   WHERE     (disabled IS NULL OR disabled = 'N')
                         AND valid = '+'
                         AND sid IS NULL
                         AND bgp_id NOT IN (921,
                                            599,
                                            996,
                                            942)
                         AND NOT (    bgp = '985.1'
                                  AND NOT SYSDATE BETWEEN TO_DATE (
                                                                 TO_CHAR (
                                                                     TRUNC (
                                                                         SYSDATE),
                                                                     'ddmmyyyy')
                                                              || ' 06:30',
                                                              'ddmmyyyy HH24:MI')
                                                      AND TO_DATE (
                                                                 TO_CHAR (
                                                                     TRUNC (
                                                                         SYSDATE),
                                                                     'ddmmyyyy')
                                                              || ' 16:30',
                                                              'ddmmyyyy HH24:MI'))
                         AND NOT (    bgp LIKE '918%'
                                  AND NOT SYSDATE BETWEEN TO_DATE (
                                                                 TO_CHAR (
                                                                     TRUNC (
                                                                         SYSDATE),
                                                                     'ddmmyyyy')
                                                              || ' 06:30',
                                                              'ddmmyyyy HH24:MI')
                                                      AND TO_DATE (
                                                                 TO_CHAR (
                                                                     TRUNC (
                                                                         SYSDATE),
                                                                     'ddmmyyyy')
                                                              || ' 19:30',
                                                              'ddmmyyyy HH24:MI'))
                         AND NOT (bgp_id IN (918, 985) AND l_nr = 1) --ignore Sofie and Isabel on Lux holiday
                ORDER BY bgp)
        LOOP
            --Dont show Sofie and Isabel during weekends
            IF is_weekend AND (o.bgp LIKE '918%' OR o.bgp LIKE '985%')
            THEN
                CONTINUE;
            END IF;

            IF (o.last_heartbeat > SYSDATE - 1 / 24 / 2)
            THEN
                write_query ('->' || o.bgp || ' ' || o.name,
                             'No SID',
                             'NULL',
                             c_major_p,
                             '=',
                             'none');
            ELSE
                write_query (
                    '->' || o.bgp || ' ' || o.name,
                       'No SID since '
                    || TO_CHAR (o.last_heartbeat, 'ddmmyyyy HH24:MI'),
                    'NULL',
                    c_sys_blocking_p,
                    '=',
                    'none');
                p_html_pool :=
                       '<br/><b>WARNING for Operators and AM : '
                    || o.bgp
                    || ' '
                    || o.name
                    || ' No SID since '
                    || TO_CHAR (o.last_heartbeat, 'ddmmyyyy HH24:MI')
                    || '</b><br/>'
                    || p_html_pool;

                IF is_prod
                THEN
                    p_to := upsert_mails (p_to, ';', l_mail_exploit);
                    p_to := upsert_mails (p_to, ';', l_mail_operateurs);
                END IF;
            END IF;
        END LOOP;
    END IF;

    --bgp doc_logger
    DECLARE
        CURSOR c4 IS
            SELECT c.user_id, d.prc_timestamp, err_log.msg
              FROM k.doc_log_consmr     d,
                   code_doc_log_consmr  c,
                   (SELECT doc_log_err.*, SUBSTR (LOG.ctx, 0, 25) msg
                      FROM (SELECT id, user_id, last_log_id
                              FROM DOC_LOG_CONSMR_DOC_V
                             WHERE activ = '+' AND last_log_id IS NOT NULL
                            UNION ALL
                            SELECT id, user_id, last_log_id
                              FROM DOC_LOG_CONSMR_OBJ_V
                             WHERE activ = '+' AND last_log_id IS NOT NULL
                            UNION ALL
                            SELECT id, user_id, last_log_id
                              FROM DOC_LOG_CONSMR_EVT_V
                             WHERE activ = '+' AND last_log_id IS NOT NULL)
                           doc_log_err,
                           k.LOG
                     WHERE doc_log_err.last_log_id = LOG.id(+)) err_log
             WHERE     prc_timestamp <
                       SYSDATE - NUMTODSINTERVAL (10, 'MINUTE')
                   AND c.send_interval_sec <= 60
                   AND c.id = d.id
                   AND c.user_id = err_log.user_id(+)
                   AND c.activ IS NOT NULL
                   AND c.user_id NOT IN ('NC$CRM_BP_CH',
                                         'NC$CRM_CONT_CH',
                                         'NC$CRM_ADDR_CH',
                                         'NC$CRM_PERS_CH',
                                         'NC$CRM_COLL_CH')
                   AND c.user_id != 'AFS_TAB_TRANS';
    BEGIN
        SELECT COUNT (*)
          INTO l_nr
          FROM k.doc_log_consmr d, code_doc_log_consmr c
         WHERE     prc_timestamp < SYSDATE - NUMTODSINTERVAL (10, 'MINUTE')
               AND c.send_interval_sec <= 60
               AND c.id = d.id
               AND c.activ IS NOT NULL
               AND user_id NOT IN ('NC$CRM_BP_CH',
                                   'NC$CRM_CONT_CH',
                                   'NC$CRM_ADDR_CH',
                                   'NC$CRM_PERS_CH',
                                   'NC$CRM_COLL_CH')
               AND user_id != 'AFS_TAB_TRANS';

        write_query ('BGP Doc Logger',
                     TO_CHAR (l_nr),
                     '0',
                     c_major_p,
                     '=',
                     'bgp_doc_logger');

        FOR rec4 IN c4
        LOOP
            IF    NOT is_weekend --ignore a selection of consumrs during weekend
               OR rec4.user_id NOT IN ('BDL_FX_EXPO',
                                       'BE_FX_EXPO',
                                       'CH_FX_EXPO',
                                       'NC$FX_EXPO_CISG',
                                       'CTR_PRICE_FEED',
                                       'CTR_RED_RENW')
            THEN
                write_query (
                    '->' || rec4.user_id || ' not logging for 10 min',
                    '1',
                    '0',
                    c_major_p,
                    '=',
                    'none');

                IF rec4.msg IS NOT NULL
                THEN
                    IF rec4.user_id IN ('PTT_CANC_BLBE',
                                        'PTT_CANC_BLLU',
                                        'PTT_CANC_BTLU',
                                        'PTT_EQ_BLBE',
                                        'PTT_EQ_BLLU',
                                        'PTT_EQ_BTLU',
                                        'PTT_NON_EQ_BLBE',
                                        'PTT_NON_EQ_BLLU',
                                        'PTT_NON_EQ_BTLU')
                    THEN
                        p_html_pool :=
                               '<br/><b>WARNING for TRX TEAM: BGP Doc Logger '
                            || rec4.user_id
                            || ' is blocked : </b>'
                            || rec4.msg
                            || ' <br/>'
                            || p_html_pool;
                        p_to := upsert_mails (p_to, ';', l_mail_cbs_transac);
                    ELSE
                        p_html_pool :=
                               '<br/><b>WARNING for AM TEAM: BGP Doc Logger '
                            || rec4.user_id
                            || ' is blocked : </b>'
                            || rec4.msg
                            || ' <br/>'
                            || p_html_pool;

                        IF is_prod
                        THEN
                            p_to := upsert_mails (p_to, ';', l_mail_exploit);
                            p_to :=
                                upsert_mails (p_to, ';', l_mail_operateurs);
                        END IF;
                    END IF;

                    write_query ('--->' || rec4.msg,
                                 '1',
                                 '0',
                                 c_blocking_p,
                                 '=',
                                 'none');
                END IF;
            END IF;
        END LOOP;
    END;

    --Sofie
    IF l_execution_time >
       TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:00',
                'ddmmyyyy HH24:MI')
    THEN
        SELECT COUNT (*)
          INTO l_text
          FROM k.obj_bgp_v
         WHERE bgp_id = 918 AND valid = '+';

        write_query ('BGP Sofie',
                     l_text,
                     '1',
                     c_blocking_p,
                     '=',
                     'bgp_sofie');
    END IF;

    --MQ Bridge
    SELECT COUNT (*)
      INTO l_text
      FROM k.obj_bgp_v
     WHERE bgp_id = 502 AND valid = '+' AND sid IS NOT NULL;

    write_query ('BGP MQ Bridge',
                 l_text,
                 '1',
                 c_blocking_p,
                 '=',
                 'bgp_mq');

    --MQ Bridge
    SELECT COUNT (*)
      INTO l_text
      FROM (SELECT intl_id
              FROM code_msg_mq_prop
             WHERE activ = '+'
            MINUS
            SELECT thread_grp_name
              FROM OBJ_BGP_THREAD_V
             WHERE bgp_id = 502 AND thread_grp_name IS NOT NULL);

    write_query ('BGP MQ Bridge inactive threads',
                 l_text,
                 '0',
                 c_sys_blocking_p,
                 '=',
                 'bgp_mq');

    --MQ Bridge - Detail
    IF l_text <> '0'
    THEN
        l_text := '';
        l_nr := 0;

        FOR c
            IN (SELECT intl_id
                  FROM (SELECT intl_id
                          FROM code_msg_mq_prop
                         WHERE activ = '+'
                        MINUS
                        SELECT thread_grp_name
                          FROM OBJ_BGP_THREAD_V
                         WHERE bgp_id = 502 AND thread_grp_name IS NOT NULL))
        LOOP
            l_nr := l_nr + 1;
            l_text := c.intl_id || ', ' || l_text;
        END LOOP;

        IF l_nr > 0
        THEN
            l_text := SUBSTR (l_text, 0, LENGTH (l_text) - 2);
            p_html_pool :=
                   '<br/><b>WARNING for AM TEAM: No BGP Thread for </b> <br/>'
                || l_text
                || ' <br/>'
                || p_html_pool;

            IF is_prod
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_exploit);
                p_to := upsert_mails (p_to, ';', l_mail_operateurs);
            END IF;
        END IF;
    END IF;

    --Credit Check
    SELECT COUNT (*)
      INTO l_text
      FROM k.obj_bgp_v
     WHERE bgp_id = 988 AND valid = '+';

    write_query ('BGP Credit Check',
                 l_text,
                 '1',
                 c_blocking_p,
                 '=',
                 'bgp_credit_check');

    --BGP session blocking
    BEGIN
        l_nr := 0;

        WITH
            bgp_info
            AS
                (SELECT TO_NUMBER (
                            REGEXP_REPLACE (J.JOB_NAME,
                                            '.*_([[:digit:]]{1,})_.*',
                                            '\1'))    bgp_id,
                        TO_NUMBER (
                            REGEXP_REPLACE (J.JOB_NAME,
                                            '.*_([[:digit:]]{1,})$.*',
                                            '\1'))    inst_id,
                        r.session_id,
                        r.owner
                   FROM DBA_SCHEDULER_RUNNING_JOBS  r
                        JOIN DBA_SCHEDULER_JOBS j
                            ON (R.JOB_NAME = J.JOB_NAME)
                  WHERE     J.JOB_NAME LIKE 'AVQ$AAA_BGP%'
                        AND J.JOB_NAME != 'AVQ$AAA_BGP_TEMPL')
        SELECT COUNT (*)
          INTO l_nr
          FROM (SELECT aa.owner       "Owner blocker",
                       aa.bgp_id      "Bgp Id blocker",
                       aa.inst_id     "Inst Id blocker",
                       a.sid          "Session Id blocker",
                       ' is blocking ',
                       bb.owner       "Owner blockee",
                       bb.bgp_id      "Bgp Id blockee",
                       bb.inst_id     "Inst Id blockee",
                       b.sid          "Session Id blockee",
                       ' since (sec) ',
                       b.ctime
                  FROM v$lock  a
                       JOIN bgp_info aa ON (aa.SESSION_ID = a.sid)
                       JOIN v$lock b ON (a.id1 = b.id1 AND a.id2 = b.id2)
                       JOIN bgp_info bb ON (bb.SESSION_ID = b.sid)
                 WHERE a.block = 1 AND b.request > 0 AND b.ctime > 180 -- 180 secondes
                                                                      );

        IF l_nr > 0
        THEN
            FOR l_bgp
                IN (WITH
                        bgp_info
                        AS
                            (SELECT TO_NUMBER (
                                        REGEXP_REPLACE (
                                            J.JOB_NAME,
                                            '.*_([[:digit:]]{1,})_.*',
                                            '\1'))    bgp_id,
                                    TO_NUMBER (
                                        REGEXP_REPLACE (
                                            J.JOB_NAME,
                                            '.*_([[:digit:]]{1,})$.*',
                                            '\1'))    inst_id,
                                    r.session_id,
                                    r.owner
                               FROM DBA_SCHEDULER_RUNNING_JOBS  r
                                    JOIN DBA_SCHEDULER_JOBS j
                                        ON (R.JOB_NAME = J.JOB_NAME)
                              WHERE     J.JOB_NAME LIKE 'AVQ$AAA_BGP%'
                                    AND J.JOB_NAME != 'AVQ$AAA_BGP_TEMPL')
                    SELECT DISTINCT aa.owner       Ownerblocker,
                                    aa.bgp_id      BgpIdblocker,
                                    aa.inst_id     InstIdblocker,
                                    a.sid          SessionIdblocker,
                                    bb.owner       Ownerblockee,
                                    bb.bgp_id      BgpIdblockee,
                                    bb.inst_id     InstIdblockee,
                                    b.sid          SessionIdblockee,
                                    b.ctime
                      FROM v$lock  a
                           JOIN bgp_info aa ON (aa.SESSION_ID = a.sid)
                           JOIN v$lock b ON (a.id1 = b.id1 AND a.id2 = b.id2)
                           JOIN bgp_info bb ON (bb.SESSION_ID = b.sid)
                     WHERE a.block = 1 AND b.request > 0 AND b.ctime > 180 -- 180 secondes
                                                                          )
            LOOP
                p_html_pool :=
                       '<br/><b>WARNING for OPERATORS TEAM : BGP '
                    || l_bgp.BgpIdblocker
                    || '.'
                    || l_bgp.InstIdblocker
                    || ' (owner : '
                    || l_bgp.Ownerblocker
                    || ', session ID : '
                    || l_bgp.SessionIdblocker
                    || ') is blocking BGP '
                    || l_bgp.BgpIdblockee
                    || '.'
                    || l_bgp.InstIdblockee
                    || ' (owner : '
                    || l_bgp.Ownerblockee
                    || ', session ID : '
                    || l_bgp.SessionIdblockee
                    || ') since '
                    || l_bgp.ctime
                    || ' seconds.</b><br/>'
                    || p_html_pool;

                IF is_prod
                THEN
                    p_to := upsert_mails (p_to, ';', l_mail_exploit);
                    p_to := upsert_mails (p_to, ';', l_mail_operateurs);
                END IF;
            END LOOP;
        END IF;

        write_query ('BGP session blocking',
                     l_nr,
                     '0',
                     c_blocking_p,
                     '=',
                     'bgp_session_blocking');
    EXCEPTION
        WHEN OTHERS
        THEN
            write_query ('BGP session blocking',
                         1,
                         '0',
                         c_blocking_p,
                         '=',
                         'bgp_session_blocking'); -- OOOOOOOOOOOOOPS: append || sqlerrm;
    END;

    -- Blocked files
    SELECT COUNT (*)
      INTO l_text
      FROM k.msg_os_out
     WHERE     msg_status_id <> 6
           AND timestamp_ins >= TRUNC (SYSDATE)
           AND timestamp_ins <= (SYSDATE - NUMTODSINTERVAL (3, 'MINUTE'))
           AND text != '$AAA_DB_BIN/bdl_mqbridge.sh 502';

    write_query ('Blocked files',
                 l_text,
                 '0',
                 c_blocking_p,
                 '=',
                 'blocked_files');

    IF l_text <> '0'
    THEN
        p_html_pool :=
               '<br/><b>WARNING for OPERATORS TEAM : '
            || l_text
            || ' Blocked files detected <br/>'
            || p_html_pool;

        IF is_prod
        THEN
            p_to := upsert_mails (p_to, ';', l_mail_exploit);
            p_to := upsert_mails (p_to, ';', l_mail_operateurs);
        END IF;
    END IF;

    -- Problems in Time Series injection
    SELECT COUNT (*)
      INTO l_nr
      FROM doc
     WHERE     meta_typ_id = 247
           AND wfc_status_id NOT IN (90, 104)
           AND ins_by_sec_user_id IN (33)
           AND bp_imed_id NOT IN (8)
           AND timestamp >= SYSDATE - 1 / 24;

    write_query ('Problem in TimeSeries Injection',
                 l_nr,
                 '0',
                 c_blocking_p,
                 '=',
                 'pb_timeSeries');

    IF l_nr > 0
    THEN
        SELECT LISTAGG (id, ',')
          INTO l_text
          FROM doc
         WHERE     meta_typ_id = 247
               AND wfc_status_id NOT IN (90, 104)
               AND ins_by_sec_user_id IN (33)
               AND bp_imed_id NOT IN (8)
               AND timestamp >= SYSDATE - 1 / 24;

        p_to := p_to || ';' || l_mail_cbs_transac || ';' || l_mail_secdb;
        p_html_pool :=
               '<br/><b>WARNING for Securities Database and CBS-Transaction TEAMS:  Problem in TimeSeries Injection - orders concerned : </b> '
            || l_text
            || ' <br/>'
            || p_html_pool;
    END IF;

      --Locks
      SELECT COUNT (*)
        INTO l_nr
        FROM v$session_wait w
       WHERE wait_class != 'Idle' AND wait_time = 0 AND seconds_in_wait > 300
    ORDER BY w.seconds_in_wait DESC;

    write_query ('Locks',
                 TO_CHAR (l_nr),
                 '0',
                 c_blocking_p,
                 '=',
                 'locks');

    IF l_nr > 0
    THEN
        p_to := p_to ||';'|| l_mail_dba;
        p_html_pool :=
               '<br/><b>WARNING for DBA TEAM: Number of locks of more than 300 seconds : </b> '
            || l_nr
            || ' <br/>'
            || p_html_pool;

        IF is_prod
        THEN
            p_to := upsert_mails (p_to, ';', l_mail_exploit);
            p_to := upsert_mails (p_to, ';', l_mail_operateurs);
        END IF;
    END IF;



    --Unparsed msg for netw trilog
    SELECT COUNT (*)
      INTO l_nr
      FROM k.msg_extl_in
     WHERE     netw_id = 132
           AND msg_status_id = 8
           AND timestamp > (SYSDATE - NUMTODSINTERVAL (30, 'MINUTE'));

    write_query ('Unparsed msg for netw trilog (132)',
                 TO_CHAR (l_nr),
                 '0',
                 c_blocking_p,
                 '=',
                 'unparsed_trilog');

    IF l_nr > 0
    THEN
        p_to := p_to || ';' || l_mail_msg_fitax;
        p_html_pool :=
               '<br/><b>WARNING for TAX TEAM : '
            || l_nr
            || ' Message trilog error for the last 30 minutes.</b><br/>'
            || p_html_pool;
    END IF;


    DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_FIX_REP');

    --Check for errors on FIX_EXE:REP_CANC_IN messages in the past 15 minutes (added 24/05/2013)
    BEGIN
        l_nr := 0;
        l_text := '';

        FOR l_msg
            IN (SELECT *
                  FROM msg
                 WHERE     netw_id = 83                         -- FIX network
                       AND meta_msg_id = 245   -- messages FIX_EXE_REP_CANC_IN
                       AND msg_status_id = 8                   -- Error status
                       AND hdl_attempt_cnt > 100 -- > 100 retries? -> laisser Avaloq faire le retry?
                       AND timestamp >= SYSDATE - 1 / 24 / 3)
        LOOP
            l_nr := l_nr + 1;

            IF l_nr = 1
            THEN                              --no seperator for first element
                l_text := '' || l_msg.id;
            ELSIF l_nr <= 20
            THEN                                   --not more than 20 messages
                IF MOD (l_nr, 10) = 0
                THEN                              --linebreak every 10 entries
                    l_text := l_text || ', ' || l_msg.id || CHR (10);
                ELSE
                    l_text := l_text || ', ' || l_msg.id;
                END IF;
            ELSIF l_nr = 21
            THEN                               --if more than 20 -> add 3 dots
                l_text := l_text || '...more';
            END IF;
        END LOOP;

        IF l_nr > 0
        THEN
            p_html_pool :=
                   '<br/><b>WARNING for Market Team : '
                || l_nr
                || ' Errors on FIX_EXE_REP_CANC_IN message: '
                || l_text
                || '</b>'
                || p_html_pool;
            p_to := p_to || ';' || l_mail_market;
        END IF;

        write_query ('Error on FIX_EXE_REP_CANC_IN message (15 minutes)',
                     l_nr,
                     '0',
                     c_major_p,
                     '=',
                     'fix_exe_rep_canc_in');
    END;

    DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_FIX_DOC_CANC_REQ_IN');

    --Check if message of type FIX_DOC_CANC_REQ_IN is in error (added 06/11/2013)
    DECLARE
        l_nr     NUMBER := 0;
        l_text   VARCHAR2 (500) := '';
    BEGIN
        FOR l_msg
            IN (SELECT *
                  FROM msg
                 WHERE     netw_id = 83                         -- FIX network
                       AND meta_msg_id = 733   -- messages FIX_DOC_CANC_REQ_IN
                       AND msg_status_id = 8                   -- Error status
                       AND timestamp >= SYSDATE - 1 / 24 / 3)
        LOOP
            l_nr := l_nr + 1;

            IF l_nr = 1
            THEN                              --no seperator for first element
                l_text := '' || l_msg.id;
            ELSIF l_nr <= 20
            THEN                                   --not more than 20 messages
                IF MOD (l_nr, 10) = 0
                THEN                              --linebreak every 10 entries
                    l_text := l_text || ', ' || l_msg.id || CHR (10);
                ELSE
                    l_text := l_text || ', ' || l_msg.id;
                END IF;
            ELSIF l_nr = 21
            THEN                               --if more than 20 -> add 3 dots
                l_text := l_text || '...more';
            END IF;
        END LOOP;

        IF l_nr > 0
        THEN
            p_html_pool :=
                   '<br/><b>WARNING Stex Fix : '
                || l_nr
                || ' Errors on FIX_DOC_CANC_REQ_IN message: '
                || l_text
                || '</b>'
                || p_html_pool;
            p_to := p_to || ';' || l_mail_stex_fix;
        END IF;

        write_query ('Error on FIX_DOC_CANC_REQ_IN message (15 minutes)',
                     l_nr,
                     '0',
                     c_major_p,
                     '=',
                     'fix_doc_canc_req_in');
    EXCEPTION
        WHEN OTHERS
        THEN
            write_query ('Error on FIX_DOC_CANC_REQ_IN message (15 minutes)',
                         1,
                         '0',
                         c_major_p,
                         '=',
                         'fix_doc_canc_req_in'); -- OOOOOOOOOOOPS: apprend || sqlerrm);
    END;


    --Check log for BGP File Dispatcher issue (22/03/2013) -- increased time period to 30 minutes 14/05/2013

    SELECT COUNT (*)
      INTO l_nr
      FROM LOG
     WHERE     ctx LIKE
                   'file_idx#.store(i_file_status_id => %, i_file_idx_batch_id => %)'
           AND timestamp > SYSDATE - 1 / 24 / 2;

    write_query ('New File Dispatcher Issue in last 30 minutes',
                 TO_CHAR (l_nr),
                 '0',
                 c_sys_blocking_p,
                 '=',
                 'file_dispatcher_issue');

    IF l_nr > 0
    THEN
        p_html_pool :=
               '<br/><b>WARNING for AM TEAM : BGP File Dispatcher needs to be restarted.</b><br/>'
            || p_html_pool;

        IF is_prod
        THEN
            p_to := upsert_mails (p_to, ';', l_mail_exploit);
            p_to := upsert_mails (p_to, ';', l_mail_operateurs);
        END IF;
    END IF;

    SELECT COUNT (*)
      INTO l_nr
      FROM LOG
     WHERE     ctx LIKE 'file_lib#.file#stmt(i_file => %, i_file_aggr => %)'
           AND timestamp > SYSDATE - 1 / 24 / 2;

    write_query ('File Dispatcher Issue in last 30 minutes ',
                 TO_CHAR (l_nr),
                 '0',
                 c_blocking_p,
                 '=',
                 'file_dispatcher_issue');


    --Check for message bundles in error - added 22/05/2013

    DECLARE
        l_meta_nr     NUMBER;
        l_meta_name   VARCHAR2 (250);
    BEGIN
        l_nr := 0;
        l_text := '';

        --check for error logs
        SELECT COUNT (*)
          INTO l_nr
          FROM LOG
         WHERE     text LIKE '%netw#parse_bdl.prc_msg%'
               AND timestamp > SYSDATE - 1 / 24 / 4;

        IF l_nr > 0
        THEN
            --get last msg bdl in error
            SELECT id, meta_msg_bdl_id
              INTO l_nr2, l_meta_nr
              FROM (  SELECT *
                        FROM msg_bdl
                       WHERE bdl_status_id IN (8)
                    ORDER BY id DESC)
             WHERE ROWNUM = l_nr;

            SELECT intl_id
              INTO l_meta_name
              FROM meta_msg_bdl
             WHERE id = l_meta_nr;

            p_html_pool :=
                   '<br/><b>WARNING : Message Bundle in error: '
                || l_nr2
                || '('
                || l_meta_name
                || ')</b>'
                || p_html_pool;
            p_to := p_to || ';' || l_mail_msg_bdl;
        END IF;

        write_query ('Message Bundle in error (15 minutes)',
                     l_nr,
                     '0',
                     c_blocking_p,
                     '=',
                     'msg_bundle_error');
    EXCEPTION
        WHEN OTHERS
        THEN
            write_query ('Unparsed Message error (15 minutes)',
                         l_nr,
                         '0',
                         c_blocking_p,
                         '=',
                         'msg_bundle_error');
    END;


    --Check all MSG AFP OUT for Replication are consumed (by BGP JMS -> ActiveMQ -> Sync Server)
    SELECT COUNT (*)
      INTO l_nr
      FROM k.msg_extl_out mextl
     WHERE     mextl.netw_id IN (189, 461)
           AND timestamp > TRUNC (SYSDATE)
           AND mextl.msg_status_id = 1;

    write_query ('AFP OUT msg not consumed',
                 TO_CHAR (l_nr),
                 '5',
                 c_blocking_p,
                 '<=',
                 'none');


    --Check AFP replication errors in FWOM on ACP side.
    DECLARE
        l_tab    VARCHAR2 (3200);
        l_sql    VARCHAR2 (3200);
        l_nb     INTEGER;
        l_tot    INTEGER;
        l_text   VARCHAR2 (500) := '';
    BEGIN
        l_tot := 0;

        FOR l_tab
            IN (SELECT table_name
                  FROM all_tables
                 WHERE     owner = 'AFS'
                       AND table_name LIKE 'ERR$%'
                       AND table_name NOT IN
                               ('ERR$_AFS_OBJ_ADDR',
                                'ERR$_AFS_DOC_TAB_POSTIT',
                                'ERR$_AFS_OBJ_PERSON'))
        LOOP
            l_sql :=
                   'select count(*) from AFS.'
                || l_tab.table_name
                || ' where timestp > sysdate - INTERVAL ''1'' HOUR';

            EXECUTE IMMEDIATE l_sql
                INTO l_nb;

            IF l_nb > 0
            THEN
                l_text :=
                       l_text
                    || l_nb
                    || ' error(s) in table : '
                    || l_tab.table_name
                    || CHR (10);
                l_tot := l_tot + l_nb;
            END IF;
        END LOOP;

        write_query ('AFP replication error (last hour)',
                     TO_CHAR (l_tot),
                     '0',
                     c_none_p,
                     '=',
                     'none');

        IF LENGTH (l_text) > 0
        THEN
            p_html_pool :=
                   '<br/><b>WARNING for AFP Team : '
                || l_tot
                || ' replication error(s) logged in the last 1 Hour: </b>'
                || l_text
                || '</b><br/>'
                || p_html_pool;
            p_to := p_to || ';' || l_mail_afp;
        END IF;
    END;

    -- STEX orders in high number of execution

    DECLARE
        l_cnt          NUMBER := 0;
        l_sys_minute   NUMBER;
        l_cnt_for      NUMBER := 0;
        l_text         VARCHAR2 (1000) := '';
        l_orig_qty     NUMBER := 0;
        l_sum          NUMBER := 0;
        l_remain_qty   NUMBER := 0;
        l_progress     NUMBER := 0;
    BEGIN
        SELECT EXTRACT (MINUTE FROM SYSTIMESTAMP)     AS current_minute
          INTO l_sys_minute
          FROM DUAL;

        IF l_sys_minute BETWEEN 0 AND 15
        THEN
            FOR rec
                IN (  SELECT e.doc_id, COUNT (e.doc_id) AS cnt
                        FROM k.doc d, k.docp_exec_aggr_entry e
                       WHERE     d.id = e.doc_id
                             AND d.timestamp > TRUNC (SYSDATE) - 5
                    GROUP BY e.doc_id
                      HAVING COUNT (*) > 5000
                    ORDER BY COUNT (*) DESC)
            LOOP
                l_orig_qty := 0;
                l_sum := 0;
                l_remain_qty := 0;

                SELECT amount
                  INTO l_orig_qty
                  FROM k.doc
                 WHERE id = rec.doc_id;

                SELECT SUM (e.qty)
                  INTO l_sum
                  FROM k.docp_exec_aggr_entry e, k.doc d
                 WHERE d.id = rec.doc_id AND d.id = e.doc_id;

                l_remain_qty := l_orig_qty - l_sum;

                IF (l_orig_qty <> 0)
                THEN
                    l_progress := ROUND(100 * ABS (l_sum / l_orig_qty),2);
                END IF;

                IF (l_remain_qty <> 0)
                THEN
                    l_cnt := l_cnt + 1;
                    l_text :=
                           l_text
                        || '<br> Order Nr: '
                        || rec.doc_id
                        || ' - Count of exec aggr:'
                        || rec.cnt
                        || ' - Orig. Qty: '
                        || l_orig_qty
                        || ' - Sum aggr Qty: '
                        || l_sum
                        || ' - Remaining Qty: '
                        || l_remain_qty
                        || ' - Progress Ratio (Sum/Orig Qty): '
                        || l_progress
                        || ' %';
                END IF;
            END LOOP;

            write_query (
                'Recent STEX orders with more than 5000 executions not completely executed',
                TO_CHAR (l_cnt),
                '0',
                c_blocking_p,
                '=',
                'none');

            IF l_cnt > 0
            THEN
                p_html_pool :=
                       '<br/><b>WARNING for COMTAX Team on STEX orders : '
                    || l_text
                    || '</b><br/>'
                    || p_html_pool;
                p_to := p_to || ';' || l_mail_tax_compliance;
            END IF;
        END IF;
    END;

    -- BU CISG messages in 'wait for ack'
    DECLARE
        c_check_name       VARCHAR2 (100) := 'wait_ack_cisg';
        c_check_title      VARCHAR2 (100)
                               := 'Outgoing Msg in Wait for Ack - CISG';

        TYPE array_netw IS TABLE OF VARCHAR2 (100);

        TYPE array_meta_msg IS TABLE OF VARCHAR2 (100);

        TYPE array_count IS TABLE OF NUMBER;

        TYPE array_error IS TABLE OF BOOLEAN;

        l_array_netw       array_netw := array_netw ();
        l_array_meta_msg   array_meta_msg := array_meta_msg ();
        l_array_count      array_count := array_count ();
        l_array_error      array_error := array_error ();

        i                  NUMBER := 1;

        l_cnt_blocking     NUMBER := 0;
    BEGIN
        FOR l_res
            IN (SELECT (SELECT intl_id
                          FROM code_netw
                         WHERE id = res.netw_id)        netw,
                       (SELECT intl_id
                          FROM meta_msg
                         WHERE id = res.meta_msg_id)    meta_msg,
                       cnt
                  FROM (  SELECT netw_id, meta_msg_id, COUNT (*) cnt
                            FROM msg
                           WHERE     1 = 1
                                 AND dir = 'o'
                                 AND bu_id = 8
                                 AND msg_status_id = 2
                                 AND timestamp BETWEEN SYSDATE - 1
                                                   AND SYSDATE - 1 / 24 / 4
                        GROUP BY netw_id, meta_msg_id) res)
        LOOP
            l_array_netw.EXTEND ();
            l_array_netw (i) := l_res.netw;
            l_array_meta_msg.EXTEND ();
            l_array_meta_msg (i) := l_res.meta_msg;
            l_array_count.EXTEND ();
            l_array_count (i) := l_res.cnt;
            l_array_error.EXTEND ();
            l_array_error (i) := FALSE;

            IF l_res.cnt > 50
            THEN
                FOR l_trans
                    IN (  SELECT code_netw.intl_id     AS netw,
                                 meta_msg.intl_id      AS meta_msg,
                                 COUNT (*)             AS cnt_trans
                            FROM msg_trans,
                                 msg,
                                 code_netw,
                                 meta_msg
                           WHERE     new_msg_status_id = 3
                                 AND msg_trans.timestp BETWEEN SYSDATE - 1
                                                           AND   SYSDATE
                                                               - 1 / 24 / 4
                                 AND msg_trans.msg_id = msg.id
                                 AND timestamp BETWEEN SYSDATE - 1
                                                   AND SYSDATE - 1 / 24 / 4
                                 AND msg.dir = 'o'
                                 AND msg.bu_id = 8
                                 AND msg.netw_id = code_netw.id
                                 AND msg.meta_msg_id = meta_msg.id
                                 AND code_netw.intl_id = l_res.netw
                                 AND meta_msg.intl_id = l_res.meta_msg
                        GROUP BY code_netw.intl_id, meta_msg.intl_id)
                LOOP
                    IF l_trans.cnt_trans = 0
                    THEN
                        l_cnt_blocking := l_cnt_blocking + 1;
                        l_array_error (i) := TRUE;
                    END IF;
                END LOOP;
            END IF;

            i := i + 1;
        END LOOP;

        write_query (c_check_title,
                     TO_CHAR (l_cnt_blocking),
                     '0',
                     c_blocking_p,
                     '=',
                     c_check_name);

        FOR j IN 1 .. i - 1
        LOOP
            html_append (
                write_msg (
                       '&nbsp;&nbsp;&nbsp;->'
                    || l_array_netw (j)
                    || ' - '
                    || l_array_meta_msg (j)
                    || ' - count:'
                    || l_array_count (j)));

            IF l_array_error (j)
            THEN
                html_append (
                    write_msg (
                        '&nbsp;&nbsp;&nbsp;&nbsp;-> /!\ NO MSG TRANS STATUS'));
            END IF;
        END LOOP;

        IF l_cnt_blocking > 0
        THEN
            p_html_pool :=
                   '<br/><b>WARNING for Middleware Team : Possibility of CISG MQ FAIL</b>'
                || p_html_pool;
            p_to := p_to || ';' || l_mail_it_middleware;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            handle_check_exception (c_check_name,
                                    SQLERRM,
                                    DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    END;


    --Security
    write_subheader ('Security');

    --Open end users
    SELECT COUNT (*)
      INTO l_text
      FROM k.sec_user_acc_v a, k.sec_user s
     WHERE     a.sec_user_id = s.id
           AND s.user_type_id = 1
           AND a.new_acc_status IN ('OPEN', 'EXPIRED');

    write_query ('Open end users',
                 l_text,
                 '300',
                 c_major_p,
                 '>=',
                 'open_end_user');

    --CRM VPD activation check,  src NC$VPD_USER_SEC  must be re-applied after a CRM table modification
    SELECT COUNT (*)
      INTO l_nr
      FROM dba_tables
     WHERE     owner = 'K'
           AND table_name LIKE 'BDL_CRM%'
           AND table_name NOT IN ('BDL_CRM_BU_SAT_MAP', 'BDL_CRM_LOG')
           AND table_name NOT IN
                   (SELECT object_name
                      FROM sys.dba_policies
                     WHERE     object_owner = 'K'
                           AND object_name LIKE 'BDL_CRM%'
                           AND package = 'NC$VPD_CTX_MGR#'
                           AND function = 'GET_VISIB_BU');

    write_query ('VPD CRM',
                 l_nr,
                 '0',
                 c_none_p,
                 '=',
                 'vpd_crm');

    -- Safewatch connection check
    DBMS_APPLICATION_INFO.SET_ACTION (
        'CHECK_SAFEWATCH_CONNEXION_OR_SLOWNESS');

    DECLARE
        l_nr      NUMBER := 0;
        l_count   NUMBER := 0;
        l_text    VARCHAR2 (4000) := '';
    BEGIN
        DBMS_APPLICATION_INFO.SET_ACTION (
            'CHECK_SAFEWATCH_CONNEXION_OR_SLOWNESS');

        IF is_prod
        THEN
            SELECT COUNT (*)
              INTO l_nr
              FROM doc d, doc_crm_issue crm, obj_bp bp1
             WHERE     d.id = crm.doc_id
                   AND d.bp_1_id = bp1.obj_id
                   AND d.meta_typ_id = 215                        -- crm issue
                   AND d.order_type_id = 30073            -- order_type wtlist
                   AND crm.issue_type_id = 5104       -- issue_type trans_auth
                   AND crm.issue_sub_type_id = 1105 -- sub_issue_type nc$wtlist_timeout
                   AND bp1.bu_id IN (3,
                                     7,
                                     10,
                                     11)
                   AND d.wfc_status_id NOT IN (90, 91)
                   AND d.timestamp > SYSDATE - 16 / (24 * 60);
        ELSIF is_pre
        THEN
            SELECT COUNT (*)
              INTO l_nr
              FROM doc d, doc_crm_issue crm, obj_bp bp1
             WHERE     d.id = crm.doc_id
                   AND d.bp_1_id = bp1.obj_id
                   AND d.meta_typ_id = 215                        -- crm issue
                   AND d.order_type_id = 30073            -- order_type wtlist
                   AND crm.issue_type_id = 5104       -- issue_type trans_auth
                   AND crm.issue_sub_type_id = 1105 -- sub_issue_type nc$wtlist_timeout
                   AND bp1.bu_id IN (3,
                                     7,
                                     10,
                                     11)
                   AND d.wfc_status_id NOT IN (90, 91)
                   AND d.timestamp > SYSDATE - 1;
        END IF;

        write_query ('Crm issue safewatch timeout',
                     TO_CHAR (l_nr),
                     '0',
                     c_blocking_p,
                     '=',
                     'crm_issue_wtlist_timeout');

        IF l_nr > 0
        THEN
            l_text := NULL;

            IF is_prod
            THEN
                FOR bu IN (SELECT COLUMN_VALUE     AS BU_ID
                             FROM TABLE (SYS.dbms_debug_vc2coll (3,
                                                                 7,
                                                                 10,
                                                                 11)))
                LOOP
                    FOR ent
                        IN (SELECT doc_id, bu_id, DOC_REF_ID
                              FROM doc d, doc_crm_issue crm, obj_bp bp1
                             WHERE     d.id = crm.doc_id
                                   AND d.bp_1_id = bp1.obj_id
                                   AND d.meta_typ_id = 215
                                   AND d.order_type_id = 30073
                                   AND crm.issue_type_id = 5104
                                   AND crm.issue_sub_type_id = 1105
                                   AND bp1.bu_id = bu.bu_id
                                   AND d.timestamp > SYSDATE - 17 / (24 * 60) -- add one minute to avoid alert without doc_id displayed if check is launched at the right bad time
                                   AND d.wfc_status_id NOT IN (90, 91))
                    LOOP
                        --limit entries to 20 by counter
                        IF l_count > 20
                        THEN
                            EXIT;
                        END IF;

                        --add no comma for first entry
                        IF l_text IS NOT NULL
                        THEN
                            l_text := l_text || ', ';
                        END IF;

                        --add doc_id
                        l_text :=
                               l_text
                            || TRUNC (TO_CHAR (ent.DOC_ID, 99999999999999))
                            || ' (DOC_REF_ID : '
                            || ent.DOC_REF_ID
                            || ' '
                            || ent.bu_id
                            || ')';

                        --increment failsafe counter
                        l_count := l_count + 1;
                    END LOOP;

                    l_count := 0;            --reset increment on new_BU query
                END LOOP;

                p_html_pool :=
                       '<br/><b>WARNING for TAX TEAM : '
                    || l_nr
                    || ' issues safewatch in timeout:</b><br/>'
                    || l_text
                    || '<br/>'
                    || p_html_pool;

                l_is_override := TRUE;
                l_override_mail :=
                    upsert_mails (l_override_mail,
                                  ';',
                                  l_mail_tax_compliance);
                p_to := upsert_mails (p_to, ';', l_mail_tax_compliance);
            ELSIF is_pre
            THEN
                FOR bu IN (SELECT COLUMN_VALUE     AS BU_ID
                             FROM TABLE (SYS.dbms_debug_vc2coll (3,
                                                                 7,
                                                                 10,
                                                                 11)))
                LOOP
                    FOR ent
                        IN (SELECT doc_id, bu_id, DOC_REF_ID
                              FROM doc d, doc_crm_issue crm, obj_bp bp1
                             WHERE     d.id = crm.doc_id
                                   AND d.bp_1_id = bp1.obj_id
                                   AND d.meta_typ_id = 215
                                   AND d.order_type_id = 30073
                                   AND crm.issue_type_id = 5104
                                   AND crm.issue_sub_type_id = 1105
                                   AND bp1.bu_id = bu.bu_id
                                   AND d.timestamp > SYSDATE - 1
                                   AND d.wfc_status_id NOT IN (90, 91))
                    LOOP
                        --limit entries to 20 by counter
                        IF l_count > 20
                        THEN
                            EXIT;
                        END IF;

                        --add no comma for first entry
                        IF l_text IS NOT NULL
                        THEN
                            l_text := l_text || ', ';
                        END IF;

                        --add doc_id
                        l_text :=
                               l_text
                            || TRUNC (TO_CHAR (ent.DOC_ID, 99999999999999))
                            || ' (DOC_REF_ID : '
                            || ent.DOC_REF_ID
                            || ' '
                            || ent.bu_id
                            || ')';

                        --increment failsafe counter
                        l_count := l_count + 1;
                    END LOOP;

                    l_count := 0;            --reset increment on new_BU query
                END LOOP;

                p_html_pool :=
                       '<br/><b>WARNING for TAX TEAM / SERVICE DESK FIX TEAM : '
                    || l_nr
                    || ' issues safewatch in timeout:</b><br/>'
                    || l_text
                    || '<br/>'
                    || p_html_pool;

                p_to := upsert_mails (p_to, ';', l_mail_tax_compliance);
            END IF;
        END IF;
    END;

    --Pillars to be deleted
    IF     l_execution_time >
           TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 7:00',
                    'ddmmyyyy HH24:MI')
       AND l_execution_time <
           TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:20',
                    'ddmmyyyy HH24:MI')                          --tODO fix me
    THEN
        write_subheader ('Pillars');

        DECLARE
            c_check_name    VARCHAR2 (100) := 'pillar_delete';
            c_check_title   VARCHAR2 (100)
                                := 'Pillars deleted in the next 30 days';
            l_count         NUMBER := 0;
            l_max           NUMBER := 6000;      --limit adapted on 13.12.2023
        BEGIN
            SELECT COUNT (*)     cnt
              INTO l_count
              FROM serpil
             WHERE     del_date_tab IS NOT NULL
                   AND del_date_tab BETWEEN SYSDATE AND SYSDATE + 30;

            write_query (c_check_title,
                         l_count,
                         l_max,
                         c_none_p,
                         '<=',
                         c_check_name);

            FOR l_pillar
                IN (  SELECT tab, COUNT (*) cnt
                        FROM serpil
                       WHERE     del_date_tab IS NOT NULL
                             AND del_date_tab BETWEEN SYSDATE AND SYSDATE + 30
                    GROUP BY tab
                    ORDER BY tab)
            LOOP
                IF l_pillar.tab = 'BALSTRU_SERPIL'
                THEN
                    IF l_pillar.cnt > 1000
                    THEN
                        write_query ('->  ' || l_pillar.tab,
                                     l_pillar.cnt,
                                     '1000',
                                     c_major_p,
                                     '<=',
                                     c_check_name);
                    END IF;
                ELSIF l_pillar.tab LIKE 'POS_RECON_SERPIL%'
                THEN
                    IF l_pillar.cnt > 5
                    THEN
                        write_query ('->  ' || l_pillar.tab,
                                     l_pillar.cnt,
                                     '5',
                                     c_major_p,
                                     '<=',
                                     c_check_name);
                    END IF;
                ELSIF l_pillar.tab LIKE 'PERF%'
                THEN
                    IF l_pillar.cnt > 0
                    THEN
                        write_query ('->  ' || l_pillar.tab,
                                     l_pillar.cnt,
                                     '0',
                                     c_blocking_p,
                                     '<=',
                                     c_check_name);
                        p_html_pool :=
                               '<br/><b>WARNING for RM TEAM : '
                            || l_pillar.cnt
                            || ' PERF% pillars will be deleted in the next 30 days.</b><br/>'
                            || p_html_pool;

                        IF is_prod
                        THEN
                            p_to := upsert_mails (p_to, ';', l_mail_exploit);
                        END IF;
                    END IF;
                ELSIF l_pillar.cnt > 300
                THEN                             --limit adapted on 21.08.2023
                    write_query ('->  ' || l_pillar.tab,
                                 l_pillar.cnt,
                                 '100',
                                 c_major_p,
                                 '<=',
                                 c_check_name);
                END IF;
            END LOOP;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END;
    END IF;

    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    --
    --Name: Functional checks for european business units
    --
    --Summary: Checks are not to be executed on Singapore only hours and dates
    --
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------

    DECLARE
        c_force_bdl_active   BOOLEAN := FALSE;
        c_force_active       BOOLEAN := FALSE;


        ---------------------------------
        --Summary:check if user is blocking prcq on order
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_user_lock
        IS
            -- Order being locked

            l_is_empty    NUMBER := 1;
            l_cnt_tot     NUMBER := 0;
            l_sec_user    VARCHAR2 (20);
            l_list_user   VARCHAR2 (255);

            CURSOR c1 IS
                  SELECT REGEXP_SUBSTR (SUBSTR (err_stack, '53'), '[0-9]{8,9}')
                             order_nr_err_stack,
                         ctx,
                         REGEXP_SUBSTR (SUBSTR (err_stack, '53'),
                                        '[A-Z]+[0-9]{1}+[A-Z]*')
                             sec_user,
                         COUNT (*)
                             cnt
                    FROM (SELECT *
                            FROM k.LOG
                           WHERE timestamp >
                                 SYSDATE - NUMTODSINTERVAL (15, 'MINUTE'))
                   WHERE err_stack LIKE
                             'ORA-20001: 5000:Transaction already in use by user:%'
                GROUP BY REGEXP_SUBSTR (SUBSTR (err_stack, '53'),
                                        '[0-9]{8,9}'),
                         ctx,
                         REGEXP_SUBSTR (SUBSTR (err_stack, '53'),
                                        '[A-Z]+[0-9]{1}+[A-Z]*');
        BEGIN
            FOR rec IN c1
            LOOP
                --get names
                IF (rec.cnt > 3)
                THEN
                    IF (l_list_user IS NULL)
                    THEN
                        l_list_user := rec.sec_user;
                    ELSIF (   (INSTR (l_list_user, rec.sec_user) = 0)
                           OR (INSTR (l_list_user, rec.sec_user) IS NULL))
                    THEN
                        l_list_user := l_list_user || ', ' || rec.sec_user;
                    END IF;
                END IF;
            END LOOP;

            l_text :=
                   '<br/><br/><b>WARNING for '
                || l_list_user
                || ' : In the last 15 minutes :</b>';

            FOR rec IN c1
            LOOP
                --only for more then 3 retry on a process exec
                IF (rec.cnt > 3)
                THEN
                    l_text :=
                           l_text
                        || '<br/> User '
                        || rec.sec_user
                        || ' locking order '
                        || rec.order_nr_err_stack
                        || ' in Avaloq user interface prevented '
                        || rec.cnt
                        || ' try on a process execution or msg injection ('
                        || rec.ctx
                        || ').';
                    --check if the user is in 'user' format (not technical)
                    --select regexp_substr(rec.sec_user,'[A-Z]+[0-9]{1}+[A-Z]*') into l_sec_user from dual;
                    l_sec_user := rec.sec_user;

                    IF (l_sec_user IS NOT NULL)
                    THEN
                        SELECT COUNT (*)
                          INTO l_sec_user_count
                          FROM sec_user
                         WHERE oracle_user = rec.sec_user;

                        IF l_sec_user_count != 0
                        THEN
                            SELECT email
                              INTO l_sec_user_mail
                              FROM sec_user
                             WHERE oracle_user = rec.sec_user;
                        ELSE
                            IF is_prod
                            THEN
                                l_sec_user_mail :=
                                    rec.sec_user || '@blu.bank';
                            ELSE
                                l_sec_user_mail :=
                                    'relman@blu.bank';
                            END IF;
                        END IF;

                        --check if user already in recipients list, if possible take email from sec_user table
                        IF     (   (INSTR (l_mail_lock, l_sec_user_mail) = 0)
                                OR (INSTR (l_mail_lock, l_sec_user_mail) IS NULL))
                           AND l_mail_lock_cnt <= 10
                        THEN
                            l_mail_lock_cnt := l_mail_lock_cnt + 1;
                            l_mail_lock :=
                                l_mail_lock || ';' || l_sec_user_mail;
                        END IF;
                    END IF;

                    l_sec_user := '';
                    l_is_empty := 0;
                END IF;

                l_cnt_tot := l_cnt_tot + rec.cnt;
            END LOOP;

            IF l_is_empty = 0
            THEN
                p_html_pool := l_text || p_html_pool;
            END IF;

            --################  TO DESACTIVATE FOR TESTS  ----------- START  #################
            IF is_prod
            THEN
                p_to := p_to || l_mail_lock;
--             ELSE
--                 p_to := p_to || ';dg.informatique.AppMan.rm@blu.bank';
            END IF;

            --################   END ---------------- TO DESACTIVATE FOR TESTS   #################
            write_query ('User locking order (last 15 minutes)',
                         TO_CHAR (l_cnt_tot),
                         '0',
                         c_none_p,
                         '=',
                         'user_lock');
        END check_user_lock;


        ---------------------------------
        --Summary:Check if payment order is locked for more than 30 mins
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_pay_order_locked
        IS
            l_count       NUMBER := 0;
            l_max         NUMBER := 10;
            p_temp_html   CLOB;
        BEGIN
            FOR c
                IN (SELECT d.id,
                           s.name,
                           s.email,
                           ROUND (l.ctime / 60, 0)     AS MIN
                      FROM v$lock     l,
                           k.doc      d,
                           sec_user   s,
                           v$session  sess
                     WHERE     1 = 1
                           AND l.TYPE = 'UL'
                           AND d.id = l.id1
                           AND sess.sid = l.sid
                           AND d.meta_typ_id = 6
                           AND d.bp_imed_id = 3
                           AND l.ctime >= 1800
                           AND d.wfc_status_id NOT IN (90, 91)
                           AND TO_CHAR (s.id) = sess.client_info
                           AND s.user_type_id = 1  -- limit to chargeable user
                                                 )
            LOOP
                l_count := l_count + 1;

                IF l_count <= l_max
                THEN
                    IF l_count = 1
                    THEN
                        p_temp_html :=
                            '- ' || TO_CHAR (c.id) || ' (' || c.name || ')';
                    ELSE
                        p_temp_html :=
                               p_temp_html
                            || ', '
                            || TO_CHAR (c.id)
                            || ' ('
                            || c.name
                            || ')';
                    END IF;
                END IF;

                IF c.email IS NOT NULL
                THEN
                    p_to := upsert_mails (p_to, ';', assign_mail (c.email));
                END IF;
            END LOOP;

            IF l_count > 0
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_pay_dflt);

                IF l_count > l_max
                THEN
                    p_temp_html := p_temp_html || ' (more...)';
                END IF;

                p_html_pool :=
                       '<br /><b>WARNING for PAYMENT TEAM : '
                    || TO_CHAR (l_count)
                    || ' Payment(s) locked more than 30 min</b><br />'
                    || p_temp_html
                    || '<br />'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                write_query ('Payment Orders Locked',
                             1,
                             '0',
                             c_blocking_p,
                             '=',
                             'pay_order_locked'); -- OOOOOOOOOOOOOOOPS : append || sqlerrm;
        END check_pay_order_locked;


        ---------------------------------
        --Summary: Timing Condition for SMP BU check
        --Parameters:
        --Author:CHRBEC
        --Date:18/12/2018
        ---------------------------------
        FUNCTION cond_check_smp_bu
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF (SYSDATE BETWEEN TO_DATE (
                                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy')
                                    || ' 12:00',
                                    'ddmmyyyy HH24:MI')
                            AND TO_DATE (
                                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy')
                                    || ' 12:20',
                                    'ddmmyyyy HH24:MI'))
            THEN
                RETURN TRUE;
            ELSE
                RETURN FALSE;
            END IF;
        END cond_check_smp_bu;

        ---------------------------------
        --Summary: Check if "PAD Letter" minstr have the correct SMP assigned
        --Parameters:
        --Author:CHRBEC, modified by ADRGUS9
        --Date:18/12/2018
        ---------------------------------
        PROCEDURE check_smp_bu
        IS
            c_check_name    VARCHAR2 (100) := 'smp_bu';
            c_check_title   VARCHAR2 (100)
                                := 'BPs with missing or incoherent SMP';
            l_cnt           NUMBER := 0;
            c_max           NUMBER := 0;
        BEGIN
            FOR l_bp
                IN (SELECT mi.obj_id BP_ID, o.bu_id BP_BU_ID
                      FROM minstr mi INNER JOIN obj o ON mi.obj_id = o.id
                     WHERE     mi.minstr_templ_id = 5347
                           AND (   (o.close_Date IS NULL)
                                OR (o.close_date >= base#.today))
                           AND NOT EXISTS
                                   (SELECT 1
                                      FROM minstr_item  mit
                                           INNER JOIN obj_smp os
                                               ON mit.smp_id = os.obj_id
                                           INNER JOIN obj_key ok
                                               ON os.obj_id = ok.obj_id
                                     WHERE     mit.minstr_id = mi.id
                                           AND meta_smp_id = 242
                                           AND mit.mail_id = 446
                                           AND os.bu_id = o.bu_id
                                           AND ok.obj_key_id = 231
                                           AND UPPER (ok.key_val) = 'PAD'))
            LOOP
                l_cnt := l_cnt + 1;

                IF l_cnt = 1
                THEN                          --no seperator for first element
                    l_text :=
                        '' || l_bp.BP_ID || '(BU ' || l_bp.BP_BU_ID || ')';
                ELSIF l_cnt BETWEEN 2 AND 50
                THEN                                    --not more than 50 IDs
                    l_text :=
                           l_text
                        || ', '
                        || l_bp.BP_ID
                        || '(BU '
                        || l_bp.BP_BU_ID
                        || ')';
                ELSIF l_cnt = 51
                THEN                           --if more than 50 -> add 3 dots
                    l_text := l_text || '...more';
                END IF;
            END LOOP;

            write_query (c_check_title,
                         l_cnt,
                         c_max,
                         c_major_p,
                         '=',
                         c_check_name);

            IF l_cnt > 0
            THEN        --warning message including ID list, include dest mail
                p_html_pool :=
                       '<br/><b>WARNING for REPORTING TEAM : '
                    || l_cnt
                    || ' BPs with missing or incoherent SMP </b><br/>'
                    || l_text
                    || '<br/>'
                    || p_html_pool;
                p_to := upsert_mails (p_to, ';', l_mail_client_reporting);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_smp_bu;



        ---------------------------------
        --Summary:Check if european business units are active - date and timeframe, exclude holidays
        --Parameters:none
        --Author:CHRBEC
        --Date:08/08/2013
        ---------------------------------
        FUNCTION bdl_active_cond
            RETURN BOOLEAN
        IS
            l_bdl_active   BOOLEAN := TRUE;
            l_cnt_lu       NUMBER;
            l_cnt_be       NUMBER;
        BEGIN
            --limit timeframe to european business hours - sysdate is in european timezone
            IF    SYSDATE <
                  TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:00',
                           'ddmmyyyy HH24:MI')
               OR SYSDATE >
                  TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 20:00',
                           'ddmmyyyy HH24:MI')
               OR is_weekend
            THEN
                l_bdl_active := FALSE;
            END IF;

            --exclude holidays (only luxembourg and belgium country day offs)
            SELECT COUNT (*)
              INTO l_cnt_lu
              FROM country_day_off
             WHERE     day = TRUNC (CURRENT_DATE)
                   AND country_id = 2015
                   AND is_bank_day = '+';

            SELECT COUNT (*)
              INTO l_cnt_be
              FROM country_day_off
             WHERE     day = TRUNC (CURRENT_DATE)
                   AND country_id = 2008
                   AND is_bank_day = '+';

            IF l_cnt_lu > 0 AND l_cnt_be > 0
            THEN
                l_bdl_active := FALSE;
            END IF;

            RETURN l_bdl_active;
        END bdl_active_cond;


        ---------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------
        --European Rates and Prices
        ---------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------

        ---------------------------------
        --Summary:Date and timeframe condition FX Rates last entries check
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        FUNCTION cond_fx_rates_trade
            RETURN BOOLEAN
        IS
        BEGIN
            RETURN TRUE;
        END cond_fx_rates_trade;

        ---------------------------------
        --Summary:Date and timeframe condition FX Rates last entries check -> blocking status,  false means severity = none
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        FUNCTION cond_fx_rates_trade_blocking
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF     (SYSDATE BETWEEN TO_DATE (
                                           TO_CHAR (TRUNC (SYSDATE),
                                                    'ddmmyyyy')
                                        || ' 06:00',
                                        'ddmmyyyy HH24:MI')
                                AND TO_DATE (
                                           TO_CHAR (TRUNC (SYSDATE),
                                                    'ddmmyyyy')
                                        || ' 18:45',
                                        'ddmmyyyy HH24:MI'))
               AND (SYSDATE NOT BETWEEN TO_DATE (
                                               TO_CHAR (TRUNC (SYSDATE),
                                                        'ddmmyyyy')
                                            || ' 09:00',
                                            'ddmmyyyy HH24:MI')
                                    AND TO_DATE (
                                               TO_CHAR (TRUNC (SYSDATE),
                                                        'ddmmyyyy')
                                            || ' 10:30',
                                            'ddmmyyyy HH24:MI'))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_fx_rates_trade_blocking;



        ---------------------------------
        --Summary:Check if at least 70 fx rates have been processed in the last 1000 entries of the OBJ_TS_REP table
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        PROCEDURE check_fx_rates_trade
        IS
            c_check_name    VARCHAR2 (100) := 'fx_rates_trade';
            c_check_title   VARCHAR2 (100)
                                := 'FX Rates Trade (in last 1000 entries)';
            l_cnt           NUMBER;
            c_min           NUMBER := 70;
        BEGIN
            --TODO reimplement if necessary (table not 3.8. compatible)
            NULL;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_fx_rates_trade;

        ---------------------------------
        --Summary:Date and timeframe condition FX Rates last 15 minutes check
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        FUNCTION cond_fx_rates_15
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            RETURN TRUE;
        END cond_fx_rates_15;

        ---------------------------------
        --Summary:Date and timeframe condition for blocking status of the fx rates 15 minutes check
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        FUNCTION cond_fx_rates_15_blocking
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF (    SYSDATE >
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 06:00',
                        'ddmmyyyy HH24:MI')
                AND SYSDATE <
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:45',
                        'ddmmyyyy HH24:MI'))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_fx_rates_15_blocking;

        ---------------------------------
        --Summary:Check if at least 1 FX Rates message has been received during the past 15 minutes
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        PROCEDURE check_fx_rates_15
        IS
            c_check_name    VARCHAR2 (100) := 'fx_rates_15';
            c_check_title   VARCHAR2 (100)
                                := 'FX Rates messages (15 last minutes)';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg
             WHERE     netw_id = 116
                   AND meta_msg_id = 526
                   AND msg_status_id = 6
                   AND timestamp >=
                       (SYSDATE - NUMTODSINTERVAL (16, 'MINUTE'));

            IF cond_fx_rates_15_blocking
            THEN
                write_query (c_check_title,
                             l_cnt,
                             c_min,
                             c_blocking_p,
                             '>=',
                             c_check_name);

                IF l_cnt = 0
                THEN
                    p_html_pool :=
                           '<br/><b>WARNING for MARKET TEAM : No FX rates received in the last 15 minutes.</b><br/>'
                        || p_html_pool;
                    p_to := upsert_mails (p_to, ';', l_mail_market_rates);
                END IF;
            ELSE
                write_query (c_check_title,
                             l_cnt,
                             c_min,
                             c_none_p,
                             '>=',
                             c_check_name);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_fx_rates_15;



        ---------------------------------
        --Summary: Conditions for starting rates to irc task execution check
        --Parameters: none
        --Author:ADRGUS
        --Date:20/11/2024
        ---------------------------------
        FUNCTION cond_rates_to_irc_task
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF (SYSDATE BETWEEN (TRUNC (SYSDATE, 'hh') + INTERVAL '15' MINUTE) -- every hour between 15 and 30 to be executed once every hour
                            AND (TRUNC (SYSDATE, 'hh') + INTERVAL '30' MINUTE))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_rates_to_irc_task;

        ---------------------------------
        --Summary: Checks for amount of rates to irc tasks completed compared to amount of rates to irc tasks tasks started in the last 24 hours
        --Parameters: none
        --Author:ADRGUS
        --Date:20/11/2024
        ---------------------------------
        PROCEDURE check_rates_to_irc_task
        IS
            c_check_name     VARCHAR2 (100) := 'check_rates_to_irc_task';
            c_check_title    VARCHAR2 (100)
                                 := 'Rates to IRC TASKS runned (last 24h)';
            l_cnt            NUMBER;
            c_min            NUMBER;
            l_period_start   DATE;
        BEGIN
            SELECT TRIM (TO_CHAR (today, 'DAY'))
              INTO l_t
              FROM k.base
             WHERE ROWNUM = 1;

            IF ((l_t = 'LUNDI') OR (l_t = 'MONDAY'))
            THEN
                --get from last friday to avoid loosing tasks executed during the weekend
                l_period_start := SYSDATE - 3;
            ELSE
                --get from last 24 hours
                l_period_start := SYSDATE - 1;
            END IF;

            SELECT COUNT (*)
              INTO c_min
              FROM OUT_JOB_V o, TABLE (o.bind_val_tab) b
             WHERE     meta_out_templ_id IN (SELECT lookup_ddic#.task_templ_id (
                                                        UPPER (
                                                            'TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'),
                                                        NULL,
                                                        NULL,
                                                        '+',
                                                        NULL)
                                               FROM DUAL)
                   AND timestamp_ins > TRUNC (l_period_start, 'hh') -- selecting the last 24 hours
                   AND timestamp_ins < TRUNC (SYSDATE, 'hh')
                   AND par_type_id = 1;

            SELECT COUNT (*)
              INTO l_cnt
              FROM OUT_JOB_V o, TABLE (o.bind_val_tab) b
             WHERE     meta_out_templ_id IN (SELECT lookup_ddic#.task_templ_id (
                                                        UPPER (
                                                            'TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'),
                                                        NULL,
                                                        NULL,
                                                        '+',
                                                        NULL)
                                               FROM DUAL)
                   AND timestamp_ins > TRUNC (l_period_start, 'hh') -- selecting the last 24 hours
                   AND timestamp_ins < TRUNC (SYSDATE, 'hh')
                   AND par_type_id = 1
                   AND out_status_id IN (7);

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_to := upsert_mails (p_to, ';', l_mail_market_treasury);
                p_to := upsert_mails (p_to, ';', l_mail_market_secdb);

                FOR c
                    IN (SELECT PAR_VAL
                          FROM OUT_JOB_V o, TABLE (o.bind_val_tab) b
                         WHERE     meta_out_templ_id IN (SELECT lookup_ddic#.task_templ_id (
                                                                    UPPER (
                                                                        'TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'),
                                                                    NULL,
                                                                    NULL,
                                                                    '+',
                                                                    NULL)
                                                           FROM DUAL)
                               AND timestamp_ins >
                                   TRUNC (l_period_start, 'hh')
                               AND timestamp_ins < TRUNC (SYSDATE, 'hh')
                               AND par_type_id = 1
                               AND out_status_id NOT IN (7))
                LOOP
                    p_html_pool :=
                        '<br/> Rate: ' || c.PAR_VAL || '<br/>' || p_html_pool;
                END LOOP;

                p_html_pool :=
                       '<br/><b>WARNING for SEC DB TEAM : '
                    || (c_min - l_cnt)
                    || ' Rates to IRC TASKS did not run or are still running : </b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_rates_to_irc_task;

        ---------------------------------
        --Summary:Generic check if task 'TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC', running after reception of rate from SDM has been processed.
        --Parameters: c_check_name: name of corresponding check,
        --            c_check_title: message sent in case of warning,
        --            c_rate_name: name of checked rate,
        --            c_rate_def: dt.extn.ass_md_scen_ref.id & first dt.extn.ass_md_ref.id of checked rate
        --            i_sop: end_of_period of rate reception,
        --            i_eop: start_of_period of rate reception
        --Author:ADRGUS
        --Date:14/11/2024
        ---------------------------------
        PROCEDURE check_rates_to_irc_generic_task (c_check_name     VARCHAR2,
                                                   c_check_title    VARCHAR2,
                                                   c_rate_name      VARCHAR2,
                                                   c_rate_par_val   VARCHAR2,
                                                   i_sop            DATE,
                                                   i_eop            DATE)
        IS
            c_min   NUMBER;
            l_cnt   NUMBER;
        BEGIN
            SELECT COUNT (*)
              INTO c_min
              FROM OUT_JOB_V o, TABLE (o.bind_val_tab) b
             WHERE     timestamp_ins > TRUNC (SYSDATE)
                   AND meta_out_templ_id IN (SELECT lookup_ddic#.task_templ_id (
                                                        UPPER (
                                                            'TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'),
                                                        NULL,
                                                        NULL,
                                                        '+',
                                                        NULL)
                                               FROM DUAL)
                   AND b.par_name = 'I_EXPR'
                   AND b.par_val LIKE '%' || c_rate_par_val || '%'
                   AND par_type_id = 1
                   AND timestamp_ins > i_sop
                   AND timestamp_ins < i_eop
                   AND timestamp_ins < SYSDATE - INTERVAL '15' MINUTE; -- allow 15 minute timeframe where not alert is necessary

            SELECT COUNT (*)
              INTO l_cnt
              FROM OUT_JOB_V o, TABLE (o.bind_val_tab) b
             WHERE     timestamp_ins > TRUNC (SYSDATE)
                   AND meta_out_templ_id IN (SELECT lookup_ddic#.task_templ_id (
                                                        UPPER (
                                                            'TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'),
                                                        NULL,
                                                        NULL,
                                                        '+',
                                                        NULL)
                                               FROM DUAL)
                   AND b.par_name = 'I_EXPR'
                   AND b.par_val LIKE '%' || c_rate_par_val || '%'
                   AND par_type_id = 1
                   AND timestamp_ins > i_sop
                   AND timestamp_ins < i_eop
                   AND timestamp_ins < SYSDATE - INTERVAL '15' MINUTE -- allow 15 minute timeframe where not alert is necessary
                   AND out_status_id IN (7);                      -- processed

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_to := upsert_mails (p_to, ';', l_mail_market_treasury);
                p_to := upsert_mails (p_to, ';', l_mail_market_secdb);
                p_html_pool :=
                       '<br/><b>WARNING for SEC DB TEAM : '
                    || c_rate_name
                    || ' Rates to IRC TASK did not run or is still running</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_rates_to_irc_generic_task;



        ---------------------------------
        --Summary:Date and timeframe condition for blocking status of the loan_fta rates SDM 15 minutes check
        --Parameters:
        ---------------------------------
        FUNCTION cond_sdm_rates_loan_fta
            RETURN BOOLEAN
        IS
            l_cnt    NUMBER;
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF (    SYSDATE >
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 08:00',
                        'ddmmyyyy HH24:MI')
                AND SYSDATE <
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:45',
                        'ddmmyyyy HH24:MI'))
            THEN
                SELECT COUNT (*)
                  INTO l_cnt
                  FROM msg_extl_in mi, msg m
                 WHERE     m.id = mi.id
                       AND mi.msg_type = 'MMKT_RATES'
                       AND m.meta_msg_id = 540
                       AND m.netw_id = 116
                       AND m.msg_status_id = 6
                       AND mi.msg_status_id = 3
                       AND mi.text LIKE '%<Md_Scen>loan_fta</Md_Scen>%'
                       AND m.timestamp > TRUNC (SYSDATE);

                IF l_cnt > 0
                THEN
                    l_cond := TRUE;
                END IF;
            END IF;

            RETURN l_cond;
        END cond_sdm_rates_loan_fta;


        ---------------------------------
        --Summary:Check if task that runs after reception of loan_fta Rates from SDM has been processed.
        --Parameters:
        ---------------------------------
        PROCEDURE check_sdm_rates_loan_fta_task
        IS
            c_check_name    VARCHAR2 (100) := 'check_sdm_rates_loan_fta_task';
            c_check_title   VARCHAR2 (100)
                                := 'Rates loan_fta SDM messages TASK runned';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO c_min
              FROM OUT_JOB_V o, TABLE (o.bind_val_tab) b
             WHERE     timestamp_ins > TRUNC (SYSDATE)
                   AND meta_out_templ_id IN (SELECT lookup_ddic#.task_templ_id (
                                                        UPPER (
                                                            'TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'),
                                                        NULL,
                                                        NULL,
                                                        '+',
                                                        NULL)
                                               FROM DUAL)
                   AND b.par_name = 'I_EXPR'
                   AND b.par_val LIKE
                           '%dt.extn.ass_md_scen_ref.id = 6019 and dt.extn.ass_md_ref.id in (49498,%'
                   AND timestamp_ins >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 08:00',
                           'ddmmyyyy HH24:MI')
                   AND timestamp_ins <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:00',
                           'ddmmyyyy HH24:MI')
                   AND timestamp_ins < SYSDATE - INTERVAL '12' MINUTE; -- allow 10 minute timeframe where not alert is necessary

            SELECT COUNT (*)
              INTO l_cnt
              FROM OUT_JOB_V o, TABLE (o.bind_val_tab) b
             WHERE     timestamp_ins > TRUNC (SYSDATE)
                   AND meta_out_templ_id IN (SELECT lookup_ddic#.task_templ_id (
                                                        UPPER (
                                                            'TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'),
                                                        NULL,
                                                        NULL,
                                                        '+',
                                                        NULL)
                                               FROM DUAL)
                   AND b.par_name = 'I_EXPR'
                   AND b.par_val LIKE
                           '%dt.extn.ass_md_scen_ref.id = 6019 and dt.extn.ass_md_ref.id in (49498,%'
                   AND timestamp_ins >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 08:00',
                           'ddmmyyyy HH24:MI')
                   AND timestamp_ins <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:00',
                           'ddmmyyyy HH24:MI')
                   AND out_status_id IN (7);                      -- processed

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_to := upsert_mails (p_to, ';', l_mail_market_treasury);
                p_html_pool :=
                       '<br/><b>WARNING for SDM TEAM : loan_fta SDM rates TASK not runned or still running</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_sdm_rates_loan_fta_task;



        ---------------------------------
        --Summary:Date and timeframe condition for blocking status of the mmkt rates SDM 15 minutes check
        --Parameters:
        ---------------------------------
        FUNCTION cond_sdm_rates_mmkt
            RETURN BOOLEAN
        IS
            l_cnt    NUMBER;
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF (    SYSDATE >
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 08:00',
                        'ddmmyyyy HH24:MI')
                AND SYSDATE <
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:45',
                        'ddmmyyyy HH24:MI'))
            THEN
                SELECT COUNT (*)
                  INTO l_cnt
                  FROM msg_extl_in mi, msg m
                 WHERE     mi.msg_type LIKE '%MMKT_RATES'
                       AND m.id = mi.id
                       AND mi.msg_status_id = 3
                       AND m.msg_status_id = 6
                       AND mi.text LIKE '%<Md_Scen>mmkt</Md_Scen>%'
                       AND mi.timestamp > TRUNC (SYSDATE);

                IF l_cnt > 0
                THEN
                    l_cond := TRUE;
                END IF;
            END IF;

            RETURN l_cond;
        END cond_sdm_rates_mmkt;


        ---------------------------------
        --Summary:Check if task that runs after reception of MMKT Rates from SDM has been processed.
        --Parameters:
        ---------------------------------
        PROCEDURE check_sdm_rates_mmkt_task
        IS
            c_check_name    VARCHAR2 (100) := 'check_sdm_rates_mmkt_task';
            c_check_title   VARCHAR2 (100)
                                := 'Rates MMKT SDM messages TASK runned';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO c_min
              FROM OUT_JOB_V o, TABLE (o.bind_val_tab) b
             WHERE     timestamp_ins > TRUNC (SYSDATE)
                   AND meta_out_templ_id IN (SELECT lookup_ddic#.task_templ_id (
                                                        UPPER (
                                                            'TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'),
                                                        NULL,
                                                        NULL,
                                                        '+',
                                                        NULL)
                                               FROM DUAL)
                   AND b.par_name = 'I_EXPR'
                   AND b.par_val LIKE
                           '%dt.extn.ass_md_scen_ref.id = 1003 and dt.extn.ass_md_ref.id in (49498,%'
                   AND timestamp_ins >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 08:00',
                           'ddmmyyyy HH24:MI')
                   AND timestamp_ins <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:00',
                           'ddmmyyyy HH24:MI')
                   AND timestamp_ins < SYSDATE - INTERVAL '30' MINUTE -- allow 30 minute timeframe where not alert is necessary
                   AND out_status_id >= 0;             -- not in a fail status


            SELECT COUNT (*)
              INTO l_cnt
              FROM OUT_JOB_V o, TABLE (o.bind_val_tab) b
             WHERE     timestamp_ins > TRUNC (SYSDATE)
                   AND meta_out_templ_id IN (SELECT lookup_ddic#.task_templ_id (
                                                        UPPER (
                                                            'TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'),
                                                        NULL,
                                                        NULL,
                                                        '+',
                                                        NULL)
                                               FROM DUAL)
                   AND b.par_name = 'I_EXPR'
                   AND b.par_val LIKE
                           '%dt.extn.ass_md_scen_ref.id = 1003 and dt.extn.ass_md_ref.id in (49498,%'
                   AND timestamp_ins >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 08:00',
                           'ddmmyyyy HH24:MI')
                   AND timestamp_ins <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:00',
                           'ddmmyyyy HH24:MI')
                   AND out_status_id IN (7);                      -- processed

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_to := upsert_mails (p_to, ';', l_mail_market_treasury);
                p_html_pool :=
                       '<br/><b>WARNING for SDM TEAM : MMKT SDM rates TASK not runned or still running</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_sdm_rates_mmkt_task;



        ---------------------------------
        --Summary:Timing condition for the FX rates 15 minutes update check - do not check when no fx messages are supposed to be injected
        --Parameters:none
        --Author:CHRBEC
        --Date:12/03/2014
        ---------------------------------
        FUNCTION cond_fx_rates_15_update
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            l_cond := FALSE;

            IF is_day_off (2103, SYSDATE)                        -- IOR-130206
            THEN
                l_cond := FALSE;
            ELSIF (    SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 06:00',
                           'ddmmyyyy HH24:MI')
                   AND (SYSDATE <
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || '18:45',
                            'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_fx_rates_15_update;

        ---------------------------------
        --Summary:Check if the rates in the received xml file have are up-to-date
        --Parameters:none
        --Author:CHRBEC - Modified by ADRGUS
        --Date:28/01/2014
        ---------------------------------
        PROCEDURE check_fx_rates_15_update
        IS
            c_check_name        VARCHAR2 (100) := 'fx_rates_15_update';
            c_check_title       VARCHAR2 (100) := 'FX Rates 15min up-to-date';
            l_cnt               NUMBER;
            l_cnt3              NUMBER := 0;
            l_xml               CLOB;
            l_ctrl_time         TIMESTAMP;
            l_test_time         TIMESTAMP;
            l_test_time_local   TIMESTAMP;
            c_rates_amount      NUMBER := 27;
            p_missing_rates     CLOB;

            -- To be maintained when new currency is added
            TYPE currency IS VARRAY (27) OF VARCHAR2 (10);

            l_currencies        currency
                                    := currency ('EUR',
                                                 'GBP',
                                                 'CHF',
                                                 'JPY',
                                                 'CAD',
                                                 'AUD',
                                                 'CZK',
                                                 'DKK',
                                                 'HKD',
                                                 'HUF',
                                                 'ILS',
                                                 'NOK',
                                                 'NZD',
                                                 'MXN',
                                                 'PLN',
                                                 'SEK',
                                                 'SGD',
                                                 'ZAR',
                                                 'AED',
                                                 'RON',
                                                 'TRY',
                                                 'XAU',
                                                 'XAG',
                                                 'XPT',
                                                 'XPD',
                                                 'CNH',
                                                 'THB');
        BEGIN
            -- Count the amount of fx rates recieved the last 16 minutes
            SELECT COUNT (*)
              INTO l_cnt
              FROM k.msg_extl_in i, k.msg m
             WHERE     m.id = i.id
                   AND m.netw_id = 116
                   AND m.meta_msg_id = 526
                   AND m.msg_status_id = 6
                   --and i.text not like '%<Md_Scen>nc$eval_ecb</Md_Scen>%'
                   AND m.doc_id IS NULL
                   AND i.timestamp >=
                       (SYSDATE - NUMTODSINTERVAL (16, 'MINUTE'))
                   AND m.id >= (SELECT MAX (id) - 100000 FROM k.msg)
                   AND i.id >= (SELECT MAX (id) - 100000 FROM k.msg_extl_in);

            -- When no rates have been recieved in the last 16 minutes
            IF l_cnt > 0
            THEN
                -- Retrives xml file the of latest recived fx rates
                SELECT text, timestamp
                  INTO l_xml, l_ctrl_time
                  FROM (SELECT i.text, i.timestamp
                          FROM k.msg_extl_in i, k.msg m
                         WHERE     m.id = i.id
                               AND m.netw_id = 116
                               AND m.meta_msg_id = 526
                               AND m.msg_status_id = 6
                               --and i.text not like '%<Md_Scen>nc$eval_ecb</Md_Scen>%'
                               AND m.doc_id IS NULL
                               AND i.timestamp >=
                                   (SYSDATE - NUMTODSINTERVAL (16, 'MINUTE'))
                               AND m.id >=
                                   (SELECT MAX (id) - 100000 FROM k.msg)
                               AND i.id >=
                                   (SELECT MAX (id) - 100000
                                      FROM k.msg_extl_in))
                 WHERE ROWNUM = 1;


                -- For every rate, checks if trade time is older than 15 minutes
                FOR c IN 1 .. l_currencies.COUNT
                LOOP
                    l_test_time :=
                        TO_TIMESTAMP (
                               parse_cur_xml_tag_value (
                                   l_xml,
                                   'Trade_Date',
                                   12,
                                   l_currencies (c) || '=')
                            || ' '
                            || parse_cur_xml_tag_value (
                                   l_xml,
                                   'Trade_Time',
                                   12,
                                   l_currencies (c) || '='),
                            'YYYY/MM/DD HH24:MI');

                    SELECT FROM_TZ (l_test_time, 'UTC')
                               AT TIME ZONE SESSIONTIMEZONE
                      INTO l_test_time_local
                      FROM DUAL;

                    l_cnt :=
                        timestamp_diff_minutes (l_test_time_local,
                                                l_ctrl_time);

                    IF (l_cnt >= 15)
                    THEN
                        l_cnt3 := l_cnt3 + 1;
                        p_missing_rates :=
                               ' - '
                            || l_currencies (c)
                            || ' has not been received since '
                            || l_cnt
                            || ' minutes<br/>'
                            || p_missing_rates;
                    END IF;
                END LOOP;


                write_query (c_check_title,
                             c_rates_amount - l_cnt3,
                             c_rates_amount,
                             c_major_p,
                             '=',
                             c_check_name);

                IF l_cnt3 > 0
                THEN
                    p_html_pool :=
                           '<br/><b>WARNING for MARKET TEAM : Following FX rate(s) not up-to-date :</b><br/>'
                        || p_missing_rates
                        || p_html_pool;
                    p_to := upsert_mails (p_to, ';', l_mail_market_rates);
                END IF;
            ELSE
                -- WARNING for MARKET TEAM : No FX rates have been recieved in the last 15 minutes, already displayed by check_fx_rates_15

                write_query (c_check_title,
                             0,
                             c_rates_amount,
                             c_major_p,
                             '=',
                             c_check_name);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_fx_rates_15_update;

        ---------------------------------
        --Summary:Check if the received rates are uploaded in avaloq
        --Parameters:none
        --Author:CHRBEC - Modified by ADRGUS
        --Date:25/02/2025
        ---------------------------------
        PROCEDURE check_fx_rates_15_upload
        IS
            c_check_name2    VARCHAR2 (100) := 'fx_rates_15_update_avaloq';
            c_check_title2   VARCHAR2 (100) := 'FX Rates 15min Avaloq upload';
            l_cnt            NUMBER;
            c_min            NUMBER := 1;
        BEGIN
            SELECT COUNT (DISTINCT d_ts.doc_id)
              INTO l_cnt
              FROM doc_tsed  d_ts
                   INNER JOIN doc d ON d_ts.doc_id = d.id
                   INNER JOIN docp_tsed_ld_item item
                       ON d_ts.doc_id = item.doc_id
             WHERE     d.timestamp >=
                       (SYSDATE - NUMTODSINTERVAL (16, 'MINUTE'))
                   AND d.meta_typ_id = 247
                   AND d.wfc_status_id = 90
                   AND d.order_type_id IN (247001,
                                           247002,
                                           247005,
                                           247003,
                                           247004)
                   AND d.trx_date = TO_DATE (SYSDATE, 'DD/MM/YYYY');

            write_query (c_check_title2,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name2);

            IF l_cnt = 0
            THEN
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : No FX rates uploaded to Avaloq in the last 15 minutes.</b><br/>'
                    || p_html_pool;
                p_to := upsert_mails (p_to, ';', l_mail_market_rates);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title2,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_fx_rates_15_upload;


        ---------------------------------
        --Summary:Date and timeframe condition FX Rates MSG  check
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        FUNCTION cond_fx_rates_msg
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF     SYSDATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 06:00',
                       'ddmmyyyy HH24:MI')
               AND SYSDATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:45',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_fx_rates_msg;


        ---------------------------------
        --Summary:Check if an average of 1 msg/ 15 minutes containing fx rates information has been received during the current day
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        PROCEDURE check_fx_rates_msg
        IS
            c_check_name    VARCHAR2 (100) := 'fx_rates_msg';
            c_check_title   VARCHAR2 (100)
                                := 'FX Rates messages (today : 1msg/15min)';
            l_cnt           NUMBER;
            l_period_cnt    NUMBER;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg
             WHERE     netw_id = 116
                   AND meta_msg_id = 526
                   AND msg_status_id = 6
                   AND timestamp >=
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 06:00',
                           'ddmmyyyy HH24:MI');

            SELECT TRUNC (
                         (  SYSDATE
                          - TO_DATE (
                                   TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy')
                                || ' 06:00',
                                'ddmmyyyy HH24:MI'))
                       * 60
                       * 24
                       / 15)
              INTO l_period_cnt
              FROM DUAL;                         -- number of 15min since 6:00

            write_query (
                c_check_title,
                l_cnt,
                   '['
                || TO_CHAR (l_period_cnt - 1)
                || ';'
                || TO_CHAR (l_period_cnt + 1)
                || ']',
                c_none_p,
                'in',
                'fx_rates_msg');
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_fx_rates_msg;


        ---------------------------------
        --Summary:Date and timeframe condition FX Rates Exotic currencies check in the morning
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        FUNCTION cond_fx_exotic_morning
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF l_execution_time <
               TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:40',
                        'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_fx_exotic_morning;


        ---------------------------------
        --Summary:Check if an exotic currencies fx rates message has been received during the morning
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        PROCEDURE check_fx_exotic_morning
        IS
            c_check_name    VARCHAR2 (100) := 'fx_exotic_morning';
            c_check_title   VARCHAR2 (100)
                                := 'FX Rates for exotic ccy (morning msg)';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg m, msg_extl_in mi
             WHERE     m.netw_id = 116
                   AND m.meta_msg_id = 526
                   AND m.msg_status_id = 6
                   AND m.timestamp BETWEEN TO_DATE (
                                                  TO_CHAR (TRUNC (SYSDATE),
                                                           'ddmmyyyy')
                                               || ' 06:50',
                                               'ddmmyyyy HH24:MI')
                                       AND SYSDATE
                   AND mi.id = m.id
                   AND mi.text LIKE '%COP%';

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt = 0
            THEN
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : No FX rates received this morning for exotic currencies.</b><br/>'
                    || p_html_pool;
                p_to := upsert_mails (p_to, ';', l_mail_market_rates);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_fx_exotic_morning;

        ---------------------------------
        --Summary:Date and timeframe condition FX Rates Exotic currencies check in the evening
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        FUNCTION cond_fx_exotic_evening
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF l_execution_time >
               TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:40',
                        'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_fx_exotic_evening;


        ---------------------------------
        --Summary:Check if an exotic currencies fx rates message has been received in the evening
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        PROCEDURE check_fx_exotic_evening
        IS
            c_check_name    VARCHAR2 (100) := 'fx_exotic_evening';
            c_check_title   VARCHAR2 (100)
                                := 'FX Rates for exotic ccy (evening msg)';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg m, msg_extl_in mi
             WHERE     m.netw_id = 116
                   AND m.meta_msg_id = 526
                   AND m.msg_status_id = 6
                   AND m.timestamp BETWEEN TO_DATE (
                                                  TO_CHAR (TRUNC (SYSDATE),
                                                           'ddmmyyyy')
                                               || ' 18:20',
                                               'ddmmyyyy HH24:MI')
                                       AND SYSDATE
                   AND mi.id = m.id
                   AND mi.text LIKE '%COP%';

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt = 0
            THEN
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : No FX rates received this evening for exotic currencies.</b><br/>'
                    || p_html_pool;
                p_to := upsert_mails (p_to, ';', l_mail_market_rates);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_fx_exotic_evening;


        ---------------------------------
        --Summary:Timing condition for the FX rates exotic update check
        --Parameters:none
        --Author:CHRBEC
        --Date:12/03/2014
        ---------------------------------
        FUNCTION cond_fx_rates_exotic_update
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF    l_execution_time <
                  TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:40',
                           'ddmmyyyy HH24:MI')
               OR (    l_execution_time >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:40',
                           'ddmmyyyy HH24:MI')
                   AND l_execution_time <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 19:00',
                           'ddmmyyyy HH24:MI'))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_fx_rates_exotic_update;

        ---------------------------------
        --Summary:Check if the exotic fx rates in the last received xml file have are up-to-date
        --Parameters:none
        --Author:CHRBEC
        --Date:12/03/2014
        ---------------------------------
        PROCEDURE check_fx_rates_exotic_update
        IS
            c_check_name        VARCHAR2 (100) := 'fx_rates_exotic_update';
            c_check_title       VARCHAR2 (100) := 'FX Rates exotic up-to-date';
            l_cnt               NUMBER;
            c_max               NUMBER := 10;
            l_xml               CLOB;
            l_ctrl_time         TIMESTAMP;
            l_test_time         TIMESTAMP;
            l_test_time_local   TIMESTAMP;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg m, msg_extl_in mi
             WHERE     m.netw_id = 116
                   AND m.meta_msg_id = 526
                   AND m.msg_status_id = 6
                   AND m.timestamp > (SYSDATE - 1 / 24)
                   AND m.id = mi.id
                   AND mi.text LIKE '%COP%';



            IF l_cnt > 0
            THEN
                SELECT text, timestamp
                  INTO l_xml, l_ctrl_time
                  FROM (  SELECT mi.text, mi.timestamp
                            FROM msg_extl_in mi, msg m
                           WHERE     m.id = mi.id
                                 AND m.netw_id = 116
                                 AND m.meta_msg_id = 526
                                 AND m.msg_status_id = 6
                                 AND m.timestamp > (SYSDATE - 1 / 24)
                                 AND mi.text LIKE '%COP%'
                        ORDER BY mi.timestamp DESC)
                 WHERE ROWNUM = 1;



                l_test_time :=
                    TO_TIMESTAMP (
                           parse_cur_xml_tag_value (l_xml, 'Trade_Date', 12)
                        || ' '
                        || parse_cur_xml_tag_value (l_xml, 'Trade_Time', 12),
                        'YYYY/MM/DD HH24:MI');

                SELECT FROM_TZ (l_test_time, 'UTC')
                           AT TIME ZONE SESSIONTIMEZONE
                  INTO l_test_time_local
                  FROM DUAL;

                l_cnt :=
                    timestamp_diff_minutes (l_test_time_local, l_ctrl_time);

                write_query (c_check_title,
                             l_cnt,
                             c_max,
                             c_major_p,
                             '<=',
                             c_check_name);

                IF l_cnt > c_max
                THEN
                    p_html_pool :=
                           '<br/><b>WARNING for MARKET TEAM : Exotic FX rates are not up-to-date: '
                        || l_test_time_local
                        || ' received at '
                        || l_ctrl_time
                        || '.</b><br/>'
                        || p_html_pool;
                    p_to := upsert_mails (p_to, ';', l_mail_market_rates);
                END IF;
            ELSE
                write_query (c_check_title,
                             0,
                             1,
                             c_major_p,
                             '>=',
                             c_check_name);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_fx_rates_exotic_update;


        ---------------------------------
        --Summary:Date and timeframe condition for
        --/ Euribor check
        --Parameters:
        --Author:ADRMEN
        --Date:01/09/2020
        ---------------------------------
        FUNCTION cond_euribor
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            l_cond := FALSE;

            IF    is_day_off (2103, SYSDATE)
               OR is_day_off (2103, get_previous_day)
            THEN
                l_cond := FALSE;
            ELSIF (    SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:40',
                           'ddmmyyyy HH24:MI')
                   AND (SYSDATE <
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:55',
                            'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_euribor;

        ---------------------------------
        --Summary:Check if Euribor Rates have been received
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        PROCEDURE check_euribor
        IS
            c_check_name    VARCHAR2 (100) := 'euribor_libor';
            c_check_title   VARCHAR2 (100)
                                := 'EURIBOR (today : 13:30 - 13:40)';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.id = m.id
                   AND m.netw_id = 116
                   AND m.msg_status_id = 6
                   AND mi.msg_type IN ('MMKT_RATES', 'MMKT_EVAL_RATES')
                   AND mi.text LIKE '%EURIBOR%'
                   AND mi.timestamp >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:30',
                           'ddmmyyyy HH24:MI')
                   AND mi.timestamp <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:40',
                           'ddmmyyyy HH24:MI');

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_major_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : No EURIBOR rates received today.</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_euribor;

        ---------------------------------
        --Summary:Check if SGP Rates have been received
        --Parameters:
        --Author:ADRMEN7
        --Date:11/06/2020
        ---------------------------------
        FUNCTION cond_SGP
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF is_day_off (2015, SYSDATE)
            THEN
                l_cond := FALSE;
            ELSIF (    SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 15:00',
                           'ddmmyyyy HH24:MI')
                   AND (SYSDATE <
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 15:20',
                            'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_SGP;

        ---------------------------------
        --Summary:Check if SGP Rates have been received
        --Parameters:
        --Author:ADRMEN7
        --Date:21/01/2014
        ---------------------------------
        PROCEDURE check_SGP
        IS
            c_check_name    VARCHAR2 (100) := 'sgp_rate';
            c_check_title   VARCHAR2 (100) := 'SGP Rate';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.id = m.id
                   AND m.netw_id = 116
                   AND m.msg_status_id = 6
                   AND mi.msg_type IN ('MMKT_RATES', 'MMKT_EVAL_RATES')
                   AND mi.text LIKE '%KLIMYR3MD=%'
                   AND mi.text LIKE
                              '%<Trade_Date>'
                           || TO_CHAR (TRUNC (SYSDATE), 'yyyy/mm/dd')
                           || '</Trade_Date>%'
                   AND mi.timestamp > TRUNC (SYSDATE)
                   AND mi.timestamp <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 15:00',
                           'ddmmyyyy HH24:MI');

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to :=
                    upsert_mails (
                        p_to,
                        ';',
                        'it.sdm@blu.bank;mqa@blu.bank;it.cbs.ops@blu.bank;securitiesdatabase@blu.bank');
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : No SGP rates received today.</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_SGP;

        ---------------------------------
        --Summary:Check if trade date of euribor rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:17/07/2014
        ---------------------------------
        PROCEDURE check_euribor_update
        IS
            c_check_name   VARCHAR2 (100) := 'euribor_update';
            c_rate_name    VARCHAR2 (50) := 'EURIBOR';
            c_tag_name     VARCHAR2 (50) := 'EURIBORSWD=';
        BEGIN
            --use generic check procedure
            check_generic_rates_update (
                c_check_name,
                c_rate_name,
                c_tag_name,
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:30',
                         'ddmmyyyy HH24:MI'),
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:40',
                         'ddmmyyyy HH24:MI'));
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_euribor_update;

        ---------------------------------
        --Summary:Check if task that runs after reception of euribor rates has been processed
        --Parameters:none
        --Author:ADRGUS
        --Date:14/11/2024
        ---------------------------------
        PROCEDURE check_euribor_task
        IS
            c_check_name     VARCHAR2 (100) := 'euribor_task';
            c_check_title    VARCHAR2 (100)
                                 := 'EURIBOR Rates SDM message TASK';
            c_rate_name      VARCHAR2 (100) := 'EURIBOR';
            c_rate_par_val   VARCHAR2 (100)
                := 'dt.extn.ass_md_scen_ref.id = 1003 and dt.extn.ass_md_ref.id in (50180,';
        BEGIN
            --use generic check procedure
            check_rates_to_irc_generic_task (
                c_check_name,
                c_check_title,
                c_rate_name,
                c_rate_par_val,
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:30',
                         'ddmmyyyy HH24:MI'),
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:40',
                         'ddmmyyyy HH24:MI'));
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_euribor_task;

        ---------------------------------
        --Summary:Date and timeframe condition for SOFR check
        --Parameters:
        --Author:CHRBEC
        --Date:30/05/2018
        ---------------------------------
        FUNCTION cond_sofr
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF    is_day_off (78570944, get_previous_day)
               OR is_day_off (78570944, TRUNC (SYSDATE))
            THEN
                l_cond := FALSE;
            ELSIF (    SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 14:35',
                           'ddmmyyyy HH24:MI')
                   AND (SYSDATE <
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 15:30',
                            'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_sofr;

        ---------------------------------
        --Summary:Check if trade date of sofr rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:04/01/2018
        ---------------------------------
        PROCEDURE check_sofr_update
        IS
            c_check_name   VARCHAR2 (100) := 'sofr_update';
            c_rate_name    VARCHAR2 (50) := 'SOFR';
            c_tag_name     VARCHAR2 (50) := 'USDSOFR=';
        BEGIN
            IF    (    EXTRACT (MONTH FROM SYSDATE) = 7
                   AND EXTRACT (DAY FROM SYSDATE) = 3
                   AND TO_CHAR (TRUNC (SYSDATE + 1), 'DAY') = 'SATURDAY')
               OR (    EXTRACT (MONTH FROM SYSDATE) = 7
                   AND EXTRACT (DAY FROM SYSDATE) = 6
                   AND TO_CHAR (TRUNC (SYSDATE - 2), 'DAY') = 'SATURDAY')
               OR (    EXTRACT (MONTH FROM SYSDATE) = 7
                   AND EXTRACT (DAY FROM SYSDATE) = 6
                   AND TO_CHAR (TRUNC (SYSDATE - 1), 'DAY') = 'SUNDAY')
               OR (    EXTRACT (MONTH FROM SYSDATE) = 7
                   AND EXTRACT (DAY FROM SYSDATE) = 7
                   AND TO_CHAR (TRUNC (SYSDATE - 2), 'DAY') = 'SUNDAY')
            THEN -- avoid alert on independance day when it appears on week-end
                NULL;
            ELSE
                IF     NOT is_day_off (78570944, get_previous_day)
                   AND NOT is_day_off (78570944, TRUNC (SYSDATE))
                THEN
                    --use generic check procedure
                    check_generic_rates_update (
                        c_check_name,
                        c_rate_name,
                        c_tag_name,
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:00',
                            'ddmmyyyy HH24:MI'),
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 15:30',
                            'ddmmyyyy HH24:MI'),
                        i_previous_date        => TRUE,
                        i_previous_date_calc   => 'B');
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_sofr_update;

        ---------------------------------
        --Summary:Date and timeframe condition for SOFR check
        --Parameters:
        --Author:CHRBEC
        --Date:30/05/2018
        ---------------------------------
        FUNCTION cond_sofr_index
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF is_day_off (78570944, TRUNC (SYSDATE))
            THEN
                l_cond := FALSE;
            ELSIF (    SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 14:35',
                           'ddmmyyyy HH24:MI')
                   AND (SYSDATE <
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 15:30',
                            'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_sofr_index;

        ---------------------------------
        --Summary:Check if trade date of SOFR-Index rates corresponds to the current day
        --Parameters:
        --Author:ANNWOJ9
        --Date:04/11/2021
        ---------------------------------
        PROCEDURE check_sofr_index_update
        IS
            c_check_name   VARCHAR2 (100) := 'sofr_index_update';
            c_rate_name    VARCHAR2 (50) := 'SOFR-Index';
            c_tag_name     VARCHAR2 (50) := 'SOFR1MAVG=';
        BEGIN
            IF    (    EXTRACT (MONTH FROM SYSDATE) = 7
                   AND EXTRACT (DAY FROM SYSDATE) = 3
                   AND TO_CHAR (TRUNC (SYSDATE + 1), 'DAY') = 'SATURDAY')
               OR (    EXTRACT (MONTH FROM SYSDATE) = 7
                   AND EXTRACT (DAY FROM SYSDATE) = 6
                   AND TO_CHAR (TRUNC (SYSDATE - 2), 'DAY') = 'SATURDAY')
               OR (    EXTRACT (MONTH FROM SYSDATE) = 7
                   AND EXTRACT (DAY FROM SYSDATE) = 6
                   AND TO_CHAR (TRUNC (SYSDATE - 1), 'DAY') = 'SUNDAY')
               OR (    EXTRACT (MONTH FROM SYSDATE) = 7
                   AND EXTRACT (DAY FROM SYSDATE) = 7
                   AND TO_CHAR (TRUNC (SYSDATE - 2), 'DAY') = 'SUNDAY')
            THEN -- avoid alert on independance day when it appears on week-end
                NULL;
            ELSE
                IF NOT is_day_off (78570944, TRUNC (SYSDATE))
                THEN
                    --use generic check procedure
                    check_generic_rates_update (
                        c_check_name,
                        c_rate_name,
                        c_tag_name,
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:00',
                            'ddmmyyyy HH24:MI'),
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 15:30',
                            'ddmmyyyy HH24:MI'),
                        i_previous_date   => FALSE);
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_sofr_index_update;

        ---------------------------------
        --Summary:Check if trade date of chftois rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:17/07/2014
        ---------------------------------
        PROCEDURE check_chftois_update
        IS
            c_check_name   VARCHAR2 (100) := 'chftois_update';
            c_rate_name    VARCHAR2 (50) := 'CHFTOIS';
            c_tag_name     VARCHAR2 (50) := 'CHFTOIS=';
        BEGIN
            IF NOT is_day_off (2089, SYSDATE)
            THEN
                --use generic check procedure
                check_generic_rates_update (
                    c_check_name,
                    c_rate_name,
                    c_tag_name,
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:30',
                        'ddmmyyyy HH24:MI'),
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:40',
                        'ddmmyyyy HH24:MI'));
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_chftois_update;



        ---------------------------------
        --Summary:Date and timeframe condition for SARON check
        --Parameters:
        --Author:CHRBEC
        --Date:04/01/2018
        ---------------------------------
        FUNCTION cond_saron
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF    is_day_off (2089, SYSDATE)
               OR (    EXTRACT (MONTH FROM SYSDATE) = 12
                   AND EXTRACT (DAY FROM SYSDATE) = 31)
            THEN
                l_cond := FALSE;
            ELSIF (    SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:30',
                           'ddmmyyyy HH24:MI')
                   AND (SYSDATE <
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 19:00',
                            'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_saron;

        ---------------------------------
        --Summary:Date and timeframe condition for SARON check
        --Parameters:
        --Author:CHRBEC
        --Date:04/01/2018
        ---------------------------------
        FUNCTION cond_saron_compound
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF    is_day_off (2089, SYSDATE)
               OR (    EXTRACT (MONTH FROM SYSDATE) = 12
                   AND EXTRACT (DAY FROM SYSDATE) = 31)
            THEN
                l_cond := FALSE;
            ELSIF (    SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 19:45',
                           'ddmmyyyy HH24:MI')
                   AND (SYSDATE <
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 20:15',
                            'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_saron_compound;

        ---------------------------------
        --Summary:Check if trade date of saron (new chftois) rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:04/01/2018
        ---------------------------------
        PROCEDURE check_saron_update
        IS
            c_check_name   VARCHAR2 (100) := 'saron_update';
            c_rate_name    VARCHAR2 (50) := 'SARON';
            c_tag_name     VARCHAR2 (50) := 'SARON.S';
        BEGIN
            IF NOT is_day_off (2089, SYSDATE)
            THEN
                --use generic check procedure
                check_generic_rates_update (
                    c_check_name,
                    c_rate_name,
                    c_tag_name,
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:30',
                        'ddmmyyyy HH24:MI'),
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 19:00',
                        'ddmmyyyy HH24:MI'),
                    i_previous_date   => FALSE);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_saron_update;

        ---------------------------------
        --Summary:Check if trade date of saron (new chftois) rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:04/01/2018
        ---------------------------------
        PROCEDURE check_saron_compound_update
        IS
            c_check_name_1   VARCHAR2 (100)
                                 := 'saron_update_1_month_compound';
            c_rate_name_1    VARCHAR2 (50) := 'SARON_1_Month_COMPOUND';
            c_tag_name_1     VARCHAR2 (50) := '.SAR1MC';
            c_check_name_3   VARCHAR2 (100)
                                 := 'saron_update_3_month_compound';
            c_rate_name_3    VARCHAR2 (50) := 'SARON_3_Month_COMPOUND';
            c_tag_name_3     VARCHAR2 (50) := '.SAR3MC';
            c_check_name_6   VARCHAR2 (100)
                                 := 'saron_update_6_month_compound';
            c_rate_name_6    VARCHAR2 (50) := 'SARON_6_Month_COMPOUND';
            c_tag_name_6     VARCHAR2 (50) := '.SAR6MC';
        BEGIN
            IF NOT is_day_off (2089, SYSDATE)
            THEN
                --use generic check procedure
                check_generic_rates_update (
                    c_check_name_1,
                    c_rate_name_1,
                    c_tag_name_1,
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 19:25',
                        'ddmmyyyy HH24:MI'),
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 20:00',
                        'ddmmyyyy HH24:MI'),
                    i_previous_date   => FALSE);

                check_generic_rates_update (
                    c_check_name_3,
                    c_rate_name_3,
                    c_tag_name_3,
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 19:25',
                        'ddmmyyyy HH24:MI'),
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 20:00',
                        'ddmmyyyy HH24:MI'),
                    i_previous_date   => FALSE);

                check_generic_rates_update (
                    c_check_name_6,
                    c_rate_name_6,
                    c_tag_name_6,
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 19:25',
                        'ddmmyyyy HH24:MI'),
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 20:00',
                        'ddmmyyyy HH24:MI'),
                    i_previous_date   => FALSE);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name_1 || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                handle_check_exception (c_rate_name_3 || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                handle_check_exception (c_rate_name_6 || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_saron_compound_update;

        ---------------------------------
        --Summary:Date and timeframe condition for MMKT FFE Rates check
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        FUNCTION cond_mmkt_rates_ffe
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF    (    EXTRACT (MONTH FROM SYSDATE) = 7
                   AND EXTRACT (DAY FROM SYSDATE) = 3
                   AND TO_CHAR (TRUNC (SYSDATE + 1), 'DAY') = 'SATURDAY')
               OR (    EXTRACT (MONTH FROM SYSDATE) = 7
                   AND EXTRACT (DAY FROM SYSDATE) = 6
                   AND TO_CHAR (TRUNC (SYSDATE - 2), 'DAY') = 'SATURDAY')
               OR (    EXTRACT (MONTH FROM SYSDATE) = 7
                   AND EXTRACT (DAY FROM SYSDATE) = 6
                   AND TO_CHAR (TRUNC (SYSDATE - 1), 'DAY') = 'SUNDAY')
               OR (    EXTRACT (MONTH FROM SYSDATE) = 7
                   AND EXTRACT (DAY FROM SYSDATE) = 7
                   AND TO_CHAR (TRUNC (SYSDATE - 2), 'DAY') = 'SUNDAY')
            THEN -- avoid alert on independance day when it appears on week-end
                NULL;
            ELSE
                IF (    SYSDATE >
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 16:15',
                            'ddmmyyyy HH24:MI')
                    AND (SYSDATE <
                         TO_DATE (
                                TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy')
                             || ' 17:00',
                             'ddmmyyyy HH24:MI')))
                THEN
                    IF is_day_off (2000, TRUNC (SYSDATE))
                    THEN
                        l_cond := FALSE;
                    ELSIF is_day_off (2000, get_previous_day)
                    THEN
                        l_cond := FALSE;
                    ELSE
                        l_cond := TRUE;
                    END IF;
                END IF;
            END IF;

            RETURN l_cond;
        END cond_mmkt_rates_ffe;


        ---------------------------------
        --Summary:Check if MMKT FFE Rates have been received
        --Parameters:
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        PROCEDURE check_mmkt_rates_ffe
        IS
            c_check_name    VARCHAR2 (100) := 'rates_mmkt_ffe';
            c_check_title   VARCHAR2 (100) := 'MMKT Rates FFE (today : 14:30 - 14:40)';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM k.MSG_EXTL_IN mi, k.msg m
             WHERE     MI.ID = m.ID
                   AND m.netw_id = 116
                   AND m.msg_status_id = 6
                   AND mi.timestamp >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 16:00',
                           'ddmmyyyy HH24:MI')
                   AND mi.timestamp <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 16:20',
                           'ddmmyyyy HH24:MI')
                   AND mi.text LIKE '%USONFFE=FEDR%'
                   AND msg_type = 'MMKT_RATES';

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_major_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : No MMKT FFE rates received today.</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_mmkt_rates_ffe;

        ---------------------------------
        --Summary:Check if trade date of chftois rates corresponds to the current day
        --Comment: cannot use generic rates update check because trade date is -1v
        --Author:CHRBEC
        --Date:17/07/2014
        ---------------------------------
        PROCEDURE check_mmkt_rates_ffe_update
        IS
            c_check_name   VARCHAR2 (100) := 'ffe_update';
            c_rate_name    VARCHAR2 (50) := 'FFE';
            c_tag_name     VARCHAR2 (50) := 'USONFFE=FEDR';

            l_sop          DATE
                := TO_DATE (
                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 16:00',
                       'ddmmyyyy HH24:MI');
            l_eop          DATE
                := TO_DATE (
                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 16:20',
                       'ddmmyyyy HH24:MI');

            l_cnt          NUMBER;
            l_test_date    DATE;
            l_xml          CLOB;
            l_msg_type     VARCHAR2 (50) := 'MMKT_RATES';
        BEGIN
              -- Check if message has been received
              SELECT COUNT (*)
                INTO l_cnt
                FROM msg_extl_in mi, msg m
               WHERE     mi.id = m.id
                     AND m.netw_id = 116
                     AND m.msg_status_id = 6
                     AND mi.msg_type IN (l_msg_type)
                     AND mi.timestamp > l_sop
                     AND mi.timestamp < l_eop
                     AND text LIKE '%<RIC>' || c_tag_name || '</RIC>%'
                     AND mi.id >= (SELECT MAX (id) - 1000000 FROM msg)      --
                     AND ROWNUM = 1
            ORDER BY m.timestamp DESC;

            IF l_cnt > 0
            THEN
                --get rate message content and pars trade date of a given identifier element
                FOR c
                    IN (SELECT *
                          FROM (  SELECT text
                                    FROM msg_extl_in mi, msg m
                                   WHERE     mi.id = m.id
                                         AND m.netw_id = 116
                                         AND m.msg_status_id = 6
                                         AND mi.msg_type IN (l_msg_type)
                                         AND mi.timestamp > l_sop
                                         AND mi.timestamp < l_eop
                                         AND text LIKE
                                                    '%<RIC>'
                                                 || c_tag_name
                                                 || '</RIC>%'
                                         AND mi.id >=
                                             (SELECT MAX (id) - 1000000
                                                FROM msg)
                                ORDER BY m.timestamp DESC)
                         WHERE ROWNUM = 1)
                LOOP
                    l_xml := c.text;
                END LOOP;

                l_test_date :=
                    TO_DATE (parse_cur_xml_tag_value (l_xml,
                                                      'Trade_Date',
                                                      12,
                                                      c_tag_name),
                             'YYYY/MM/DD');

                --Check with blocking severity
                write_query (c_rate_name || ' up-to-date',
                             TO_CHAR (l_test_date, 'DD/MM/YYYY'),
                             TO_CHAR (get_previous_day_b, 'DD/MM/YYYY'),
                             c_blocking_p,
                             '=',
                             c_check_name);

                --Warning to market team
                IF TO_CHAR (l_test_date, 'DD/MM/YYYY') !=
                   TO_CHAR (get_previous_day_b, 'DD/MM/YYYY')
                THEN
                    p_to := upsert_mails (p_to, ';', l_mail_market_it);

                    p_html_pool :=
                           '<br/><b>WARNING for MARKET TEAM : '
                        || c_rate_name
                        || ' rates not up-to-date: '
                        || TO_CHAR (l_test_date, 'DD/MM/YYYY')
                        || '</b><br/>'
                        || p_html_pool;
                END IF;
            ELSE
                --if no message received, display N/A check result with severity major, no warning - since presence check will create warning
                write_query (c_rate_name || ' up-to-date',
                             'N/A',
                             TO_CHAR (get_previous_day_b, 'DD/MM/YYYY'),
                             c_major_p,
                             '=',
                             c_check_name);
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : '
                    || c_rate_name
                    || ' rates date could not be validated!</b><br/>'
                    || p_html_pool;
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_mmkt_rates_ffe_update;


        ---------------------------------
        --Summary:Date and timeframe condition for SONIA evening check
        --Parameters:
        --Author:NICMAL2
        --Date:15/09/2014
        ---------------------------------
        FUNCTION cond_mmkt_rates_sonia
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF is_day_off (2006, SYSDATE)                                -- UK
            THEN
                l_cond := FALSE;
            ELSIF (    SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 10:40',
                           'ddmmyyyy HH24:MI')
                   AND (SYSDATE <
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 11:00',
                            'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_mmkt_rates_sonia;

        ---------------------------------
        --Summary:Date and timeframe condition for STIBOR evening check
        --Parameters:
        --Author:NICMAL2
        --Date:30/05/2019
        ---------------------------------
        FUNCTION cond_mmkt_rates_stibor
            RETURN BOOLEAN
        IS
            l_cond                     BOOLEAN := FALSE;
            l_day                      VARCHAR (20);
            l_week                     NUMBER;
            l_month                    VARCHAR (20);
            l_previous_day             DATE := get_previous_day;
            l_extract_previous_day     NUMBER;
            l_extract_previous_month   NUMBER;
        BEGIN
            IF    is_day_off (2011, TRUNC (SYSDATE))
               OR is_day_off (2011, l_previous_day)                  -- Sweden
            THEN
                l_cond := FALSE;
            ELSIF (    SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 11:50',
                           'ddmmyyyy HH24:MI')
                   AND (SYSDATE <
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:05',
                            'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            --new condition : no check on monday between 22 and 27 (Midsummer Eve)
            SELECT TO_CHAR (SYSDATE, 'D') INTO l_week FROM DUAL;

            SELECT TO_CHAR (SYSDATE, 'MM') INTO l_month FROM DUAL;

            SELECT TO_NUMBER (TO_CHAR (SYSDATE, 'DD')) INTO l_day FROM DUAL;

            SELECT EXTRACT (MONTH FROM l_previous_day)
              INTO l_extract_previous_month
              FROM DUAL;

            SELECT EXTRACT (DAY FROM l_previous_day)
              INTO l_extract_previous_day
              FROM DUAL;


            IF    (    l_day >= 22
                   AND l_day <= 26
                   AND l_month = '06'
                   AND l_week = 1)
               OR (    l_extract_previous_day = 26
                   AND l_extract_previous_month = 12)
            THEN
                l_cond := FALSE;
            END IF;


            RETURN l_cond;
        END cond_mmkt_rates_stibor;


        ---------------------------------
        --Summary:Check if MMKT SONIA Rates have been received - this evening
        --Parameters:
        --Author:NICMAL2
        --Date:15/09/2014
        ---------------------------------
        PROCEDURE check_mmkt_rates_sonia
        IS
            c_check_name    VARCHAR2 (100) := 'rates_mmkt_sonia';
            c_check_title   VARCHAR2 (100)
                                := 'MMKT Rates SONIA (today : 10:05 - 10:25)';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM k.MSG_EXTL_IN mi, k.msg m
             WHERE     MI.ID = m.ID
                   AND mi.timestamp >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 10:20',
                           'ddmmyyyy HH24:MI')
                   AND mi.timestamp <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 10:40',
                           'ddmmyyyy HH24:MI')
                   AND mi.text LIKE '%SONIAOSR=%'
                   AND msg_type = 'MMKT_RATES';

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_major_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : No MMKT SONIA rates received today.</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_mmkt_rates_sonia;


        ---------------------------------
        --Summary:Check if MMKT STIBOR Rates have been received
        --Parameters:
        --Author:NICMAL2
        --Date:30/05/2019
        ---------------------------------
        PROCEDURE check_mmkt_rates_stibor
        IS
            c_check_name    VARCHAR2 (100) := 'rates_mmkt_stibor';
            c_check_title   VARCHAR2 (100)
                := 'MMKT Rates STIBOR (today : 11:30 - 11:45)';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM k.MSG_EXTL_IN mi, k.msg m
             WHERE     MI.ID = m.ID
                   AND mi.timestamp >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 11:30',
                           'ddmmyyyy HH24:MI')
                   AND mi.timestamp <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 11:45',
                           'ddmmyyyy HH24:MI')
                   AND mi.text LIKE '%STISEK3MDFI=%'
                   AND msg_type = 'MMKT_RATES';

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_major_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : No MMKT STIBOR - Sweden - rates received today.</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_mmkt_rates_stibor;



        ---------------------------------
        --Summary:Check if trade date of SONIA (evening) rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:17/07/2014
        ---------------------------------
        PROCEDURE check_sonia_eve_update
        IS
            c_check_name   VARCHAR2 (100) := 'sonia_eve_update';
            c_rate_name    VARCHAR2 (50) := 'SONIAOSR';
            c_tag_name     VARCHAR2 (50) := 'SONIAOSR=';
        BEGIN
            --use generic check procedure
            check_generic_rates_update (
                c_check_name,
                c_rate_name,
                c_tag_name,
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 10:20',
                         'ddmmyyyy HH24:MI'),
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 10:40',
                         'ddmmyyyy HH24:MI'));
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_sonia_eve_update;


        ---------------------------------
        --Summary:Check if trade date of STIBOR rates corresponds to the current day
        --Parameters:none
        --Author:NICMAL2
        --Date:30/04/2019
        ---------------------------------
        PROCEDURE check_stibor_update
        IS
            c_check_name   VARCHAR2 (100) := 'stibor_update';
            c_rate_name    VARCHAR2 (50) := 'STIBOR - Sweden';
            c_tag_name     VARCHAR2 (50) := 'STISEK3MDFI=';
        BEGIN
            --use generic check procedure
            check_generic_rates_update (
                c_check_name,
                c_rate_name,
                c_tag_name,
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 11:30',
                         'ddmmyyyy HH24:MI'),
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 11:45',
                         'ddmmyyyy HH24:MI'),
                i_previous_date   => TRUE);
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_stibor_update;


        ---------------------------------
        --Summary:Date and timeframe condition IRS rate check
        --Parameters:none
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        FUNCTION cond_irs_rates
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF (    SYSDATE >
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:40',
                        'ddmmyyyy HH24:MI')
                AND (SYSDATE <
                     TO_DATE (
                         TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 20:00',
                         'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_irs_rates;


        ---------------------------------
        --Summary:Check if IRS Rates have been received today 18:30-18:40
        --Parameters: none
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        PROCEDURE check_irs_rates
        IS
            c_check_name    VARCHAR2 (100) := 'irs_rates';
            c_check_title   VARCHAR2 (100) := 'IRS Rates (today after 18:30)';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM k.MSG_EXTL_IN mi, k.msg m
             WHERE     MI.ID = m.ID
                   AND mi.timestamp >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:30',
                           'ddmmyyyy HH24:MI')
                   AND mi.text LIKE '%1Y=%'
                   AND msg_type = 'MMKT_EVAL_RATES';


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_major_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : No IRS rates received (after 18:30).</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_irs_rates;


        ---------------------------------
        --Summary:Check if trade date of IRS rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:17/07/2014
        ---------------------------------
        PROCEDURE check_irs_update
        IS
            c_check_name   VARCHAR2 (100) := 'irs_update';
            c_rate_name    VARCHAR2 (50) := 'IRS';
            c_tag_name     VARCHAR2 (50) := 'AUDQM3AB1Y=';
        BEGIN
            --use generic check procedure
            check_generic_rates_update_all (
                c_check_name,
                c_rate_name,
                c_tag_name,
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:30',
                         'ddmmyyyy HH24:MI'),
                SYSDATE,
                'MMKT_EVAL_RATES');
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_irs_update;


        ---------------------------------
        --Summary:Date and timeframe condition for deposit rates check
        --Parameters:none
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        FUNCTION cond_deposit_rates
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF (    SYSDATE >
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:40',
                        'ddmmyyyy HH24:MI')
                AND (SYSDATE <
                     TO_DATE (
                         TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 20:00',
                         'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_deposit_rates;


        ---------------------------------
        --Summary:Check if Deposit Rates have been received today 18:30-18:40
        --Parameters: none
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        PROCEDURE check_deposit_rates
        IS
            c_check_name    VARCHAR2 (100) := 'deposit_rates';
            c_check_title   VARCHAR2 (100)
                                := 'Deposit Rates (today after 18:30)';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM k.MSG_EXTL_IN mi, k.msg m
             WHERE     MI.ID = m.ID
                   AND mi.timestamp >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:30',
                           'ddmmyyyy HH24:MI')
                   AND mi.text LIKE '%1MD=%'
                   AND msg_type = 'MMKT_EVAL_RATES';


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_major_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : No Deposit rates received (after 18:30).</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_deposit_rates;

        ---------------------------------
        --Summary:Check if trade date of deposit rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:17/07/2014
        ---------------------------------
        PROCEDURE check_deposit_rates_update
        IS
            c_check_name   VARCHAR2 (100) := 'deposit_rates_update';
            c_rate_name    VARCHAR2 (50) := 'Deposit Rates';
            c_tag_name     VARCHAR2 (50) := 'AED1MD=';
        BEGIN
            --use generic check procedure
            check_generic_rates_update_all (
                c_check_name,
                c_rate_name,
                c_tag_name,
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:30',
                         'ddmmyyyy HH24:MI'),
                SYSDATE,
                'MMKT_EVAL_RATES');
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_deposit_rates_update;

        ---------------------------------
        --Summary:Date and timeframe condition CICH - Volatility rates check
        --Parameters:none
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        FUNCTION cond_cich_volatility_rates
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF (    SYSDATE >
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:45',
                        'ddmmyyyy HH24:MI')
                AND (SYSDATE <
                     TO_DATE (
                         TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 19:00',
                         'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cich_volatility_rates;


        ---------------------------------
        --Summary:Check if FX Volatility rates for CIC-CH have been received today.
        --Parameters: none
        --Author:CHRBEC
        --Date:24/01/2014
        ---------------------------------
        PROCEDURE check_cich_volatility_rates
        IS
            c_check_name    VARCHAR2 (100) := 'cich_volatility_rates';
            c_check_title   VARCHAR2 (100)
                := 'FX Volatility Rates for CIC-CH (today : 18:30 - 18:40)';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM k.MSG_EXTL_IN mi, k.msg m
             WHERE     MI.ID = m.ID
                   AND mi.timestamp > TRUNC (SYSDATE)
                   AND mi.msg_type = 'NC$FX_VLT';


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_major_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : No FX Volatility rates received today.</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cich_volatility_rates;



        ---------------------------------
        --Summary:Check if trade date of volatility rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:17/07/2014
        ---------------------------------
        PROCEDURE check_volatility_rates_update
        IS
            c_check_name   VARCHAR2 (100) := 'volatility_rates_update';
            c_rate_name    VARCHAR2 (50) := 'Volatility Rates';
            c_tag_name     VARCHAR2 (50) := 'CHF1MO=R';
        BEGIN
            --use generic check procedure
            check_generic_rates_update_all (
                c_check_name,
                c_rate_name,
                c_tag_name,
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 18:00',
                         'ddmmyyyy HH24:MI'),
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 19:00',
                         'ddmmyyyy HH24:MI'),
                'NC$FX_VLT');
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_volatility_rates_update;


        ---------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------
        --Other European Checks
        ---------------------------------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------------------------------

        ---------------------------------
        --Summary:Timing condition for FRS TAFREP check - only to be executed on the first run of BDL in the morning
        --Parameters:none
        --Author:CHRBEC
        --Date:11/03/2014
        ---------------------------------
        FUNCTION cond_frs_tafrep
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            /* Check pillar calculation is over from the last 20 minutes*/
            IF SYSDATE <
               TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:30',
                        'ddmmyyyy HH24:MI')
            THEN
                  SELECT COUNT (*)
                    INTO l_nr
                    FROM k.serpil
                   WHERE     tab = 'FRS_MOV'
                         AND period_start =
                             TRUNC (lookup_ddic#.date_ ('today -1v'))
                         AND bu_id = 3
                ORDER BY timestamp_end DESC;
            ELSE
                  SELECT COUNT (*)
                    INTO l_nr
                    FROM k.serpil
                   WHERE     tab = 'FRS_MOV'
                         AND period_start =
                             TRUNC (lookup_ddic#.date_ ('today -1v'))
                         AND bu_id = 3
                         AND TO_DATE (TO_CHAR (timestamp_end, 'HH24:Mi'),
                                      'HH24:Mi') >=
                             TO_DATE (
                                 TO_CHAR (SYSDATE - 1 / 24 / 3 * 2, 'HH24:Mi'),
                                 'HH24:Mi')
                         AND TO_DATE (TO_CHAR (timestamp_end, 'HH24:Mi'),
                                      'HH24:Mi') <=
                             TO_DATE (
                                 TO_CHAR (SYSDATE - 1 / 24 / 3, 'HH24:Mi'),
                                 'HH24:Mi')
                ORDER BY timestamp_end DESC;
            END IF;

            IF l_nr > 0
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_frs_tafrep;


        ---------------------------------
        --Summary:Check if the FRS_MOV pillar has the complete list of orders to be reported to CSFF
        --Parameters:none
        --Author:CHRBEC
        --Date:11/03/2014
        ---------------------------------
        PROCEDURE check_frs_tafrep
        IS
            c_check_name    VARCHAR2 (100) := 'frs_tafrep';
            c_check_title   VARCHAR2 (100)
                                := 'FRS TAFREP CSFF orders missing';
            l_cnt           NUMBER := 0;
            c_max           NUMBER := 0;
            l_text          CLOB := '';
        BEGIN
            FOR l_doc
                IN (SELECT d.*
                      FROM doc d, doc_stex stex
                     WHERE     d.id IN
                                   (SELECT doc_id
                                      FROM evt3
                                     WHERE     done_date =
                                               lookup_ddic#.date_ (
                                                   'today -1v')
                                           AND meta_typ_id = 1)
                           AND (   d.wfc_status_id IN (90, 80)
                                OR     d.wfc_status_id = 92
                                   AND (SELECT COUNT (*)
                                          FROM trans t, trans t_rev
                                         WHERE     t.doc_id = d.id
                                               AND t_rev.doc_id = d.id
                                               AND t_rev.new_wfc_status_id =
                                                   92
                                               AND t.new_wfc_status_id = 90
                                               AND TRUNC (t_rev.timestamp) =
                                                   TRUNC (t.timestamp)) =
                                       0) --also include reversed orders where reversal does not have done_date = -1v
                           AND d.bp_imed_id = 3
                           AND d.doc_role_id = 2
                           AND stex.doc_id = d.id
                           AND stex.cust_cont_id != 49323 --exclusion of FECUSTCONT
                           AND stex.mkt_id != 46211        --exlusion of OTCPM
                           AND stex.mkt_id IN
                                   (SELECT /*+NO_UNNEST */
                                           obj_id
                                      FROM obj_class
                                     WHERE     obj_classif_id = 5438
                                           AND obj_class_id = 21333) --Mifid relevant
                           AND d.asset_id IN
                                   (SELECT /*+NO_UNNEST */
                                           obj_id
                                      FROM obj_class
                                     WHERE     obj_classif_id = 4168
                                           AND obj_class_id = 202951) --asset class - mifid relevant
                           AND d.bp_1_id != 48932             --exclude INPOOL
                           AND d.cont_1_id != 49308       --exclude INPOOLCONT
                           AND d.cont_1_id NOT IN
                                   (SELECT obj_id
                                      FROM obj_class
                                     WHERE     obj_class_id IN
                                                   (3517, 3516, 3515)
                                           AND obj_classif_id = 2164) --exclude container classes
                           AND d.order_type_id IN (641,
                                                   642,
                                                   643,
                                                   644,
                                                   646,
                                                   645) --only order types BC, SC, BOPC, SOPC, BCLC, SCLC
                           AND (   stex.mkt_id IN (46208, 45943, 45957) --member markets
                                OR d.bp_1_id IN
                                       (SELECT /*+NO_UNNEST */
                                               obj_id
                                          FROM obj_class
                                         WHERE     obj_classif_id = 207
                                               AND obj_class_id = 8280) --inhouse
                                OR (       doc_stex_ddic#.exec_mkt_doc_id (
                                               d.id)
                                               IS NOT NULL
                                       AND ( (SELECT COUNT (*)
                                                FROM doc            dmkt,
                                                     doc_stex_link  l_place,
                                                     doc_stex_link  l_pool,
                                                     doc            poolmem
                                               WHERE     dmkt.id =
                                                         doc_stex_ddic#.exec_mkt_doc_id (
                                                             d.id)
                                                     AND dmkt.doc_role_id = 3 --mkt order
                                                     AND dmkt.id =
                                                         l_place.doc_id
                                                     AND poolmem.id =
                                                         l_pool.to_doc_id
                                                     AND poolmem.bp_1_id IN
                                                             (SELECT /*+NO_UNNEST */
                                                                     obj_id
                                                                FROM obj_class
                                                               WHERE     obj_classif_id =
                                                                         207
                                                                     AND obj_class_id =
                                                                         8280)
                                                     AND l_pool.doc_id =
                                                         l_place.to_doc_id
                                                     AND l_pool.link_type_id =
                                                         3
                                                     AND l_place.link_type_id =
                                                         4) >
                                            0)           --pooling for inhouse
                                    OR (SELECT COUNT (*)
                                          FROM doc dclt
                                         WHERE     dclt.id =
                                                   doc_stex_ddic#.exec_mkt_doc_id (
                                                       d.id)
                                               AND dclt.doc_role_id = 1
                                               AND dclt.bp_1_id IN
                                                       (SELECT /*+NO_UNNEST */
                                                               obj_id
                                                          FROM obj_class
                                                         WHERE     obj_classif_id =
                                                                   207
                                                               AND obj_class_id =
                                                                   8280)) >
                                       0)          --client orders for inhouse
                                         )
                           AND d.id NOT IN
                                   (SELECT ide_transaction_ref
                                      FROM frs_mov
                                     WHERE serpil_id IN
                                               (SELECT id
                                                  FROM serpil
                                                 WHERE     tab = 'FRS_MOV'
                                                       AND period_start =
                                                           lookup_ddic#.date_ (
                                                               'today -1v')
                                                       AND bu_id = 3)))
            LOOP
                l_cnt := l_cnt + 1;

                IF l_cnt = 1
                THEN                          --no seperator for first element
                    l_text := '' || l_doc.id;
                ELSIF l_cnt <= 20
                THEN                               --not more than 20 messages
                    IF MOD (l_cnt, 10) = 0
                    THEN                          --linebreak every 10 entries
                        l_text := l_text || ', ' || l_doc.id || CHR (10);
                    ELSE
                        l_text := l_text || ', ' || l_doc.id;
                    END IF;
                ELSIF l_cnt = 21
                THEN                           --if more than 20 -> add 3 dots
                    l_text := l_text || '...more';
                END IF;
            END LOOP;

            write_query (c_check_title,
                         l_cnt,
                         c_max,
                         c_major_p,
                         '=',
                         c_check_name);

            IF l_cnt > 0
            THEN
                p_html_pool :=
                       '<br/><b>WARNING for STEX TEAM : '
                    || l_cnt
                    || ' orders missing from FRS_MOV pillar: <br/></b>'
                    || l_text
                    || '<br/>'
                    || p_html_pool;
                p_to := upsert_mails (p_to, ';', l_mail_prcq_stex_lu);
                p_to := upsert_mails (p_to, ';', l_mail_fina_it);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_frs_tafrep;


        ---------------------------------
        --Summary:Check if the FRS_MOV pillar has contains orders that should not be reported to CSFF
        --Parameters:none
        --Author:CHRBEC
        --Date:11/03/2014
        ---------------------------------
        PROCEDURE check_frs_tafrep_reverse
        IS
            c_check_name    VARCHAR2 (100) := 'frs_tafrep_rev';
            c_check_title   VARCHAR2 (100) := 'FRS TAFREP CSFF false entries';
            l_cnt           NUMBER := 0;
            c_max           NUMBER := 0;
            l_text          CLOB := '';
        BEGIN
            FOR l_doc
                IN (SELECT LTRIM (ide_transaction_ref, '0')     ID
                      FROM frs_mov
                     WHERE     serpil_id IN
                                   (SELECT id
                                      FROM serpil
                                     WHERE     tab = 'FRS_MOV'
                                           AND period_start =
                                               lookup_ddic#.date_ (
                                                   'today -1v')
                                           AND bu_id = 3)
                           AND ide_transaction_ref NOT IN
                                   (SELECT d.id
                                      FROM doc d, doc_stex stex
                                     WHERE     d.id IN
                                                   (SELECT doc_id
                                                      FROM evt3
                                                     WHERE     done_date =
                                                               lookup_ddic#.date_ (
                                                                   'today -1v')
                                                           AND meta_typ_id =
                                                               1)
                                           AND (   d.wfc_status_id IN
                                                       (90, 80)
                                                OR     d.wfc_status_id = 92
                                                   AND (SELECT COUNT (*)
                                                          FROM trans  t,
                                                               trans  t_rev
                                                         WHERE     t.doc_id =
                                                                   d.id
                                                               AND t_rev.doc_id =
                                                                   d.id
                                                               AND t_rev.new_wfc_status_id =
                                                                   92
                                                               AND t.new_wfc_status_id =
                                                                   90
                                                               AND TRUNC (
                                                                       t_rev.timestamp) =
                                                                   TRUNC (
                                                                       t.timestamp)) =
                                                       0) --also include reversed orders where reversal does not have done_date = -1v
                                           AND d.bp_imed_id = 3
                                           AND d.doc_role_id = 2
                                           AND stex.doc_id = d.id
                                           AND stex.cust_cont_id != 49323 --exclusion of FECUSTCONT
                                           AND stex.mkt_id != 46211 --exlusion of OTCPM
                                           AND stex.mkt_id IN
                                                   (SELECT /*+NO_UNNEST */
                                                           obj_id
                                                      FROM obj_class
                                                     WHERE     obj_classif_id =
                                                               5438
                                                           AND obj_class_id =
                                                               21333) --Mifid relevant
                                           AND d.asset_id IN
                                                   (SELECT /*+NO_UNNEST */
                                                           obj_id
                                                      FROM obj_class
                                                     WHERE     obj_classif_id =
                                                               4168
                                                           AND obj_class_id =
                                                               202951) --asset class - mifid relevant
                                           AND d.bp_1_id != 48932 --exclude INPOOL
                                           AND d.cont_1_id != 49308 --exclude INPOOLCONT
                                           AND d.cont_1_id NOT IN
                                                   (SELECT obj_id
                                                      FROM obj_class
                                                     WHERE     obj_class_id IN
                                                                   (3517,
                                                                    3516,
                                                                    3515)
                                                           AND obj_classif_id =
                                                               2164) --exclude container classes
                                           AND d.order_type_id IN (641,
                                                                   642,
                                                                   643,
                                                                   644,
                                                                   646,
                                                                   645) --only order types BC, SC, BOPC, SOPC, BCLC, SCLC
                                           AND (   stex.mkt_id IN
                                                       (46208, 45943, 45957) --member markets
                                                OR d.bp_1_id IN
                                                       (SELECT /*+NO_UNNEST */
                                                               obj_id
                                                          FROM obj_class
                                                         WHERE     obj_classif_id =
                                                                   207
                                                               AND obj_class_id =
                                                                   8280) --inhouse
                                                OR (       doc_stex_ddic#.exec_mkt_doc_id (
                                                               d.id)
                                                               IS NOT NULL
                                                       AND ( (SELECT COUNT (
                                                                         *)
                                                                FROM doc dmkt,
                                                                     doc_stex_link
                                                                     l_place,
                                                                     doc_stex_link
                                                                     l_pool,
                                                                     doc
                                                                     poolmem
                                                               WHERE     dmkt.id =
                                                                         doc_stex_ddic#.exec_mkt_doc_id (
                                                                             d.id)
                                                                     AND dmkt.doc_role_id =
                                                                         3 --mkt order
                                                                     AND dmkt.id =
                                                                         l_place.doc_id
                                                                     AND poolmem.id =
                                                                         l_pool.to_doc_id
                                                                     AND poolmem.bp_1_id IN
                                                                             (SELECT /*+NO_UNNEST */
                                                                                     obj_id
                                                                                FROM obj_class
                                                                               WHERE     obj_classif_id =
                                                                                         207
                                                                                     AND obj_class_id =
                                                                                         8280)
                                                                     AND l_pool.doc_id =
                                                                         l_place.to_doc_id
                                                                     AND l_pool.link_type_id =
                                                                         3
                                                                     AND l_place.link_type_id =
                                                                         4) >
                                                            0) --pooling for inhouse
                                                    OR (SELECT COUNT (*)
                                                          FROM doc dclt
                                                         WHERE     dclt.id =
                                                                   doc_stex_ddic#.exec_mkt_doc_id (
                                                                       d.id)
                                                               AND dclt.doc_role_id =
                                                                   1
                                                               AND dclt.bp_1_id IN
                                                                       (SELECT /*+NO_UNNEST */
                                                                               obj_id
                                                                          FROM obj_class
                                                                         WHERE     obj_classif_id =
                                                                                   207
                                                                               AND obj_class_id =
                                                                                   8280)) >
                                                       0) --client orders for inhouse
                                                         )))
            LOOP
                l_cnt := l_cnt + 1;

                IF l_cnt = 1
                THEN                          --no seperator for first element
                    l_text := '' || l_doc.id;
                ELSIF l_cnt <= 20
                THEN                               --not more than 20 messages
                    IF MOD (l_cnt, 10) = 0
                    THEN                          --linebreak every 10 entries
                        l_text := l_text || ', ' || l_doc.id || CHR (10);
                    ELSE
                        l_text := l_text || ', ' || l_doc.id;
                    END IF;
                ELSIF l_cnt = 21
                THEN                           --if more than 20 -> add 3 dots
                    l_text := l_text || '...more';
                END IF;
            END LOOP;

            write_query (c_check_title,
                         l_cnt,
                         c_max,
                         c_major_p,
                         '=',
                         c_check_name);

            IF l_cnt > 0
            THEN
                p_html_pool :=
                       '<br/><b>WARNING for STEX TEAM : '
                    || l_cnt
                    || ' falsely added to FRS_MOV pillar: <br/></b>'
                    || l_text
                    || '<br/>'
                    || p_html_pool;
                p_to := upsert_mails (p_to, ';', l_mail_prcq_stex_lu);
                p_to := upsert_mails (p_to, ';', l_mail_fina_it);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_frs_tafrep_reverse;


        ---------------------------------
        --Summary:Activation condition for asset evaluation check
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2015
        ---------------------------------
        FUNCTION cond_check_asset_eval
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF (    SYSDATE >
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:45',
                        'ddmmyyyy HH24:MI')
                AND SYSDATE <
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 08:15',
                        'ddmmyyyy HH24:MI'))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_check_asset_eval;

        ---------------------------------
        --Summary:Date and timeframe condition for FX Rates ECB
        --Parameters:
        --Author:THOADA3
        --Date:01/07/2025
        ---------------------------------
        FUNCTION cond_fx_rates_ecb
           RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF is_day_off (2015, SYSDATE)
            THEN
                l_cond := FALSE;
            ELSIF (    SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 19:00',
                           'ddmmyyyy HH24:MI')
                   AND (SYSDATE <
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 19:30',
                            'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_fx_rates_ecb;

        ---------------------------------
        --Summary:Check if FX Rates ECB have been received
        --Parameters:
        --Author:THOADA3
        --Date:01/07/2025
        ---------------------------------
        PROCEDURE check_fx_rates_ecb
        IS
            c_check_name    VARCHAR2 (100) := 'rates_fx_ecb';
            c_check_title   VARCHAR2 (100) := 'FX Rates ECB (today : 19:00 - 19:30)';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM    k.MSG_EXTL_IN mi, k.msg m
            WHERE  MI.ID = m.ID
            AND mi.msg_type = 'FX_RATES'
            AND ( text LIKE '%<RIC>EUR%REF=</RIC>%')
            AND mi.timestamp > trunc(SYSDATE);

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_major_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : No FX Rates ECB received today.</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_fx_rates_ecb;

        ---------------------------------
        --Summary:Check if trade date of fx rates ecb rates corresponds to the current day
        --Author:THOADA3
        --Date:01/07/2025
        ---------------------------------
        PROCEDURE check_fx_rates_ecb_update
        IS
            c_check_name   VARCHAR2 (100) := 'rates_fx_ecb_update';
            c_rate_name    VARCHAR2 (50) := 'FX ECB';

            c_tag_name     VARCHAR2 (50) := 'EUR%REF=';
            l_cnt          NUMBER;
            l_test_date    DATE;
            l_xml          CLOB;
            l_msg_type     VARCHAR2 (50) := 'FX_RATES_ECB';
        BEGIN
              -- Check if message has been received
                SELECT COUNT (*)
                    INTO l_cnt
                    FROM    k.MSG_EXTL_IN mi, k.msg m
                WHERE  MI.ID = m.ID
                AND mi.msg_type = 'FX_RATES'
                AND ( text LIKE '%<RIC>' || c_tag_name || '</RIC>%')
                AND mi.timestamp > trunc(SYSDATE);

            IF l_cnt > 0
            THEN
                --get rate message content and pars trade date of a given identifier element
                FOR c
                    IN (SELECT *
                          FROM (  SELECT text
                                  FROM msg_extl_in mi, msg m
                                   WHERE     mi.id = m.id
                                        AND mi.msg_type = 'FX_RATES'
                                        AND ( text LIKE '%<RIC>' || c_tag_name || '</RIC>%')
                                        ORDER BY m.timestamp DESC)
                         WHERE ROWNUM = 1)
                LOOP
                    l_xml := c.text;
                END LOOP;

                l_test_date :=
                    TO_DATE (parse_cur_xml_tag_multi_value (l_xml,
                                                      'Trade_Date',
                                                      12,
                                                      c_tag_name),
                             'YYYY/MM/DD');

                --Check with blocking severity
                write_query (c_rate_name || ' up-to-date',
                             TO_CHAR (l_test_date, 'DD/MM/YYYY'),
                             TO_CHAR (SYSDATE, 'DD/MM/YYYY'),
                             c_blocking_p,
                             '=',
                             c_check_name);

                --Warning to market team
                IF TO_CHAR (l_test_date, 'DD/MM/YYYY') !=
                   TO_CHAR (SYSDATE, 'DD/MM/YYYY')
                THEN
                    p_to := upsert_mails (p_to, ';', l_mail_market_it);

                    p_html_pool :=
                           '<br/><b>WARNING for MARKET TEAM : '
                        || c_rate_name
                        || ' rates not up-to-date: '
                        || TO_CHAR (l_test_date, 'DD/MM/YYYY')
                        || '</b><br/>'
                        || p_html_pool;
                END IF;
            ELSE
                --if no message received, display N/A check result with severity major, no warning - since presence check will create warning
                write_query (c_rate_name || ' up-to-date',
                             'N/A',
                             TO_CHAR (SYSDATE, 'DD/MM/YYYY'),
                             c_major_p,
                             '=',
                             c_check_name);
                p_html_pool :=
                       '<br/><b>WARNING for MARKET TEAM : '
                    || c_rate_name
                    || ' rates date could not be validated!</b><br/>'
                    || p_html_pool;
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_fx_rates_ecb_update;

        ---------------------------------
        --Summary:Check for asset evaluation related error logs in the table eval log
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2015
        ---------------------------------
        PROCEDURE check_asset_eval
        IS
            c_check_name    VARCHAR2 (100) := 'asset_eval';
            c_check_title   VARCHAR2 (100) := 'Asset Evaluation Error Logs';
            l_cnt           NUMBER;
            c_max           NUMBER := 0;
            l_error_text    VARCHAR2 (2000) := '';
        BEGIN
            SELECT COUNT (DISTINCT obj_id)
              INTO l_cnt
              FROM eval_log
             WHERE     err_msg =
                       'For adding a yield curve a cashflow series is essential!'
                   AND eval_date = lookup_ddic#.date_ ('-1b');


            write_query (c_check_title,
                         l_cnt,
                         c_max,
                         c_major_p,
                         '=',
                         c_check_name);

            IF l_cnt > 0
            THEN
                --Warning to market team
                p_to := upsert_mails (p_to, ';', l_mail_asset_eval);


                l_cnt := 0;

                FOR l_entry
                    IN (SELECT DISTINCT obj_id
                          FROM eval_log el
                         WHERE     err_msg =
                                   'For adding a yield curve a cashflow series is essential!'
                               AND eval_date = lookup_ddic#.date_ ('-1b')
                               AND NOT EXISTS
                                       (SELECT *
                                          FROM ts_v t
                                         WHERE     t.obj_id = el.obj_id
                                               AND t.eff_date = el.eval_date
                                               AND t.md_domn_id =
                                                   el.md_domn_id
                                               AND t.md_scen_id =
                                                   el.calc_md_scen_id))
                LOOP
                    IF l_cnt > 0
                    THEN
                        IF MOD (l_cnt, 5) = 0
                        THEN
                            l_error_text := l_error_text || '<br/>';
                        ELSE
                            l_error_text := l_error_text || ',';
                        END IF;
                    END IF;

                    l_cnt := l_cnt + 1;

                    IF l_cnt > 40
                    THEN
                        l_error_text := l_error_text || '...more!';
                        EXIT;
                    END IF;

                    l_error_text := l_error_text || l_entry.obj_id;
                END LOOP;

                p_html_pool :=
                       '<br/><b>WARNING for FINANCE TEAM : Potential Evaluation Errors for Assets: </b><br/>'
                    || l_error_text
                    || '<br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_asset_eval;



        ---------------------------------
        --Summary:Check for asset evaluation related error logs in the table eval log
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2015
        ---------------------------------
        PROCEDURE check_pay_sas_ctrl
        IS
            c_check_name    VARCHAR2 (100) := 'pay_sas_ctrl';
            c_check_title   VARCHAR2 (100) := 'Payment SAS control bypassed';
            l_nr            NUMBER := 0;
            c_max           NUMBER := 0;
            l_text          VARCHAR2 (2000) := '';
            l_col_cnt       NUMBER;

            TYPE t_doc_list IS TABLE OF NUMBER
                INDEX BY BINARY_INTEGER;

            l_doc_list      t_doc_list;
        BEGIN
            SELECT COUNT (*)
              INTO l_col_cnt
              FROM all_tab_columns
             WHERE     table_name = 'DOC_PAY_EXTN'
                   AND column_name = 'PAY_SAS_BYPASSED';

            IF l_col_cnt > 0
            THEN
                SELECT DISTINCT d.id
                  BULK COLLECT INTO l_doc_list
                  FROM k.doc  d
                       JOIN k.doc_pay_extn e ON d.id = e.doc_id
                       JOIN k.trans t ON d.id = t.doc_id
                 WHERE     d.meta_typ_id = 6
                       AND (   (t.old_wfc_status_id = 827)
                            OR (    t.wfc_action_id = -214
                                AND t.old_wfc_status_id = 105))
                       AND t.timestamp > SYSDATE - 16 / (24 * 60)
                       AND e.pay_sas_bypassed = 5230;

                FOR l_idx IN 1 .. l_doc_list.COUNT
                LOOP
                    l_nr := l_nr + 1;

                    IF l_nr = 1
                    THEN                      --no seperator for first element
                        l_text := '' || l_doc_list (l_idx);
                    ELSIF l_nr <= 20
                    THEN                             --not more than 20 orders
                        IF MOD (l_nr, 10) = 0
                        THEN                      --linebreak every 10 entries
                            l_text :=
                                   l_text
                                || ', '
                                || l_doc_list (l_idx)
                                || CHR (10);
                        ELSE
                            l_text := l_text || ', ' || l_doc_list (l_idx);
                        END IF;
                    ELSIF l_nr = 21
                    THEN                       --if more than 20 -> add 3 dots
                        l_text := l_text || '...more';
                    END IF;
                END LOOP;


                IF l_nr > c_max
                THEN
                    p_html_pool :=
                           '<br/><b>WARNING SAS control has been bypassed for '
                        || l_nr
                        || ' orders : '
                        || l_text
                        || '</b><br/>'
                        || p_html_pool;
                    p_to := upsert_mails (p_to, ';', l_mail_oprisk);
                END IF;

                write_query ('Payment SAS control bypassed (15 minutes)',
                             l_nr,
                             c_max,
                             c_major_p,
                             '=',
                             c_check_name);
            END IF;
        END check_pay_sas_ctrl;

        ---------------------------------
        --Summary:Check payment settlements failed in processing
        --Parameters:none
        --Author:CHRBEC
        --Date:10/08/2018
        ---------------------------------
        PROCEDURE check_pay_settle_fail
        IS
            c_check_name     VARCHAR2 (100) := 'pay_settle_fail';
            c_check_title    VARCHAR2 (100) := 'Payment settlement failed';
            l_nr             NUMBER := 0;
            c_max            NUMBER := 0;
            l_text           VARCHAR2 (2000) := '';

            TYPE t_doc_list IS TABLE OF NUMBER
                INDEX BY BINARY_INTEGER;

            l_doc_list       t_doc_list;
            l_min_trx_date   DATE := lookup_ddic#.date_ ('today -1v');
            l_count          NUMBER;
        BEGIN
            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_PAY_SETTLE_FAIL');

            SELECT COUNT (*)
              INTO l_nr
              FROM doc pay, doc settle
             WHERE     pay.id = settle.doc_ref_id
                   AND settle.meta_typ_id = 9
                   AND settle.trx_date >= l_min_trx_date
                   AND pay.meta_typ_id = 6
                   AND settle.bp_imed_id = 3
                   AND settle.id IN
                           (SELECT id
                              FROM prcq
                             WHERE     prcq_status_id = 9
                                   AND timestamp_start > SYSDATE - 1);


            write_query ('Pay Settlements failed ',
                         TO_CHAR (l_nr),
                         '0',
                         c_blocking_p,
                         '=',
                         'pay_settle_failed');

            --add message with order ids and bu ids
            IF l_nr > 0
            THEN
                l_text := NULL;
                l_count := 0;


                FOR ent
                    IN (SELECT settle.id     SETTLE_ID,
                               pay.id        PAYMENT_ID,
                               settle.bp_imed_id
                          FROM doc pay, doc settle
                         WHERE     pay.id = settle.doc_ref_id
                               AND settle.meta_typ_id = 9
                               AND settle.trx_date >= l_min_trx_date
                               AND pay.meta_typ_id = 6
                               AND settle.bp_imed_id = 3
                               AND settle.id IN
                                       (SELECT id
                                          FROM prcq
                                         WHERE     prcq_status_id = 9
                                               AND timestamp_start >
                                                   SYSDATE - 1))
                LOOP
                    --limit entries to 20 by counter
                    IF l_count > 20
                    THEN
                        EXIT;
                    END IF;

                    --add no comma for first entry
                    IF l_text IS NOT NULL
                    THEN
                        l_text := l_text || ', ';
                    END IF;

                    --add doc_id and bu_id
                    l_text :=
                           l_text
                        || ent.SETTLE_ID
                        || '('
                        || ent.PAYMENT_ID
                        || ')';

                    --increment failsafe counter
                    l_count := l_count + 1;
                END LOOP;


                p_html_pool :=
                       '<br/><b>WARNING for PAYMENT TEAM : '
                    || l_nr
                    || ' Settlement order(s) failed:</b><br/>'
                    || l_text
                    || '<br/>'
                    || p_html_pool;

                p_to := upsert_mails (p_to, ';', l_mail_pay_dflt);
            END IF;
        END check_pay_settle_fail;
    -----------------------------------------------------------------------------
    -----------------------------------------------------------------------------
    -----------------------MAIN For BDL functional checks------------------------
    -----------------------------------------------------------------------------
    -----------------------------------------------------------------------------
    BEGIN
        IF bdl_active_cond OR c_force_bdl_active
        THEN
            ---------
            --START SECTION EURO
            ---------

            write_header ('European Functional checks', c_severity_euro_ph);
            g_active_section := c_section_euro;

            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_USER_LOCK');
            check_user_lock;      --no line, only message and add user to mail

            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_PAY_ORDER_LOCKED');
            check_pay_order_locked;

            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_SMP_BU');

            IF cond_check_smp_bu OR c_force_active
            THEN
                check_smp_bu;
            END IF;

            ------European Rates Section------

            write_subheader ('Rates');

            IF cond_fx_rates_trade OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_FX_RATES_TRADE');
                check_fx_rates_trade;
            END IF;

            IF cond_fx_rates_15 OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_FX_RATES_15');
                check_fx_rates_15;
            END IF;

            IF cond_fx_rates_15_update OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_FX_RATES_15_update');
                check_fx_rates_15_update;
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_FX_RATES_15_upload');
                check_fx_rates_15_upload;
            END IF;

            /*
            if cond_fx_rates_msg or c_force_active then
                DBMS_APPLICATION_INFO.SET_ACTION('CHECK_FX_RATES_MSG');
                check_fx_rates_msg;
            end if;
            */

            -- starts every hour check_rates_to_irc_task
            IF cond_rates_to_irc_task OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_RATES_TO_IRC_TASK');
                check_rates_to_irc_task;
            END IF;

            --check only active when msg is received
            IF cond_sdm_rates_loan_fta OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_SDM_RATES_LOAN_FTA');
                check_sdm_rates_loan_fta_task;
            END IF;

            --check only active when msg is received
            IF cond_sdm_rates_mmkt OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_SDM_RATES_MMKT');
                check_sdm_rates_mmkt_task;
            END IF;


            IF cond_fx_exotic_morning OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_FX_EXOTIC_MORNING');
                check_fx_exotic_morning;
            END IF;

            IF cond_fx_exotic_evening OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_FX_EXOTIC_EVENING');
                check_fx_exotic_evening;
            END IF;

            IF cond_fx_rates_exotic_update OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_FX_EXOTIC_UPDATE');
                check_fx_rates_exotic_update;
            END IF;

            IF cond_fx_rates_ecb OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_FX_RATES_ECB');
                check_fx_rates_ecb;
                check_fx_rates_ecb_update;
            END IF;

            IF cond_euribor OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_EURIBOR');
                check_euribor;
                check_euribor_update;
                check_euribor_task;
            END IF;

            IF cond_SGP OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_SGP');
                check_SGP;
            END IF;

            IF cond_sofr OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_SOFR');
                check_sofr_update;
            END IF;

            IF cond_sofr_index OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_SOFR');
                check_sofr_index_update;
            END IF;

            IF cond_saron OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_SARON');
                check_saron_update;
            END IF;

            IF cond_saron_compound OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_SARON');
                check_saron_compound_update;
            END IF;

            IF cond_mmkt_rates_ffe OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_MMKT_RATES_FFE');
                check_mmkt_rates_ffe;
                check_mmkt_rates_ffe_update;
            END IF;

            IF cond_mmkt_rates_sonia OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION (
                    'CHECK_MMKT_RATES_SONIA_EVE');
                check_mmkt_rates_sonia;
                check_sonia_eve_update;
            END IF;

            IF cond_mmkt_rates_stibor OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_MMKT_RATES_STIBOR');
                check_mmkt_rates_stibor;
                check_stibor_update;
            END IF;

            IF cond_irs_rates OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_IRS');
                check_irs_rates;
                check_irs_update;
            END IF;

            IF cond_deposit_rates OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_DEPOSIT_RATES');
                check_deposit_rates;
                check_deposit_rates_update;
            END IF;

            IF cond_cich_volatility_rates OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_VOLATILITY_RATES');
                check_cich_volatility_rates;
                check_volatility_rates_update;
            END IF;


            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CIC_ISSUER_ASSET');

            --Ceci concerne le probleme de propagation des assets au CIC  (ne fonctionne pas quand l'issuer d'un asset de type security est en BU LU, ce qui ne devrait pas arriver)
            --alerter le service Securities Database quand la requete renvoie des resultats ( = quand il y a des assets avec issuer en BU LU)
            -- test if this the first execution of the day (before 7h35)
            IF l_execution_time <
               TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:40',
                        'ddmmyyyy HH24:MI')
            THEN
                --ISSUER
                write_subheader ('Issuer');

                FOR s
                    IN (SELECT DISTINCT
                               (obj_asset.obj_id)         id,
                               ok1.key_val                isin,
                               ok2.key_val                asset_key,
                               obj_asset.bp_issuer_id     issuer_id,
                               ok3.key_val                issuer_key,
                               obj_bp.BU_ID               bu_id
                          FROM k.obj_asset,
                               k.obj,
                               k.obj_bp,
                               k.obj_name  on1,
                               k.obj_key   ok1,
                               k.obj_key   ok2,
                               k.obj_name  on2,
                               k.obj_key   ok3
                         WHERE     obj.close_date IS NULL
                               AND obj.id = obj_asset.obj_id
                               AND obj_bp.obj_id = obj_asset.bp_issuer_id
                               AND obj_asset.bp_issuer_id > 10
                               AND obj_bp.BU_ID <> 6
                               AND obj_asset.bu_id = 6
                               AND obj.obj_sub_type_id IN (2, 17)
                               AND on1.obj_id(+) = obj_asset.obj_id
                               AND on1.lang_id(+) = -1
                               AND ok1.obj_id(+) = obj_asset.obj_id
                               AND ok1.obj_key_id(+) = 1
                               AND ok2.obj_id(+) = obj_asset.obj_id
                               AND ok2.obj_key_id(+) = 18
                               AND ok3.obj_id(+) = obj_asset.bp_issuer_id
                               AND ok3.obj_key_id(+) = 11
                               AND on2.obj_id(+) = obj_asset.bp_issuer_id
                               AND on2.lang_id(+) = -1)
                LOOP
                    p_html_pool :=
                           'ASSET_ID: '
                        || s.id
                        || ', ISIN: '
                        || s.isin
                        || ', ASSET_KEY: '
                        || s.asset_key
                        || ', ISSUER_ID: '
                        || s.issuer_id
                        || ', ISSUER_KEY: '
                        || s.issuer_key
                        || ', BU_ID: '
                        || s.id
                        || '<br/>'
                        || p_html_pool;
                    l_cnt_loop := l_cnt_loop + 1;
                END LOOP;

                IF l_cnt_loop > 0
                THEN
                    p_to := p_to || ';' || l_mail_prcq_secdb;
                    p_html_pool :=
                           '<br/><b>WARNING for SECURITIES DATABASE TEAM : '
                        || l_cnt_loop
                        || ' Asset(s) with issuer in BU LU :</b><br/>'
                        || p_html_pool;
                END IF;

                write_query ('Asset(s) with issuer in BU LU',
                             TO_CHAR (l_cnt_loop),
                             '0',
                             c_major_p,
                             '=',
                             'asset_issuer');
                l_cnt_loop := 0;
            END IF;

            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_!SECURED_OBJECT');

            --Concerne le probleme des objets qui ont comme nom 'Secured!'. le but est d'informer la security team
            -- test if this the first execution of the day (before 7h35)
            IF l_execution_time <
               TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:40',
                        'ddmmyyyy HH24:MI')
            THEN
                write_subheader ('BPs names is "Secured!"');

                FOR s
                    IN (SELECT o.ID               id,
                               oni.SORT_ALPHA     sort_alpha,
                               o.BU_ID            bu_id
                          FROM k.obj_name_intl oni, k.obj o
                         WHERE     o.id = oni.obj_id
                               AND o.obj_type_id = 4
                               AND oni.name = 'Secured!')
                LOOP
                    p_html_pool :=
                           'OBJ_ID: '
                        || s.id
                        || ', SORT_ALPHA: '
                        || s.sort_alpha
                        || ', BU_ID: '
                        || s.bu_id
                        || '<br/>'
                        || p_html_pool;
                    l_cnt_loop := l_cnt_loop + 1;
                END LOOP;

                IF l_cnt_loop > 0
                THEN
                    p_to := p_to || ';' || l_mail_prcq_secur;
                    p_html_pool :=
                           '<br/><b>WARNING for SECURITY TEAM : '
                        || l_cnt_loop
                        || ' BPs with their names set as "Secured!" :</b><br/>'
                        || p_html_pool;
                END IF;

                write_query ('BPs with name set as "Secured!"',
                             TO_CHAR (l_cnt_loop),
                             '0',
                             c_major_p,
                             '=',
                             'bp_name_secured');
                l_cnt_loop := 0;
            END IF;

            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_MSG_BUNDLE');

            --probleme des msg bundle qui tombent en FAIL
            -- test if this the first execution of the day (before 7h35)
            IF l_execution_time <
               TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:40',
                        'ddmmyyyy HH24:MI')
            THEN
                write_subheader ('Message bundle');

                FOR s
                    IN (  SELECT msg_bdl_id
                            FROM k.msg
                           WHERE     meta_msg_id = 432
                                 AND f4 = 'FAIL'
                                 AND timestamp > SYSDATE - 1
                        GROUP BY msg_bdl_id)
                LOOP
                    p_html_pool :=
                           'MSG_BDL_ID: '
                        || s.msg_bdl_id
                        || '<br/>'
                        || p_html_pool;
                    l_cnt_loop := l_cnt_loop + 1;
                END LOOP;

                IF l_cnt_loop > 0
                THEN
                    p_to := p_to || ';' || l_mail_prcq_pay;
                    p_html_pool :=
                           '<br/><b>WARNING for PAY TEAM : '
                        || l_cnt_loop
                        || ' Message bundle processing failed :</b><br/>'
                        || p_html_pool;
                END IF;

                write_query ('Msg Bundle fail',
                             TO_CHAR (l_cnt_loop),
                             '0',
                             c_major_p,
                             '=',
                             'msg_bdl_fail');
                l_cnt_loop := 0;
            END IF;

            ----------------------------
            ----European STEX Checks----
            ----------------------------

            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_EUROPEAN_STEX');

            write_subheader ('Stock Exchange');

            -- Ready for Pooling orders
            l_idx := l_idx + 1;
            l_text := '';
            l_nr := 0;
            l_nr_bl := 0;
            l_bu_list.delete;

            FOR c
                IN (  SELECT d.id
                        FROM k.doc          d,
                             k.doc_stex     s,
                             k.obj_asset_add a,
                             k.code_const   c,
                             k.trans        t
                       WHERE     d.id = s.doc_id
                             AND d.wfc_status_id = 4000
                             AND d.asset_id = a.obj_id
                             AND a.ASSET_fd_net = 202
                             AND (   (    asset_fd_tech_cut_off_rdmpt = c.id
                                      AND d.order_type_grp_id = 102)
                                  OR (    asset_fd_tech_cut_off_subscr = c.id
                                      AND d.order_type_grp_id = 101))
                             AND t.doc_id = d.id
                             AND t.new_wfc_status_id = d.wfc_status_id
                             AND t.seq_nr =
                                 (SELECT MAX (seq_nr)
                                    FROM k.trans r
                                   WHERE     r.doc_id = d.id
                                         AND r.new_wfc_status_id =
                                             d.wfc_status_id)
                             AND (   (      SYSDATE
                                          - NUMTODSINTERVAL (5, 'MINUTE') >
                                          TO_DATE (
                                                 TO_CHAR (trx_date, 'ddmmyyyy')
                                              || ' '
                                              || c.name,
                                              'ddmmyyyy hh24:mi')
                                      AND (t.timestamp <
                                           TO_DATE (
                                                  TO_CHAR (trx_date,
                                                           'ddmmyyyy')
                                               || ' '
                                               || c.name,
                                               'ddmmyyyy hh24:mi')))
                                  OR (    (t.timestamp >=
                                           TO_DATE (
                                                  TO_CHAR (trx_date,
                                                           'ddmmyyyy')
                                               || ' '
                                               || c.name,
                                               'ddmmyyyy hh24:mi'))
                                      AND ((  SYSDATE
                                            - NUMTODSINTERVAL (5, 'MINUTE')) >
                                           TO_DATE (
                                                  TO_CHAR (
                                                      GREATEST (
                                                          (CASE TRIM (
                                                                    UPPER (
                                                                        TO_CHAR (
                                                                              trx_date
                                                                            + 1
                                                                            + (TRUNC (
                                                                                     TO_DATE (
                                                                                         TO_CHAR (
                                                                                             t.timestamp,
                                                                                             'ddmmyyyy hh24:mi'),
                                                                                         'ddmmyyyy hh24:mi')
                                                                                   - TO_DATE (
                                                                                            TO_CHAR (
                                                                                                trx_date,
                                                                                                'ddmmyyyy')
                                                                                         || ' '
                                                                                         || c.name,
                                                                                         'ddmmyyyy hh24:mi'))),
                                                                            'DAY')))
                                                               WHEN 'SUNDAY'
                                                               THEN
                                                                     trx_date
                                                                   + 2
                                                                   + (TRUNC (
                                                                            TO_DATE (
                                                                                TO_CHAR (
                                                                                    t.timestamp,
                                                                                    'ddmmyyyy hh24:mi'),
                                                                                'ddmmyyyy hh24:mi')
                                                                          - TO_DATE (
                                                                                   TO_CHAR (
                                                                                       trx_date,
                                                                                       'ddmmyyyy')
                                                                                || ' '
                                                                                || c.name,
                                                                                'ddmmyyyy hh24:mi')))
                                                               WHEN 'DIMANCHE'
                                                               THEN
                                                                     trx_date
                                                                   + 2
                                                                   + (TRUNC (
                                                                            TO_DATE (
                                                                                TO_CHAR (
                                                                                    t.timestamp,
                                                                                    'ddmmyyyy hh24:mi'),
                                                                                'ddmmyyyy hh24:mi')
                                                                          - TO_DATE (
                                                                                   TO_CHAR (
                                                                                       trx_date,
                                                                                       'ddmmyyyy')
                                                                                || ' '
                                                                                || c.name,
                                                                                'ddmmyyyy hh24:mi')))
                                                               WHEN 'SATURDAY'
                                                               THEN
                                                                     trx_date
                                                                   + 3
                                                                   + (TRUNC (
                                                                            TO_DATE (
                                                                                TO_CHAR (
                                                                                    t.timestamp,
                                                                                    'ddmmyyyy hh24:mi'),
                                                                                'ddmmyyyy hh24:mi')
                                                                          - TO_DATE (
                                                                                   TO_CHAR (
                                                                                       trx_date,
                                                                                       'ddmmyyyy')
                                                                                || ' '
                                                                                || c.name,
                                                                                'ddmmyyyy hh24:mi')))
                                                               WHEN 'SAMEDI'
                                                               THEN
                                                                     trx_date
                                                                   + 3
                                                                   + (TRUNC (
                                                                            TO_DATE (
                                                                                TO_CHAR (
                                                                                    t.timestamp,
                                                                                    'ddmmyyyy hh24:mi'),
                                                                                'ddmmyyyy hh24:mi')
                                                                          - TO_DATE (
                                                                                   TO_CHAR (
                                                                                       trx_date,
                                                                                       'ddmmyyyy')
                                                                                || ' '
                                                                                || c.name,
                                                                                'ddmmyyyy hh24:mi')))
                                                               ELSE
                                                                     trx_date
                                                                   + 1
                                                                   + (TRUNC (
                                                                            TO_DATE (
                                                                                TO_CHAR (
                                                                                    t.timestamp,
                                                                                    'ddmmyyyy hh24:mi'),
                                                                                'ddmmyyyy hh24:mi')
                                                                          - TO_DATE (
                                                                                   TO_CHAR (
                                                                                       trx_date,
                                                                                       'ddmmyyyy')
                                                                                || ' '
                                                                                || c.name,
                                                                                'ddmmyyyy hh24:mi')))
                                                           END),
                                                          TRUNC (t.timestamp)),
                                                      'ddmmyyyy')
                                               || ' '
                                               || c.name,
                                               'ddmmyyyy hh24:mi'))))
                    ORDER BY d.id)
            LOOP
                l_nr := l_nr + 1;

                IF l_nr <= 50
                THEN
                    IF l_nr > 1
                    THEN                    --seperator not before first entry
                        l_text := l_text || ',';
                    END IF;

                    l_order_bu_id := getOrderBu (c.id);

                    l_bu_list (l_bu_list.COUNT + 1) := l_order_bu_id;

                    IF l_order_bu_id = 3
                    THEN
                        l_text := l_text || c.id;       --append only order_id
                    ELSE
                        l_order_bu_name := getBuName (l_order_bu_id);
                        l_text :=
                            l_text || c.id || '(' || l_order_bu_name || ')'; --append order_id and bu
                    END IF;

                    IF l_order_bu_id IN (3, 7)
                    THEN
                        l_nr_bl := l_nr_bl + 1;
                    END IF;
                END IF;
            END LOOP;

            IF l_nr > 0
            THEN
                IF l_nr_bl > 0
                THEN
                    p_html_pool :=
                           '<br/>- Fund desk: '
                        || l_text
                        || '<br/>'
                        || p_html_pool;
                ELSE
                    p_html_pool :=
                        '<br/>' || l_text || '<br/>' || p_html_pool;
                END IF;

                p_html_pool :=
                       '<br/><b>WARNING for STEX TEAM : '
                    || l_nr
                    || ' STEX order(s) with Pooling problems (at cut off) :</b>'
                    || p_html_pool;
                p_to := appendMails (p_to, l_bu_list, 'STEX');
            END IF;

            write_query ('Ready for Pooling orders at cut off',
                         TO_CHAR (l_nr),
                         '0',
                         c_blocking_p,
                         '=',
                         'stex_ready_for_pooling');

            -- pooling now
            l_text := '';
            l_nr := 0;
            l_nr_bl := 0;
            l_bu_list.delete;

            FOR c
                IN (SELECT DISTINCT d.id
                      FROM k.doc              d,
                           k.doc_stex         s,
                           k.obj_asset_add    a,
                           k.obj_class        c,
                           k.obj              o,
                           k.sched_queue_job  j,
                           k.trans            t
                     WHERE     d.id = s.doc_id
                           AND d.wfc_status_id = 4000
                           AND d.asset_id = a.obj_id
                           AND d.asset_id = c.obj_id
                           AND d.asset_id = o.id
                           AND c.OBJ_CLASSIF_ID = 117
                           AND o.close_date IS NULL
                           AND a.ASSET_fd_net = 202
                           AND asset_fd_tech_cut_off_rdmpt IS NULL
                           AND asset_fd_tech_cut_off_subscr IS NULL
                           AND d.order_type_grp_id IN (101, 102)
                           AND j.name LIKE 'ISTX025%'
                           AND j.date_start >= d.trx_date
                           AND j.bu_id = d.bp_imed_id
                           AND t.doc_id = d.id
                           AND t.new_wfc_status_id = d.wfc_status_id
                           AND t.seq_nr =
                               (SELECT MAX (seq_nr)
                                  FROM k.trans r
                                 WHERE     r.doc_id = d.id
                                       AND r.new_wfc_status_id =
                                           d.wfc_status_id)
                           AND j.date_start > t.timestamp)
            LOOP
                l_nr := l_nr + 1;

                IF l_nr > 1 AND l_nr < 400
                THEN                       --no seperator before first element
                    l_text := l_text || ',';
                END IF;

                l_order_bu_id := getOrderBu (c.id);

                l_bu_list (l_bu_list.COUNT + 1) := l_order_bu_id;

                IF l_nr < 400
                THEN                      --display a maximum of 400 order ids
                    IF l_order_bu_id = 3
                    THEN
                        l_text := l_text || c.id;      --display only order id
                    ELSE
                        l_order_bu_name := getBuName (l_order_bu_id);
                        l_text :=
                            l_text || c.id || '(' || l_order_bu_name || ')'; --append order_id and bu-name
                    END IF;

                    IF l_order_bu_id IN (3, 7)
                    THEN
                        l_nr_bl := l_nr_bl + 1;
                    END IF;
                END IF;
            END LOOP;

            IF l_nr > 0
            THEN
                IF l_nr_bl > 0
                THEN
                    p_html_pool :=
                           '<br />- Fund Desk: '
                        || l_text
                        || '<br />'
                        || p_html_pool;
                ELSE
                    p_html_pool :=
                        '<br />' || l_text || '<br />' || p_html_pool;
                END IF;

                p_html_pool :=
                       '<br /><b>WARNING for STEX TEAM : '
                    || l_nr
                    || ' STEX order(s) with Pooling problems (Pool now) :</b>'
                    || p_html_pool;
                p_to := appendMails (p_to, l_bu_list, 'STEX');
            END IF;

            write_query ('Pooling Now orders',
                         TO_CHAR (l_nr),
                         '0',
                         c_blocking_p,
                         '=',
                         'stex_pooling_now');

            -- specific broker OHA
            l_text := '';
            l_nr := 0;
            l_nr_bl := 0;
            l_bu_list.delete;

            FOR c
                IN (SELECT DISTINCT d.id
                      FROM k.doc              d,
                           k.doc_stex         s,
                           k.obj_cont_add     a,
                           k.obj              o,
                           k.sched_queue_job  j
                     WHERE     d.id = s.doc_id
                           AND d.wfc_status_id = 4000
                           AND d.cont_1_id = a.obj_id
                           AND a.CONT_SPEC_BROKER IS NOT NULL
                           AND d.order_type_grp_id IN (101, 102)
                           AND j.name LIKE 'ISTX025%'
                           AND j.date_start >= d.trx_date)
            LOOP
                l_nr := l_nr + 1;

                IF l_nr > 1 AND l_nr < 400
                THEN
                    l_text := l_text || ',';
                END IF;

                l_order_bu_id := getOrderBu (c.id);

                l_bu_list (l_bu_list.COUNT + 1) := l_order_bu_id;

                IF l_nr < 400
                THEN
                    IF l_order_bu_id = 3
                    THEN
                        l_text := l_text || c.id;       --append only order_id
                    ELSE
                        l_order_bu_name := getBuName (l_order_bu_id);
                        l_text :=
                            l_text || c.id || '(' || l_order_bu_name || ')'; --append order_id and bu
                    END IF;

                    IF l_order_bu_id IN (3, 7)
                    THEN
                        l_nr_bl := l_nr_bl + 1;
                    END IF;
                END IF;
            END LOOP;

            IF l_nr > 0
            THEN
                IF l_nr_bl > 0
                THEN
                    p_html_pool :=
                           '<br/>- Fund Desk: '
                        || l_text
                        || '<br/>'
                        || p_html_pool;
                ELSE
                    p_html_pool :=
                        '<br/>' || l_text || '<br/>' || p_html_pool;
                END IF;

                p_html_pool :=
                       '<br/><b>WARNING for STEX TEAM : '
                    || l_nr
                    || ' STEX order(s) with Pooling problems (spec. broker OHA) :</b>'
                    || p_html_pool;
                p_to := appendMails (p_to, l_bu_list, 'STEX');
            END IF;

            write_query ('Not Pooled for specific broker OHA',
                         TO_CHAR (l_nr),
                         '0',
                         c_blocking_p,
                         '=',
                         'stex_not_pooled_oha');

            -- petercam
            l_text := '';
            l_nr := 0;
            l_nr_bl := 0;
            l_bu_list.delete;

            FOR c IN (SELECT d.id
                        FROM k.doc d, k.doc_stex s, k.sched_queue_job j
                       WHERE     d.id = s.doc_id
                             AND d.wfc_status_id = 4000
                             AND d.cont_1_id IN (757791,
                                                 858677,
                                                 858916,
                                                 859356,
                                                 859739)
                             AND d.order_type_grp_id IN (101, 102)
                             AND j.name LIKE 'ISTX030%'
                             AND j.date_start >= d.timestamp)
            LOOP
                l_nr := l_nr + 1;

                IF l_nr > 1 AND l_nr < 400
                THEN
                    l_text := l_text || ',';
                END IF;

                l_order_bu_id := getOrderBu (c.id);

                l_bu_list (l_bu_list.COUNT + 1) := l_order_bu_id;

                IF l_nr < 400
                THEN
                    IF l_order_bu_id = 3
                    THEN
                        l_text := l_text || c.id;       --append only order id
                    ELSE
                        l_order_bu_name := getBuName (l_order_bu_id);
                        l_text :=
                            l_text || c.id || '(' || l_order_bu_name || ')'; --append order_id and bu
                    END IF;

                    IF l_order_bu_id IN (3, 7)
                    THEN
                        l_nr_bl := l_nr_bl + 1;
                    END IF;
                END IF;
            END LOOP;

            IF l_nr > 0
            THEN
                IF l_nr_bl > 0
                THEN
                    p_html_pool :=
                           '<br/>- Fund Desk: '
                        || l_text
                        || '<br/>'
                        || p_html_pool;
                ELSE
                    p_html_pool :=
                        '<br/>' || l_text || '<br/>' || p_html_pool;
                END IF;

                p_html_pool :=
                       '<br/><b>WARNING : '
                    || l_nr
                    || ' STEX order(s) with Pooling problems (Petercam) :</b>'
                    || p_html_pool;
                p_to := appendMails (p_to, l_bu_list, 'STEX');
            END IF;

            write_query ('Not Pooled orders for Petercam',
                         TO_CHAR (l_nr),
                         '0',
                         c_blocking_p,
                         '=',
                         'stex_not_pooled_petercam');
            -- stex transmission
            l_text_wait_ack := '';
            l_text_error := '';
            l_text_wait_mt509 := '';
            l_text_wait_fix := '';
            l_nr_wait_ack := 0;
            l_nr_error := 0;
            l_nr_bond := 0;
            l_nr_fund := 0;
            l_nr_fund_bllu := 0;
            l_nr_equities := 0;
            l_nr_wait_mt509 := 0;
            l_nr_wait_fix := 0;
            l_idx := l_idx + 1;
            l_nr2 := 0;
            l_desk := '';
            l_text := '';
            l_bu_list.delete;

            --order by equities fund and bond to show them under the right topic (Desk)
            FOR c
                IN (  SELECT d.id,
                             d.timestamp,
                             (SELECT COUNT (*)
                                FROM msg m
                               WHERE     m.doc_id = d.id
                                     AND m.msg_status_id IN (1,
                                                             2,
                                                             11,
                                                             22,
                                                             29))
                                 wack,
                             (SELECT COUNT (*)
                                FROM msg m
                               WHERE     m.doc_id = d.id
                                     AND m.msg_status_id IN (4,
                                                             8,
                                                             10,
                                                             28,
                                                             33))
                                 nack,
                             (SELECT COUNT (*)
                                FROM msg m
                               WHERE m.doc_id = d.id AND m.netw_id = 83)
                                 fix,
                             (SELECT s#bdl_doc_stex_pred.doc#is_traded_like_equity (
                                         d.id)
                                FROM DUAL)
                                 equi,
                             (SELECT s#bdl_doc_stex_pred.doc#is_traded_like_bond (
                                         d.id)
                                FROM DUAL)
                                 bond,
                             (SELECT s#bdl_doc_stex_pred.doc#is_traded_like_fund_ta (
                                         d.id)
                                FROM DUAL)
                                 fund,
                             (SELECT s#bdl_doc_stex_pred.doc#get_stex_asset_type (
                                         i_doc   => d.id)
                                FROM DUAL)
                                 struct_product
                        FROM doc d
                       WHERE     meta_typ_id = 1
                             AND wfc_status_id IN (2170, 3060, 3400)
                             AND (   l_execution_time <
                                     TO_DATE (
                                            TO_CHAR (TRUNC (SYSDATE),
                                                     'ddmmyyyy')
                                         || ' 07:40',
                                         'ddmmyyyy HH24:MI')
                                  OR timestamp >
                                     SYSDATE - NUMTODSINTERVAL (120, 'MINUTE'))
                    ORDER BY equi,
                             fund,
                             bond,
                             id DESC)
            LOOP
                l_nr := 0;

                IF (l_nr_wait_ack + l_nr_error + l_nr_wait_mt509) < 400
                THEN
                    --Definition of the desk concerned
                    IF c.equi = '+'
                    THEN
                        l_desk := 'Equities';
                    ELSIF c.fund = '+'
                    THEN
                        l_desk := 'Funds';
                    ELSIF (   c.bond = '+'
                           OR c.struct_product =
                              s#bdl_doc_stex_const.c_stex_asset_like_struct_prod)
                    THEN
                        l_desk := 'Bond';
                    ELSE
                        l_desk := 'Others';
                    END IF;

                    IF     c.wack > 0
                       AND (c.timestamp <
                            SYSDATE - NUMTODSINTERVAL (10, 'MINUTE'))
                    THEN
                        --Call to the setDesk function to define the desk
                        l_order_bu_id := getOrderBu (c.id);

                        l_text_wait_ack :=
                            setDesk (l_desk, l_text_wait_ack, l_order_bu_id);

                        l_nr_wait_ack := l_nr_wait_ack + 1;
                        l_nr := 1;

                        l_bu_list (l_bu_list.COUNT + 1) := l_order_bu_id;

                        IF l_order_bu_id = 3
                        THEN
                            l_text_wait_ack := l_text_wait_ack || c.id; --append only order id
                        ELSE
                            l_order_bu_name := getBuName (l_order_bu_id);
                            l_text_wait_ack :=
                                   l_text_wait_ack
                                || c.id
                                || '('
                                || l_order_bu_name
                                || ')';               --append order_id and bu
                        END IF;
                    ELSIF c.nack > 0
                    THEN
                        --Call to the setDesk function to define the desk
                        l_order_bu_id := getOrderBu (c.id);
                        l_text_error :=
                            setDesk (l_desk, l_text_error, l_order_bu_id);

                        l_nr_error := l_nr_error + 1;
                        l_nr := 1;


                        l_bu_list (l_bu_list.COUNT + 1) := l_order_bu_id;

                        IF l_order_bu_id = 3
                        THEN
                            l_text_error := l_text_error || c.id; --append only order id
                        ELSE
                            l_order_bu_name := getBuName (l_order_bu_id);
                            l_text_error :=
                                   l_text_error
                                || c.id
                                || '('
                                || l_order_bu_name
                                || ')';               --append order_id and bu
                        END IF;
                    ELSIF c.timestamp <
                          SYSDATE - NUMTODSINTERVAL (25, 'MINUTE')
                    THEN
                        l_nr := 1;

                        IF c.fix > 0
                        THEN
                            l_order_bu_id := getOrderBu (c.id);
                            --Call to the setDesk function to define the desk
                            l_text_wait_fix :=
                                setDesk (l_desk,
                                         l_text_wait_fix,
                                         l_order_bu_id);

                            l_nr_wait_fix := l_nr_wait_fix + 1;

                            l_bu_list (l_bu_list.COUNT + 1) := l_order_bu_id;

                            IF l_order_bu_id = 3
                            THEN
                                l_text_wait_fix := l_text_wait_fix || c.id; --append only order id
                            ELSE
                                l_order_bu_name := getBuName (l_order_bu_id);
                                l_text_wait_fix :=
                                       l_text_wait_fix
                                    || c.id
                                    || '('
                                    || l_order_bu_name
                                    || ')';           --append order_id and bu
                            END IF;
                        ELSE
                            l_order_bu_id := getOrderBu (c.id);
                            --Call to the setDesk function to define the desk
                            l_text_wait_mt509 :=
                                setDesk (l_desk,
                                         l_text_wait_mt509,
                                         l_order_bu_id);

                            l_nr_wait_mt509 := l_nr_wait_mt509 + 1;

                            l_bu_list (l_bu_list.COUNT + 1) := l_order_bu_id;

                            IF l_order_bu_id = 3
                            THEN
                                l_text_wait_mt509 :=
                                    l_text_wait_mt509 || c.id; --append only order id
                            ELSE
                                l_order_bu_name := getBuName (l_order_bu_id);
                                l_text_wait_mt509 :=
                                       l_text_wait_mt509
                                    || c.id
                                    || '('
                                    || l_order_bu_name
                                    || ')';           --append order_id and bu
                            END IF;
                        END IF;
                    END IF;
                END IF;

                IF l_nr > 0
                THEN
                    -- equities not sent
                    IF l_nr_equities = 0
                    THEN
                        IF s#bdl_doc_stex_pred.doc#is_traded_like_equity (
                               c.id) =
                           '+'
                        THEN
                            l_nr_equities := l_nr_equities + 1;
                        END IF;
                    END IF;

                    IF l_nr_bond = 0
                    THEN
                        -- send to Bond desk = bond + struct product
                        IF    (s#bdl_doc_stex_pred.doc#is_traded_like_bond (
                                   c.id) =
                               '+')
                           OR (s#bdl_doc_stex_pred.doc#get_stex_asset_type (
                                   i_doc   => c.id) =
                               s#bdl_doc_stex_const.c_stex_asset_like_struct_prod)
                        THEN
                            l_nr_bond := l_nr_bond + 1;
                        END IF;
                    END IF;

                    IF l_nr_fund = 0 OR l_nr_fund_bllu = 0
                    THEN
                        -- send to fund desk
                        IF s#bdl_doc_stex_pred.doc#is_traded_like_fund_ta (
                               c.id) =
                           '+'
                        THEN
                            IF l_order_bu_id = 3
                            THEN
                                l_nr_fund_bllu := l_nr_fund_bllu + 1;
                            ELSE
                                l_nr_fund := l_nr_fund + 1;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END LOOP;

            l_nr :=
                l_nr_error + l_nr_wait_ack + l_nr_wait_mt509 + l_nr_wait_fix;

            IF l_nr_error > 0
            THEN
                p_html_pool :=
                    '<br />' || l_text_error || '<br />' || p_html_pool;
                p_html_pool :=
                       '<br /><b>WARNING for STEX TEAM : '
                    || l_nr_error
                    || ' STEX order(s) with Transmission problems (in error) :</b>'
                    || p_html_pool;
            END IF;

            IF l_nr_wait_ack > 0
            THEN
                p_html_pool :=
                    '<br />' || l_text_wait_ack || '<br />' || p_html_pool;
                p_html_pool :=
                       '<br /><b>WARNING for STEX TEAM : '
                    || l_nr_wait_ack
                    || ' STEX order(s) with Transmission problems (Wait for ACK) :</b>'
                    || p_html_pool;
            END IF;

            IF l_nr_wait_mt509 > 0
            THEN
                p_html_pool :=
                    '<br />' || l_text_wait_mt509 || '<br />' || p_html_pool;
                p_html_pool :=
                       '<br /><b>WARNING for STEX TEAM : '
                    || l_nr_wait_mt509
                    || ' STEX order(s) with Transmission problems (Wait for MT509) :</b>'
                    || p_html_pool;
            END IF;

            IF l_nr_wait_fix > 0
            THEN
                p_html_pool :=
                    '<br />' || l_text_wait_fix || '<br />' || p_html_pool;
                p_html_pool :=
                       '<br /><b>WARNING for STEX TEAM : '
                    || l_nr_wait_fix
                    || ' STEX order(s) with Transmission problems (Wait for FIX) :</b>'
                    || p_html_pool;
            END IF;

            IF l_nr > 0
            THEN
                IF l_nr_bond = 0 AND l_nr_fund = 0 AND l_nr_fund_bllu = 0
                THEN
                    p_html_pool :=
                           '<br />Bond and Fund desk are not concerned.'
                        || p_html_pool;
                ELSE
                    IF l_nr_bond > 0
                    THEN
                        p_to := appendMails (p_to, l_bu_list, 'STEX_BOND');
                    END IF;

                    --Special case for BLLU - to make sure they do not receive warnings from other BUs
                    IF l_nr_fund_bllu > 0 AND l_nr_wait_mt509 > 0
                    THEN
                        p_to :=
                            appendMails (p_to,
                                         l_bu_list,
                                         'STEX_FUND_MARKET_BLLU');
                    ELSIF l_nr_fund_bllu > 0
                    THEN
                        p_to :=
                            appendMails (p_to, l_bu_list, 'STEX_FUND_BLLU');
                    END IF;

                    IF l_nr_fund > 0 AND l_nr_wait_mt509 > 0
                    THEN
                        p_to :=
                            appendMails (p_to, l_bu_list, 'STEX_FUND_MARKET');
                    ELSIF l_nr_fund > 0
                    THEN
                        p_to := appendMails (p_to, l_bu_list, 'STEX_FUND');
                    END IF;
                END IF;
            END IF;


            IF l_nr < 50
            THEN
                write_query ('STEX Transmission',
                             TO_CHAR (l_nr),
                             '0',
                             c_major_p,
                             '=',
                             'stex_transmission');
            ELSE
                write_query ('STEX Transmission',
                             TO_CHAR (l_nr),
                             '0',
                             c_blocking_p,
                             '=',
                             'stex_transmission');
            END IF;

            ---------------------------------
            --Summary:Check for equities and structured product orders that waited or are waiting for their ACK for more than 3 minutes
            --Parameters:none
            --Author:CHRBEC
            --Date:26/05/2014
            ---------------------------------
            DECLARE
                l_cnt            NUMBER := 0;
                l_error_string   VARCHAR2 (500);
            BEGIN
                DBMS_APPLICATION_INFO.SET_ACTION (
                    'CHECK_STRUCTURED_PRODUCT_WAIT');

                --structured products that waited more than 3 minutes for their ACK in the past 20 minutes or are still waiting
                FOR l_doc
                    IN (SELECT d.id,
                               d.timestamp,
                               t_2.timestamp - t_1.timestamp     delay
                          FROM doc d, trans t_1, trans t_2
                         WHERE     t_1.doc_id = d.id
                               AND t_2.doc_id = d.id
                               AND d.bp_imed_id = 3
                               AND t_2.seq_nr = t_1.seq_nr + 1
                               AND d.meta_typ_id = 1
                               AND t_1.new_wfc_status_id IN
                                       (2170, 3060, 3400) --wait for ack statuses
                               AND (SELECT s#bdl_doc_stex_pred.doc#get_stex_asset_type (
                                               i_doc   => d.id)
                                      FROM DUAL) =
                                   7                    -- structured products
                               AND d.timestamp > SYSDATE - 1 / 24 / 3 --during last 20 minutes
                               AND t_2.timestamp > SYSDATE - 1 / 24 / 3 --only recent waiting periods
                               AND t_2.timestamp - t_1.timestamp >
                                   NUMTODSINTERVAL (3, 'MINUTE') --waited more than 3 minutes
                        UNION
                        (SELECT d.id,
                                d.timestamp,
                                SYSDATE - t_1.timestamp     delay
                           FROM doc d, trans t_1
                          WHERE     t_1.doc_id = d.id
                                AND d.bp_imed_id = 3                      --BU
                                AND d.meta_typ_id = 1                   --stex
                                AND t_1.new_wfc_status_id IN
                                        (2170, 3060, 3400) --wait for ack statuses
                                AND (SELECT s#bdl_doc_stex_pred.doc#get_stex_asset_type (
                                                i_doc   => d.id)
                                       FROM DUAL) =
                                    7                   -- structured products
                                AND SYSDATE - t_1.timestamp >
                                    NUMTODSINTERVAL (3, 'MINUTE') --waiting for more than 3 mins
                                AND t_1.timestamp > SYSDATE - 1 / 24 / 3 --dont repeat the same orders more than once
                                AND NOT EXISTS
                                        (SELECT COUNT (*)
                                           FROM trans
                                          WHERE     doc_id = d.id
                                                AND seq_nr > t_1.seq_nr)) --is last status transition
                                                                         )
                LOOP
                    l_cnt := l_cnt + 1;

                    IF l_cnt > 5
                    THEN
                        l_error_string :=
                            l_error_string || '...more orders delayed!';
                        EXIT;
                    END IF;

                    l_error_string :=
                           l_error_string
                        || 'Order: '
                        || l_doc.id
                        || ' Delay: '
                        || l_doc.delay
                        || '<br/>';
                END LOOP;

                IF l_cnt > 0
                THEN
                    p_html_pool :=
                        '<br />' || l_error_string || '<br />' || p_html_pool;
                    p_html_pool :=
                           '<br /><b>WARNING for STEX TEAM : ACK delayed more than 3 minutes on structured product: </b>'
                        || p_html_pool;
                    p_to := upsert_mails (p_to, ';', l_mail_stex_struct);
                END IF;

                write_query ('STEX Delay Structured Products',
                             l_cnt,
                             '0',
                             c_none_p,
                             '=',
                             'stex_delay_struct');


                l_cnt := 0;
                l_error_string := '';


                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_EQUITIES_ACK');

                --equities that waited more than 3 minutes for their ACK in the past 20 minutes or are still waiting
                FOR l_doc
                    IN (SELECT d.id,
                               d.timestamp,
                               t_2.timestamp - t_1.timestamp     delay
                          FROM doc d, trans t_1, trans t_2
                         WHERE     t_1.doc_id = d.id
                               AND t_2.doc_id = d.id
                               AND d.bp_imed_id = 3
                               AND t_2.seq_nr = t_1.seq_nr + 1
                               AND d.meta_typ_id = 1
                               AND t_1.new_wfc_status_id IN
                                       (2170, 3060, 3400) --wait for ack statuses
                               AND s#bdl_doc_stex_pred.doc#is_traded_like_equity (
                                       d.id) =
                                   '+'                              --equities
                               AND d.timestamp > SYSDATE - 1 / 24 / 3 --during last 20 minutes
                               AND t_2.timestamp > SYSDATE - 1 / 24 / 3 --only recent waiting periods
                               AND t_2.timestamp - t_1.timestamp >
                                   NUMTODSINTERVAL (3, 'MINUTE') --waited more than 3 minutes
                        UNION
                        (SELECT d.id,
                                d.timestamp,
                                SYSDATE - t_1.timestamp     delay
                           FROM doc d, trans t_1
                          WHERE     t_1.doc_id = d.id
                                AND d.bp_imed_id = 3                      --BU
                                AND d.meta_typ_id = 1                   --stex
                                AND t_1.new_wfc_status_id IN
                                        (2170, 3060, 3400) --wait for ack statuses
                                AND s#bdl_doc_stex_pred.doc#is_traded_like_equity (
                                        d.id) =
                                    '+'                             --equities
                                AND SYSDATE - t_1.timestamp >
                                    NUMTODSINTERVAL (3, 'MINUTE') --waiting for more than 3 mins
                                AND t_1.timestamp > SYSDATE - 1 / 24 / 3 --dont repeat the same orders more than once
                                AND NOT EXISTS
                                        (SELECT COUNT (*)
                                           FROM trans
                                          WHERE     doc_id = d.id
                                                AND seq_nr > t_1.seq_nr)) --is last status transition
                                                                         ) --is last status transition)
                LOOP
                    l_cnt := l_cnt + 1;

                    IF l_cnt > 5
                    THEN
                        l_error_string :=
                               l_error_string
                            || '...more orders delayed!'
                            || '<br />';
                        EXIT;
                    END IF;

                    l_error_string :=
                           l_error_string
                        || 'Order: '
                        || l_doc.id
                        || ' Delay: '
                        || l_doc.delay
                        || '<br/>';
                END LOOP;

                IF l_cnt > 0
                THEN
                    p_html_pool := '<br />' || l_error_string || p_html_pool;
                    p_html_pool :=
                           '<br /><b>WARNING for STEX TEAM : ACK delayed more than 3 minutes on equities: </b>'
                        || p_html_pool;
                    p_to := upsert_mails (p_to, ';', l_mail_stex_equity);
                END IF;

                write_query ('STEX Delay Equities',
                             l_cnt,
                             '0',
                             c_none_p,
                             '=',
                             'stex_delay_equities');
            END;



            ------------------------------------------------------------------------------------------------------
            -- aging optimized  --
            ------------------------------------------------------------------------------------------------------
            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_STEX_WITHOUT_PRINT');
            -- Stex without print
            l_idx := l_idx + 1;

            WITH aging_list AS (
                SELECT
                    id
                FROM
                    k.aging
                WHERE
                        aging_entity_id = 9
                    AND aging_status_id = 20
                    AND ( (trunc(period_start, 'MM') >=  trunc(sysdate, 'MM')
                        OR (period_start IS NULL AND period_end IS NULL ) )
                        )
            )
            SELECT
            COUNT (d.doc_id) INTO l_text
            FROM k.doc_stex d join k.trans t on (d.doc_id = t.doc_id)
            WHERE wfc_action_id = 2007
            AND timestamp > (SYSDATE - 18 / 24)
            AND d.aging_id in (select id from aging_list)
            AND t.aging_id in (select id from aging_list)
            AND NOT EXISTS (SELECT 1 FROM prcq p WHERE p.prcq_id = 895 AND p.id = d.doc_id);

            write_query ('Stex without print',
                         l_text,
                         '0',
                         c_blocking_p,
                         '=',
                         'stex_without_print');


            -----FRS TAFREP CHECK-----

            /*if cond_frs_tafrep or c_force_active then
                check_frs_tafrep;
                check_frs_tafrep_reverse;
            end if;*/

            --RELEST
            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_RELEST');
            write_subheader ('Relev頥stimatif');
            -- Right balance on mini-relop
            l_idx := l_idx + 1;

            SELECT COUNT (*)
              INTO l_text
              FROM k.NC$LOG_RELOP_BAL
             WHERE     timestamp >= TRUNC (SYSDATE - 1)
                   AND (sob_ava <> sob_relop OR eob_ava <> eob_relop)
                   AND sop >= TO_DATE ('20091101', 'yyyymmdd')
                   AND exec_mode = 'MINI RELOP';

            write_query ('Right balance on mini-relop',
                         l_text,
                         '0',
                         c_major_p,
                         '=',
                         'balance_mini_relop');


            --RELOP
            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_RELOP');
            write_subheader ('Mailings (' || l_timecheck || ')');
            -- Errors on Mailing
            l_idx := l_idx + 1;

            SELECT COUNT (*)
              INTO l_text
              FROM k.mail_idx
             WHERE timestamp_create >= l_timestamp AND mail_status_id = 101;

            write_query ('Errors on Mailing (' || l_timecheck || ')',
                         l_text,
                         '0',
                         c_blocking_p,
                         '=',
                         'mailing_error');
            --CHECK WAIT 4 STREAMING
            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_WAIT4STREAMING');
            write_subheader ('Wait For Streaming (past 15 days)');
            -- Errors Wait 4 Streaming
            l_idx := l_idx + 1;

            SELECT COUNT (*)
              INTO l_count
              FROM mail_idx
             WHERE     mail_status_id = 3
                   AND timestamp_create < SYSDATE - 1
                   AND timestamp_create > SYSDATE - 15
                   AND eop < TRUNC (SYSDATE);

            IF l_count > 0
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_reporting_team);
                p_html_pool :=
                       '<br/><b>WARNING for Reporting TEAM : '
                    || l_count
                    || ' mailings in wait_for_streaming for more than 24 hours</b><br/>'
                    || p_html_pool;

                IF is_prod
                THEN
                    p_to := upsert_mails (p_to, ';', l_mail_operateurs);
                END IF;
            END IF;

            write_query ('Wait For Streaming > 24h',
                         l_count,
                         '0',
                         c_blocking_p,
                         '=',
                         'wait4streaming');

            l_to := '';
            l_text2 := '';

            --p_html_pool:= '</h4>' || p_html_pool;

            FOR s
                IN (SELECT *
                      FROM (  SELECT id,
                                     timestamp_create,
                                     (SELECT name
                                        FROM k.code_mail
                                       WHERE id = mail_id)
                                         mailing_product,
                                     (SELECT name
                                        FROM k.code_stream_file_type
                                       WHERE id = stream_file_type_id)
                                         mail_pool,
                                     bp_id,
                                     cont_id,
                                     addr_id,
                                     err_msg,
                                     bu_id
                                FROM k.mail_idx
                               WHERE     timestamp_create > l_timestamp
                                     AND mail_status_id IN (111,
                                                            107,
                                                            101,
                                                            104)
                            ORDER BY mailing_product, timestamp_create DESC)
                     WHERE ROWNUM < 11)
            LOOP
                IF (INSTR (s.mailing_product, 'IIS_') > 0)
                THEN
                    l_text2 := ', PBS: ';

                    IF (l_to IS NULL)
                    THEN
                        l_to := l_mail_pbs_projects || ';';
                    END IF;
                ELSE
                    l_text2 := ', PRODUCT: ';
                END IF;

                p_html_pool :=
                       'BU: '
                    || s.bu_id
                    || ' ID: '
                    || s.id
                    || ', TIME: '
                    || TO_CHAR (s.timestamp_create, 'DD/MON/YYYY HH24:MM:SS')
                    || l_text2
                    || s.mailing_product
                    || ', POOL: '
                    || s.mail_pool
                    || ', BP_ID: '
                    || s.bp_id
                    || ', CONT_ID: '
                    || s.cont_id
                    || ', ADDR_ID: '
                    || s.addr_id
                    || ', ERROR: '
                    || s.err_msg
                    || '<br/>'
                    || p_html_pool;
                l_cnt_loop := l_cnt_loop + 1;
            END LOOP;

            IF l_cnt_loop > 0
            THEN
                p_to :=
                       p_to
                    || ';'
                    || l_mail_prcq_mail
                    || ';'
                    || l_mail_multiline;
                p_html_pool :=
                       '<br/><b>WARNING for REPORTING TEAM : '
                    || l_text
                    || ' Mailing(s) in error (only 10 first rows shown) :</b><br/>'
                    || p_html_pool;

                IF is_prod
                THEN
                    p_to := upsert_mails (p_to, ';', l_mail_operateurs);
                END IF;

                l_cnt_loop := 0;
            END IF;


            --------------------------------
            --Check for log entries considering failed PFST Light report generations - no entry in check list, just warning message
            --Checks the last 15mins  - first execution of the day also checks the last night / or the past weekend if it is monday morning
            --------------------------------

            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_LOG_PFST_LIGHT');

            DECLARE
                l_idx                 NUMBER;
                l_idx2                NUMBER;
                l_cont_marker         VARCHAR2 (50) := 'Container Symbolic Key : ';
                l_mail_marker         VARCHAR2 (50) := 'E-Mail : ';
                l_cont_string         VARCHAR2 (100);
                l_mail_string         VARCHAR2 (100);
                l_error_message       VARCHAR2 (200);
                l_error_message_add   VARCHAR2 (200)
                    := 'PFST Light only possible for containers with Cash only! Please select classic PFST for this container.';
                l_period_start        DATE;
            BEGIN
                l_nr := 0;

                IF SYSDATE BETWEEN TO_DATE (
                                          TO_CHAR (TRUNC (SYSDATE),
                                                   'ddmmyyyy')
                                       || ' 07:30',
                                       'ddmmyyyy HH24:MI')
                               AND TO_DATE (
                                          TO_CHAR (TRUNC (SYSDATE),
                                                   'ddmmyyyy')
                                       || ' 07:45',
                                       'ddmmyyyy HH24:MI')
                THEN
                    SELECT TRIM (TO_CHAR (today, 'DAY'))
                      INTO l_t
                      FROM k.base
                     WHERE ROWNUM = 1;

                    IF ((l_t = 'LUNDI') OR (l_t = 'MONDAY'))
                    THEN
                        --get back up to 18:39 from 2 days back
                        l_period_start := SYSDATE - 5 / 2;
                    ELSE
                        --get back up to 18:39 from last night
                        l_period_start := SYSDATE - 1 / 2;
                    END IF;
                ELSE
                    l_period_start := SYSDATE - (1 / 24 / 4);
                END IF;

                FOR ent
                    IN (SELECT *
                          FROM LOG
                         WHERE     timestamp > l_period_start
                               AND log_type_id = 7
                               AND ctx LIKE '%PFST # err id: 1%'
                               AND ctx LIKE
                                       '%# msg: Mass generation of PFST Light%'
                               AND ctx LIKE
                                       '%PFST Light only possible for containers with Cash only !%'
                               AND sec_user_id = 92)
                LOOP
                    l_nr := l_nr + 1;

                    --parse Container key
                    l_idx := INSTR (ent.ctx, l_cont_marker);
                    l_idx := l_idx + LENGTH (l_cont_marker);
                    l_idx2 := INSTR (ent.ctx, CHR (10), l_idx);
                    l_cont_string := SUBSTR (ent.ctx, l_idx, l_idx2 - l_idx);

                    --parse Mail
                    l_idx := INSTR (ent.ctx, l_mail_marker);
                    l_idx := l_idx + LENGTH (l_mail_marker);
                    l_idx2 := INSTR (ent.ctx, CHR (10), l_idx);
                    l_mail_string := SUBSTR (ent.ctx, l_idx, l_idx2 - l_idx);

                    --Build error message
                    l_error_message :=
                           l_mail_string
                        || ': Container '
                        || l_cont_string
                        || ' BU: '
                        || ent.bu_id;

                    IF INSTR (p_to, l_mail_string) = 0
                    THEN
                        p_to := upsert_mails (p_to, ';', l_mail_string); -- replaced in dev version
                    END IF;

                    IF l_nr = 1
                    THEN
                        p_html_pool :=
                               '<br/>'
                            || l_error_message
                            || '<br/>'
                            || p_html_pool;
                    ELSE
                        p_html_pool :=
                            '<br/>' || l_error_message || '' || p_html_pool;
                    END IF;
                END LOOP;

                IF l_error_message IS NOT NULL
                THEN
                    p_html_pool :=
                           '<b><br/>WARNING : '
                        || l_error_message_add
                        || '</b>'
                        || p_html_pool;
                END IF;
            END;



            --PAYMENT
            write_subheader ('Payment');

            DECLARE
                c_check_title   VARCHAR2 (100) := 'incomplete_bundle_msg';
                c_max           NUMBER := 0;
                l_nr            NUMBER;
                l_file_name     VARCHAR2 (250);
            BEGIN
                --Bundle messages incomplete .
                --Added work around for re-injections with the same name -> do not care if msg_bdl_id difference is big.
                SELECT COUNT (*)
                  INTO l_nr
                  FROM (SELECT s.id,
                               (SELECT pl.val
                                  FROM TABLE (s.prty_list) pl
                                 WHERE pl.name = 'ami.cetr_isabel.file_name')    name
                          FROM k.msg_bdl s) b,
                       k.dupl_ctrl  d
                 WHERE     name IS NOT NULL
                       AND d.signt = name
                       AND d.timestamp > TRUNC (SYSDATE)
                       AND NOT EXISTS
                               (SELECT *
                                  FROM msg m
                                 WHERE m.msg_bdl_id = b.id)
                       AND (d.trig_item_id - id) < 200000000;

                write_query ('Incomplete bundle messages',
                             l_nr,
                             c_max,
                             c_blocking_p,
                             '=',
                             c_check_title);

                IF l_nr > c_max
                THEN
                    SELECT name
                      INTO l_file_name
                      FROM (SELECT s.id,
                                   (SELECT pl.val
                                      FROM TABLE (s.prty_list) pl
                                     WHERE pl.name =
                                           'ami.cetr_isabel.file_name')    name
                              FROM k.msg_bdl s) b,
                           k.dupl_ctrl  d
                     WHERE     name IS NOT NULL
                           AND d.signt = name
                           AND d.timestamp > TRUNC (SYSDATE)
                           AND NOT EXISTS
                                   (SELECT *
                                      FROM msg m
                                     WHERE m.msg_bdl_id = b.id)
                           AND (d.trig_item_id - id) < 200000000
                           AND ROWNUM = 1;

                    p_html_pool :=
                           '<br/><b>WARNING for PAY Team : Incomplete bundle messages for file: '
                        || l_file_name
                        || '</b>'
                        || p_html_pool;
                    p_to := p_to || ';' || l_mail_msg_bdl;
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    handle_check_exception (
                        c_check_title,
                        SQLERRM,
                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            END;

            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_MSG_BDL');

            --bundle msg parse fail
            DECLARE
                l_bllu_mail_added   BOOLEAN := FALSE;
                l_btlu_mail_added   BOOLEAN := FALSE;
                c_check_title       VARCHAR2 (100) := 'msg_bdl_pain';
            BEGIN
                l_nr := 0;
                l_text := '';


                SELECT COUNT (*)
                  INTO l_nr
                  FROM k.msg
                 WHERE     timestamp > l_timestamp
                       AND msg_bdl_id IN
                               (SELECT id
                                  FROM k.msg_bdl
                                 WHERE     id IN
                                               (SELECT msg_bdl_id
                                                  FROM k.msg
                                                 WHERE timestamp >
                                                       l_timestamp)
                                       AND meta_msg_bdl_id IN (49))
                       AND msg_status_id IN (8);


                IF l_nr > 0
                THEN
                    FOR l_file
                        IN (SELECT bu_id,
                                   doc_id,
                                   msg_bdl_id,
                                   CASE
                                       WHEN INSTR (file_name, '/') > 0
                                       THEN
                                           SUBSTR (
                                               file_name,
                                               (  INSTR (file_name,
                                                         '/',
                                                         -1,
                                                         1)
                                                + 1),
                                               LENGTH (file_name)) -- UNIX system
                                       WHEN INSTR (file_name, '\') > 0
                                       THEN
                                           SUBSTR (
                                               file_name,
                                               (  INSTR (file_name,
                                                         '\',
                                                         -1,
                                                         1)
                                                + 1),
                                               LENGTH (file_name)) --'Windows system
                                       ELSE
                                           file_name
                                   END    name
                              FROM file_upl
                             WHERE msg_bdl_id IN
                                       (SELECT msg_bdl_id
                                          FROM k.msg
                                         WHERE     timestamp > l_timestamp
                                               AND msg_bdl_id IN
                                                       (SELECT id
                                                          FROM k.msg_bdl
                                                         WHERE     id IN
                                                                       (SELECT msg_bdl_id
                                                                          FROM k.msg
                                                                         WHERE timestamp >
                                                                               l_timestamp)
                                                               AND meta_msg_bdl_id IN
                                                                       (49))
                                               AND msg_status_id IN (8)))
                    LOOP
                        l_nr := l_nr + 1;

                        IF l_nr = 1
                        THEN                  --no seperator for first element
                            l_text :=
                                   ''
                                || getBuName (l_file.bu_id)
                                || ', doc_id: '
                                || NVL (l_file.doc_id, '-')
                                || ', msg_bdl_id: '
                                || NVL (l_file.msg_bdl_id, '-')
                                || ', '
                                || l_file.name;
                        ELSIF l_nr <= 20
                        THEN                       --not more than 20 messages
                            IF MOD (l_nr, 10) = 0
                            THEN                  --linebreak every 10 entries
                                l_text :=
                                       l_text
                                    || ', '
                                    || getBuName (l_file.bu_id)
                                    || ', doc_id: '
                                    || NVL (l_file.doc_id, '-')
                                    || ', msg_bdl_id: '
                                    || NVL (l_file.msg_bdl_id, '-')
                                    || ', '
                                    || l_file.name
                                    || CHR (10);
                            ELSE
                                l_text :=
                                       l_text
                                    || ', '
                                    || getBuName (l_file.bu_id)
                                    || ', doc_id: '
                                    || NVL (l_file.doc_id, '-')
                                    || ', msg_bdl_id: '
                                    || NVL (l_file.msg_bdl_id, '-')
                                    || ', '
                                    || l_file.name;
                            END IF;
                        ELSIF l_nr = 21
                        THEN                   --if more than 20 -> add 3 dots
                            l_text := l_text || '...more';
                        END IF;

                        --add the destination mail once
                        IF (l_file.bu_id = 11 AND NOT l_btlu_mail_added)
                        THEN
                            p_to := p_to || ';' || l_mail_btlu_dflt;
                            l_btlu_mail_added := TRUE;
                        ELSIF (NOT l_bllu_mail_added)
                        THEN
                            p_to := p_to || ';' || l_mail_msg_bdl;
                            l_bllu_mail_added := TRUE;
                        END IF;
                    END LOOP;

                    p_html_pool :=
                           '<br/><b>WARNING for PAY Team : '
                        || l_nr
                        || ' Errors on MX.PAIN message:</b> '
                        || l_text
                        || '<br />'
                        || p_html_pool;
                END IF;

                write_query ('Error on MX.PAIN message (15 minutes)',
                             l_nr,
                             '0',
                             c_blocking_p,
                             '=',
                             'msg_bdl_pain');
            EXCEPTION
                WHEN OTHERS
                THEN
                    handle_check_exception (
                        c_check_title,
                        SQLERRM,
                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            END;

            DECLARE
                ---------------------------------
                --Summary:Activation condition for generic asset on standing orders check
                --Parameters:none
                --Author:CHRBEC
                --Date:31/08/2015
                ---------------------------------
                FUNCTION cond_gen_asset_stord
                    RETURN BOOLEAN
                IS
                    l_result   BOOLEAN := FALSE;
                BEGIN
                    IF l_execution_time <=
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:40',
                           'ddmmyyyy HH24:MI')
                    THEN
                        l_result := TRUE;
                    END IF;

                    RETURN l_result;
                END cond_gen_asset_stord;


                ---------------------------------
                --Summary:Check if standing orders have been booked with a generic asset
                --Parameters:none
                --Author:CHRBEC
                --Date:31/08/2015
                ---------------------------------
                PROCEDURE check_gen_asset_stord
                IS
                    l_nr            NUMBER;
                    c_check_title   VARCHAR2 (150) := 'Generic Asset Stord';
                    c_check_name    VARCHAR2 (150) := 'gen_asset_stord';
                    c_max           NUMBER := 0;
                    l_past_day      DATE;
                    l_count         NUMBER := 0;
                    l_text          CLOB;
                BEGIN
                    SELECT COUNT (*)
                      INTO l_nr
                      FROM k.pos_serpil
                     WHERE     asset_id =
                               (SELECT obj_id
                                  FROM k.obj_rel_key
                                 WHERE     UPPER (key_val) = 'STORD_FRN'
                                       AND obj_key_id = 18) -- Asset generic for Standing Order
                           AND serpil_id =
                               (SELECT MAX (id)
                                  FROM k.serpil
                                 WHERE     tab = 'POS_SERPIL'
                                       AND period_end =
                                           TO_DATE (SYSDATE, 'DD/MM/YYYY')
                                       AND period_end = period_start
                                       AND del IS NULL
                                       AND done = '+'
                                       AND date_type_id = 4)
                           AND pko_id = 1
                           AND to_atrx_seq_nr = 1E35;

                    IF l_nr > c_max
                    THEN
                        FOR l_pos
                            IN (SELECT bp_id,
                                       cont_id,
                                       pos_id,
                                       asset_id,
                                       bu_id
                                  FROM k.pos_serpil
                                 WHERE     asset_id =
                                           (SELECT obj_id
                                              FROM k.obj_rel_key
                                             WHERE     UPPER (key_val) =
                                                       'STORD_FRN'
                                                   AND obj_key_id = 18) -- Asset generic for Standing Order
                                       AND serpil_id =
                                           (SELECT MAX (id)
                                              FROM k.serpil
                                             WHERE     tab = 'POS_SERPIL'
                                                   AND period_end =
                                                       TO_DATE (SYSDATE,
                                                                'DD/MM/YYYY')
                                                   AND period_end =
                                                       period_start
                                                   AND del IS NULL
                                                   AND done = '+'
                                                   AND date_type_id = 4)
                                       AND pko_id = 1
                                       AND to_atrx_seq_nr = 1E35)
                        LOOP
                            --limit entries to 20 by counter
                            IF l_count > 20
                            THEN
                                l_text := l_text || '...more';
                                EXIT;
                            END IF;

                            --add no comma for first entry
                            IF l_text IS NOT NULL
                            THEN
                                l_text := l_text || ', ';
                            END IF;


                            --add doc_id and bu_id
                            l_text :=
                                   l_text
                                || l_pos.pos_id
                                || ' (BU:'
                                || l_pos.bu_id
                                || ')';


                            --increment failsafe counter
                            l_count := l_count + 1;
                        END LOOP;


                        p_html_pool :=
                               '<br/><b>WARNING for PAYMENT TEAM : '
                            || l_nr
                            || ' Standing order(s) booked with generic asset:</b><br/>'
                            || l_text
                            || '<br/>'
                            || p_html_pool;

                        p_to :=
                            upsert_mails (p_to, ';', l_mail_settle_on_hold); --Paymon.follow
                    END IF;

                    write_query (c_check_title,
                                 TO_CHAR (l_nr),
                                 '0',
                                 c_blocking_p,
                                 '=',
                                 'gen_asset_stord');
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        handle_check_exception (
                            c_check_title,
                            SQLERRM,
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                END check_gen_asset_stord;
            BEGIN
                IF cond_gen_asset_stord
                THEN
                    check_gen_asset_stord;
                END IF;
            END;



            ------------
            --TREASURY--
            ------------
            DECLARE
                ---------------------------------
                --Summary:Common activation condition for all Treasury settlement NPV checks
                --Parameters:none
                --Author:CHRBEC
                --Date:04/03/2014
                ---------------------------------
                FUNCTION cond_treasury_checks
                    RETURN BOOLEAN
                IS
                    l_result     BOOLEAN := FALSE;
                    l_past_day   DATE;
                BEGIN
                    l_past_day := get_previous_day;

                    IF     l_execution_time <=
                           TO_DATE (
                                  TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy')
                               || ' 07:40',
                               'ddmmyyyy HH24:MI')
                       AND NOT is_day_off (2103, l_past_day)
                       AND TO_CHAR (TRUNC (l_past_day), 'MM-DD') != '11-11'
                       AND TO_CHAR (TRUNC (l_past_day), 'MM-DD') != '05-08'
                       AND TO_CHAR (TRUNC (l_past_day), 'MM-DD') != '07-14'
                       AND TO_CHAR (TRUNC (l_past_day), 'MM-DD') != '05-01'
                       AND TO_CHAR (TRUNC (l_past_day), 'MM-DD') != '01-01'
                       AND TO_CHAR (TRUNC (l_past_day), 'MM-DD') != '12-25'
                       AND TO_CHAR (TRUNC (l_past_day), 'MM-DD') != '08-15'
                    THEN
                        l_result := TRUE;
                    END IF;

                    RETURN l_result;
                END cond_treasury_checks;


                ---------------------------------
                --Summary:Check for IRS Price / VAL_CAP_IRS
                --Parameters:none
                --Author:CHRBEC
                --Date:04/03/2014
                ---------------------------------
                PROCEDURE check_irs_price
                IS
                    l_nr            NUMBER;
                    c_check_title   VARCHAR2 (150) := 'npv_irs_price';
                    c_min           NUMBER := 2;
                    l_past_day      DATE;
                BEGIN
                    l_past_day := get_previous_day;

                    /* no control on 11 nov and 5 may */
                    IF     TO_CHAR (TRUNC (l_past_day), 'MM-DD') != '11-11'
                       AND TO_CHAR (TRUNC (l_past_day), 'MM-DD') != '05-08'
                       AND TO_CHAR (TRUNC (l_past_day), 'MM-DD') != '07-14'
                    THEN
                        SELECT COUNT (*)
                          INTO l_nr
                          FROM k.MSG_EXTL_IN a, k.MSG m
                         WHERE     m.meta_msg_id = 516
                               AND a.id = m.id
                               AND m.bu_id = 3
                               AND m.timestamp BETWEEN l_past_day
                                                   AND l_past_day + 26 / 24
                               AND a.text LIKE '%<key>VAL_IMP_IRS:%'
                               AND a.text LIKE
                                       '%<Price_Domain>price</Price_Domain>%'
                               AND a.text LIKE
                                       '%<Price_Type>npv_hdg</Price_Type>%'
                               AND a.text LIKE
                                          '%<Date>'
                                       || TO_CHAR (TO_DATE (l_past_day),
                                                   'dd/mm/yyyy')
                                       || '</Date>%';

                        write_query ('NPV - IRS/CIRS',
                                     l_nr,
                                     c_min,
                                     c_blocking_p,
                                     '>=',
                                     c_check_title);

                        IF l_nr < c_min
                        THEN
                            p_to :=
                                upsert_mails (p_to, ';', l_mail_market_it);
                            p_to := upsert_mails (p_to, ';', l_mail_finacc);
                            p_html_pool :=
                                   '<br/><b>WARNING for MARKET TEAM : No NPV - IRS/CIRS Price messages received or Wrong Date </b><br/>'
                                || p_html_pool;
                        END IF;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        handle_check_exception (
                            c_check_title,
                            SQLERRM,
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                END check_irs_price;

                ---------------------------------
                --Summary:Check for IRS - Dirty fair value messages
                --Parameters:none
                --Author:CHRBEC
                --Date:04/03/2014
                ---------------------------------
                PROCEDURE check_irs_dirty_fair
                IS
                    l_nr            NUMBER;
                    c_check_title   VARCHAR2 (150) := 'npv_irs_dirty_fair';
                    c_min           NUMBER := 2;
                    l_past_day      DATE;
                BEGIN
                    l_past_day := get_previous_day;

                    SELECT COUNT (*)
                      INTO l_nr
                      FROM k.MSG_EXTL_IN a, k.MSG m
                     WHERE     m.meta_msg_id = 516
                           AND a.id = m.id
                           AND m.bu_id = 3
                           AND TRUNC (m.timestamp) BETWEEN l_past_day
                                                       AND   l_past_day
                                                           + 25 / 24
                           AND a.text LIKE '%<key>%IRS:%'
                           AND a.text LIKE
                                   '%<Price_Domain>fv_dirty</Price_Domain>%'
                           AND a.text LIKE
                                      '%<Date>'
                                   || TO_CHAR (TO_DATE (l_past_day),
                                               'dd/mm/yyyy')
                                   || '</Date>%';

                    write_query ('NPV - IRS/CIRS Dirty Fair Value',
                                 l_nr,
                                 c_min,
                                 c_blocking_p,
                                 '>=',
                                 c_check_title);

                    IF l_nr < c_min
                    THEN
                        p_to := upsert_mails (p_to, ';', l_mail_market_it);
                        p_to := upsert_mails (p_to, ';', l_mail_finacc);
                        p_html_pool :=
                               '<br/><b>WARNING for MARKET TEAM : No NPV - IRS/CIRS Dirty Fair Value messages received or Wrong Date </b><br/>'
                            || p_html_pool;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        handle_check_exception (
                            c_check_title,
                            SQLERRM,
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                END check_irs_dirty_fair;


                ---------------------------------
                --Summary:Check for IRS - Fair value messages
                --Parameters:none
                --Author:CHRBEC
                --Date:04/03/2014
                ---------------------------------
                PROCEDURE check_irs_fair
                IS
                    l_nr            NUMBER;
                    c_check_title   VARCHAR2 (150) := 'npv_irs_fair';
                    c_min           NUMBER := 2;
                    l_past_day      DATE;
                BEGIN
                    l_past_day := get_previous_day;

                    SELECT COUNT (*)
                      INTO l_nr
                      FROM k.MSG_EXTL_IN a, k.MSG m
                     WHERE     m.meta_msg_id = 516
                           AND a.id = m.id
                           AND m.bu_id = 3
                           AND TRUNC (m.timestamp) BETWEEN l_past_day
                                                       AND   l_past_day
                                                           + 25 / 24
                           AND a.text LIKE '%<key>%IRS:%'
                           AND a.text LIKE
                                   '%<Price_Domain>fv</Price_Domain>%'
                           AND a.text LIKE
                                      '%<Date>'
                                   || TO_CHAR (TO_DATE (l_past_day),
                                               'dd/mm/yyyy')
                                   || '</Date>%';

                    write_query ('NPV - IRS/CIRS Fair Value',
                                 l_nr,
                                 c_min,
                                 c_blocking_p,
                                 '>=',
                                 c_check_title);

                    IF l_nr < c_min
                    THEN
                        p_to := upsert_mails (p_to, ';', l_mail_market_it);
                        p_to := upsert_mails (p_to, ';', l_mail_finacc);
                        p_html_pool :=
                               '<br/><b>WARNING for MARKET TEAM : No NPV - IRS/CIRS Fair Value messages received or Wrong Trade Date </b><br/>'
                            || p_html_pool;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        handle_check_exception (
                            c_check_title,
                            SQLERRM,
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                END check_irs_fair;


                ---------------------------------
                --Summary:Check for IRS + CIRS messages
                --Parameters:none
                --Author:CHRBEC
                --Date:04/03/2014
                ---------------------------------
                PROCEDURE check_irs_fv_eval
                IS
                    l_nr            NUMBER;
                    c_check_title   VARCHAR2 (150) := 'irs_fv_eval';
                    c_min           NUMBER := 2;
                    l_past_day      DATE;
                BEGIN
                    l_past_day := get_previous_day;

                    SELECT COUNT (*)
                      INTO l_nr
                      FROM k.MSG_EXTL_IN a, k.MSG m
                     WHERE     m.meta_msg_id = 516
                           AND a.id = m.id
                           AND m.bu_id = 3
                           AND TRUNC (m.timestamp) BETWEEN l_past_day
                                                       AND   l_past_day
                                                           + 25 / 24
                           AND a.text LIKE '%<key>VAL_IMP_IRS:%'
                           AND a.text LIKE
                                   '%<Price_Domain>price</Price_Domain>%'
                           AND a.text LIKE '%<Price_Type>eval</Price_Type>%'
                           AND a.text LIKE
                                      '%<Date>'
                                   || TO_CHAR (TO_DATE (l_past_day),
                                               'dd/mm/yyyy')
                                   || '</Date>%';


                    write_query ('NPV - IRS/CIRS Fair Value Eval',
                                 l_nr,
                                 c_min,
                                 c_blocking_p,
                                 '>=',
                                 c_check_title);

                    IF l_nr < c_min
                    THEN
                        p_to := upsert_mails (p_to, ';', l_mail_market_it);
                        p_to := upsert_mails (p_to, ';', l_mail_treasury);
                        p_html_pool :=
                               '<br/><b>WARNING for MARKET TEAM : No NPV - IRS/CIRS Fair Value Eval messages received or Wrong Date </b><br/>'
                            || p_html_pool;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        handle_check_exception (
                            c_check_title,
                            SQLERRM,
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                END check_irs_fv_eval;


                ---------------------------------
                --Summary:Check for NPV - Bonds messages
                --Parameters:none
                --Author:CHRBEC
                --Date:04/03/2014
                ---------------------------------
                PROCEDURE check_npv_bonds
                IS
                    l_nr            NUMBER;
                    c_check_title   VARCHAR2 (150) := 'npv_bonds';
                    c_min           NUMBER := 1;
                    l_past_day      DATE;
                BEGIN
                    l_past_day := get_previous_day;

                    SELECT COUNT (*)
                      INTO l_nr
                      FROM k.MSG_EXTL_IN a, k.MSG m
                     WHERE     m.meta_msg_id = 516
                           AND a.id = m.id
                           AND m.bu_id = 3
                           AND TRUNC (m.timestamp) BETWEEN l_past_day
                                                       AND   l_past_day
                                                           + 25 / 24
                           AND a.text LIKE '%<ProductName>NPV</ProductName>%'
                           AND a.text LIKE '%<Meta_Typ>asset</Meta_Typ>%'
                           AND a.text LIKE
                                      '%<Date>'
                                   || TO_CHAR (TO_DATE (l_past_day),
                                               'dd/mm/yyyy')
                                   || '</Date>%';

                    write_query ('NPV - Bonds',
                                 l_nr,
                                 c_min,
                                 c_blocking_p,
                                 '>=',
                                 c_check_title);

                    IF l_nr < c_min
                    THEN
                        p_to := upsert_mails (p_to, ';', l_mail_market_it);
                        p_to := upsert_mails (p_to, ';', l_mail_finacc);
                        p_html_pool :=
                               '<br/><b>WARNING for MARKET TEAM : No NPV - Bonds messages received or Wrong date </b><br/>'
                            || p_html_pool;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        handle_check_exception (
                            c_check_title,
                            SQLERRM,
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                END check_npv_bonds;

                ---------------------------------
                --Summary:Check for NPV - Swaption messages
                --Parameters:none
                --Author:CHRBEC
                --Date:04/03/2014
                ---------------------------------
                PROCEDURE check_npv_swaption
                IS
                    l_nr            NUMBER;
                    c_check_title   VARCHAR2 (150) := 'npv_swaption';
                    c_min           NUMBER := 1;
                    l_past_day      DATE;
                BEGIN
                    l_past_day := get_previous_day;

                    SELECT COUNT (*)
                      INTO l_nr
                      FROM k.MSG_EXTL_IN a, k.MSG m
                     WHERE     m.meta_msg_id = 516
                           AND a.id = m.id
                           AND m.bu_id = 3
                           AND TRUNC (m.timestamp) BETWEEN l_past_day
                                                       AND   l_past_day
                                                           + 25 / 24
                           AND a.text LIKE '%<key>%SWO:%'
                           AND a.text LIKE
                                      '%<Date>'
                                   || TO_CHAR (TO_DATE (l_past_day),
                                               'dd/mm/yyyy')
                                   || '</Date>%';

                    write_query ('NPV - Swaption',
                                 l_nr,
                                 c_min,
                                 c_blocking_p,
                                 '>=',
                                 c_check_title);

                    IF l_nr < c_min
                    THEN
                        p_to := upsert_mails (p_to, ';', l_mail_market_it);
                        p_to := upsert_mails (p_to, ';', l_mail_finacc);
                        p_html_pool :=
                               '<br/><b>WARNING for MARKET TEAM : No NPV - Swaption messages received or Wrong Date </b><br/>'
                            || p_html_pool;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        handle_check_exception (
                            c_check_title,
                            SQLERRM,
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                END check_npv_swaption;

                ---------------------------------
                --Summary:Check for NPV - Swaption messages
                --Parameters:none
                --Author:CHRBEC
                --Date:04/03/2014
                ---------------------------------
                PROCEDURE check_npv_fxoption
                IS
                    l_nr            NUMBER;
                    c_check_title   VARCHAR2 (150) := 'npv_fxoption';
                    c_min           NUMBER := 1;
                    l_past_day      DATE;
                BEGIN
                    l_past_day := get_previous_day;

                    SELECT COUNT (*)
                      INTO l_nr
                      FROM k.MSG_EXTL_IN a, k.MSG m
                     WHERE     m.meta_msg_id = 516
                           AND a.id = m.id
                           AND m.bu_id = 3
                           AND TRUNC (m.timestamp) BETWEEN l_past_day
                                                       AND   l_past_day
                                                           + 25 / 24
                           AND a.text LIKE '%<key>%FXO:%'
                           AND a.text LIKE
                                      '%<Date>'
                                   || TO_CHAR (TO_DATE (l_past_day),
                                               'dd/mm/yyyy')
                                   || '</Date>%';

                    write_query ('NPV - FXOption',
                                 l_nr,
                                 c_min,
                                 c_blocking_p,
                                 '>=',
                                 c_check_title);

                    IF l_nr < c_min
                    THEN
                        p_to := upsert_mails (p_to, ';', l_mail_market_it);
                        p_to := upsert_mails (p_to, ';', l_mail_finacc);
                        p_html_pool :=
                               '<br/><b>WARNING for MARKET TEAM : No NPV - FXOption messages received or Wrong Date </b><br/>'
                            || p_html_pool;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        handle_check_exception (
                            c_check_title,
                            SQLERRM,
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                END check_npv_fxoption;

                ---------------------------------
                --Summary:Check for NPV - CF Fair Value messages
                --Parameters:none
                --Author:CHRBEC
                --Date:04/03/2014
                ---------------------------------
                PROCEDURE check_npv_cf_fair
                IS
                    l_nr            NUMBER;
                    c_check_title   VARCHAR2 (150) := 'npv_cf_fair';
                    c_min           NUMBER := 1;
                    l_past_day      DATE;
                BEGIN
                    l_past_day := get_previous_day;

                    SELECT COUNT (*)
                      INTO l_nr
                      FROM k.MSG_EXTL_IN a, k.MSG m
                     WHERE     m.meta_msg_id = 516
                           AND a.id = m.id
                           AND m.bu_id = 3
                           AND TRUNC (m.timestamp) BETWEEN l_past_day
                                                       AND   l_past_day
                                                           + 25 / 24
                           AND a.text LIKE '%<key>%CNF:%'
                           AND a.text LIKE
                                   '%<Price_Domain>fv</Price_Domain>%'
                           AND a.text LIKE
                                      '%<Date>'
                                   || TO_CHAR (TO_DATE (l_past_day),
                                               'dd/mm/yyyy')
                                   || '</Date>%';

                    write_query ('NPV - CF Fair Value',
                                 l_nr,
                                 c_min,
                                 c_blocking_p,
                                 '>=',
                                 c_check_title);

                    IF l_nr < c_min
                    THEN
                        p_to := upsert_mails (p_to, ';', l_mail_market_it);
                        p_to := upsert_mails (p_to, ';', l_mail_finacc);
                        p_html_pool :=
                               '<br/><b>WARNING for MARKET TEAM : No NPV - CF Fair Value messages received or Wrong Date </b><br/>'
                            || p_html_pool;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        handle_check_exception (
                            c_check_title,
                            SQLERRM,
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                END check_npv_cf_fair;


                ---------------------------------
                --Summary:Check for NPV - CF Dirty Fair Value messages
                --Parameters:none
                --Author:CHRBEC
                --Date:04/03/2014
                ---------------------------------
                PROCEDURE check_npv_cf_dirty
                IS
                    l_nr            NUMBER;
                    c_check_title   VARCHAR2 (150) := 'npv_cf_dirty';
                    c_min           NUMBER := 1;
                    l_past_day      DATE;
                BEGIN
                    l_past_day := get_previous_day;

                    SELECT COUNT (*)
                      INTO l_nr
                      FROM k.MSG_EXTL_IN a, k.MSG m
                     WHERE     m.meta_msg_id = 516
                           AND a.id = m.id
                           AND m.bu_id = 3
                           AND TRUNC (m.timestamp) BETWEEN l_past_day
                                                       AND   l_past_day
                                                           + 25 / 24
                           AND a.text LIKE '%<key>%CNF:%'
                           AND a.text LIKE
                                   '%<Price_Domain>fv_dirty</Price_Domain>%'
                           AND a.text LIKE
                                      '%<Date>'
                                   || TO_CHAR (TO_DATE (l_past_day),
                                               'dd/mm/yyyy')
                                   || '</Date>%';

                    write_query ('NPV - CF Dirty Fair Value',
                                 l_nr,
                                 c_min,
                                 c_blocking_p,
                                 '>=',
                                 c_check_title);

                    IF l_nr < c_min
                    THEN
                        p_to := upsert_mails (p_to, ';', l_mail_market_it);
                        p_to := upsert_mails (p_to, ';', l_mail_finacc);
                        p_html_pool :=
                               '<br/><b>WARNING for MARKET TEAM : No NPV - CF Dirty Fair Value messages received or Wrong date </b><br/>'
                            || p_html_pool;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        handle_check_exception (
                            c_check_title,
                            SQLERRM,
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                END check_npv_cf_dirty;


                ---------------------------------
                --Summary:Check for NPV - CF Fair Value Eval messages
                --Parameters:none
                --Author:CHRBEC
                --Date:04/03/2014
                ---------------------------------
                PROCEDURE check_npv_cf_eval
                IS
                    l_nr            NUMBER;
                    c_check_title   VARCHAR2 (150) := 'npv_cf_eval';
                    c_min           NUMBER := 1;
                    l_past_day      DATE;
                BEGIN
                    l_past_day := get_previous_day;

                    SELECT COUNT (*)
                      INTO l_nr
                      FROM k.MSG_EXTL_IN a, k.MSG m
                     WHERE     m.meta_msg_id = 516
                           AND a.id = m.id
                           AND m.bu_id = 3
                           AND TRUNC (m.timestamp) BETWEEN l_past_day
                                                       AND   l_past_day
                                                           + 25 / 24
                           AND a.text LIKE '%<key>%CNF:%'
                           AND a.text LIKE
                                   '%<Price_Domain>price</Price_Domain>%'
                           AND a.text LIKE '%<Price_Type>eval</Price_Type>%'
                           AND a.text LIKE
                                      '%<Date>'
                                   || TO_CHAR (TO_DATE (l_past_day),
                                               'dd/mm/yyyy')
                                   || '</Date>%';

                    write_query ('NPV - CF Fair Value Eval',
                                 l_nr,
                                 c_min,
                                 c_blocking_p,
                                 '>=',
                                 c_check_title);

                    IF l_nr < c_min
                    THEN
                        p_to := upsert_mails (p_to, ';', l_mail_market_it);
                        p_to := upsert_mails (p_to, ';', l_mail_treasury);
                        p_html_pool :=
                               '<br/><b>WARNING for MARKET TEAM : No NPV - CF Fair Value Eval messages received or Wrong Date</b><br/>'
                            || p_html_pool;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        handle_check_exception (
                            c_check_title,
                            SQLERRM,
                            DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                END check_npv_cf_eval;
            ------------------------------------
            --Treasury settlement execution block
            ------------------------------------
            BEGIN
                IF cond_treasury_checks OR c_force_active
                THEN
                    DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_TREASURY');


                    write_subheader ('Treasury settlement');

                    check_irs_price;

                    check_irs_dirty_fair;

                    check_irs_fair;

                    check_irs_fv_eval;

                    check_npv_bonds;

                    check_npv_swaption;

                    check_npv_fxoption;
                --check_npv_cf_fair;

                --check_npv_cf_dirty;

                --check_npv_cf_eval;

                END IF;
            END;



            DBMS_APPLICATION_INFO.SET_ACTION (
                'CHECK_PAYMENT_WAIT_PROCESSING');

            --Payment wait for processing (25)
            BEGIN
                l_bu_list.delete;

                SELECT COUNT (id)
                  INTO l_nr
                  FROM k.doc
                 WHERE     meta_typ_id = 6
                       AND wfc_status_id = 25
                       AND (SELECT SYSDATE - MAX (timestamp)
                              FROM k.trans
                             WHERE doc_id = id AND new_wfc_status_id = 25) >
                           INTERVAL '3' HOUR
                       AND id NOT IN (SELECT item_doc_id
                                        FROM k.doc_cord_link
                                       WHERE doc_id IN (358595580,
                                                        358601092,
                                                        358630333,
                                                        358631497,
                                                        358640451,
                                                        358635194))
                       AND id NOT IN (223591444,
                                      223591452,
                                      245019321,
                                      255072045,
                                      256913892,
                                      256914306,
                                      256914686,
                                      256914693,
                                      256915681,
                                      256915717,
                                      256916522,
                                      256916529,
                                      256916710,
                                      256917783,
                                      256917955,
                                      256918512,
                                      256918652,
                                      256918884,
                                      256918899,
                                      256918906,
                                      256918916); --orders that will stay in wrong status that we can ignore

                IF l_nr > 0
                THEN
                    l_text2 := NULL;
                        -- make sure to return something (null here) even if the main query returns nothing. Oherwise no alert is raised on payment.
                        FOR i IN (        WITH POTENTIALLY_EMPTY
                                             AS (SELECT DISTINCT NVL(MSG_BDL_ID,123456789) MSG_BDL_ID
                                                   FROM K.MSG
                                                  WHERE     DOC_ID IN (SELECT ID
                                                                         FROM K.DOC
                                                                        WHERE     META_TYP_ID = 6
                                                                              AND WFC_STATUS_ID = 25
                                                                              AND (SELECT SYSDATE - MAX (TIMESTAMP)
                                                                                     FROM K.TRANS
                                                                                    WHERE     DOC_ID = ID
                                                                                          AND NEW_WFC_STATUS_ID = 25) >
                                                                                     INTERVAL '3' HOUR
                                                                              AND id NOT IN (SELECT item_doc_id FROM k.doc_cord_link WHERE doc_id IN (358595580,358601092,358630333,358631497,358640451,358635194))
                                                                              AND ID NOT IN (223591444,
                                                                                             223591452,
                                                                                             245019321,
                                                                                             255072045,
                                                                                             256913892,
                                                                                             256914306,
                                                                                             256914686,
                                                                                             256914693,
                                                                                             256915681,
                                                                                             256915717,
                                                                                             256916522,
                                                                                             256916529,
                                                                                             256916710,
                                                                                             256917783,
                                                                                             256917955,
                                                                                             256918512,
                                                                                             256918652,
                                                                                             256918884,
                                                                                             256918899,
                                                                                             256918906,
                                                                                             256918916)))
                                        SELECT * FROM POTENTIALLY_EMPTY
                                        WHERE MSG_BDL_ID <> 123456789
                                        UNION ALL
                                        SELECT NULL
                                          FROM DUAL
                                        WHERE NOT EXISTS (SELECT * FROM POTENTIALLY_EMPTY)

                                      ) LOOP

                                    BEGIN

                                        SELECT mbpl.val INTO l_text FROM k.msg_bdl mb, TABLE(mb.prty_list) mbpl WHERE id = i.msg_bdl_id
                                        UNION ALL
                                        SELECT 'NO_NAME' FROM DUAL WHERE NOT EXISTS (SELECT mbpl.val FROM k.msg_bdl mb, TABLE(mb.prty_list) mbpl WHERE id = i.msg_bdl_id);
                                        SELECT COUNT(*) INTO l_count
                                            FROM k.doc
                                            WHERE meta_typ_id = 6
                                            AND wfc_status_id = 25
                                            AND id IN (SELECT doc_id FROM k.msg WHERE msg_bdl_id = i.msg_bdl_id);
                                        l_cnt_loop := 0;
                                        l_text2 := l_text2 || '<br/>Bundle: '||i.msg_bdl_id||' File: '||l_text||'<br/>'||'Orders (' || l_count || ') : ';
                                        FOR j IN (    SELECT     id
                                                    FROM     k.doc
                                                    WHERE     meta_typ_id = 6
                                                        AND wfc_status_id = 25
                                                        AND id IN (    SELECT     doc_id
                                                                    FROM     k.msg
                                                                    WHERE     msg_bdl_id = i.msg_bdl_id)  )LOOP -- payment wait for processing


                                            l_order_bu_id := getOrderBu(j.id);

                                            l_bu_list(l_bu_list.COUNT + 1) := l_order_bu_id;

                                            IF l_cnt_loop < 100 THEN
                                                IF l_order_bu_id = 3 THEN
                                                    l_text2 := l_text2 || j.id ||', ' ; --append only order id
                                                ELSE
                                                    l_order_bu_name := getBuName(l_order_bu_id);
                                                    l_text2 := l_text2 || j.id || '(' || l_order_bu_name || '), '; --append order_id and bu
                                                END IF;
                                            ELSE
                                                l_nr_error := l_count - l_cnt_loop;
                                                l_text2 := l_text2 ||'... and '|| l_nr_error || ' more..' ;
                                                EXIT;
                                            END IF;
                                            l_cnt_loop := l_cnt_loop + 1;
                                        END LOOP;
                                    SELECT SUBSTR(l_text2,1,LENGTH(l_text2)-2) INTO l_text2 FROM DUAL;

                                EXCEPTION --ignore inconsistency problem where select on msg_bdl_id does not return results
                                    WHEN NO_DATA_FOUND THEN
                                        NULL;
                                END;

                            END LOOP;

                    l_text := NULL;

                    SELECT COUNT (*)
                      INTO l_count
                      FROM k.doc
                     WHERE     meta_typ_id = 6
                           AND wfc_status_id = 25
                           AND (SELECT SYSDATE - MAX (timestamp)
                                  FROM k.trans
                                 WHERE doc_id = id AND new_wfc_status_id = 25) >
                               INTERVAL '3' HOUR
                           AND id NOT IN (SELECT doc_id
                                            FROM k.msg
                                           WHERE msg_bdl_id IS NOT NULL)
                           AND id NOT IN (SELECT item_doc_id
                                            FROM doc_cord_link
                                           WHERE doc_id IN (358595580,
                                                            358601092,
                                                            358630333,
                                                            358631497,
                                                            358640451,
                                                            358635194))
                           AND id NOT IN (223591444,
                                          223591452,
                                          245019321,
                                          255072045,
                                          256913892,
                                          256914306,
                                          256914686,
                                          256914693,
                                          256915681,
                                          256915717,
                                          256916522,
                                          256916529,
                                          256916710,
                                          256917783,
                                          256917955,
                                          256918512,
                                          256918652,
                                          256918884,
                                          256918899,
                                          256918906,
                                          256918916);

                    l_cnt_loop := 0;

                    FOR i
                        IN (SELECT id
                              FROM k.doc
                             WHERE     meta_typ_id = 6
                                   AND wfc_status_id = 25
                                   AND (SELECT SYSDATE - MAX (timestamp)
                                          FROM k.trans
                                         WHERE     doc_id = id
                                               AND new_wfc_status_id = 25) >
                                       INTERVAL '3' HOUR
                                   AND id NOT IN
                                           (SELECT doc_id
                                              FROM k.msg
                                             WHERE msg_bdl_id IS NOT NULL)
                                   AND id NOT IN
                                           (SELECT item_doc_id
                                              FROM k.doc_cord_link
                                             WHERE doc_id IN (358595580,
                                                              358601092,
                                                              358630333,
                                                              358631497,
                                                              358640451,
                                                              358635194))
                                   AND id NOT IN (223591444,
                                                  223591452,
                                                  245019321,
                                                  255072045,
                                                  256913892,
                                                  256914306,
                                                  256914686,
                                                  256914693,
                                                  256915681,
                                                  256915717,
                                                  256916522,
                                                  256916529,
                                                  256916710,
                                                  256917783,
                                                  256917955,
                                                  256918512,
                                                  256918652,
                                                  256918884,
                                                  256918899,
                                                  256918906,
                                                  256918916))
                    LOOP                        -- payment wait for processing
                        l_order_bu_id := getOrderBu (i.id);

                        l_bu_list (l_bu_list.COUNT + 1) := l_order_bu_id;

                        IF l_cnt_loop < 100
                        THEN
                            IF l_order_bu_id = 3
                            THEN
                                l_text := l_text || i.id || ', '; --append only order id
                            ELSE
                                l_order_bu_name := getBuName (l_order_bu_id);
                                l_text :=
                                       l_text
                                    || i.id
                                    || '('
                                    || l_order_bu_name
                                    || '), ';         --append order_id and bu
                            END IF;
                        ELSE
                            l_nr_error := l_count - l_cnt_loop;
                            l_text :=
                                   l_text
                                || '... and '
                                || l_nr_error
                                || ' more..';
                            EXIT;
                        END IF;

                        l_cnt_loop := l_cnt_loop + 1;
                    END LOOP;

                    SELECT SUBSTR (l_text, 1, LENGTH (l_text) - 2)
                      INTO l_text
                      FROM DUAL;

                    IF l_text IS NOT NULL
                    THEN
                        l_text2 :=
                               l_text2
                            || '<br/>Orders with no message bundle ('
                            || l_count
                            || ') : '
                            || l_text;
                    END IF;

                    IF l_text2 IS NOT NULL
                    THEN
                        --p_to := p_to ||';' || l_mail_pay_wfp;
                        p_to := appendMails (p_to, l_bu_list, 'PAY_WFP');
                        p_html_pool :=
                               '<br/><b>WARNING for PAYMENT TEAM : '
                            || l_nr
                            || ' Payment in status "wait for processing (25)" for at least 3 hours</b>'
                            || l_text2
                            || '<br/>'
                            || p_html_pool;
                    END IF;
                END IF;

                write_query ('Payment wait for processing (25)',
                             TO_CHAR (l_nr),
                             '0',
                             c_blocking_p,
                             '=',
                             'payment_wait_for_processing');
            EXCEPTION
                WHEN OTHERS
                THEN
                    handle_check_exception (
                        'payment_wait_for_processing',
                        SQLERRM,
                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            END;



            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CORD_WAIT_PROCESSING');

            --CORD wait for processing (810)
            BEGIN
                l_bu_list.delete;

                SELECT COUNT (id)
                  INTO l_nr
                  FROM k.doc
                 WHERE     meta_typ_id = 35
                       AND wfc_status_id = 810
                       AND (SELECT SYSDATE - MAX (timestamp)
                              FROM k.trans
                             WHERE doc_id = id AND new_wfc_status_id = 810) >
                           INTERVAL '15' MINUTE;

                IF l_nr > 0
                THEN
                    l_text := NULL;
                    l_cnt_loop := 0;

                    FOR i
                        IN (SELECT id
                              FROM k.doc
                             WHERE     meta_typ_id = 35
                                   AND wfc_status_id = 810
                                   AND (SELECT SYSDATE - MAX (timestamp)
                                          FROM k.trans
                                         WHERE     doc_id = id
                                               AND new_wfc_status_id = 810) >
                                       INTERVAL '15' MINUTE)
                    LOOP
                        l_order_bu_id := getOrderBu (i.id);

                        l_bu_list (l_bu_list.COUNT + 1) := l_order_bu_id;

                        IF l_cnt_loop < 100
                        THEN
                            IF l_order_bu_id = 3
                            THEN
                                l_text := l_text || i.id || ', '; --append only order id
                            ELSE
                                l_order_bu_name := getBuName (l_order_bu_id);
                                l_text :=
                                       l_text
                                    || i.id
                                    || '('
                                    || l_order_bu_name
                                    || '), ';         --append order_id and bu
                            END IF;
                        ELSE
                            l_nr_error := l_nr - l_cnt_loop;
                            l_text :=
                                   l_text
                                || '... and '
                                || l_nr_error
                                || ' more..';
                            EXIT;
                        END IF;

                        l_cnt_loop := l_cnt_loop + 1;
                    END LOOP;

                    SELECT SUBSTR (l_text, 1, LENGTH (l_text) - 2)
                      INTO l_text
                      FROM DUAL;

                    IF l_text IS NOT NULL
                    THEN
                        p_to := appendMails (p_to, l_bu_list, 'PAY_WFP');
                        p_html_pool :=
                               '<br/><b>WARNING for PAYMENT TEAM : '
                            || l_nr
                            || ' CORD orders in status "wait for processing (810)" for at least 15 minutes</b><br/>'
                            || l_text
                            || '<br/>'
                            || p_html_pool;
                    END IF;
                END IF;

                write_query ('CORD wait for processing (810)',
                             TO_CHAR (l_nr),
                             '0',
                             c_blocking_p,
                             '=',
                             'cord_wait_for_processing');
            EXCEPTION
                WHEN OTHERS
                THEN
                    handle_check_exception (
                        'cord_wait_for_processing',
                        SQLERRM,
                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            END;



            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_SETTLE_ON_HOLD');

            --Settlement orders on hold

            SELECT COUNT (*)
              INTO l_nr
              FROM k.doc d, k.doc d2
             WHERE     d.meta_typ_id = 9                         -- settlement
                   AND d.trx_date >= lookup_ddic#.date_ ('today -1v') -- handle w-e
                   AND d.timestamp < SYSDATE - 1 / 24         -- last trans 1h
                   AND d.bp_imed_id = 3
                   AND d.settle_plan_id IN (8760,
                                            12190,
                                            7000,
                                            9930,
                                            25290,
                                            9935,
                                            9936,
                                            7420,
                                            25430,
                                            7060,
                                            25295,
                                            25310,
                                            7410,
                                            7010,
                                            25300,
                                            7450,
                                            7440,
                                            8080,
                                            8090) --DUMMY_PMO,DUMMY_PMO_SDD,O103,,O103_BE,O103_BONY,O103_BTBE,O103_BTLU,O103_DB,O103_EUR_FR,O103_O202.CL,O103_O202_BONY,O103_SEPA,O103_TARGET,O202,O202_BONY,O202_DB,O202_TARGET,PAY_VOSTRO_O103,PAY_VOSTRO_O202
                   AND d.doc_ref_id = d2.id
                   AND d2.meta_typ_id IN (6, 56)       -- payment, chqprc only
                   AND d.wfc_status_id = 210;                       -- on hold


            write_query ('Settlement Orders On Hold',
                         TO_CHAR (l_nr),
                         '0',
                         c_blocking_p,
                         '=',
                         'settlement_on_hold');

            --add message with order ids and bu ids
            IF l_nr > 0
            THEN
                l_text := NULL;
                l_count := 0;
                l_bu_list.delete;

                FOR ent
                    IN (SELECT d.*
                          FROM k.doc d, k.doc d2
                         WHERE     d.meta_typ_id = 9             -- settlement
                               AND d.trx_date >=
                                   lookup_ddic#.date_ ('today -1v')
                               AND d.timestamp < SYSDATE - 1 / 24
                               AND d.bp_imed_id = 3
                               AND d.settle_plan_id IN (8760,
                                                        12190,
                                                        7000,
                                                        9930,
                                                        25290,
                                                        9935,
                                                        9936,
                                                        7420,
                                                        25430,
                                                        7060,
                                                        25295,
                                                        25310,
                                                        7410,
                                                        7010,
                                                        25300,
                                                        7450,
                                                        7440,
                                                        8080,
                                                        8090)
                               AND d.doc_ref_id = d2.id
                               AND d2.meta_typ_id IN (6, 56) -- payment, chqprc only
                               AND d.wfc_status_id = 210)
                LOOP
                    --limit entries to 20 by counter
                    IF l_count > 20
                    THEN
                        EXIT;
                    END IF;

                    --add no comma for first entry
                    IF l_text IS NOT NULL
                    THEN
                        l_text := l_text || ', ';
                    END IF;

                    l_order_bu_id := getOrderBu (ent.id);

                    l_bu_list (l_bu_list.COUNT + 1) := l_order_bu_id;

                    IF l_order_bu_id = 3
                    THEN
                        --add doc_id and bu_id
                        l_text := l_text || ent.id;
                    ELSE
                        l_order_bu_name := getBuName (l_order_bu_id);
                        l_text :=
                            l_text || ent.id || '(' || l_order_bu_name || ')'; --append order_id and bu
                    END IF;

                    --increment failsafe counter
                    l_count := l_count + 1;
                END LOOP;


                p_html_pool :=
                       '<br/><b>WARNING for PAYMENT TEAM : '
                    || l_nr
                    || ' Settlement order(s) still in status "On Hold":</b><br/>'
                    || l_text
                    || '<br/>'
                    || p_html_pool;

                --p_to := p_to ||';' || l_mail_settle_on_hold;
                p_to := appendMails (p_to, l_bu_list, 'SETTLE_ON_HOLD');
            END IF;


            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_PAY_SETTLE_FAIL');
            check_pay_settle_fail;



            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_PAY_SAS_CTRL');
            check_pay_sas_ctrl;


            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_TRADING_DESK');

            --Trading desk
            write_subheader ('Trading desk');



            DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_PENDING CANCELLATION');
            --pending cancellation
            l_text := '';
            l_nr := 0;
            l_bu_list.delete;

            FOR c
                IN (SELECT t.doc_id
                      FROM trans t, prcq p
                     WHERE     t.old_wfc_status_id = 2450
                           AND t.new_wfc_status_id = 91
                           AND t.doc_id = p.id
                           AND p.timestamp_prc IS NULL
                           AND TRUNC (p.timestamp_ins) = TRUNC (SYSDATE)
                           AND (p.timestamp_start - p.timestamp_ins) >
                               INTERVAL '1' MINUTE)
            LOOP
                l_nr := l_nr + 1;

                IF l_nr > 1
                THEN
                    l_text := l_text || ',';
                END IF;

                l_order_bu_id := getOrderBu (c.doc_id);

                l_bu_list (l_bu_list.COUNT + 1) := l_order_bu_id;

                IF l_order_bu_id = 3
                THEN
                    l_text := l_text || c.doc_id;       --append only order id
                ELSE
                    l_order_bu_name := getBuName (l_order_bu_id);
                    l_text :=
                        l_text || c.doc_id || '(' || l_order_bu_name || ')'; --append order_id and bu
                END IF;
            END LOOP;

            IF l_nr > 0
            THEN
                p_html_pool := '<br/>' || l_text || '<br/>' || p_html_pool;
                p_html_pool :=
                       '<br/><b>WARNING for STEX TEAM : '
                    || l_nr
                    || ' STEX order(s) blocked in Pending cancellation :</b><br/>'
                    || p_html_pool;
                p_to := appendMails (p_to, l_bu_list, 'STEX');
            END IF;

            write_query ('Orders pending cancellation',
                         TO_CHAR (l_nr),
                         '0',
                         c_blocking_p,
                         '=',
                         'orders_pending_cancellation');


            --Asset Evaluation
            write_subheader ('Asset Evaluation');

            --Check Asset Validation
            IF cond_check_asset_eval OR c_force_bdl_active
            THEN
                check_asset_eval;
            END IF;
        END IF;                               --end european functional checks
    END;


    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    --
    --Name: CIC-SG Check Block
    --
    --Summary: All Checks that are executed specifically for CIC-SG / BU 8
    --
    --
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    DECLARE
        c_force_active   BOOLEAN := FALSE;
        c_force_date     BOOLEAN := FALSE;

        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG FOREX Morning message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_forex_morning
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 09:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 09:30',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_forex_morning;

        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG FX option message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_fx_option_cisg
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF (SYSDATE BETWEEN TO_DATE (
                                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy')
                                    || ' 01:00',
                                    'ddmmyyyy HH24:MI')
                            AND TO_DATE (
                                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy')
                                    || ' 01:15',
                                    'ddmmyyyy HH24:MI'))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_fx_option_cisg;


        ---------------------------------
        --Summary:Check if at least 1 FOREX message for CIC-SG was received during the moring period
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_forex_morning
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_forex_morning';
            c_check_title   VARCHAR2 (100)
                                := 'Forex Morning messages received';
            l_cnt_in        NUMBER;
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.msg_type LIKE 'NC$CISG_FX_RATES'
                   AND m.id = mi.id
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 6
                   AND mi.text LIKE '%trade_cisg%'
                   AND mi.timestamp > TRUNC (SYSDATE) --msg.timestamp is in BDL time
                   AND TO_NUMBER (TO_CHAR (mi.timestamp, 'hh24')) < 17;


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_major_p,
                         '>=',
                         c_check_name);


            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No FX messages received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_forex_morning;


        ---------------------------------
        --Summary: Date and timeframe condition for the CIC-SG FOREX Evening message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_forex_evening
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 18:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 19:00',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_forex_evening;


        ---------------------------------
        --Summary:Check if at least 1 FOREX message for CIC-SG has been received during the evening
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_forex_evening
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_forex_evening';
            c_check_title   VARCHAR2 (100)
                                := 'Forex Evening messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.msg_type LIKE 'NC$CISG_FX_RATES'
                   AND m.id = mi.id
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 6
                   AND mi.text LIKE '%trade_cisg%'
                   AND mi.timestamp > TRUNC (SYSDATE) --msg.timestamp is in BDL time
                   AND TO_NUMBER (TO_CHAR (mi.timestamp, 'hh24')) > 16;

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No FX rates messages received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_forex_evening;



        ---------------------------------
        --Summary: Date and timeframe condition for the CIC-SG NPV that comes at 18h
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_npv_18h
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);



            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 23:00',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_npv_18h;


        ---------------------------------
        --Summary:Check if all 13 NPV msg are received
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_npv_18h
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_npv_18h';
            c_check_title   VARCHAR2 (100) := 'NPV 18h messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 12;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM k.MSG_EXTL_IN a, k.MSG m
             WHERE     m.meta_msg_id = 516
                   AND a.id = m.id
                   AND m.bu_id = 8
                   AND a.timestamp >=
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 17:50',
                           'ddmmyyyy HH24:MI')
                   AND a.timestamp <=
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 20:30',
                           'ddmmyyyy HH24:MI')
                   AND a.text LIKE '%<ProductName>NPV</ProductName>%';

            --and     a.text like '%<Date>'||to_char(trunc(sysdate), 'DD/MM/YYYY')||'</Date>%';

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_to := upsert_mails (p_to, ';', l_mail_market_it_light);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : NPV 18h messages not received ('
                    || TO_CHAR (l_cnt)
                    || ' / '
                    || TO_CHAR (c_min)
                    || ')</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_npv_18h;



        ---------------------------------
        --Summary:Date and timeframe condition for the FOREX Tokyo Cutoff message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_forex_tokyo
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 14:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 19:00',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_forex_tokyo;


        ---------------------------------
        --Summary:Check if at least 1 message of the type FOREX Tokyo Cutoff was received during the day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_forex_tokyo
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_forex_tokyo';
            c_check_title   VARCHAR2 (100)
                                := 'Forex Tokyo Cutoff messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.msg_type LIKE 'NC$CISG_FX_RATES'
                   AND m.id = mi.id
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 6
                   AND mi.text LIKE '%cutoff_tokyo_1500%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No FX Tokyo Cutoff rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_forex_tokyo;



        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG FOREX ILS message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_forex_ils
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);


            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 07:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 19:00',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_forex_ils;

        ---------------------------------
        --Summary:Check if at least one FOREX ILS message for CIC-SG was received during the day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_forex_ils
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_forex_ils';
            c_check_title   VARCHAR2 (100) := 'Forex ILS messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.msg_type LIKE 'NC$CISG_FX_RATES'
                   AND m.id = mi.id
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 6
                   AND mi.text LIKE '%trade_cisg%'
                   AND mi.text LIKE '%ILS=%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_forex_ils;


        ---------------------------------
        --Summary:Date and timeframe condition for the MMKT_Rates unparsed/error check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_mmkt_rates_unparsed
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF     SYSDATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 02:00',
                       'ddmmyyyy HH24:MI')
               AND SYSDATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:00',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_mmkt_rates_unparsed;

        ---------------------------------
        --Summary:Check if any MMKT_RATES messages for CIC-SG are in erroneous state - like unparsed
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_mmkt_rates_unparsed
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_mmkt_rates_unparsed';
            c_check_title   VARCHAR2 (100) := 'Unparsed MMKT Rates messages';
            l_cnt           NUMBER;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi
             WHERE     mi.msg_type LIKE 'NC$CISG_MMKT_RATES'
                   AND mi.msg_status_id IN (8, 23, 33)
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         0,
                         c_blocking_p,
                         '=',
                         c_check_name);

            IF l_cnt > 0
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_mmkt_rates_unparsed;

        /*

                    ---------------------------------
                    --Summary:Date and timeframe condition for CIC-SG MMKT_Rates T1 message check
                    --Parameters:
                    --Author:
                    --Date:
                    ---------------------------------
                    function cond_cisg_mmkt_rates_t1
                    return boolean
                    is
                        l_cond boolean := false;
                    begin

                        session#.open_session(i_bu_id=>8);


                        if sysdate > to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 02:30', 'ddmmyyyy HH24:MI')
                            and sysdate < to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 13:00', 'ddmmyyyy HH24:MI')
                        then

                            l_cond := true;

                        end if;

                        return l_cond;

                    end cond_cisg_mmkt_rates_t1;

                    ---------------------------------
                    --Summary:Check if at least 1 MMKT_Rates T1 message has been received during the current day
                    --Parameters:
                    --Author:
                    --Date:
                    ---------------------------------
                    procedure check_cisg_mmkt_rates_t1
                    is
                        c_check_name varchar2(100) := 'check_cisg_mmkt_rates_t1';
                        c_check_title varchar2(100) := 'Rates MMKT T1 messages received';
                        l_cnt number;
                        c_min number := 1;
                    begin

                        select count(*) into l_cnt from msg_extl_in mi, msg m
                            where mi.msg_type like 'NC$CISG_MMKT_RATES'
                                and m.id = mi.id
                                and mi.msg_status_id = 3
                                and m.msg_status_id = 6
                                and mi.text like '%cisg_mmkt_t1%'
                                and mi.text like '%USDOND%'
                                and mi.timestamp > trunc(sysdate); --msg.timestamp is in BDL time


                        write_query(c_check_title, l_cnt, c_min, c_blocking_p,'>=', c_check_name);

                        if l_cnt < c_min then
                            p_to := upsert_mails(p_to, ';', l_mail_cisg_msg);
                            p_html_pool:= '<br/><b>WARNING for CIC-SG : No MMKT T1 rates received</b><br/>' || p_html_pool;
                        end if;
                    exception
                        when others then
                            handle_check_exception(c_check_title, sqlerrm, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                    end check_cisg_mmkt_rates_t1;



                    ---------------------------------
                    --Summary:Date and timeframe condition for CIC-SG MMKT_Rates T1 message TASK runned check
                    --Parameters:
                    --Author:
                    --Date:
                    ---------------------------------
                    function cond_cisg_mmkt_rates_t1_task
                    return boolean
                    is
                        l_cond boolean := false;
                    begin

                        session#.open_session;

                        if sysdate > to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 02:30', 'ddmmyyyy HH24:MI')
                            and sysdate < to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 13:00', 'ddmmyyyy HH24:MI')
                        then

                            l_cond := true;

                        end if;

                        return l_cond;

                    end cond_cisg_mmkt_rates_t1_task;

                    ---------------------------------
                    --Summary:Check if task that runs after reception of MMKT_Rates has been processed. If it's running for too long, CISG wants an Email alert.
                    --Parameters:
                    --Author:
                    --Date:
                    ---------------------------------
                    procedure check_cisg_mmkt_rates_t1_task
                    is
                        c_check_name varchar2(100) := 'check_cisg_mmkt_rates_t1_task';
                        c_check_title varchar2(100) := 'Rates MMKT T1 messages TASK runned';
                        l_cnt number;
                        c_min number := 1;
                    begin

                        SELECT  count(*) into c_min
                        FROM    OUT_JOB_V o, table(o.bind_val_tab) b
                        where   timestamp_ins > trunc(sysdate)
                            and meta_out_templ_id in (
                                    SELECT  lookup_ddic#.task_templ_id(upper('TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'), null, null, '+', null)
                                    FROM    dual
                            )
                            and b.par_name = 'I_EXPR'
                            and b.par_val like '%dt.extn.ass_md_scen_ref.id = 1009 and dt.extn.ass_md_ref.id in (49964,%'
                            and timestamp_ins > to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 09:25', 'ddmmyyyy HH24:MI')
                            and timestamp_ins < to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 20:00', 'ddmmyyyy HH24:MI')
                            and timestamp_ins < sysdate - INTERVAL '5' MINUTE; -- allow 5 minute timeframe where not alert is necessary

                        SELECT  count(*) into l_cnt
                        FROM    OUT_JOB_V o, table(o.bind_val_tab) b
                        where   timestamp_ins > trunc(sysdate)
                            and meta_out_templ_id in (
                                    SELECT  lookup_ddic#.task_templ_id(upper('TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'), null, null, '+', null)
                                    FROM    dual
                            )
                            and b.par_name = 'I_EXPR'
                            and b.par_val like '%dt.extn.ass_md_scen_ref.id = 1009 and dt.extn.ass_md_ref.id in (49964,%'
                            and timestamp_ins > to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 09:25', 'ddmmyyyy HH24:MI')
                            and timestamp_ins < to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 20:00', 'ddmmyyyy HH24:MI')
                            and out_status_id in (7); -- processed

                        write_query(c_check_title, l_cnt, c_min, c_blocking_p,'>=', c_check_name);

                        if l_cnt < c_min then
                            p_to := upsert_mails(p_to, ';', l_mail_cisg_msg);
                            p_to := upsert_mails(p_to, ';', l_mail_cisg_mmkt_task);
                            p_html_pool:= '<br/><b>WARNING for CIC-SG : MMKT T1 rates TASK not runned or still running</b><br/>' || p_html_pool;
                        end if;
                    exception
                        when others then
                            handle_check_exception(c_check_title, sqlerrm, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                    end check_cisg_mmkt_rates_t1_task;




                    ---------------------------------
                    --Summary:Date and timeframe condition for the CIC-SG MMKT Rates T2 message check
                    --Parameters:
                    --Author:
                    --Date:
                    ---------------------------------
                    function cond_cisg_mmkt_rates_t2
                    return boolean
                    is
                        l_cond boolean := false;
                    begin

                        if sysdate > to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 02:30', 'ddmmyyyy HH24:MI')
                            and sysdate < to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 13:00', 'ddmmyyyy HH24:MI')
                        then

                            l_cond := true;

                        end if;

                        return l_cond;

                    end cond_cisg_mmkt_rates_t2;

                    ---------------------------------
                    --Summary:Check if at least 1 MMKT_Rates T2 message has been received during the current day
                    --Parameters:
                    --Author:
                    --Date:
                    ---------------------------------
                    procedure check_cisg_mmkt_rates_t2
                    is
                        c_check_name varchar2(100) := 'check_cisg_mmkt_rates_t2';
                        c_check_title varchar2(100) := 'Rates MMKT T2 messages received';
                        l_cnt number;
                        c_min number := 1;
                    begin

                        select count(*) into l_cnt from msg_extl_in mi, msg m
                            where mi.msg_type like 'NC$CISG_MMKT_RATES'
                                and m.id = mi.id
                                and mi.msg_status_id = 3
                                and m.msg_status_id = 6
                                and mi.text like '%cisg_mmkt_t2%'
                                and mi.timestamp > trunc(sysdate); --msg.timestamp is in BDL time


                        write_query(c_check_title, l_cnt, c_min, c_blocking_p,'>=', c_check_name);

                        if l_cnt < c_min then
                            p_to := upsert_mails(p_to, ';', l_mail_cisg_msg);
                            p_html_pool:= '<br/><b>WARNING for CIC-SG : No MMKT T2 rates received</b><br/>' || p_html_pool;
                        end if;

                    exception
                        when others then
                            handle_check_exception(c_check_title, sqlerrm, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                    end check_cisg_mmkt_rates_t2;



                    ---------------------------------
                    --Summary:Date and timeframe condition for CIC-SG MMKT_Rates T2 message TASK runned check
                    --Parameters:
                    --Author:
                    --Date:
                    ---------------------------------
                    function cond_cisg_mmkt_rates_t2_task
                    return boolean
                    is
                        l_cond boolean := false;
                    begin

                        session#.open_session;

                        if sysdate > to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 02:30', 'ddmmyyyy HH24:MI')
                            and sysdate < to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 13:00', 'ddmmyyyy HH24:MI')
                        then

                            l_cond := true;

                        end if;

                        return l_cond;

                    end cond_cisg_mmkt_rates_t2_task;

                    ---------------------------------
                    --Summary:Check if task that runs after reception of MMKT_Rates has been processed. If it's running for too long, CISG wants an Email alert.
                    --Parameters:
                    --Author:
                    --Date:
                    ---------------------------------
                    procedure check_cisg_mmkt_rates_t2_task
                    is
                        c_check_name varchar2(100) := 'check_cisg_mmkt_rates_t2_task';
                        c_check_title varchar2(100) := 'Rates MMKT T2 messages TASK runned';
                        l_cnt number;
                        c_min number := 1;
                    begin

                        SELECT  count(*) into c_min
                        FROM    OUT_JOB_V o, table(o.bind_val_tab) b
                        where   timestamp_ins > trunc(sysdate)
                            and meta_out_templ_id in (
                                    SELECT  lookup_ddic#.task_templ_id(upper('TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'), null, null, '+', null)
                                    FROM    dual
                            )
                            and b.par_name = 'I_EXPR'
                            and b.par_val like '%dt.extn.ass_md_scen_ref.id = 1010 and dt.extn.ass_md_ref.id in (49964,%'
                            and timestamp_ins > to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 09:25', 'ddmmyyyy HH24:MI')
                            and timestamp_ins < to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 20:00', 'ddmmyyyy HH24:MI')
                            and timestamp_ins < sysdate - INTERVAL '5' MINUTE; -- allow 5 minute timeframe where not alert is necessary

                        SELECT  count(*) into l_cnt
                        FROM    OUT_JOB_V o, table(o.bind_val_tab) b
                        where   timestamp_ins > trunc(sysdate)
                            and meta_out_templ_id in (
                                    SELECT  lookup_ddic#.task_templ_id(upper('TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'), null, null, '+', null)
                                    FROM    dual
                            )
                            and b.par_name = 'I_EXPR'
                            and b.par_val like '%dt.extn.ass_md_scen_ref.id = 1010 and dt.extn.ass_md_ref.id in (49964,%'
                            and timestamp_ins > to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 09:25', 'ddmmyyyy HH24:MI')
                            and timestamp_ins < to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 20:00', 'ddmmyyyy HH24:MI')
                            and out_status_id in (7); -- processed

                        write_query(c_check_title, l_cnt, c_min, c_blocking_p,'>=', c_check_name);

                        if l_cnt < c_min then
                            p_to := upsert_mails(p_to, ';', l_mail_cisg_msg);
                            p_to := upsert_mails(p_to, ';', l_mail_cisg_mmkt_task);
                            p_html_pool:= '<br/><b>WARNING for CIC-SG : MMKT T2 rates TASK not runned or still running</b><br/>' || p_html_pool;
                        end if;
                    exception
                        when others then
                            handle_check_exception(c_check_title, sqlerrm, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                    end check_cisg_mmkt_rates_t2_task;


                    ---------------------------------
                    --Summary:Date and timeframe condition for the CIC-SG MMKT_Rates T3 check
                    --Parameters:
                    --Author:
                    --Date:
                    ---------------------------------
                    function cond_cisg_mmkt_rates_t3
                    return boolean
                    is
                        l_cond boolean := false;
                    begin


                        if sysdate > to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 02:30', 'ddmmyyyy HH24:MI')
                            and sysdate < to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 13:00', 'ddmmyyyy HH24:MI')
                        then

                            l_cond := true;

                        end if;

                        return l_cond;

                    end cond_cisg_mmkt_rates_t3;

                    ---------------------------------
                    --Summary:Check if at least 1 MMKT_Rates T3 message has been received during the current day
                    --Parameters:
                    --Author:
                    --Date:
                    ---------------------------------
                    procedure check_cisg_mmkt_rates_t3
                    is
                        c_check_name varchar2(100) := 'check_cisg_mmkt_rates_t3';
                        c_check_title varchar2(100) := 'Rates MMKT T3 messages received';
                        l_cnt number;
                        c_min number := 1;
                    begin

                        select count(*) into l_cnt from msg_extl_in mi, msg m
                            where mi.msg_type like 'NC$CISG_MMKT_RATES'
                                and m.id = mi.id
                                and mi.msg_status_id = 3
                                and m.msg_status_id = 6
                                and mi.text like '%cisg_mmkt_t3%'
                                and mi.timestamp > trunc(sysdate); --msg.timestamp is in BDL time


                        write_query(c_check_title, l_cnt, c_min, c_blocking_p,'>=', c_check_name);

                        if l_cnt < c_min then
                            p_to := upsert_mails(p_to, ';', l_mail_cisg_msg);
                            p_html_pool:= '<br/><b>WARNING for CIC-SG : No MMKT T3 rates received</b><br/>' || p_html_pool;
                        end if;
                    exception
                        when others then
                            handle_check_exception(c_check_title, sqlerrm, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                    end check_cisg_mmkt_rates_t3;



                    ---------------------------------
                    --Summary:Date and timeframe condition for CIC-SG MMKT_Rates T3 message TASK runned check
                    --Parameters:
                    --Author:
                    --Date:
                    ---------------------------------
                    function cond_cisg_mmkt_rates_t3_task
                    return boolean
                    is
                        l_cond boolean := false;
                    begin

                        session#.open_session;

                        if sysdate > to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 02:30', 'ddmmyyyy HH24:MI')
                            and sysdate < to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 13:00', 'ddmmyyyy HH24:MI')
                        then

                            l_cond := true;

                        end if;

                        return l_cond;

                    end cond_cisg_mmkt_rates_t3_task;

                    ---------------------------------
                    --Summary:Check if task that runs after reception of MMKT_Rates has been processed. If it's running for too long, CISG wants an Email alert.
                    --Parameters:
                    --Author:
                    --Date:
                    ---------------------------------
                    procedure check_cisg_mmkt_rates_t3_task
                    is
                        c_check_name varchar2(100) := 'check_cisg_mmkt_rates_t3_task';
                        c_check_title varchar2(100) := 'Rates MMKT T3 messages TASK runned';
                        l_cnt number;
                        c_min number := 1;
                    begin

                        SELECT  count(*) into c_min
                        FROM    OUT_JOB_V o, table(o.bind_val_tab) b
                        where   timestamp_ins > trunc(sysdate)
                            and meta_out_templ_id in (
                                    SELECT  lookup_ddic#.task_templ_id(upper('TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'), null, null, '+', null)
                                    FROM    dual
                            )
                            and b.par_name = 'I_EXPR'
                            and b.par_val like '%dt.extn.ass_md_scen_ref.id = 1011 and dt.extn.ass_md_ref.id in (49964,%'
                            and timestamp_ins > to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 09:25', 'ddmmyyyy HH24:MI')
                            and timestamp_ins < to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 20:00', 'ddmmyyyy HH24:MI')
                            and timestamp_ins < sysdate - INTERVAL '5' MINUTE; -- allow 5 minute timeframe where not alert is necessary

                        SELECT  count(*) into l_cnt
                        FROM    OUT_JOB_V o, table(o.bind_val_tab) b
                        where   timestamp_ins > trunc(sysdate)
                            and meta_out_templ_id in (
                                    SELECT  lookup_ddic#.task_templ_id(upper('TASK_ASSET_LIST.NC$COPY_RATES_TO_IRC'), null, null, '+', null)
                                    FROM    dual
                            )
                            and b.par_name = 'I_EXPR'
                            and b.par_val like '%dt.extn.ass_md_scen_ref.id = 1011 and dt.extn.ass_md_ref.id in (49964,%'
                            and timestamp_ins > to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 09:25', 'ddmmyyyy HH24:MI')
                            and timestamp_ins < to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 20:00', 'ddmmyyyy HH24:MI')
                            and out_status_id in (7); -- processed

                        write_query(c_check_title, l_cnt, c_min, c_blocking_p,'>=', c_check_name);

                        if l_cnt < c_min then
                            p_to := upsert_mails(p_to, ';', l_mail_cisg_msg);
                            p_to := upsert_mails(p_to, ';', l_mail_cisg_mmkt_task);
                            p_html_pool:= '<br/><b>WARNING for CIC-SG : MMKT T3 rates TASK not runned or still running</b><br/>' || p_html_pool;
                        end if;
                    exception
                        when others then
                            handle_check_exception(c_check_title, sqlerrm, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                    end check_cisg_mmkt_rates_t3_task;


            */



        ---------------------------------
        --Summary: Date and timeframe condition for the CIC-SG NPV that comes at 21h
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_npv_21h
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 21:40',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 23:00',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_npv_21h;


        ---------------------------------
        --Summary:Check if all 13 NPV msg are received
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_npv_21h
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_npv_21h';
            c_check_title   VARCHAR2 (100) := 'NPV 21h messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 12;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM k.MSG_EXTL_IN a, k.MSG m
             WHERE     m.meta_msg_id = 516
                   AND a.id = m.id
                   AND m.bu_id = 8
                   AND a.timestamp >=
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 20:30',
                           'ddmmyyyy HH24:MI')
                   AND a.timestamp <=
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 23:00',
                           'ddmmyyyy HH24:MI')
                   AND a.text LIKE '%<ProductName>NPV</ProductName>%';

            --and     a.text like '%<Date>'||to_char(trunc(sysdate), 'DD/MM/YYYY')||'</Date>%';

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_to := upsert_mails (p_to, ';', l_mail_market_it);

                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : NPV 21h messages not received ('
                    || TO_CHAR (l_cnt)
                    || ' / '
                    || TO_CHAR (c_min)
                    || ') </b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_npv_21h;



        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG MMKT_Rates AUD message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_mmkt_rates_aud
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF     SYSDATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 03:00',
                       'ddmmyyyy HH24:MI')
               AND SYSDATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 13:00',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_mmkt_rates_aud;

        ---------------------------------
        --Summary:Check if at least 1 MMKT_Rates AUD message has been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_mmkt_rates_aud
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_mmkt_rates_aud';
            c_check_title   VARCHAR2 (100)
                                := 'Rates Bank Bill AUD messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.msg_type LIKE 'NC$CISG_MMKT_RATES'
                   AND m.id = mi.id
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.text LIKE '%cisg_mmkt_t1%'
                   AND mi.text LIKE '%AU1MBA%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No MMKT Bank Bill AUD rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_mmkt_rates_aud;

        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG MMKT_Rates TONAR message check
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2014
        ---------------------------------
        FUNCTION cond_cisg_mmkt_rates_tonar
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF is_day_off (2014, SYSDATE)
            THEN
                l_cond := FALSE;
            ELSE
                IF     SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 08:10',
                           'ddmmyyyy HH24:MI')
                   AND SYSDATE <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 08:30',
                           'ddmmyyyy HH24:MI')
                THEN
                    l_cond := TRUE;
                END IF;
            END IF;

            RETURN l_cond;
        END cond_cisg_mmkt_rates_tonar;

        ---------------------------------
        --Summary:Check if at least 1 MMKT_Rates TONAR message has been received during the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2014
        ---------------------------------
        PROCEDURE check_cisg_mmkt_rates_tonar
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_mmkt_rates_tonar';
            c_check_title   VARCHAR2 (100)
                                := 'MMKT TONAR Rates messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.msg_type LIKE 'MMKT_RATES'
                   AND m.id = mi.id
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.text LIKE '%JPONA%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No MMKT TONAR rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_mmkt_rates_tonar;

        ---------------------------------
        --Summary:Check if trade date of TONAR rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:16/07/2014
        ---------------------------------
        PROCEDURE check_cisg_tonar_update
        IS
            c_check_name   VARCHAR2 (100) := 'cisg_tonar_update';
            c_rate_name    VARCHAR2 (50) := 'MMKT TONAR Rates';
            c_tag_name     VARCHAR2 (50) := 'JPONA001=RR';
        BEGIN
            --use generic check procedure
            check_generic_rates_update (
                c_check_name,
                c_rate_name,
                c_tag_name,
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 00:00',
                         'ddmmyyyy HH24:MI'),
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 23:59',
                         'ddmmyyyy HH24:MI'));
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_tonar_update;


        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG MMKT_Rates TIBOR message check
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2014
        ---------------------------------
        function cond_cisg_mmkt_rates_tibor
        return boolean
        is
            l_cond boolean := false;
        begin
            if is_day_off(2014, sysdate) then

                l_cond := false;

            ELSE

                if sysdate > to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 07:50', 'ddmmyyyy HH24:MI')
                    and sysdate < to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 08:10', 'ddmmyyyy HH24:MI')
                then

                    l_cond := true;

                end if;

            end if;

            return l_cond;

        end cond_cisg_mmkt_rates_tibor;

        ---------------------------------
        --Summary:Check if at least 1 MMKT_Rates TIBOR message has been received during the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2014
         ---------------------------------
        procedure check_cisg_mmkt_rates_tibor
        is
            c_check_name varchar2(100) := 'check_cisg_mmkt_rates_tibor';
            c_check_title varchar2(100) := 'MMKT TIBOR Rates messages received';
            l_cnt number;
            c_min number := 1;
        begin

            select count(*) into l_cnt from msg_extl_in mi, msg m
                where mi.msg_type like 'MMKT_RATES'
                    and m.id = mi.id
                    and mi.msg_status_id = 3
                    and m.msg_status_id = 6
                    and mi.text like '%TIJPY%'
                    and mi.timestamp > trunc(sysdate); --msg.timestamp is in BDL time

            write_query(c_check_title, l_cnt, c_min, c_blocking_p,'>=', c_check_name);

            if l_cnt < c_min then
                p_to := upsert_mails(p_to, ';', l_mail_cisg_msg);
                p_to := upsert_mails(p_to, ';', l_mail_market_it);
                p_html_pool:= '<br/><b>WARNING for CIC-SG : No MMKT TIBOR rates received</b><br/>' || p_html_pool;
            end if;

        exception
            when others then
                handle_check_exception(c_check_title, sqlerrm, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end check_cisg_mmkt_rates_tibor;


        ---------------------------------
        --Summary:Check if trade date of TIBOR rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:16/07/2014
        ---------------------------------
        procedure check_cisg_tibor_update
        is
            c_check_name varchar2(100) := 'cisg_tibor_update';
            c_rate_name varchar2(50) := 'MMKT TIBOR Rates';
            c_tag_name varchar2(50) := 'DIBJP1MD=';
        begin

            --use generic check procedure
            check_generic_rates_update(
                    c_check_name,
                    c_rate_name,
                    c_tag_name,
                    to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 00:00', 'ddmmyyyy HH24:MI'),
                    to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 23:59', 'ddmmyyyy HH24:MI')
                    );

        exception
            when others then
                handle_check_exception(c_rate_name || ' up-to-date', sqlerrm, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end check_cisg_tibor_update;


        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG MMKT_Rates HIBOR message check
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2014
        ---------------------------------
        FUNCTION cond_cisg_mmkt_rates_hibor
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF is_day_off (2066, SYSDATE)
            THEN
                l_cond := FALSE;
            ELSE
                IF     SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 06:50',
                           'ddmmyyyy HH24:MI')
                   AND SYSDATE <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 07:10',
                           'ddmmyyyy HH24:MI')
                THEN
                    l_cond := TRUE;
                END IF;
            END IF;

            RETURN l_cond;
        END cond_cisg_mmkt_rates_hibor;

        ---------------------------------
        --Summary:Check if at least 1 MMKT_Rates HIBOR message has been received during the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2014
        ---------------------------------
        PROCEDURE check_cisg_mmkt_rates_hibor
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_mmkt_rates_hibor';
            c_check_title   VARCHAR2 (100)
                                := 'MMKT HIBOR Rates messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.msg_type LIKE 'MMKT_RATES'
                   AND m.id = mi.id
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.text LIKE '%HIHKD%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No MMKT HIBOR rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_mmkt_rates_hibor;


        ---------------------------------
        --Summary:Check if trade date of HIBOR rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:16/07/2014
        ---------------------------------
        PROCEDURE check_cisg_hibor_update
        IS
            c_check_name   VARCHAR2 (100) := 'cisg_hibor_update';
            c_rate_name    VARCHAR2 (50) := 'MMKT HIBOR Rates';
            c_tag_name     VARCHAR2 (50) := 'HIHKD1MD=';
        BEGIN
            --use generic check procedure
            check_generic_rates_update (
                c_check_name,
                c_rate_name,
                c_tag_name,
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 00:00',
                         'ddmmyyyy HH24:MI'),
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 23:59',
                         'ddmmyyyy HH24:MI'));
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_hibor_update;



        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG MMKT_Rates AONIA message check
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2014
        ---------------------------------
        FUNCTION cond_cisg_mmkt_rates_aonia
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF is_day_off (2074, SYSDATE)
            THEN
                l_cond := FALSE;
            ELSE
                IF     SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:00',
                           'ddmmyyyy HH24:MI')
                   AND SYSDATE <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:20',
                           'ddmmyyyy HH24:MI')
                THEN
                    l_cond := TRUE;
                END IF;
            END IF;

            RETURN l_cond;
        END cond_cisg_mmkt_rates_aonia;

        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG MMKT_Rates AONIA message check
        --Parameters:none
        --Author:ADRMEN7
        --Date:08/06/2020
        ---------------------------------

        FUNCTION cond_cisg_mmkt_aonia_AUCASH
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF is_day_off (2074, SYSDATE)
            THEN
                l_cond := FALSE;
            ELSE
                IF     SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 11:20',
                           'ddmmyyyy HH24:MI')
                   AND SYSDATE <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 11:40',
                           'ddmmyyyy HH24:MI')
                THEN
                    l_cond := TRUE;
                END IF;
            END IF;

            RETURN l_cond;
        END cond_cisg_mmkt_aonia_AUCASH;

        ---------------------------------
        --Summary:Check if at least 1 MMKT_Rates AONIA message has been received during the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2014
        ---------------------------------
        PROCEDURE check_cisg_mmkt_rates_aonia
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_mmkt_rates_aonia';
            c_check_title   VARCHAR2 (100)
                                := 'MMKT AONIA Rates messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.msg_type LIKE 'MMKT_RATES'
                   AND m.id = mi.id
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.text LIKE '%AUCASH%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No MMKT AONIA rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_mmkt_rates_aonia;

        ---------------------------------
        --Summary:Check if at least 1 MMKT_Rates AONIA message has been received during the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2014
        ---------------------------------
        PROCEDURE check_cisg_mmkt_aonia_AUCASH
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_mmkt_aonia_AUCASH';
            c_check_title   VARCHAR2 (100)
                := 'MMKT AONIA AUCASH Rates messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.msg_type LIKE 'MMKT_RATES'
                   AND m.id = mi.id
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.text LIKE '%<RIC>AUCASH=RBAA</RIC>%'
                   AND mi.timestamp BETWEEN TO_DATE (
                                                   TO_CHAR (TRUNC (SYSDATE),
                                                            'ddmmyyyy')
                                                || ' 16:45',
                                                'ddmmyyyy HH24:MI')
                                        AND TO_DATE (
                                                   TO_CHAR (TRUNC (SYSDATE),
                                                            'ddmmyyyy')
                                                || ' 18:30',
                                                'ddmmyyyy HH24:MI'); --msg.timestamp is in BDL time

            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No MMKT AONIA AUCASH rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_mmkt_aonia_AUCASH;

        ---------------------------------
        --Summary:Check if trade date of AONIA rates corresponds to the last day
        --Parameters:none
        --Author:CHRBEC
        --Date:26/08/2014
        ---------------------------------
        PROCEDURE check_cisg_aonia_update
        IS
            c_check_name   VARCHAR2 (100) := 'cisg_aonia_update';
            c_rate_name    VARCHAR2 (50) := 'MMKT AONIA Rates';
            c_tag_name     VARCHAR2 (50) := 'AUCASH=RBAA';
        BEGIN
            --use generic check procedure
            check_generic_rates_update (
                c_check_name,
                c_rate_name,
                c_tag_name,
                TO_DATE (
                    TO_CHAR (TRUNC (SYSDATE - 1), 'ddmmyyyy') || ' 00:00',
                    'ddmmyyyy HH24:MI'),
                TO_DATE (
                    TO_CHAR (TRUNC (SYSDATE - 1), 'ddmmyyyy') || ' 23:59',
                    'ddmmyyyy HH24:MI'));
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_aonia_update;


        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG MMKT_Rates HONIA message check
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2014
        ---------------------------------
        FUNCTION cond_cisg_mmkt_rates_honia
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF is_day_off (2066, SYSDATE)
            THEN
                l_cond := FALSE;
            ELSE
                IF     SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:30',
                           'ddmmyyyy HH24:MI')
                   AND SYSDATE <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:50',
                           'ddmmyyyy HH24:MI')
                THEN
                    l_cond := TRUE;
                END IF;
            END IF;

            RETURN l_cond;
        END cond_cisg_mmkt_rates_honia;

        ---------------------------------
        --Summary:Check if at least 1 MMKT_Rates Honia message has been received during the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:20/01/2014
        ---------------------------------
        PROCEDURE check_cisg_mmkt_rates_honia
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_mmkt_rates_honia';
            c_check_title   VARCHAR2 (100)
                                := 'MMKT HONIA Rates messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.msg_type LIKE 'MMKT_RATES'
                   AND m.id = mi.id
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.text LIKE '%HONIA%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No MMKT HONIA rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_mmkt_rates_honia;


        ---------------------------------
        --Summary:Check if trade date of HONIA rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:16/07/2014
        ---------------------------------
        PROCEDURE check_cisg_honia_update
        IS
            c_check_name   VARCHAR2 (100) := 'cisg_honia_update';
            c_rate_name    VARCHAR2 (50) := 'MMKT HONIA Rates';
            c_tag_name     VARCHAR2 (50) := 'HONIA=';
        BEGIN
            --use generic check procedure
            check_generic_rates_update (
                c_check_name,
                c_rate_name,
                c_tag_name,
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 00:00',
                         'ddmmyyyy HH24:MI'),
                TO_DATE (TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 23:59',
                         'ddmmyyyy HH24:MI'));
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_honia_update;

        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG MMKT_Rates CDOR message check
        --Parameters:none
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        FUNCTION cond_cisg_mmkt_rates_cdor_eve
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF is_day_off (2013, SYSDATE)
            THEN
                l_cond := FALSE;
            ELSE
                IF     SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 17:30',
                           'ddmmyyyy HH24:MI')
                   AND SYSDATE <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 17:50',
                           'ddmmyyyy HH24:MI')
                THEN
                    l_cond := TRUE;
                END IF;
            END IF;

            RETURN l_cond;
        END cond_cisg_mmkt_rates_cdor_eve;

        ---------------------------------
        --Summary:Check if at least 1 MMKT_Rates CDOR message has been received during the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        PROCEDURE check_cisg_mmkt_rates_cdor_eve
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_mmkt_rates_cdor';
            c_check_title   VARCHAR2 (100)
                                := 'MMKT CDOR Rates messages received(today)';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.msg_type LIKE 'MMKT_RATES'
                   AND m.id = mi.id
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.text LIKE '%CA6MBAFIX%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No MMKT CDOR rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_mmkt_rates_cdor_eve;


        ---------------------------------
        --Summary:Check if trade date of CDOR (evening) rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:16/07/2014
        ---------------------------------
        PROCEDURE check_cisg_cdor_eve_update
        IS
            c_check_name    VARCHAR2 (100) := 'cisg_cdor_eve_update';
            c_rate_name     VARCHAR2 (50) := 'MMKT CDOR Rates';
            c_tag_name      VARCHAR2 (50) := 'CA1YBAFIX=';
            l_cad_holiday   NUMBER := 0;
            l_check_date    DATE;
        BEGIN
            SELECT COUNT (*)
              INTO l_cad_holiday
              FROM country_day_off
             WHERE country_id = 2013 AND day = TRUNC (SYSDATE);

            IF l_cad_holiday > 0
            THEN
                l_check_date := get_previous_day;
            ELSE
                l_check_date := CURRENT_DATE;
            END IF;

            --use generic check procedure
            check_generic_rates_update (
                c_check_name,
                c_rate_name,
                c_tag_name,
                TO_DATE (
                    TO_CHAR (TRUNC (l_check_date), 'ddmmyyyy') || ' 00:00',
                    'ddmmyyyy HH24:MI'),
                TO_DATE (
                    TO_CHAR (TRUNC (l_check_date), 'ddmmyyyy') || ' 23:59',
                    'ddmmyyyy HH24:MI'));
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_cdor_eve_update;


        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG MMKT_Rates CDOR message check (last night)
        --Parameters:none
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        FUNCTION cond_cisg_mmkt_rates_cdor_mor
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF is_day_off (2013, get_previous_day)
            THEN
                l_cond := FALSE;
            ELSE
                IF     SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 02:00',
                           'ddmmyyyy HH24:MI')
                   AND SYSDATE <
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 02:20',
                           'ddmmyyyy HH24:MI')
                THEN
                    l_cond := TRUE;
                END IF;
            END IF;

            RETURN l_cond;
        END cond_cisg_mmkt_rates_cdor_mor;

        ---------------------------------
        --Summary:Check if at least 1 MMKT_Rates CDOR message has been received during last night
        --Parameters:none
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        PROCEDURE check_cisg_mmkt_rates_cdor_mor
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_mmkt_rates_cdor';
            c_check_title   VARCHAR2 (100)
                := 'MMKT CDOR Rates messages received(last night)';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
            l_sop           DATE;
        BEGIN
            l_sop := get_previous_day;

            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     mi.msg_type LIKE 'MMKT_RATES'
                   AND m.id = mi.id
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.text LIKE '%CA%MBAFIX=%'
                   AND mi.timestamp > TRUNC (l_sop); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_to := upsert_mails (p_to, ';', l_mail_market_it);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No MMKT CDOR rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_mmkt_rates_cdor_mor;

        ---------------------------------
        --Summary:Check if trade date of CDOR (morning) rates corresponds to the previous day
        --Parameters:none
        --Author:CHRBEC
        --Date:16/07/2014
        ---------------------------------
        PROCEDURE check_cisg_cdor_mor_update
        IS
            c_check_name    VARCHAR2 (100) := 'cisg_cdor_mor_update';
            c_rate_name     VARCHAR2 (50) := 'MMKT CDOR Rates';
            c_tag_name      VARCHAR2 (50) := '%CA%MBAFIX=%';
            l_cad_holiday   NUMBER := 0;
            l_check_date    DATE;
        BEGIN
            l_check_date := get_previous_day;

            SELECT COUNT (*)
              INTO l_cad_holiday
              FROM country_day_off
             WHERE country_id = 2013 AND day = TRUNC (l_check_date);

            IF l_cad_holiday > 0
            THEN
                l_check_date := get_previous_day - 1;
            ELSE
                l_check_date := get_previous_day;
            END IF;

            --use generic check procedure
            check_generic_rates_update (
                c_check_name,
                c_rate_name,
                c_tag_name,
                TO_DATE (
                    TO_CHAR (TRUNC (l_check_date), 'ddmmyyyy') || ' 00:00',
                    'ddmmyyyy HH24:MI'),
                  TO_DATE (
                      TO_CHAR (TRUNC (l_check_date), 'ddmmyyyy') || ' 23:59',
                      'ddmmyyyy HH24:MI')
                + 2 / 24);
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_cdor_mor_update;

        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG MMKT_Rates NZIONA message check
        --Parameters:none
        --Author:CHRBEC
        --Date:21/01/2014
        ---------------------------------
        function cond_cisg_mmkt_rates_nziona
        return boolean
        is
            l_cond boolean := false;
        begin

            session#.open_session(i_bu_id=>8);


            if is_day_off(2076, trunc(sysdate-1)) then
                l_cond := false;
            else

                if current_date > to_date(to_char(trunc(current_date),'ddmmyyyy') || ' 18:25', 'ddmmyyyy HH24:MI')
                    and current_date < to_date(to_char(trunc(current_date),'ddmmyyyy') || ' 18:45', 'ddmmyyyy HH24:MI')
                then

                    l_cond := true;

                end if;

            end if;

            return l_cond;

        end cond_cisg_mmkt_rates_nziona;

        ---------------------------------
        --Summary:Check if at least 1 MMKT_Rates NZIONA message has been received during of the CURRENT DAY/ NIGHT
        --Parameters:none
        --Author:CHRBEC,ADRGUS
        --Date:24/06/2025
        ---------------------------------
        procedure check_cisg_mmkt_rates_nziona
        is
            c_check_name varchar2(100) := 'check_cisg_mmkt_rates_nziona';
            c_check_title varchar2(100) := 'MMKT NZIONA Rates messages received(last night)';
            l_cnt number;
            c_min number := 1;
            l_sop date := get_current_day;
        begin

            select count(*) into l_cnt from msg_extl_in mi, msg m
                where mi.msg_type like 'MMKT_RATES'
                    and m.id = mi.id
                    and mi.msg_status_id = 3
                    and m.msg_status_id = 6
                    and mi.text like '%NZCASH=RBNZ%'
                    and not mi.text like '%NC$REF=%'
                    and mi.timestamp > trunc(l_sop); --msg.timestamp is in BDL time

            write_query(c_check_title, l_cnt, c_min, c_blocking_p,'>=', c_check_name);

            if l_cnt < c_min then
                p_to := upsert_mails(p_to, ';', l_mail_cisg_msg);
                p_to := upsert_mails(p_to, ';', l_mail_market_it);
                p_html_pool:= '<br/><b>WARNING for CIC-SG : No MMKT NZIONA rates received</b><br/>' || p_html_pool;
            end if;

        exception
            when others then
                handle_check_exception(c_check_title, sqlerrm, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end check_cisg_mmkt_rates_nziona;

        ---------------------------------
        --Summary:Check if trade date of NZIONA rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:16/07/2014
        ---------------------------------
        procedure check_cisg_nziona_update
        is
            c_check_name varchar2(100) := 'cisg_nziona_update';
            c_rate_name varchar2(50) := 'MMKT NZIONA Rates';
            c_tag_name varchar2(50) := 'NZCASH=RBNZ';

        begin

            check_generic_rates_update(
                c_check_name,
                c_rate_name,
                c_tag_name,
                to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 00:00', 'ddmmyyyy HH24:MI'),
                to_date(to_char(trunc(sysdate),'ddmmyyyy') || ' 23:59', 'ddmmyyyy HH24:MI')
                );

        exception
            when others then
                handle_check_exception(c_rate_name || ' up-to-date', sqlerrm, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        end check_cisg_nziona_update;

        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG M2M FXSW message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_fxsw
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_fxsw;

        ---------------------------------
        --Summary:Check if at least 1 M2M FXSW messages has been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_fxsw
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_fxsw';
            c_check_title   VARCHAR2 (100) := 'M2M FXSwap messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%<Meta_Typ>fxsw%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M FXSW rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_fxsw;


        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG M2M Outright message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_outright
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);


            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_outright;

        ---------------------------------
        --Summary:Check if at least 1 M2M Outright messages has been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_outright
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_outright';
            c_check_title   VARCHAR2 (100)
                                := 'M2M Outright messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%<Meta_Typ>fxtr%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M Outright rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_outright;

        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG M2M Capfloor message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_capfloor
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_capfloor;

        ---------------------------------
        --Summary:Check if at least 1 M2M CAPFLOOR messages has been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_capfloor
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_capfloor';
            c_check_title   VARCHAR2 (100)
                                := 'M2M CapFloor messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%_CNF:%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M CapFloor rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_capfloor;


        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG M2M ACU message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_acu
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_acu;

        ---------------------------------
        --Summary:Check if at least 1 M2M ACU message has been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_acu
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_acu';
            c_check_title   VARCHAR2 (100)
                                := 'M2M ACU/DCU/SLN messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%<key>STRAT:%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M ACU rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_acu;


        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG M2M FXOPT message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_fxopt
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_fxopt;

        ---------------------------------
        --Summary:Check if at least 1 M2M FXOPT messages has been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_fxopt
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_fxopt';
            c_check_title   VARCHAR2 (100) := 'M2M FXOpt messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%<Meta_Typ>fxopt%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M FXOpt rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_fxopt;


        ---------------------------------
        --Summary:Date and timeframe condition for the M2M Bond message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_bond
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_bond;

        ---------------------------------
        --Summary: Check if at least 1 M2M Bond message has been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_bond
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_bond';
            c_check_title   VARCHAR2 (100) := 'M2M Bonds messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%<Obj_Type>asset</Obj_Type>%'
                   AND mi.text NOT LIKE '%_FXO:%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M Bond rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_bond;


        ---------------------------------
        --Summary:Date and timeframe condition for CIC-SG M2M DCI message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_dci
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_dci;

        ---------------------------------
        --Summary:Check if at least 1 M2M DCI messages have been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_dci
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_dci';
            c_check_title   VARCHAR2 (100) := 'M2M DCI messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%<Obj_Type>asset</Obj_Type>%'
                   AND mi.text LIKE '%_FXO:%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M DCI rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_dci;


        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG M2M IRS/CCS message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_irs
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_irs;

        ---------------------------------
        --Summary:Check if at least 2 M2M IRS messages have been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_irs
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_irs';
            c_check_title   VARCHAR2 (100) := 'M2M IRS messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 2;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%<Meta_Typ>irs%'
                   AND mi.text NOT LIKE '%<Meta_Typ>fxsw%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M IRS rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_irs;

        -->Inactive
        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG M2M OPT Bonds message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_opt_bonds
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_opt_bonds;

        -->Inactive
        ---------------------------------
        --Summary:Check if at least 1 M2M OPT Bonds message has been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_opt_bonds
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_opt_bonds';
            c_check_title   VARCHAR2 (100)
                                := 'M2M OPT Bonds messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%<key>VAL_CAP_OPB%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M OPT Bonds rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_opt_bonds;

        -->Inactive
        ---------------------------------
        --Summary:Date and timeframe condition for the CIC-SG M2M OPT Equity message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_opt_eq
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_opt_eq;

        -->Inactive
        ---------------------------------
        --Summary:Check if at least 1 M2M OPT Equity message has been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_opt_eq
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_opt_eq';
            c_check_title   VARCHAR2 (100)
                                := 'M2M OPT Equities messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%<key>VAL_CAP_EQO%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M OPT EQ rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_opt_eq;


        ---------------------------------
        --Summary:Date and timesframe condition for CIC-SG swaption message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_swaption
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);


            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_swaption;

        ---------------------------------
        --Summary:Check if at least 1 M2M Swaption message has been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_swaption
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_swaption';
            c_check_title   VARCHAR2 (100)
                                := 'M2M Swaption messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%<key>VAL_CAP_SWO%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M SWAPTION rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_swaption;


        PROCEDURE check_fx_option_cisg
        IS
            c_check_name    VARCHAR2 (100) := 'check_fx_option_cisg';
            c_check_title   VARCHAR2 (100) := 'FX Options Monitoring CISG';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            l_ligne_fx_option_cisg := '<table>';

            l_ligne_fx_option_cisg :=
                   l_ligne_fx_option_cisg
                || '<tr><td>ID</td><td>POS</td><td>CONT</td><td>ASSET</td><td>ORDER_TYPE</td><td>TOTAL</td></tr>';


            FOR c
                IN (  SELECT MAX (d.id)                       AS max_id,
                             get_obj (d.pos_1_id)             pos,
                             get_obj (d.cont_1_id)            cont,
                             get_obj (d.asset_id)             asset,
                             (SELECT name
                                FROM code_order_type
                               WHERE id = d.order_type_id)    order_type,
                             COUNT (*)                        AS total
                        FROM doc d, evt3 e
                       WHERE     d.meta_typ_id = 25               -- FX Option
                             AND d.id = e.doc_id
                             AND EXISTS
                                     (SELECT 1
                                        FROM doc d2, evt3
                                       WHERE     d2.id = evt3.doc_id
                                             AND evt3.meta_typ_id = 25
                                             AND evt3.done_date =
                                                 lookup_ddic#.date_ ('-1b')
                                             AND d.pos_1_id = d2.pos_1_id)
                             AND e.evt_status_id IN (30, 35)   --done , booked
                             AND bp_1_id <> 12088402 -- inhouse nostro trading fx options
                    GROUP BY d.pos_1_id,
                             d.order_type_id,
                             cont_1_id,
                             asset_id
                      HAVING COUNT (*) > 1
                    ORDER BY d.pos_1_id)
            LOOP
                l_ligne_fx_option_cisg :=
                       l_ligne_fx_option_cisg
                    || '<tr><td>'
                    || c.max_id
                    || '</td><td>'
                    || c.pos
                    || '</td><td>'
                    || c.cont
                    || '</td><td>'
                    || c.asset
                    || '</td><td>'
                    || c.order_type
                    || '</td><td>'
                    || c.total
                    || '</td></tr>';
                fx_option_cisg_count := fx_option_cisg_count + 1;
            END LOOP;


            l_ligne_fx_option_cisg := l_ligne_fx_option_cisg || '</table>';


            write_query (c_check_title,
                         fx_option_cisg_count,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : FX Option Problem</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_fx_option_cisg;


        ---------------------------------
        --Summary:Date and timeframe condition for CIC-SG M2M CDS message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_cds
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_cds;

        ---------------------------------
        --Summary:Check if at least 1 M2M CDS message has been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_cds
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_cds';
            c_check_title   VARCHAR2 (100) := 'M2M CDS messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%_CRE:%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M CDS rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_cds;


        ---------------------------------
        --Summary:Date and timeframe condition for CIC-SG M2M TRS message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_trs
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_trs;

        ---------------------------------
        --Summary:Check if at least 1 M2M TRS message has been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_trs
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_trs';
            c_check_title   VARCHAR2 (100) := 'M2M TRS messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%_EQS:%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M TRS rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_trs;



        ---------------------------------
        --Summary:Date and timeframe condition for CIC-SG M2M FXFWD message check
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_m2m_fxfwd
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 20:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:15',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_m2m_fxfwd;

        ---------------------------------
        --Summary:Check if at least 1 M2M TRS message has been received during the current day
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_m2m_fxfwd
        IS
            c_check_name    VARCHAR2 (100) := 'check_cisg_m2m_fxfwd';
            c_check_title   VARCHAR2 (100) := 'M2M FXFWD messages received';
            l_cnt           NUMBER;
            c_min           NUMBER := 1;
        BEGIN
            SELECT COUNT (*)
              INTO l_cnt
              FROM msg_extl_in mi, msg m
             WHERE     m.id = mi.id
                   AND m.meta_msg_id = 516
                   AND mi.msg_status_id = 3
                   AND m.msg_status_id = 6
                   AND mi.bu_id = 8
                   AND mi.text LIKE '%<Meta_Typ>fxtr%'
                   AND mi.timestamp > TRUNC (SYSDATE); --msg.timestamp is in BDL time


            write_query (c_check_title,
                         l_cnt,
                         c_min,
                         c_blocking_p,
                         '>=',
                         c_check_name);

            IF l_cnt < c_min
            THEN
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : No M2M FXFWD rates received</b><br/>'
                    || p_html_pool;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_m2m_fxfwd;


        ---------------------------------
        --Summary:Date and timeframe condition for SARON check
        --Parameters:
        --Author:CHRBEC
        --Date:04/01/2018
        ---------------------------------
        FUNCTION cond_sora
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF is_day_off (2070, SYSDATE)
            THEN
                l_cond := FALSE;
            ELSIF (    SYSDATE >
                       TO_DATE (
                           TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:10',
                           'ddmmyyyy HH24:MI')
                   AND (SYSDATE <
                        TO_DATE (
                            TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:30',
                            'ddmmyyyy HH24:MI')))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_sora;

        ---------------------------------
        --Summary:Check if trade date of saron (new chftois) rates corresponds to the current day
        --Parameters:none
        --Author:CHRBEC
        --Date:04/01/2018
        ---------------------------------
        PROCEDURE check_sora_update
        IS
            c_check_name   VARCHAR2 (100) := 'sora_update';
            c_rate_name    VARCHAR2 (50) := 'SORA';
            c_tag_name     VARCHAR2 (50) := 'SORA=MAST';
        BEGIN
            IF NOT is_day_off (2070, SYSDATE)
            THEN
                --use generic check procedure
                check_generic_rates_update (
                    c_check_name,
                    c_rate_name,
                    c_tag_name,
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 06:55',
                        'ddmmyyyy HH24:MI'),
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:10',
                        'ddmmyyyy HH24:MI'),
                    i_previous_date        => TRUE,
                    i_previous_date_calc   => 'B',
                    i_country_id           => 2070);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_sora_update;

        ---------------------------------
        --Summary:Check if trade date of SORA-Index rates corresponds to the current day
        --Parameters:none
        --Author:ANNWOJ9
        --Date:04/11/2021
        ---------------------------------
        PROCEDURE check_sora_index_update
        IS
            c_check_name   VARCHAR2 (100) := 'sora_index_update';
            c_rate_name    VARCHAR2 (50) := 'SORA-Index';
            c_tag_name     VARCHAR2 (50) := 'SORA1MAVG=';
        BEGIN
            IF NOT is_day_off (2070, SYSDATE)
            THEN
                --use generic check procedure
                check_generic_rates_update (
                    c_check_name,
                    c_rate_name,
                    c_tag_name,
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 06:55',
                        'ddmmyyyy HH24:MI'),
                    TO_DATE (
                        TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy') || ' 12:10',
                        'ddmmyyyy HH24:MI'),
                    i_previous_date   => FALSE);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_rate_name || ' up-to-date',
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_sora_index_update;

        ---------------------------------
        --Summary:Date and timeframe condition for CIC-SG check for unparsed message errors
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_unparsed_msg
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 06:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:00',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_unparsed_msg;

        ---------------------------------
        --Summary:Check for unparsed/failed messages in MSG_EXTL_IN for CIC-SGP (06/05/2013)
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_unparsed_msg
        IS
            c_check_name   VARCHAR2 (100) := 'unparsed_msg_cicsg';
        BEGIN
            l_nr := 0;
            l_text := '';

            FOR l_msg
                IN (SELECT *
                      FROM msg_extl_in m
                     WHERE     m.msg_status_id IN (SELECT id
                                                     FROM code_msg_status
                                                    WHERE is_err IS NOT NULL)
                           AND m.timestamp > (SYSDATE - 1 / 24 / 4) --msg.timestamp is in server time
                           AND m.bu_id = 8)
            LOOP
                l_nr := l_nr + 1;

                IF l_nr = 1
                THEN                          --no seperator for first element
                    l_text := '' || l_msg.id;
                ELSIF l_nr <= 20
                THEN                               --not more than 20 messages
                    IF MOD (l_nr, 10) = 0
                    THEN                          --linebreak every 10 entries
                        l_text := l_text || ', ' || l_msg.id || CHR (10);
                    ELSE
                        l_text := l_text || ', ' || l_msg.id;
                    END IF;
                ELSIF l_nr = 21
                THEN                           --if more than 20 -> add 3 dots
                    l_text := l_text || '...more';
                END IF;
            END LOOP;

            IF l_nr > 0
            THEN
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : '
                    || l_nr
                    || ' Unparsed messages for BU 8: '
                    || l_text
                    || '</b><br/>'
                    || p_html_pool;
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);


            END IF;

            write_query ('Unparsed messages for CIC-SG (15 minutes)',
                         l_nr,
                         '0',
                         c_major_p,
                         '=',
                         'unparsed_msg_cicsg');
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_name,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END;

        ---------------------------------
        --Summary:Date and timeframe condition for CIC-SG Kondor network check
        --Parameters:none
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_kondor
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            session#.open_session (i_bu_id => 8);

            IF     CURRENT_DATE >
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 06:00',
                       'ddmmyyyy HH24:MI')
               AND CURRENT_DATE <
                   TO_DATE (
                       TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy') || ' 22:00',
                       'ddmmyyyy HH24:MI')
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_cisg_kondor;

        ---------------------------------
        --Summary:Check for errors on netw BDL_KONDOR and NC$KONDOR_CMCIC for CIC-SGP (06/05/2013)
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        PROCEDURE check_cisg_kondor
        IS
            l_doc_status   VARCHAR2 (250);
            c_check_name   VARCHAR2 (100) := 'check_cisg_kondor';
        BEGIN
            l_nr := 0;
            l_text := '';

            FOR l_msg
                IN (SELECT m.id,
                           m.doc_id,
                           s.name     status,
                           n.name     netw
                      FROM msg m, code_netw n, code_msg_status s
                     WHERE     m.msg_status_id IN (SELECT id
                                                     FROM code_msg_status
                                                    WHERE is_err IS NOT NULL)
                           AND m.dir = 'o'
                           AND m.netw_id IN (191, 119)
                           AND m.bu_id = 8
                           AND s.id = m.msg_status_id
                           AND n.id = m.netw_id
                           AND m.timestamp >= (SYSDATE - 1 / 24 / 4)) --msg.timestamp is in server time
            LOOP
                --check for doc
                IF l_msg.doc_id IS NOT NULL
                THEN
                    SELECT s.name
                      INTO l_doc_status
                      FROM doc d, wfc_status s
                     WHERE     d.id = l_msg.doc_id
                           AND s.meta_typ_id = d.meta_typ_id
                           AND s.id = d.wfc_status_id;
                ELSE
                    l_doc_status := 'N/A';
                END IF;

                l_nr := l_nr + 1;

                IF l_nr = 1
                THEN                          --no seperator for first element
                    l_text :=
                           'NETW: '
                        || l_msg.netw
                        || ', MSG: '
                        || l_msg.id
                        || ' STATUS: '
                        || l_msg.status
                        || ' ORDER: '
                        || NVL (l_msg.doc_id, 'N/A')
                        || ' WFC_STATUS: '
                        || l_doc_status;
                ELSIF l_nr <= 20
                THEN                               --not more than 20 messages
                    l_text :=
                           l_text
                        || CHR (10)
                        || ', '
                        || 'NETW: '
                        || l_msg.netw
                        || ', MSG: '
                        || l_msg.id
                        || ' STATUS: '
                        || l_msg.status
                        || ' ORDER: '
                        || NVL (l_msg.doc_id, 'N/A')
                        || ' WFC_STATUS: '
                        || l_doc_status;
                ELSIF l_nr = 21
                THEN                           --if more than 20 -> add 3 dots
                    l_text := l_text || CHR (10) || '...more';
                END IF;
            END LOOP;

            IF l_nr > 0
            THEN
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : '
                    || l_nr
                    || ' Outgoing Message Error for BU 8: '
                    || l_text
                    || '</b><br/>'
                    || p_html_pool;
                p_to := upsert_mails (p_to, ';', l_mail_cisg_msg);

                IF is_prod
                THEN
                    p_to := upsert_mails (p_to, ';', l_mail_operateurs);
                END IF;
            END IF;

            write_query ('Outgoing Kondor Message Errors (15 minutes)',
                         l_nr,
                         '0',
                         c_major_p,
                         '=',
                         'msg_out_error_cicsg');
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_name,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_cisg_kondor;

        ---------------------------------
        --Summary:Activation condition for ndf_option check - only after date switch
        --Parameters:none
        --Author:CHRBEC
        --Date:01/12/2015
        ---------------------------------
        FUNCTION cond_ndf_option_cisg
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF (SYSDATE BETWEEN TO_DATE (
                                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy')
                                    || ' 01:00',
                                    'ddmmyyyy HH24:MI')
                            AND TO_DATE (
                                       TO_CHAR (TRUNC (SYSDATE), 'ddmmyyyy')
                                    || ' 01:20',
                                    'ddmmyyyy HH24:MI'))
            THEN
                l_cond := TRUE;
            END IF;

            RETURN l_cond;
        END cond_ndf_option_cisg;

        ---------------------------------
        --Summary:NDF Option closed on the same day - Sascha Artz - QC 47390
        --Parameters:none
        --Author:CHRBEC
        --Date:01/12/2015
        ---------------------------------
        PROCEDURE check_ndf_option_cisg
        IS
            c_check_name    VARCHAR2 (100) := 'check_ndf_option_cisg';
            c_check_title   VARCHAR2 (100) := 'NDF Options CISG';
            l_cnt           NUMBER;
            c_max           NUMBER := 0;
            l_warning       CLOB;
            l_lines         NUMBER;
            c_max_lines     NUMBER := 10;
        BEGIN
            SELECT COUNT (1)
              INTO l_cnt
              FROM doc, evt3
             WHERE     evt3.doc_id = doc.id
                   AND doc.meta_typ_id = 52
                   AND done_date = lookup_ddic#.date_ ('-1b',
                                                       '-',
                                                       2070,
                                                       NULL)
                   AND doc.order_type_id IN (140472,
                                             140473,
                                             140474,
                                             140481);


            IF l_cnt > c_max
            THEN
                FOR l_entry
                    IN (  SELECT pos_1_id,
                                 LISTAGG (doc.id, '-')
                                     WITHIN GROUP (ORDER BY doc.id)    AS docs
                            FROM doc, evt3
                           WHERE     evt3.doc_id = doc.id
                                 AND doc.meta_typ_id = 52
                                 AND done_date = lookup_ddic#.date_ ('-1b',
                                                                     '-',
                                                                     2070,
                                                                     NULL)
                                 AND doc.order_type_id IN (140472,
                                                           140473,
                                                           140474,
                                                           140481)
                        GROUP BY pos_1_id
                          HAVING COUNT (doc_id) > 1)
                LOOP
                    l_lines := l_lines + 1;

                    l_warning :=
                           l_warning
                        || '<br/>'
                        || l_entry.pos_1_id
                        || ' : '
                        || l_entry.docs;

                    IF l_lines >= c_max_lines
                    THEN
                        l_warning := l_warning || '<br/><b>' || '...more</b>';
                        EXIT;
                    END IF;
                END LOOP;


                p_to := upsert_mails (p_to, ';', l_mail_cisg_fxopt);
                p_html_pool :=
                       '<br/><b>WARNING for CIC-SG : NDF Option Problem</b><br/>'
                    || l_warning
                    || p_html_pool;
            END IF;

            write_query (c_check_title,
                         l_cnt,
                         c_max,
                         c_major_p,
                         '=',
                         c_check_name);
        EXCEPTION
            WHEN OTHERS
            THEN
                handle_check_exception (c_check_title,
                                        SQLERRM,
                                        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        END check_ndf_option_cisg;


        ---------------------------------
        --Summary:Check if Singapore is active - prevent monitoring alerts during holidays etc. Only limit timeframe because of header display
        --Parameters:
        --Author:
        --Date:
        ---------------------------------
        FUNCTION cond_cisg_active
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
            l_cnt    NUMBER;
        BEGIN
            session#.open_session (i_bu_id => 8);

            SELECT COUNT (*)
              INTO l_cnt
              FROM country_day_off
             WHERE     country_id = 2070
                   AND is_bank_day = '+'
                   AND day = TRUNC (CURRENT_DATE);

            IF l_cnt > 0
            THEN
                l_cond := FALSE;
            ELSE
                IF     CURRENT_DATE >
                       TO_DATE (
                              TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy')
                           || ' 06:00',
                           'ddmmyyyy HH24:MI')
                   AND CURRENT_DATE <
                       TO_DATE (
                              TO_CHAR (TRUNC (CURRENT_DATE), 'ddmmyyyy')
                           || ' 23:50',
                           'ddmmyyyy HH24:MI')
                   AND NOT is_weekend
                THEN
                    l_cond := TRUE;
                ELSE
                    l_cond := FALSE;
                END IF;
            END IF;


            RETURN l_cond;
        END cond_cisg_active;

        ---------------------------------
        --Summary:Condition for the hourly report - only send when minutes between 0 and 15 - starting on september 2nd
        --Parameters:none
        --Author:CHRBEC
        --Date:13/08/2013
        ---------------------------------
        FUNCTION cond_hourly_report
            RETURN BOOLEAN
        IS
            l_cond   BOOLEAN := FALSE;
        BEGIN
            IF TO_NUMBER (TO_CHAR (SYSDATE, 'Mi')) < 15
            THEN
                l_cond := TRUE;
            ELSE
                l_cond := FALSE;
            END IF;

            RETURN l_cond;
        END cond_hourly_report;

        ---------------------------------
        --Summary:Send a report to a specific mail - only once per hour - no matter what the status of the report
        --Parameters:none
        --Author:CHRBEC
        --Date:13/08/2013
        ---------------------------------
        PROCEDURE send_hourly_report
        IS
        BEGIN
            p_to := upsert_mails (p_to, ';', l_mail_cisg_hourly_report);
        END send_hourly_report;
    ----------------------------------------------------
    ----------------------------------------------------
    -----------------------MAIN-------------------------
    ----------------------------------------------------
    ----------------------------------------------------
    BEGIN
        IF cond_cisg_active OR c_force_active
        THEN
            ---------
            --START SECTION EURO
            ---------
            write_header ('Asian Functional checks', c_severity_asia_ph);
            g_active_section := c_section_asia;


            write_subheader ('CIC Singapore - Specific Checks for BU 8');


            IF cond_hourly_report OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_SEND_HOURLY_REPORT');
                send_hourly_report;
            END IF;

            IF cond_cisg_kondor OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_KONDOR');
                check_cisg_kondor;
            END IF;

            IF cond_cisg_unparsed_msg OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_UNPARSDED_MSG');
                check_cisg_unparsed_msg;
            END IF;

            IF cond_cisg_mmkt_rates_unparsed OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION (
                    'CHECK_CISG_UNPARSDED_MMKT_RATE');
                check_cisg_mmkt_rates_unparsed;
            END IF;

            IF cond_cisg_forex_morning OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_FOREX_MORNING');
                check_cisg_forex_morning;
            END IF;

            IF cond_cisg_forex_evening OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_FOREX_EVENING');
                check_cisg_forex_evening;
            END IF;

            IF cond_cisg_npv_18h OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_NPV_18H');
                check_cisg_npv_18h;
            END IF;

            IF cond_cisg_npv_21h OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_NPV_21H');
                check_cisg_npv_21h;
            END IF;

            IF cond_cisg_forex_tokyo OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_FOREX_TOKYO');
                check_cisg_forex_tokyo;
            END IF;

            /*
                            if cond_cisg_mmkt_rates_t1 or c_force_active  then
                                DBMS_APPLICATION_INFO.SET_ACTION('CHECK_CISG_MMKT_RATES_T1');
                                check_cisg_mmkt_rates_t1;

                            end if;

                            if cond_cisg_mmkt_rates_t1_task or c_force_active  then
                                DBMS_APPLICATION_INFO.SET_ACTION('CHECK_CISG_MMKT_RATES_T1_TASK');
                                check_cisg_mmkt_rates_t1_task;

                            end if;


                            if cond_cisg_mmkt_rates_t2 or c_force_active  then
                                DBMS_APPLICATION_INFO.SET_ACTION('CHECK_CISG_MMKT_RATES_T2');
                                check_cisg_mmkt_rates_t2;

                            end if;

                            if cond_cisg_mmkt_rates_t2_task or c_force_active  then
                                DBMS_APPLICATION_INFO.SET_ACTION('CHECK_CISG_MMKT_RATES_T2_TASK');
                                check_cisg_mmkt_rates_t2_task;

                            end if;

                            if cond_cisg_mmkt_rates_t3 or c_force_active  then
                                DBMS_APPLICATION_INFO.SET_ACTION('CHECK_CISG_MMKT_RATES_T3');
                                check_cisg_mmkt_rates_t3;

                            end if;

                            if cond_cisg_mmkt_rates_t3_task or c_force_active  then
                                DBMS_APPLICATION_INFO.SET_ACTION('CHECK_CISG_MMKT_RATES_T3_TASK');
                                check_cisg_mmkt_rates_t3_task;

                            end if;

             */
            IF cond_cisg_mmkt_rates_aud OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION (
                    'CHECK_CISG_MMKT_RATES_AUD');
                check_cisg_mmkt_rates_aud;
            END IF;

            IF cond_cisg_mmkt_rates_tonar OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION (
                    'CHECK_CISG_MMKT_RATES_TONAR');
                check_cisg_mmkt_rates_tonar;
                check_cisg_tonar_update;
            END IF;

            IF cond_cisg_mmkt_rates_tibor OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION (
                    'CHECK_CISG_MMKT_RATES_TIBOR');
                check_cisg_mmkt_rates_tibor;
                check_cisg_tibor_update;
            END IF;

            IF cond_cisg_mmkt_rates_hibor OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION (
                    'CHECK_CISG_MMKT_RATES_HIBOR');
                check_cisg_mmkt_rates_hibor;
                check_cisg_hibor_update;
            END IF;

            IF cond_cisg_mmkt_rates_aonia OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION (
                    'CHECK_CISG_MMKT_RATES_AONIA');
                check_cisg_mmkt_rates_aonia;
            END IF;

            IF cond_cisg_mmkt_aonia_AUCASH OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION (
                    'check_cisg_mmkt_aonia_AUCASH');
                check_cisg_mmkt_aonia_AUCASH;
            END IF;

            IF cond_cisg_mmkt_rates_honia OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION (
                    'CHECK_CISG_MMKT_RATES_HONIA');
                check_cisg_mmkt_rates_honia;
                check_cisg_honia_update;
            END IF;

            /* New check CDOR */
            /* check temporarily suspended at request : IOR-85872
            if cond_cisg_mmkt_rates_cdor_mor or c_force_active then
                DBMS_APPLICATION_INFO.SET_ACTION('CHECK_CISG_MMKT_RATES_CDOR_MOR');
                check_cisg_mmkt_rates_cdor_mor;
                check_cisg_cdor_mor_update;

            end if;
            */

            -- only current date pour NZIONA
            IF cond_cisg_mmkt_rates_nziona OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION (
                    'CHECK_CISG_MMKT_RATES_NZIONA');
                check_cisg_mmkt_rates_nziona;
                check_cisg_nziona_update;
            END IF;

            IF cond_cisg_m2m_fxsw OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_M2M_FXSW');
                check_cisg_m2m_fxsw;
            END IF;

            IF cond_cisg_m2m_capfloor OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_M2M_CAPFLOOR');
                check_cisg_m2m_capfloor;
            END IF;

            /*
            if cond_cisg_m2m_acu or c_force_active  then
                DBMS_APPLICATION_INFO.SET_ACTION('CHECK_CISG_M2M_ACU');
                check_cisg_m2m_acu;

            end if;
            */

            IF cond_cisg_m2m_fxopt OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_M2M_FXOPT');
                check_cisg_m2m_fxopt;
            END IF;

            IF cond_cisg_m2m_bond OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_M2M_BOND');
                check_cisg_m2m_bond;
            END IF;

            IF cond_cisg_m2m_dci OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_M2M_DCI');
                check_cisg_m2m_dci;
            END IF;

            IF cond_cisg_m2m_irs OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_M2M_IRS');
                check_cisg_m2m_irs;
            END IF;

            IF cond_cisg_m2m_cds OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_M2M_IRS');
                check_cisg_m2m_cds;
            END IF;



            IF cond_cisg_m2m_trs OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_M2M_IRS');
                check_cisg_m2m_trs;
            END IF;

            IF cond_cisg_m2m_fxfwd OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_M2M_IRS');
                check_cisg_m2m_fxfwd;
            END IF;

            IF cond_ndf_option_cisg OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_NDF_OPTION');
                check_ndf_option_cisg;
            END IF;

            IF cond_sora OR c_force_active
            THEN
                DBMS_APPLICATION_INFO.SET_ACTION ('CHECK_CISG_SORA');
                check_sora_update;
                check_sora_index_update;
            END IF;
        END IF;
    END;

    html_append ('
            </table>
            ');

    IF fx_option_cisg_count > 0
    THEN
        html_append ('
            <br /><br />
            ');

        p_html_pool :=
               '<br/><b>INFORMATION for CISG : Query executed for FX Options - Results at bottom of this email <br/>'
            || p_html_pool;
        html_append (l_ligne_fx_option_cisg);
        p_to := upsert_mails (p_to, ';', l_mail_cisg_fxopt);
    END IF;



    html_append (
           '
            <br />
            <span><b>Script execution time:</b> '
        || timestamp_diff (l_time, SYSTIMESTAMP, TRUE)
        || '</span>
            <br />
            <br />
            <span><b><a href= "'
        || c_documentation_path
        || 'overview.html">Monitoring Documentation Overview</a></b></span>
        </body>
    </html>');

    --text of technical check
    IF p_html_pool = ' '
    THEN
        p_html_pool := p_html_prepool;
    ELSE
        p_html_pool :=
               p_html_pool
            || '<br/><br/><br/><b>--------------------TECHNICAL CHECKS. PLEASE DO NOT CONSIDER THE REST OF THIS EMAIL--------------------</b><br/><br/>'
            || p_html_prepool;
    END IF;

    --replace severity placeholders with a posteriori section severities
    replace_section_severity;


    p_subject :=
           l_db_name
        || ' - '
        || TO_CHAR (l_time, 'DD/MM/YYYY HH24:MI:SS')
        || ' - Automatic Monitoring : '
        || l_status;

    IF l_status = c_nok
    THEN
        CASE l_severity
            WHEN c_none_p
            THEN
                p_subject := p_subject || ' (' || c_none || ')';
            WHEN c_major_p
            THEN
                p_subject := p_subject || ' (' || c_major || ')';
            WHEN c_blocking_p
            THEN
                p_subject := p_subject || ' (' || c_blocking || ')';
            WHEN c_sys_blocking_p
            THEN
                p_subject := p_subject || ' (' || c_sys_blocking || ')';
            ELSE
                p_subject := p_subject || ' (' || c_none || ')';
        END CASE;
    END IF;

    BEGIN
        IF l_db_name LIKE '%AVAPRE%' OR l_db_name LIKE '%AVAMICC%' OR l_db_name LIKE '%AVALIV%'
        THEN
            send_mail (p_to,
                       p_subject,
                       p_html_pool,
                       l_html_temp,
                       l_is_override,
                       l_override_mail);
        ELSE
            send_mail ('nicmal2@blu.bank',
                       'TEST - ' || p_subject,
                       p_html_pool,
                       l_html_temp,
                       l_is_override,
                       l_override_mail);
        END IF;

        write_json_to_spool;

        DBMS_OUTPUT.put_line ('Email was successfully sent');
    EXCEPTION
        WHEN OTHERS
        THEN
            BEGIN
                IF l_db_name LIKE '%AVAPRE%' OR l_db_name LIKE '%AVAMICC%' OR l_db_name LIKE '%AVALIV%'
                THEN
                    send_mail (p_to,
                               p_subject,
                               p_html_pool,
                               l_html_temp,
                               l_is_override,
                               l_override_mail);
                ELSE
                    send_mail ('nicmal2@blu.bank',
                               'TEST - ' || p_subject,
                               p_html_pool,
                               l_html_temp,
                               l_is_override,
                               l_override_mail);
                END IF;

                DBMS_OUTPUT.put_line (
                    'exception(1) -- Exception thrown: ' || SQLERRM);
            END;
    END;
EXCEPTION
    WHEN OTHERS
    THEN
        BEGIN
            IF l_db_name LIKE '%AVAPRE%' OR l_db_name LIKE '%AVAMICC%' OR l_db_name LIKE '%AVALIV%'
            THEN
                send_mail (
                    p_to,
                       l_db_name
                    || ' - '
                    || TO_CHAR (l_time, 'DD/MM/YYYY HH24:MI:SS')
                    || 'TEST TEST TEST --- '
                    || ' - Automatic Monitoring : FAIL',
                       '<font size= "6"><b>MiniMonitor execution failed : '
                    || DBMS_UTILITY.format_error_backtrace
                    || '<br/>'
                    || SQLERRM
                    || '</font></b><br/>p_to: '
                    || p_to
                    || '<br/>'
                    || p_html_pool,
                    l_html_temp,
                    FALSE,
                    '');
            END IF;

            DBMS_OUTPUT.put_line (
                'exception(2) -- Exception thrown: ' || SQLERRM);
        EXCEPTION
            WHEN OTHERS
            THEN
                DBMS_OUTPUT.put_line (SQLERRM);
        END;
END;
/

SPOOL OFF;
