#this file is used to assign variable values based on the needs of the individual deployment

aws_profile  = "terransible"
aws_region   = "us-east-1"
vpc_cidr     = "10.0.0.0/16"
cidrs        = {
    public1  = "10.0.1.0/24"
    public2  = "10.0.2.0/24"
    private1 = "10.0.3.0/24"
    private2 = "10.0.4.0/24"
    rds1     = "10.0.5.0/24"
    rds2     = "10.0.6.0/24"
    rds3     = "10.0.7.0/24"
}
localip      = "34.222.180.57/32"
#change based on what is currently being used in the AWS account
#do not add .com or anything...
domain_name  = "cmcloudlab1744"
#make sure this is within allowed classes
db_instance_class = "db.t2.micro"
dbname = "superherodb"
dbuser = "superhero"
#bad password heeeeere
dbpassword = "superheropass"
#make sure this is compatible with LA labs
dev_instance_type = "t2.micro"
#look this up in AWS console for us-east-1
dev_ami = "ami-0ff8a91507f77f867"
#ssh keygen public key generated earlier in the lab
public_key_path = "/root/.ssh/kryptonite.pub"
key_name = "kryptonite"
elb_healthy_threshold = "2"
elb_unhealthy_threshold = "2"
elb_timeout = "3"
elb_interval = "30"
lc_instance_type = "t2.micro"
asg_max = "2"
asg_min = "1"
asg_grace = "300"
#health check type to ensure instance is running
asg_hct = "EC2"
#desired capacity
asg_cap = "2"
#pulled from the results of the route53 command ID field
delegation_set_id = "N2KEP9FNH4G9M8"
