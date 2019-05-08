import boto3
import ast
import sys

regions_amazon = ast.literal_eval(sys.argv[1])
country_chile = ast.literal_eval(sys.argv[2])

for regions in regions_amazon:
    print "Working in "+regions
    ec2_list=[]
    ec2client = boto3.client('ec2',region_name=str(regions))
    response = ec2client.describe_instances()
    lb_client = boto3.client('elb',region_name=str(regions))
    lb_response = lb_client.describe_load_balancers()


    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            ec2_list.append(instance["InstanceId"])

    for index in ec2_list:
        response2 = ec2client.describe_instances(InstanceIds=[str(index)])
        for each_res in response2['Reservations']:
            for each_inst in each_res['Instances']:
                flag=False
                is_nac=False
                tag_delete=[]
                ids_tag=[]
                ids_tag.append(index)
                for eni_id in each_inst['NetworkInterfaces']:
                    ids_tag.append(eni_id['NetworkInterfaceId'])

                for volumes_id in each_inst['BlockDeviceMappings']:
                    ids_tag.append(volumes_id['Ebs']['VolumeId'])

                for sg_ids in each_inst['SecurityGroups']:
                    ids_tag.append(sg_ids['GroupId'])

                for each_tag in each_inst['Tags']:
                    if each_tag['Key'] == 'Application Name' or each_tag['Key'] == 'ApplicationName'  and len(ids_tag) >= 1:
                        print " instance ID "+str(index)+" Tag id's:\n"
                        print ids_tag
                        print "\n"
                        for country in country_chile:
                            if country == each_tag['Value'].upper().strip(''):
                                is_nac=True
                        flag=True
                        if is_nac:
                            tag_delete.append(each_tag)
                            response = ec2client.create_tags(
                                Resources=ids_tag,
                                Tags = [{
                                    'Key': 'ApplicationName',
                                    'Value': str(each_tag['Value'].replace("ML Recommender","ML").upper().strip(''))
                                    },
                                    {
                                    'Key': 'Country',
                                    'Value': 'CHILE'
                                    },
                                    ]
                            )
                        else:
                            tag_delete.append(each_tag)
                            response = ec2client.create_tags(
                                Resources=ids_tag,
                                Tags = [{
                                    'Key': 'ApplicationName',
                                    'Value': str(each_tag['Value'].replace("ML Recommender","ML").upper().strip(''))
                                    },
                                    {
                                    'Key': 'Country',
                                    'Value': 'REGIONAL'
                                    }]
                            )

                if flag:
                    print "Tag a Eliminar"
                    print tag_delete
                    for lb in lb_response['LoadBalancerDescriptions']:
                        if len(lb['Instances']) > 0 and lb['Instances'][0]['InstanceId'] == index:
                            if is_nac:
                                lb_client.add_tags(
                                    LoadBalancerNames=[str(lb['LoadBalancerName'])],
                                    Tags=[
                                        {
                                            'Key': 'ApplicationName',
                                            'Value': str(tag_delete[0]['Value'].replace("ML Recommender","ML").upper().strip(''))
                                        },
                                        {
                                            'Key': 'Country',
                                            'Value': 'CHILE'
                                        }]
                                )
                            else:
                                lb_client.add_tags(
                                        LoadBalancerNames=[str(lb['LoadBalancerName'])],
                                        Tags=[
                                            {
                                                'Key': 'ApplicationName',
                                                'Value': str(tag_delete[0]['Value'].replace("ML Recommender","ML").upper().strip(''))
                                            },
                                            {
                                                'Key': 'Country',
                                                'Value': 'REGIONAL'
                                            }]
                                    )

                    if tag_delete[0]['Key'] == 'Application Name':
                        response = ec2client.delete_tags(
                        Resources=ids_tag,
                        Tags=tag_delete
                        )