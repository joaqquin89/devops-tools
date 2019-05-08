import boto3
import json
from decimal import Decimal
from datetime import datetime
from dateutil.relativedelta import relativedelta
import xlsxwriter

now = datetime.now() + relativedelta( months=-1 )
month_report=str(now.strftime("%B"))
workbook = xlsxwriter.Workbook(month_report+'_Costs.xlsx')
worksheet_per_service = workbook.add_worksheet("Costs Per Service Production")
worksheet_per_app = workbook.add_worksheet("Costs Per Aplication Production")
client = boto3.client('ce')

now = datetime.now()
init = now + relativedelta( months=-1 )
date_init=str(init.year)+"-"+str(init.strftime("%m"))+"-"+"01"
date_end=str(now.year)+"-"+str(now.strftime("%m"))+"-"+"01"
sum_total_per_owner=[]
sum_total_per_owner2=[]
projects_chile=['FORECAST','NRT','GO2CLOUD','FOLLOW']

response = client.get_cost_and_usage(
    TimePeriod={
        'Start': date_init,
        'End': date_end
    },
    Granularity='MONTHLY',
    #Filter={
    #    "Dimensions": { "Key": "REGION", "Values": ["us-east-1","us-east-2","us-west-1","us-west-2"] }
    #},
    Metrics=[
        'UnblendedCost',
    ],
    GroupBy=[
	{
            'Type': 'DIMENSION',
            'Key': 'SERVICE'
        },
        {
            'Type': 'TAG',
            'Key': 'Owner'
        }
    ]
)

response2 = client.get_cost_and_usage(
    TimePeriod={
        'Start': date_init,
        'End': date_end
    },
    Granularity='MONTHLY',
    #Filter={
    #    "Dimensions": { "Key": "REGION", "Values": ["us-east-1","us-east-2","us-west-1","us-west-2"] }
    #},
    Metrics=[
        'UnblendedCost',
    ],
    GroupBy=[
	{
            'Type': 'TAG',
            'Key': 'ApplicationName'
        },
        {
            'Type': 'TAG',
            'Key': 'Owner'
        }
    ]
)

def getOwners(input_response):
    data = input_response['ResultsByTime'][0]['Groups']
    owners = []
    for element in data:
        owners.append(element['Keys'][1].upper().replace("OWNER$",'').replace('RRR','RR').strip(' '))
    owners.remove('FRANCISCO')
    owners.remove('MARCO DE LIMA')
    return set(owners)

#CREATE SHEET PER SERVICE

# here we create bold format object .
bold = workbook.add_format({'bold': 1})
# create a data list .
per_service = ['Cost Per Service', 'Service Aws', 'Owner']
# Write in row
worksheet_per_service.write_row('A1', per_service, bold)

aux = getOwners(response)
row=1
sum_total=0
for owner in aux:
    sum_per_owner=0
    total_per_owner=[]
    for content in response['ResultsByTime'][0]['Groups']:

        if content['Keys'][1].upper().replace('OWNER$','').replace('RRR','RR').strip(' ')  == 'FRANCISCO':
            content['Keys'][1]='FRANCISCO SINNING'

        if content['Keys'][1].upper().replace('OWNER$','').replace('RRR','RR').strip(' ')  == 'MARCO DE LIMA':
            content['Keys'][1]='MARCOS DE LIMA'

        if content['Keys'][1].upper().replace('OWNER$','').replace('RRR','RR').strip(' ') == owner:
            col = 0
            cost_usd=content['Metrics']['UnblendedCost']['Amount']
            service_name=content['Keys'][0]
            owner_name=owner
            if owner == "":
                owner_name="NO TAG"

            worksheet_per_service.write(row, col, Decimal(cost_usd) )
            worksheet_per_service.write(row, col + 1, str(service_name))
            worksheet_per_service.write(row, col + 2, owner_name )
            sum_per_owner=Decimal(cost_usd) + sum_per_owner
            row += 1

    total_per_owner.append(round(Decimal(sum_per_owner),4))
    total_per_owner.append(owner_name)
    sum_total_per_owner.append(total_per_owner)
    ## sum total in usd for month
    if owner_name != "NO TAG":
        sum_total=Decimal(sum_per_owner) + sum_total



