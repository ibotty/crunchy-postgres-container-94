
### Openshift Secrets Example
This example shows how the Openshift secrets functionality can
be used to store and keep secret a set of postgres user id and passwords.

This example lets the user decide what passwords they want to use
instead of using system generated passwords as done in the other
examples.

This set of instructions was tested on the binary version of
Origin 1.1.0 on centos 7.

To run the example, first create a set of secrets that hold the
various postgres user ID and passwords used in the examples:
~~~~~~~~~~~
oc secrets new-basicauth pgroot --username=postgres --password=postgrespsw
oc secrets new-basicauth pgmaster --username=master --password=masterpsw
oc secrets new-basicauth pguser --username=testuser --password=somepassword
~~~~~~~~~~~

These secrets are used by the pg-standalone-secret pod to use
as the postgres authentication strings.  Create the example pod
as follows:
~~~~~~~~~~~
cd crunchy-postgresql-container-94/openshift
oc login
oc process -f standalone-secret.json | oc create -f -
~~~~~~~~~~~

This example, mounts the secrets into the containers /pgsecrets directory.
The start.sh script will pull a username and password from this directory if
exists and use it to populate the postgres database.

You should have a secret, running pod, and service:

~~~~~~~~~~~
oc get pods
oc get services
oc get secrets
~~~~~~~~~~~

Test the container by logging into the postgresql database:
~~~~~~~~~
psql -h serviceIP -U testuser userdb
~~~~~~~~~
