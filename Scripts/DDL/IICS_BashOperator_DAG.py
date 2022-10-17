
#Start Code

import airflow
from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from datetime import datetime, timedelta
from airflow.operators.dummy_operator import DummyOperator


# these args will get passed on to each operator
# you can override them on a per-task basis during operator initialization
default_args = {
'owner': 'infa',
'depends_on_past': False,
'email': ['deepbhattacharyya@deloitte.com'],
'email_on_failure': False,
'email_on_retry': False,
'retries': 1,
'retry_delay': timedelta(minutes=1),
'start_date': datetime(2022,2,18)
}

dag = DAG(
'IICS_Airflow_Stats_DAG',
default_args=default_args,
schedule_interval=None,
description='A simple Informatica IICS DAG')

# Printing start date and time of the DAG

t1 = BashOperator(
task_id='run_IICS_Taskflowtest_Airflow',
bash_command='/home/deepbhattacharyya/airflow_env/runAJobCli/cli.sh runAJobCli -t TASKFLOW -un Taskflowtest_Airflow',
dag=dag)


t2 = BashOperator(
task_id='run_IICS_Process',
depends_on_past=False,
bash_command='curl -k --netrc-file /home/deepbhattacharyya/creds.netrc https://use4-cai.dm-us.informaticacloud.com/active-bpel/rt/TaskflowInfaAudit-2?tfname=Tf_test',
dag=dag)


t3 = BashOperator(

   task_id='cdi_end',
   bash_command='curl -k --netrc-file /home/deepbhattacharyya/creds.netrc https://use4-cai.dm-us.informaticacloud.com/active-bpel/rt/TaskflowInfaAudit-2?tfname=Taskflowtesting',
   dag=dag)

t4 = BashOperator(

   task_id='cdi_end_new',
   bash_command='curl -k --netrc-file /home/deepbhattacharyya/creds.netrc https://use4-cai.dm-us.informaticacloud.com/active-bpel/rt/TaskflowInfaAudit-2?tfname=Taskflowtest',
   dag=dag)




t1 >> t2 >> t3 >> t4

 

 

# End code