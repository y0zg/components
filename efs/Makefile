.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= efs
DOMAIN_NAME    ?= dev.stacks.delivery
STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1

export AWS_PROFILE        ?= default
export AWS_DEFAULT_REGION ?= us-east-2
export TF_LOG             ?= info
export TF_LOG_PATH        ?= .terraform/$(DOMAIN_NAME).log
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update

export TF_VAR_name             := $(COMPONENT_NAME)
export TF_VAR_performance_mode ?= generalPurpose
export TF_VAR_cname_zone       ?= i.$(DOMAIN_NAME)
export TF_VAR_cname_record     ?= nfs
# export TF_VAR_aws_az           ?=
export TF_VAR_subnet_id        ?=
export TF_VAR_sgs              ?=

terraform ?= terraform
TFPLAN ?= .terraform/$(COMPONENT_NAME).tfplan

deploy: init plan apply

init:
	@mkdir -p .terraform
	$(terraform) init -get=true $(TF_CMD_OPTS) -reconfigure -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(DOMAIN_NAME)/efs/$(COMPONENT_NAME)/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)"
.PHONY: init

get:
	$(terraform) get $(TF_UPDATE)
.PHONY: get

plan:
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=$(TFPLAN)
.PHONY: plan

apply:
	$(terraform) apply $(TF_OPTS) -Xshadow=false $(TFPLAN)
.PHONY: apply

undeploy: init
	$(MAKE) plan TF_OPTS=-destroy
	$(MAKE) apply
.PHONY: undeploy