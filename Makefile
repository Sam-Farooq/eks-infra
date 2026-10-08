ENV ?= staging

.PHONY: fmt lint validate plan apply bootstrap
fmt:       ; terraform fmt -recursive
lint:      ; tflint --recursive && trivy config --config trivy.yaml .
validate:  ; terraform -chdir=envs/$(ENV) init -backend=false && terraform -chdir=envs/$(ENV) validate
plan:      ; terraform -chdir=envs/$(ENV) init && terraform -chdir=envs/$(ENV) plan
apply:     ; terraform -chdir=envs/$(ENV) apply
bootstrap: ; ./scripts/bootstrap-cluster.sh $(ENV)
