import boto3
import json
from decimal import Decimal
from datetime import datetime
from dateutil.relativedelta import relativedelta
import xlsxwriter

now = datetime.now() + relativedelta( months=-1 )
month_report=str(now.strftime("%B"))
workbook = xlsxwriter.Workbook(month_report+'_Costs.xlsx')
worksheet = workbook.add_worksheet()
client = boto3.client('ce')

now = datetime.now()
init = now + relativedelta( months=-1 )
date_init=str(init.year)+"-"+str(init.strftime("%m"))+"-"+"01"
date_end=str(now.year)+"-"+str(now.strftime("%m"))+"-"+"01"

response = client.get_cost_and_usage(
    TimePeriod={
        'Start': date_init,
        'End': date_end
    },
    Granularity='MONTHLY',
    Filter={
        "Dimensions": { "Key": "REGION", "Values": ["us-east-1","us-east-2","us-west-1","us-west-2"] }
    },
    Metrics=[
        'UnblendedCost',
    ],
    GroupBy=[
	{
            'Type': 'TAG',
            'Key': 'Application Name'
        },
        {
            'Type': 'TAG',
            'Key': 'Owner'
        }
    ]
)
data = response['ResultsByTime'][0]['Groups']
owners = []
for element in data:
     owners.append(element['Keys'][1])

#print json.dumps(data, indent=4)
aux=set(owners)
# here we create bold format object .
bold = workbook.add_format({'bold': 1})
# create a data list .
headings = ['Cost Per Service', 'Service Aws', 'Owner', 'Total Por Owner(USD)']
# Write in row
worksheet.write_row('A1', headings, bold)

row=1
for owner in aux:
    print owner.strip('Owner$')
    sum_usd=0
    for content in data:
        if content['Keys'][1] == owner:
            col = 0
            cost_usd=content['Metrics']['UnblendedCost']['Amount']
            service_name=content['Keys'][0]
            worksheet.write(row, col, Decimal(cost_usd) )
            worksheet.write(row, col + 1, str(service_name))
            worksheet.write(row, col + 2, owner.strip('Owner$'))
            sum_usd=Decimal(cost_usd) + sum_usd
            row += 1
    worksheet.write(row - 1, 3 ,round(Decimal(sum_usd),4))
workbook.close()