Crunchy PostgreSQL 9.4.5
==========================

This project includes a Dockerfile that lets you build
a PostgreSQL 9.4.5 Docker image.  The image by default
is built on a RHEL 7.2 64 bit base, but can also be built
on a centos 7 64 bit base.  NOTICE, to build the RHEL 7 
version of this container, you need to build the Docker
container on a licensed RHEL 7 host!

Installation
------------

Builds are done by issuing the make command:
~~~~~~~~~~~~~~~~~~~~~
make
~~~~~~~~~~~~~~~~~~~~~
 

Running PostgreSQL in Standalone Mode
------------

To run the Crunchy PostgreSQL container (crunchy-pg) on Openshift, see
the document docs/openshift-setup-nodes.md for complete details
and instructions.  The container has now been updated to run
in a master-slave replication configuration as well as standalone.

To create the Docker container, you will need to have
PostgreSQL installed on your local machine.  This is 
due to the requirement of setting the data directory
ownership to the postgres user and also you will need
the psql command to test the container.

To install PostgreSQL locally, run the following:
~~~~~~~~~~~~~~~~~~~~~
sudo rpm -Uvh http://yum.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-redhat94-9.4-1.noarch.rpm
sudo yum -y install postgresql94-server postgresql94
~~~~~~~~~~~~~~~~~~~~~

Run the container with this command:
~~~~~~~~~~~~~~~~~~~~~
./run-pg.sh
~~~~~~~~~~~~~~~~~~~~~

This script will start up a container named crunchy-pg, it will
create a data directory for the database in /tmp/crunchy-pg-data.

It will initialize the database using the passed in environment
variables, building a user, database, schema, and table based
on the environment variable values.

The script also maps the PostgreSQL port of 5432 in the container
to your local host port of 12000.

You can adjust the following Postgres configuration parameters
by setting environment variables:
~~~~
MAX_CONNECTIONS - defaults to 100
SHARED_BUFFERS - defaults to 128MB
TEMP_BUFFERS - defaults to 8MB
WORK_MEM - defaults to 4MB
MAX_WAL_SENDERS - defaults to 6
~~~~

Overriding Postgres Configuration Files
---------------------------------------

You have the ability to override the pg_hba.conf and postgresql.conf
files used by the container.  To enable this, you create a 
directory to hold your own copy of these configuration files.

Then you mount that directory into the container using the /pgconf
volume mount as follows:

~~~~~~~
-v $YOURDIRECTORY:/pgconf
~~~~~~~

Inside YOURDIRECTORY would be your pg_hba.conf and postgresql.conf
files.  These files are not manipulated or changed by the container
start scripts.

Connecting to  PostgreSQL
------------

The container creates a default database called 'testdb', a default
user called 'testuser' with a default password of 'testpsw', you can
use this to connect from your local host as follows:
~~~~~~~~~~~~~~~~~~~~~
psql -h localhost -p 12000 -U testuser -W testdb
~~~~~~~~~~~~~~~~~~~~~


Shutting Down 
------------

To shut down the instance, run the following commands:

~~~~~~~~~~~~~~~~~~~~~
docker stop crunchy-pg
~~~~~~~~~~~~~~~~~~~~~
	

To start the instance, run the following commands:

~~~~~~~~~~~~~~~~~~~~~
docker start crunchy-pg
~~~~~~~~~~~~~~~~~~~~~
	
Running PostgreSQL in Master-Slave Configuration
------------
The container can be passed environment variables that will cause
it to assume a PostgreSQL replication configuration with 
a master instance streaming to a slave replica instance.

The following env variables are specified for this configuration option:
~~~~~~~~~~~~~~~~~~~
PG_MASTER_USER - The username used for master-slave replication value=master
PG_MASTER_PASSWORD - The password for the PG master user
PG_USER - The username that clients will use to connect to PG server value=user
PG_PASSWORD  - The password for the PG master user
PG_DATABASE - The name of the database that will be created value=userdb
PG_ROOT_PASSWORD - The password for the PG admin
~~~~~~~~~~~~~~~~~~~

For running this master-slave configuration outside of Openshift, you can
run the following scripts:
~~~~~~
run-pg-master.sh
run-pg-replica.sh
~~~~~~

Modify the run-pg-replica.sh script to include the Docker assigned IP address of the master
container.

This set of scripts will create a single master that replicates to a single standby database.


### DNS

To run the crunchy-pg container outside of Openshift, and when you
want a master-slave configuration, you would pass in suitable values
for these env variables when you run the container and you will
need a Docker-DNS bridge similar to what Crunchy PostgreSQL Manager
uses, skybridge.  

See these for more details:
~~~~~~~~~~~~~~~~~~~~~~~~~~
https://github.com/CrunchyData/crunchy-postgresql-manager
https://github.com/CrunchyData/skybridge
~~~~~~~~~~~~~~~~~~~~~~~~~~

DNS names are used within the PostgreSQL replication configuration
whereas the slave can find the master by hostname instead of IP address.
Openshift includes a DNS-to-Docker bridge for you.



# crunchy-pg on Openshift
crunchy-pg is a container image that allows you to run
PostgreSQL 9.4.5 within Openshift.

There are 4 possible scenarios that are included in this
repository:
- standalone (emptydir volume)
- master-slave (emptydir volumes, one master and one slave)
- master-slave using replication controllers (emptydir volumes)
- standalone (nfs volume)


## Openshift Configuration

This example uses Openshift/Kube EmptyDir volumes to hold 
the PostgreSQL data files.

