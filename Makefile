centos:
	docker build -t crunchy-pg -f Dockerfile.centos7 .
	docker tag -f crunchy-pg:latest crunchydata/crunchy-pg
rhel:
	docker build -t crunchy-pg -f Dockerfile.rhel7 .
	docker tag -f crunchy-pg:latest crunchydata/crunchy-pg

