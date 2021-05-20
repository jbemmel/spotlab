# SpotLab
Sets up a virtual lab environment to run Containerlab and SR Linux, using an AWS metal Spot instance.

Using an Ansible script, SpotLab finds the cheapest region matching the hourly price you are willing to pay.
It brings up a CentOS baremetal host using AWS CloudFormation, in a matter of minutes.

## Getting started
1. Run the spotlab Docker container, mounting the current directory as a home volume on the host:

   ```docker run -it --rm -v `pwd`:/home/spotlab:Z eccloud/spotlab```

2. Inside the shell, edit ~/local_settings.yml and insert your AWS credentials:
   
   ```AWS_ACCESS_KEY_ID: "...."```

   ```AWS_SECRET_ACCESS_KEY: "...."```

3. Run ```spotlab_launch_aws_instance -e spotprice=2.50``` -> you get an AWS Spot baremetal instance if available for $2.50/hour or less.

   You can use ```-e altname=myname``` to launch additional labs with different names.

4. SSH to your new lab using the IP address printed in the output. 
   Note that you can see and manage your instance at https://console.aws.amazon.com/cloudformation

## Obtaining and working with container images
Once you get a SpotLab instance up and running, you will likely need to obtain container images. There are various ways to go about this:
1. AWS has private Docker repos available 
2. SpotLab includes an S3 Fuse FS driver that allows you to mount an S3 bucket as storage
