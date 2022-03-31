.PHONY: verify_tekton_pipelines_available prepare_general_pipeline verify-argocd-available
.PHONY: prepare prepare-ibm-catalog pipeline_commonservices  set-entitlement-key run_pipeline_commonservices set_namespace prepare_github_credentials
.PHONY: install_es_operator install_mq_operator install_apic_operator output_details

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
		QUERY="{.items[0].status.phase}"; \
		sleep 30 ; \
		OPERATORSTATUS=""; \
		while [ "$$OPERATORSTATUS" != "Complete" ]; do \
			OPERATORSTATUS=$$(oc get installplan -n openshift-operators -l operators.coreos.com/$$OPERATORNAME.openshift-operators -o jsonpath="$$QUERY"); \
			echo $$OPERATORSTATUS; \
			sleep 90 ; \
		done; \
	else \
		echo $$OPERATORNAME "Installed"; \
	fi


# command definitions for cicd
# -------------------------------
CICD_NS = rt-inventory-cicd
verify_tekton_pipelines_available:
	@echo "-----------------------------------------------------------------"	
	@echo "Installing pipelines operator and dedicated project for pipelines"
	@echo "-----------------------------------------------------------------"
	@$(call ensure_operator_installed,"openshift-pipelines-operator","./bootstrap/openshift-pipelines-operator")
	@oc apply -k ./bootstrap/pipelines/00-common/cicd
	@oc apply -k ./bootstrap/pipelines/00-common/tasks
	@oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.5/git-clone.yaml -n $(CICD_NS)
	@oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/maven/0.2/maven.yaml -n $(CICD_NS)

verify-argocd-available:
	@$(call ensure_operator_installed,"openshift-gitops-operator","./bootstrap/openshift-gitops-operator")

set_argo_project:
	@oc apply -k bootstrap/argocd-project

output_argo:
	@echo "Argo admin credential"
	@oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
	@echo "Argo admin console url"
	@oc get route openshift-gitops-server -o jsonpath='{.status.ingress[].host}'  -n openshift-gitops

prepare_general_pipeline: verify_tekton_pipelines_available prepare_github_credentials verify-argocd-available set_argo_project

prepare_github_credentials: 
	@oc apply -f ./github-credentials.yaml

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

# Different operators used in the solution 
# ----------------------
install_es_operator:
	@$(call ensure_operator_installed,"ibm-eventstreams","./bootstrap/ibm-eventstreams")

install_mq_operator:
	@$(call ensure_operator_installed,"ibm-mq","./bootstrap/ibm-mq")

install_apic_operator:
	@$(call ensure_operator_installed,"ibm-apiconnect","./bootstrap/ibm-apiconnect")

prepare: prepare_general_pipeline  set-entitlement-key prepare-ibm-catalog 

install_cp4i_operators: pipeline_commonservices install_es_operator install_mq_operator install_apic_operator

start_argocd_apps:
	@oc apply -k ./config/argocd

DEV_NS = rt-inventory-dev
start_mq_source:
	@oc apply -f environments/rt-inventory-dev/apps/mq-source/kafka-mq-src-connector.yaml -n $(DEV_NS)

start_cos_sink:
	@oc apply -f environments/rt-inventory-dev/apps/cos-sink/kafka-cos-sink-connector.yaml -n $(DEV_NS)

all: prepare install_cp4i_operators start_argocd_apps

output_details:
	@echo "Install complete.\n\n"
	@echo "Openshift admin credential"
	@oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
	@echo "\nMQ Console console url"
	@oc get route store-mq-ibm-mq-web -o jsonpath='{.status.ingress[].host}'  -n $(DEV_NS)
	@echo "\n\nEvent Streams Console console url"
	@oc get route dev-ibm-es-ui -o jsonpath='{.status.ingress[].host}'  -n $(DEV_NS)
	@echo "\n\nStore simulator url\n"
	@oc get route store-simulator -o jsonpath='{.status.ingress[].host}'  -n $(DEV_NS)