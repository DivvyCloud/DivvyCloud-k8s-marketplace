TAG ?= 18

include marketplace-k8s-app-tools/crd.Makefile
include marketplace-k8s-app-tools/gcloud.Makefile
include marketplace-k8s-app-tools/marketplace.Makefile
include marketplace-k8s-app-tools/app.Makefile
include marketplace-k8s-app-tools/var.Makefile

APP_DEPLOYER_IMAGE ?= $(REGISTRY)/marketplace/divvycloud/deployer:$(TAG)
NAME ?= divvycloud
$(info ---- APP_DEPLOYER_IMAGE = $(APP_DEPLOYER_IMAGE))
APP_PARAMETERS ?= { "name" :  "$(NAME)", "namespace": "$(NAMESPACE)","imageName": "$(REGISTRY)/marketplace/divvycloud:$(TAG)" }

TESTER_IMAGE ?= $(REGISTRY)/marketplace/divvycloud/tester:$(TAG)
APP_TEST_PARAMETERS ?= { \
  "tester.image": "$(TESTER_IMAGE)" \
}


app/build:: .build/divvycloud/deployer \
		    .build/divvycloud/divvycloud \
			.build/divvycloud/tester 

.build/divvycloud: | .build
	$(call print_target, $@)
	mkdir -p "$@"

.build/divvycloud/tester:
	$(call print_target, $@)
	docker pull cosmintitei/bash-curl
	docker tag cosmintitei/bash-curl "$(TESTER_IMAGE)"
	docker push "$(TESTER_IMAGE)"
	@touch "$@"


.build/divvycloud/deployer: k8s-helm-chart/divvycloud/* k8s-helm-chart/divvycloud/templates/* deployer/* .build/marketplace/deployer/helm .build/var/APP_DEPLOYER_IMAGE .build/var/REGISTRY .build/var/TAG | .build/divvycloud
	$(call print_target, $@)
	docker build \
	    --build-arg REGISTRY="$(REGISTRY)" \
	    --build-arg TAG="$(TAG)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	docker push "$(APP_DEPLOYER_IMAGE)"

	@touch "$@"


# Simulate building of primary app image. Actually just copying public image to
# local registry.
.build/divvycloud/divvycloud: .build/var/REGISTRY \
                    .build/var/TAG \
                    | .build/divvycloud
	$(call print_target, $@)
	docker pull divvycloud/divvycloud:latest
	docker tag divvycloud/divvycloud:latest "$(REGISTRY)/marketplace/divvycloud:$(TAG)"
	docker push "$(REGISTRY)/marketplace/divvycloud:$(TAG)"
	@touch "$@"





.PHONY: cluster/create
 cluster/create:
	$(call print_target, $0)
	scripts/create_cluster.sh

.PHONY: cluster/delete
 cluster/delete:
	$(call print_target, $0)
	scripts/destroy_cluster.sh
