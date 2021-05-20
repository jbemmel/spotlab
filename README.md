# spot-lab
Sets up a virtual lab environment to run Containerlab and SR Linux, using an AWS metal instance

## Getting started
1. Run the spotlab Docker container:
```docker run -it --rm eccloud/spot-lab```

It will output a suitable commandline for running the container

2. Copy&paste the commandline suggested by SpotLab -> you get a Docker shell

3. Edit ~/local_settings.yml and insert your AWS credentials

4. Run ```spotlab_deploy``` -> you get an AWS Spot baremetal instance

5. SSH to your new lab using the IP address printed in the output

## Obtaining and working with container images
Once you get SpotLab up and running, you will need to obtain container images. There are various ways to go about this:
1. AWS has private Docker repos available 
2. SpotLab includes an S3 Fuse FS driver that allows you to mount an S3 bucket as storage
