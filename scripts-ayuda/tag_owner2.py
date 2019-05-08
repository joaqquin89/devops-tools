import boto3
import ast
import sys

regions_amazon = ast.literal_eval(sys.argv[1])

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

def tag_lb(regions,id_instance,owner_name):
    lb_client = boto3.client('elb',region_name=str(regions))
    lb_response = lb_client.describe_load_balancers()
    for lb in lb_response['LoadBalancerDescriptions']:
        if len(lb['Instances']) > 0 and id_instance in lb['Instances'][0]['InstanceId']:
            print "tag loadbalancer "+str(lb['LoadBalancerName'])
            lb_client.add_tags(
                LoadBalancerNames=[str(lb['LoadBalancerName'])],
                Tags=[
                {
                    'Key': 'Owner',
                    'Value': str(owner_name[0])
                }]
            )

def main(regions_amazon):

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
                    owner_name=[]
                    ids_tag=describe_instance(index, each_inst)
                    if each_inst['State']['Name'] != 'terminated':
                        for each_tag in each_inst['Tags']:
                            if each_tag['Key'] == 'Owner' and len(ids_tag) >= 1:
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
                                tag_lb(regions,index,owner_name)

if __name__ == '__main__':
    main(regions_amazon)