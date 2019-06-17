.DEFAULT_GOAL := deploy


KUBECTL_ARGS 		:= --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
kubectl 			?= kubectl $(KUBECTL_ARGS)
export NAMESPACE 	?= rook-ceph
CEPH_DASHBOARD_ROLE ?= admin-no-iscsi
CEPH_DASHBOARD_USER ?= admin
CEPH_DASHBOARD_PASS ?= 12345678
TIMEOUT     		?= 600

deploy: install config_dashboard

undeploy: unistall delete_data

install:
	- $(kubectl) create namespace $(NAMESPACE)
	- $(kubectl) create -f rbac.yaml
	- $(kubectl) create -f ceph-operator.yaml
	- $(kubectl) create -f ceph-cluster.yaml
	- $(kubectl) create -f ceph-blockdevice.yaml
	- $(kubectl) create -f ceph-toolbox.yaml
	- $(kubectl) create -f ingress.yaml
	- $(MAKE) wait_up

unistall:
	- $(kubectl) delete -f ingress.yaml
	- $(kubectl) delete -f ceph-blockdevice.yaml
	- $(kubectl) delete -f ceph-toolbox.yaml
	- $(kubectl) delete -f ceph-cluster.yaml
	- $(kubectl) delete -f ceph-operator.yaml
	- $(kubectl) delete ds rook-discover
	- $(kubectl) delete ds rook-ceph-agent
	- $(kubectl) delete -f rbac.yaml
	- $(MAKE) wait_shutdown

delete_data:
	- $(kubectl) create -f cleanup.yaml
	sleep 10
	- $(kubectl) delete -f cleanup.yaml

config_dashboard:
	@ echo "Configure CEPH dashboard"
	$(eval ceph_toolbox=$(shell $(kubectl) get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}'))
	- $(kubectl) exec -it $(ceph_toolbox) -- bash -c "ceph dashboard ac-role-create $(CEPH_DASHBOARD_ROLE)"
	@ for scope in dashboard-settings log rgw prometheus grafana nfs-ganesha manager hosts rbd-image config-opt rbd-mirroring cephfs user osd pool monitor; do \
		$(kubectl) exec -it $(ceph_toolbox) -- bash -c "ceph dashboard ac-role-add-scope-perms $(CEPH_DASHBOARD_ROLE) $${scope} create delete read update"; \
	done
	- $(kubectl) exec -it $(ceph_toolbox) -- bash -c "ceph dashboard ac-user-set-roles admin $(CEPH_DASHBOARD_ROLE)"
	- $(kubectl) exec -it $(ceph_toolbox) -- bash -c "ceph dashboard ac-user-set-password $(CEPH_DASHBOARD_USER) $(CEPH_DASHBOARD_PASS)"

ceph_tools:
	- $(kubectl) exec -it $(shell $(kubectl) get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash

wait_up:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval count=$(shell $(kubectl) get pods --no-headers --output=json -l 'app=rook-ceph-agent' --output=json | jq -M '.items[0].spec.containers | length'))
	$(eval get_pod=$(kubectl) get pods --no-headers -l 'app=rook-ceph-osd' --output=jsonpath='{.items..containerStatuses[?(@.ready==true)].containerID}')
	@ echo "Waiting for ceph osd pod up and running [container count: $(count)]"

	@ while [ `date +%s` -le "$(timeout)" ]; do \
		if [[ `$(get_pod) | wc -w | xargs` -ge '$(count)' ]]; then \
			echo " done"; \
			exit 0; \
		fi; \
		printf "."; \
		sleep 8; \
	done; \
	echo " ERROR timeout $(TIMEOUT)sec"; \
	exit 1

wait_shutdown:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval get_pod=$(kubectl) get pods --no-headers -l 'app=rook-ceph-agent' --output=json)
	@ echo "Waiting for ceph manager pod to terminate"

	@ while [ `date +%s` -le "$(timeout)" ]; do \
		if [[ -z `$(get_pod) | jq -c '.items[].spec.containers'` ]]; then \
			echo " done"; \
			exit 0; \
		fi; \
		printf "."; \
		sleep 8; \
	done; \
	echo " ERROR timeout $(TIMEOUT)sec"; \
	exit 1