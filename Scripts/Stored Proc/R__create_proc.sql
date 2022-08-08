CREATE OR REPLACE PROCEDURE SNOWFLAKE_CI_CD_POC.CI_CD_DEMO.CICD_POC()
RETURNS string
LANGUAGE JAVASCRIPT
AS
$$
    var sql1 = "create table ci_cd_demo.CICD_dummy1 (name string,date datetime)";
    var statement1 = snowflake.createStatement({sqlText: sql1});
    var result1 = statement1.execute();
 
$$ 
;