At the moment, to run this example in Selinux Enforcing mode, 
there is a slight bug in the selinux labels
on the Openshift /var/lib/openshift directory.  As root
you will need to run the following command to set the selinux
labels to the correct values:
~~~~~~~~~~~~~~~~~
chcon -Rt svirt_sandbox_file_t /var/lib/openshift
~~~~~~~~~~~~~~~~~

This is being tracked with an Openshift github issue.

https://github.com/openshift/origin/issues/3989

## Finding the Postgresql Passwords

The passwords used for the PostgreSQL user accounts are generated
by the Openshift 'process' command.  To inspect what value was
supplied, you can inspect the master pod as follows:

~~~~~~~~~~~~~~~
oc get pod pg-master-rc-1-n5z8r -o json
~~~~~~~~~~~~~~~

Look for the values of the environment variables:
- PG_USER
- PG_PASSWORD
- PG_DATABASE

## DNS Names

This example used an Openshift project name of 'pgproject'.  The
project name is used as part of the DNS names set by Openshift
for Services.  

## standalone.json

This openshift template will create a single PostgreSQL instance.

### Running the example

~~~~~~~~~~~~~~~~
oc create -f standalone.json | oc create -f -
~~~~~~~~~~~~~~~~

Then in the running standalone pod, you can run the following
command to test the database:

~~~~~~~~~~~~~~
psql -h pg-standalone.pgproject.svc.cluster.local -U testuser userdb
~~~~~~~~~~~~~~


## master-slave.json

This openshift template will create a single master PostgreSQL instance
and a single slave instance, configured for streaming replication.

### Running the example

~~~~~~~~~~~~~~~~
oc create -f master-slave.json | oc create -f -
~~~~~~~~~~~~~~~~

Then in the running standalone pod, you can run the following
command to test the database:

~~~~~~~~~~~~~~
psql -h pg-master.pgproject.svc.cluster.local -U testuser userdb
psql -h pg-slave.pgproject.svc.cluster.local -U testuser userdb
~~~~~~~~~~~~~~

## master-slave-rc.json

This openshift template will create a single master PostgreSQL instance
and a single slave instance, configured as a Replication Controller, allowing
you to scale up the number of slave instances.

### Running the example

~~~~~~~~~~~~~~~~
oc create -f master-slave-rc.json | oc create -f -
~~~~~~~~~~~~~~~~

Connect to the PostgreSQL instances with the following:

~~~~~~~~~~~~~~
psql -h pg-master-rc.pgproject.svc.cluster.local -U testuser userdb
psql -h pg-slave-rc.pgproject.svc.cluster.local -U testuser userdb
~~~~~~~~~~~~~~

## Scaling up Slaves
Here is an example of increasing or scaling up the Postgres 'slave'
pods to 2:
~~~~~~~~~~
oc scale rc pg-slave-rc-1 --replicas=2
~~~~~~~~~~

## Verify Postgresql Replication is Working

Enter the following commands to verify the PostgreSQL 
replication is working.

First, find the pods:

~~~~~~~~~~~~~~~~
[root@origin openshift]# oc get pods
NAME                      READY     STATUS    RESTARTS   AGE
docker-registry-1-vrli4   1/1       Running   1          6h
pg-master-rc-1-n5z8r      1/1       Running   0          15m
pg-slave-rc-1-4gsfo       1/1       Running   0          15m
pg-slave-rc-1-f1rlo       1/1       Running   0          11m
~~~~~~~~~~~~~~~~~

Next, exec into the master pod:

~~~~~~~~~~~~~~~~~~~~~
[root@origin openshift]# oc exec -it pg-master-rc-1-n5z8r /bin/bash

~~~~~~~~~~~~~~~~~~~~~~~

Next, run the psql command to view the replication status, you
should see something similar to this output, in this example 
we are replicating database state to 2 pods:

~~~~~~~~~~~~~~~~~
bash-4.2$ psql -U postgres postgres
psql (9.4.5)
Type "help" for help.

postgres=# select * from pg_stat_replication;
 pid | usesysid | usename | application_name | client_addr | client_hostname | client_port |         backend_start         | backend_xmin |   state   | sent_location | write_location | flush_location | replay_location | sync_priority | sync_state 
 -----+----------+---------+------------------+-------------+-----------------+-------------+-------------------------------+--------------+-----------+---------------+----------------+----------------+-----------------+---------------+------------
   86 |    16384 | master  | walreceiver      | 172.17.0.11 |                 |       34522 | 2015-07-26 20:26:39.688865-04 |              | streaming | 0/5000210     | 0/5000210      | 0/5000210      | 0/5000210       |             0 | async
    130 |    16384 | master  | walreceiver      | 172.17.0.13 |                 |       37211 | 2015-07-26 20:30:41.29627-04  |              | streaming | 0/5000210     | 0/5000210      | 0/5000210      | 0/5000210       |             0 | async
    (2 rows)
~~~~~~~~~~~~~~~~~


## NFS Example

I have provided an example of using NFS for the postgres data volume.
The NFS example is able to run in selinux Enforcing mode if you 
following the instructions here:

https://github.com/openshift/origin/tree/master/examples/wordpress

To run it, you would execute the following as the openshift administrator:

~~~~~~~~~~~~~~~
oc create -f pv.json
~~~~~~~~~~~~~~~

Then as the normal openshift user account, create the Persistence Volume
Claim as follows:
~~~~~~~~~~~~~~~
oc create -f pvc.json
~~~~~~~~~~~~~~~

Lastly,  as the normal openshift user account, create the standalone
pod which specifies the NFS PVC:
~~~~~~~~~~~~~~~
oc process -f standalone-nfs.json | oc create -f -
~~~~~~~~~~~~~~~

This will create a single standalone postgres pod that is using 
an NFS volume to store the postgres data files.

