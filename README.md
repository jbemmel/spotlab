# SpotLab
Sets up a virtual lab environment to run Containerlab and SR Linux, using an AWS metal Spot instance.

Using an Ansible script, SpotLab finds the cheapest region matching the hourly price you are willing to pay.
It brings up a CentOS baremetal host using AWS CloudFormation, in a matter of minutes.

## Getting started
1. Run the spotlab Docker container, mounting a home volume on the host:

   ```docker run -it --rm -v /home/spotlab:/home/spotlab:Z eccloud/spotlab```

2. Inside the shell, edit ~/local_settings.yml and insert your AWS credentials

3. Run ```spotlab_launch_aws_instance``` -> you get an AWS Spot baremetal instance

4. SSH to your new lab using the IP address printed in the output

## Obtaining and working with container images
Once you get SpotLab up and running, you will likely need to obtain container images. There are various ways to go about this:
1. AWS has private Docker repos available 
2. SpotLab includes an S3 Fuse FS driver that allows you to mount an S3 bucket as storage