# here we create bold format object .
bold = workbook.add_format({'bold': 2})
# create a data list .
per_service = ['Cost Per Owner', 'Owner Name']
# Write in row
worksheet_per_service.write_row('F6', per_service, bold)

## TOTAL PER OWNER AND TOTAL MONTH

#print "TOTAL DEL MES:"
#print str(sum_total)
sum_total_per_owner.sort(reverse=True)
cont1 = 0
cont2 = 0
cont3 = 0
fila=7
NO_TAG_PRICE=0
while(cont1 < len(sum_total_per_owner)):
    column=5
    while(cont2 < len(sum_total_per_owner[cont1])):
        cont3=cont2 + 1
        worksheet_per_service.write(fila, column , sum_total_per_owner[cont1][cont2] )
        worksheet_per_service.write(fila, column + 1 , sum_total_per_owner[cont1][cont3] )
        if sum_total_per_owner[cont1][cont3] == "NO TAG":
            NO_TAG_PRICE=Decimal(sum_total_per_owner[cont1][cont2])
        cont3=0
        fila += 1
        cont2 = cont2+2
    cont1 = cont1+1
    cont2 = 0

##.-----------------------------------------------------
###PUT TOTAL MONTH PER OWNER

# here we create bold format object .
bold = workbook.add_format({'bold': 1})
# create a data list .
per_app = ['Owner', ' Producto', str(month_report) , '%' , 'No Tag Cross','Total + No tag Cross' ]
# Write title
worksheet_per_app.write_row('A1', per_app, bold)


aux2=getOwners(response2)
# here we create bold format object
row2=1
for content2 in response2['ResultsByTime'][0]['Groups']:
    sum_usd2=0
    total_per_owner2=[]
    col2=0
    for owner2 in aux2:

        if content2['Keys'][1].upper().replace('OWNER$','').replace('RRR','RR').strip(' ')  == 'FRANCISCO':
            content2['Keys'][1]='FRANCISCO SINNING'

        if content2['Keys'][1].upper().replace('OWNER$','').replace('RRR','RR').strip(' ')  == 'MARCO DE LIMA':
            content2['Keys'][1]='MARCOS DE LIMA'

        if content2['Keys'][1].upper().replace('OWNER$','').replace('RRR','RR').strip(' ') == owner2:
            col = 0
            cost_usd2=content2['Metrics']['UnblendedCost']['Amount']
            app_name=content2['Keys'][0].upper().replace('APPLICATION NAME$','').strip(' ')
           
            owner_name2=owner2
            
            if owner_name2 == "":
                owner_name2="NO OWNER TAG"
            if app_name == "":
                app_name="NO APP TAG"
            sum_usd2=Decimal(cost_usd2) + sum_usd2
            row2=row2+1
            print app_name+" - "+owner_name2

    PERCENT_PER_TOTAL=(sum_usd2/sum_total) * 100
    NO_TAG_CROSS=(NO_TAG_PRICE * PERCENT_PER_TOTAL) / 100
    NO_TAG_CROSS_TOTAL=sum_usd2 + NO_TAG_CROSS

    worksheet_per_app.write(row2, col2, owner_name2 )
    worksheet_per_app.write(row2, col2 + 1, app_name)
    worksheet_per_app.write(row2, col2 + 2, round(Decimal(cost_usd2),4))
    worksheet_per_app.write(row2, col2 + 3, round(Decimal(PERCENT_PER_TOTAL),2)) 
    worksheet_per_app.write(row2, col2 + 4, round(Decimal(NO_TAG_CROSS),2 ))
    worksheet_per_app.write(row2, col2 + 5, round(Decimal(NO_TAG_CROSS_TOTAL),2 ))
    total_per_owner2.append(owner_name2)
    total_per_owner2.append(app_name)
    total_per_owner2.append(round(Decimal(sum_usd2),4))
    sum_total_per_owner2.append(total_per_owner2)



workbook.close()