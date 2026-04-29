EKS Corp
This task will simulate the needs of an imagines company. Multiple resources will be needed.

Task:
EKS and related
Run any web application or applications from an EKS cluster.
The images are gained from a private ECR.
When you configure the eks node group then select appropriate instance sizes (not too small).
Set up appropriate scaling for your node groups
Configure your node groups for high availability. (Multy AZ)
Configure EKS addons to solve automatic EBS provisioning, loadbalancing, high availability secure limited entry points to your cluster.
Deploy at least one application in your cluster.
You may chose to also deploy a database inside of the cluster but the task will alter ask you to have managed database instances.
Configure appropriate AWS permissions for your instances. Use pod identity.

AWS database
Configure a high availability aws managed database and connect to them from your backend servers inside of your EKS (remember aws permissions)

[OPTIONAL TASKS]
These are optional tasks but you are encouraged to do them at a certain point.

Company S3
Set up a company S3 bucket with appropriate permissions.
Create AWS policies to access the bucket or specific folders of the bucket. (Use your imagination here, if you need someone to help brainstorming then send me a message 🙂 )
Make sure that your backend servers can upload to and download from your bucket. S3 bucket access is done through a backend server acting as a middle man.

Terraform backend
In a dedicated S3 bucket store your terraform state and use it as backend, use it together with DynamoDB.
AWS Automation
Set up automations in AWS to run specific AWS Lambda functions to create a service check where it calls the health endpoint of your servers and collects some metadata from your S3 bucket (any kind) and assembles a report that gets saved to a specific folder in your S3.
Make a dedicated policy just for this.

Cheap static website
Use Cloudfront with your S3 to serve a cheap static website, independent from your other work.

BACKEND
If you are coming from a developer branch then you can make an application rather than a single endpoint node server.
You may want to explore the language/tech stack native AWS SDK for a bit. Up to you.
And lets be serious, stop making these shallow games ha ha, make an HR app or some management software with appropriate authentication and everything.