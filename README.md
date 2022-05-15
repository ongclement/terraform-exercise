<h1>Terraform Exercise</h1>

<h3>Description:</h3>

The following terraform file performs the following actions:

1. Start up a VPC service in `ap-southeast-1` region with CIDR `10.9.0.0/16` along with 2 subnets in `ap-southeast-1a` & `ap-southeast-1b` availability zones.
2. Configure 2 EC2 instances, residing within each subnet, each attached to an EBS volume mounted to `/data` path.
3. Start up nginx in each instance and serving a static webpage with content: `Hello`.
4. Configure an Application Load Balancer for the 2 instances with traffic going into port 80.

<h3>Setup:</h3>

To run this terraform document, you need to perform the following actions:

1. Sign up for an account on AWS.
2. Go to EC2 service dashboard and access `Key Pairs` in the side-menu on the left.
3. Create new key pair and name it `ec2-pvt-key`, select `RSA` key pair type and `.pem` key file format.
4. Save the `.pem` file into the `/keys` directory of this repository.
5. Run the following command to generate a public key with your private key.

    ``` 
        ssh-keygen -y -f keys/ec2-pvt-key.pem > keys/ec2-key.pub
    ```

6. Go to your AWS dashboard and access `Security Credentials` in the account menu on the top right
7. Expand the `Access keys` dropdown menu and create a new access key
8. Run the following commands to add your `ACCESS_KEY` and `SECRET_KEY` into environment variables.
    ```
        export TF_VAR_ACCESS_KEY= <YOUR ACCESS KEY>
        export TF_VAR_SECRET_KEY= <YOUR SECRET KEY>
    ```

9. You are required to initialize a working directory containing Terraform configuration files if you have never done it before.
    ```angular2html
        terraform init
    ```
10. Start up the configured AWS services with the following command
    ```angular2html
        terraform apply
    ```
    
11. To teardown the services

    ```angular2html
        terraform destroy
    ```


<h1>Troubleshooting</h1>


**Error Message:**
```
    WARNING: UNPROTECTED PRIVATE KEY FILE!
```
- This error occurs because your private key file allows anyone to have read and write access. To resolve this, change the permissionos of your private key file with the command below
    ```angular2html
        sudo chmod 600 /keys/ec2-pvt-key.pem
    ```
