.PHONY: verify_tekton_pipelines_available prepare_general_pipeline verify-argocd-available
.PHONY: prepare prepare-ibm-catalog pipeline_commonservices  set-entitlement-key run_pipeline_commonservices set_namespace
.PHONY: output_details

# integration from Dale Dane work
#
# Reusable functions

wait_for_pipelinerun = \
	PIPELINERUN=$1; \
	echo "$$PIPELINERUN"; \
	STATUS="Running"; \
	while [ $$STATUS = "Running" ]; do \
		oc wait $$PIPELINERUN --for=condition=Succeeded --timeout=30m; \
		STATUS=$$(oc get $$PIPELINERUN -o jsonpath='{.status.conditions[0].reason}'); \
	done; \
	if [ "$$STATUS" != "Succeeded" ]; \
	then \
		echo "$$PIPELINERUN failed"; \
		exit 1; \
	fi

ensure_operator_installed = \
	OPERATORNAME=$1; \
	OPERATORINSTALLER=$2; \
	ISOPERATORINSTALLED=$$(oc get subscription -n openshift-operators  -o go-template='{{len .items}}' --field-selector metadata.name=$$OPERATORNAME); \
	if [ $$ISOPERATORINSTALLED -eq 0 ]; \
	then \
		oc apply -k $$OPERATORINSTALLER ; \
		QUERY="{.items[?(@.metadata.ownerReferences[0].name==\"$$OPERATORNAME\")].status.phase}"; \
		sleep 30 ; \
		OPERATORSTATUS=""; \
		while [ "$$OPERATORSTATUS" != *"Complete"* ]; do \
			OPERATORSTATUS=$$(oc get installplan -n openshift-operators -o jsonpath="$$QUERY"); \
			@/bin/echo -n ".."; \
			sleep 90 ; \
		done; \
	else \
		echo $$OPERATORNAME "Installed"; \
	fi


# command definitions
# -------------------------------
CICD_NS = rt-inventory-cicd
verify_tekton_pipelines_available:
	@echo "-----------------------------------------------------------------"	
	@echo "Installing pipelines operator and dedicated project for pipelines"
	@echo "-----------------------------------------------------------------"
	@$(call ensure_operator_installed,"openshift-pipelines-operator","./bootstrap/openshift-pipelines-operator")
	@oc apply -k ./bootstrap/pipelines/00-common/cicd
	@oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.5/git-clone.yaml -n $(CICD_NS)
	@oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/maven/0.2/maven.yaml -n $(CICD_NS)

verify-argocd-available:
	@$(call ensure_operator_installed,"openshift-gitops-operator","./bootstrap/openshift-gitops-operator")


prepare_general_pipeline: verify_tekton_pipelines_available verify-argocd-available

set_namespace:
	@oc project $(CICD_NS)

# IBM subscriptions
# -----------------

set-entitlement-key:
	@oc create secret docker-registry ibm-entitlement-key --docker-username=cp --docker-server=cp.icr.io --namespace=openshift-operators --docker-password=$(KEY)

prepare-ibm-catalog:
	@echo "------------------------------------------------------------"
	@echo "Installing the IBM Catalog into the cluster..."
	@echo "------------------------------------------------------------"
	@oc apply -f https://raw.githubusercontent.com/ibm-cloud-architecture/eda-gitops-catalog/main/ibm-catalog/catalog-source.yaml

# CP4I specifics
# --------------
prepare_pipeline_commonservices:
	@oc apply -f ./bootstrap/pipelines/00-common/pipelines/cp4i.yaml
	@oc apply -f ./bootstrap/pipelines/00-common/operands/cp4i-overrides-cm.yaml

run_pipeline_commonservices:
	@echo "------------------------------------------------------------"
	@echo "Configuring IBM Common Services..."
	@echo "------------------------------------------------------------"
	@$(call wait_for_pipelinerun,$(shell oc create -f ./bootstrap/pipelines/00-common/pipelines/pipelinerun.yaml -o name))

pipeline_commonservices: set_namespace prepare_pipeline_commonservices run_pipeline_commonservices

prepare: prepare_general_pipeline  set-entitlement-key prepare-ibm-catalog output_details


output_details:
	@echo "Install complete.\n\n"