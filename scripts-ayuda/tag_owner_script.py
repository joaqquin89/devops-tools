import boto3
import ast
import sys

regions_amazon = ast.literal_eval(sys.argv[1])

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
        owner_name=[]
        flag=False
        id_ec2=index
        for each_res in response2['Reservations']:
            for each_inst in each_res['Instances']:
                ids_tag=[]
                for eni_id in each_inst['NetworkInterfaces']:
                    ids_tag.append(eni_id['NetworkInterfaceId'])

                for volumes_id in each_inst['BlockDeviceMappings']:
                    ids_tag.append(volumes_id['Ebs']['VolumeId'])

                for sg_ids in each_inst['SecurityGroups']:
                    ids_tag.append(sg_ids['GroupId'])

                for each_tag in each_inst['Tags']:
                    if each_tag['Key'] == 'Owner' and len(ids_tag) >= 1:
                        flag=True
                        print "Per owner "+str(each_tag['Value'] )+" instance ID "+str(index)+" Tag id's:\n"
                        print ids_tag
                        print "\n"
                        owner_name.append(each_tag['Value'])
                        response = ec2client.create_tags(
                            Resources=ids_tag,
                            Tags = [{
                                'Key': 'Owner',
                                'Value': str(owner_name[0])
                            }]
                        )
        if flag:
            for lb in lb_response['LoadBalancerDescriptions']:
                if len(lb['Instances']) > 0 and id_ec2 in lb['Instances'][0]['InstanceId']:
                    lb_client.add_tags(
                        LoadBalancerNames=[str(lb['LoadBalancerName'])],
                        Tags=[
                        {
                            'Key': 'Owner',
                            'Value': str(owner_name[0])
                        }]
                    )