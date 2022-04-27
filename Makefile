.PHONY: verify_tekton_pipelines_available prepare_general_pipeline verify-argocd-available
.PHONY: prepare prepare-ibm-catalog pipeline_commonservices  set-entitlement-key run_pipeline_commonservices set_namespace prepare_github_credentials
.PHONY: install_es_operator install_mq_operator install_apic_operator output_details

# Setting global variables
CICD_NS = rt-inventory-cicd
DEV_NS = rt-inventory-dev
ES_VERSION = v10.5
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
verify_tekton_pipelines_available:
	@echo "-----------------------------------------------------------------"	
	@echo "Installing pipelines operator and dedicated project for pipelines"
	@echo "-----------------------------------------------------------------"
	@$(call ensure_operator_installed,"openshift-pipelines-operator","./bootstrap/openshift-pipelines-operator")

apply_tekton_tasks:
	@oc apply -k ./bootstrap/pipelines/00-common/cicd
	@oc apply -k ./bootstrap/pipelines/00-common/tasks
	@oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.5/git-clone.yaml -n $(CICD_NS)
	@oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/maven/0.2/maven.yaml -n $(CICD_NS)

verify_argocd:
	@$(call ensure_operator_installed,"openshift-gitops-operator","./bootstrap/openshift-gitops-operator")

set_argo_project:
	@oc apply -k bootstrap/argocd-project

output_argo:
	@echo "Argo admin credential"
	@oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
	@echo "Argo admin console url"
	@oc get route openshift-gitops-server -o jsonpath='{.status.ingress[].host}'  -n openshift-gitops

prepare_general_pipeline: verify_tekton_pipelines_available \
	create_cicd_project \
	prepare_github_credentials \
	verify_argocd \
	set_argo_project

prepare_github_credentials: 
	@oc apply -f ./github-credentials.yaml

create_cicd_project:
	@oc new-project $(CICD_NS)

set_namespace:
	@oc project $(CICD_NS)

# IBM subscriptions
# -----------------

set_entitlement_key:
	@oc create secret docker-registry ibm-entitlement-key --docker-username=cp --docker-server=cp.icr.io --namespace=openshift-operators --docker-password=$(KEY)

prepare_ibm_catalog:
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


# -------------------------------------------------------
# Entry points
# -------------------------------------------------------
prepare: prepare_general_pipeline  set_entitlement_key prepare_ibm_catalog 

all: prepare install_cp4i_operators start_argocd_apps

install_cp4i_operators: pipeline_commonservices install_es_operator install_mq_operator install_apic_operator

# Different operators used in the solution 
# ----------------------
install_nav_operator:
	@$(call ensure_operator_installed,"ibm-integration-platform-navigator","./bootstrap/ibm-integration-platform-navigator")

install_es_operator:
	@$(call ensure_operator_installed,"ibm-eventstreams","./bootstrap/ibm-eventstreams")

install_mq_operator:
	@$(call ensure_operator_installed,"ibm-mq","./bootstrap/ibm-mq")

install_apic_operator:
	@$(call ensure_operator_installed,"ibm-apiconnect","./bootstrap/ibm-apiconnect")

start_argocd_apps:
	@oc apply -k ./config/argocd

clean_argocd_apps:
	@oc delete -k ./config/argocd


start_mq_source:
	@oc apply -f environments/rt-inventory-dev/apps/mq-source/kafka-mq-src-connector.yaml -n $(DEV_NS)

start_cos_sink:
	@oc apply -f environments/rt-inventory-dev/apps/cos-sink/kafka-cos-sink-connector.yaml -n $(DEV_NS)

# ---------------------------------------------------------------
# assume CoC environment with CP4I already installed. 
# Use rt-inventory-dev namespace, event streams in cp4i-eventstreams
# ---------------------------------------------------------------
mt_prepare_ns:
	@oc apply -k ./environments/multi-tenancy/rt-inventory-dev/
	@oc project rt-inventory-dev

mt_eventstreams_config:
	@oc apply -k ./environments/multi-tenancy/cp4i-eventstreams/overlays

mq_config:
	@oc apply -k ./environments/rt-inventory-dev/services/ibm-mq/overlays

mt_kconnect:
	@oc apply -k ./environments/multi-tenancy/kconnect -n rt-inventory-dev

mt_mq_kconnector:
	@oc apply -f ./environments/multi-tenancy/apps/mq-source/kafka-mq-src-connector.yaml -n rt-inventory-dev
# ----------- app specific -------------
mt_store_simulator:
	@oc apply -k ./environments/multi-tenancy/apps/store-simulator/

mt_store_inventory:
	@oc apply -k ./environments/multi-tenancy/apps/store-inventory/

mt_item_inventory:
	@oc apply -k ./environments/multi-tenancy/apps/item-inventory/

multi_tenants: \
	mt_prepare_ns \
	mt_eventstreams_config \
	mq_config \
	mt_kconnect \
	mt_mq_kconnector \
	mt_store_simulator \
	mt_store_inventory \
	mt_item_inventory 

clean_multi_tenants:
	@oc delete -k ./environments/multi-tenancy/apps/item-inventory/
	@oc delete -k ./environments/multi-tenancy/apps/store-inventory/
	@oc delete -k ./environments/multi-tenancy/apps/store-simulator/
	@oc delete -k  multi-tenancy/kconnect
	@oc delete -k environments/rt-inventory-dev/services/ibm-mq/overlays
	@oc delete -k  multi-tenancy/cp4i-eventstreams/overlays

output_details:
	@echo "Install complete.\n\n"
	@echo "Openshift admin credential"
	@oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
	@echo "\nMQ Console console url"
	@oc get queuemanager store-mq -o jsonpath='{.status.adminUiUrl}'  -n $(DEV_NS)
	@echo "\n\nEvent Streams Console console url"
	@oc get route dev-ibm-es-ui -o jsonpath='{.status.ingress[].host}'  -n $(DEV_NS)
	@echo "\n\nStore simulator url\n"
	@oc get route store-simulator -o jsonpath='{.status.ingress[].host}'  -n $(DEV_NS)

# --------------------------
# RT inventory in dev namespace
# --------------------------
prepare_dev_ns:
	@oc apply -k ./environments/rt-inventory-dev/env/overlays
	@oc project $(DEV_NS)

eventstreams_config:
	@oc apply -k ./environments/rt-inventory-dev/services/ibm-eventstreams/overlays/$(ES_VERSION)

rt_store_simulator:
	@oc apply -k ./environments/rt-inventory-dev/apps/store-simulator/

rt_store_inventory:
	@oc apply -k ./environments/rt-inventory-dev/apps/store-inventory/

rt_item_inventory:
	@oc apply -k ./environments/rt-inventory-dev/apps/item-inventory/

deploy_rt_inventory: prepare_dev_ns \
	eventstreams_config \
	rt_store_inventory \
	rt_item_inventory \
	rt_store_simulator

clean_rt_inventory:
	@oc project rt-inventory-dev
	@oc delete -k ./environments/rt-inventory-dev/apps/item-inventory
	@oc delete -k ./environments/rt-inventory-dev/apps/store-inventory
	@oc delete -k ./environments/rt-inventory-dev/apps/store-simulator
	@oc delete -k ./environments/rt-inventory-dev/services/kconnect
	@oc delete -k ./environments/rt-inventory-dev/services/ibm-mq/overlays
	@oc delete -k ./environments/rt-inventory-dev/services/ibm-eventstreams
	