import boto3
import ast
import sys

regions_amazon = ast.literal_eval(sys.argv[1])
country_chile = ast.literal_eval(sys.argv[2])

def get_ids(regions):
    ec2=[]
    ec2client = boto3.client('ec2',region_name=str(regions))
    response = ec2client.describe_instances()
    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            ec2.append(instance["InstanceId"])

    return ec2

def describe_instance(id_instance, each_inst):
    ids=[]

    ids.append(id_instance)
    for eni_id in each_inst['NetworkInterfaces']:
        ids.append(eni_id['NetworkInterfaceId'])

    for volumes_id in each_inst['BlockDeviceMappings']:
        ids.append(volumes_id['Ebs']['VolumeId'])

    for sg_ids in each_inst['SecurityGroups']:
        ids.append(sg_ids['GroupId'])

    return ids

def tag_lb(regions,id_instance,is_nac,tag_delete):
    lb_client = boto3.client('elb',region_name=str(regions))
    lb_response = lb_client.describe_load_balancers()
    for lb in lb_response['LoadBalancerDescriptions']:
        if len(lb['Instances']) > 0 and lb['Instances'][0]['InstanceId'] == id_instance:
            print "tag loadbalancer "+str(lb['LoadBalancerName'])
            if is_nac:
                lb_client.add_tags(
                    LoadBalancerNames=[str(lb['LoadBalancerName'])],
                    Tags=[{
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
                    Tags=[{
                        'Key': 'ApplicationName',
                        'Value': str(tag_delete[0]['Value'].replace("ML Recommender","ML").upper().strip(''))
                    },
                    {
                        'Key': 'Country',
                        'Value': 'REGIONAL'
                    }]
                )

def main(regions_amazon,country_chile):

    for regions in regions_amazon:

        ec2client = boto3.client('ec2',region_name=str(regions))
        response = ec2client.describe_instances()

        print "Working in "+regions
        ec2_list=[]
        ec2_list=get_ids(regions)

        for index in  get_ids(regions):
            response2 = ec2client.describe_instances(InstanceIds=[str(index)])
            for each_res in response2['Reservations']:
                for each_inst in each_res['Instances']:
                    is_nac=False
                    ids_tag=[]
                    tag_delete=[]
                    ids_tag=describe_instance(index, each_inst)
                    if each_inst['State']['Name'] != 'terminated':
                        for each_tag in each_inst['Tags']:
                            for country in country_chile:
                                if country == each_tag['Value'].upper().strip(''):
                                    is_nac=True

                            if each_tag['Key'] == 'Application Name' or each_tag['Key'] == 'ApplicationName'  and len(ids_tag) >= 1:
                                print " instance ID "+str(index)+" Tag id's:\n"
                                print ids_tag
                                print "\n"
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
                                tag_lb(regions,index,is_nac,tag_delete)
                                if tag_delete[0]['Key'] == 'Application Name':
                                    response = ec2client.delete_tags(
                                    Resources=ids_tag,
                                    Tags=tag_delete
                                    )

if __name__ == '__main__':
    main(regions_amazon,country_chile)