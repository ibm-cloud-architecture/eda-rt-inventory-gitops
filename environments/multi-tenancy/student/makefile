


# Reusable functions
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

verify-argocd-available:
	@$(call ensure_operator_installed,"openshift-gitops-operator","../../../bootstrap/openshift-gitops-operator")

define-argocd-project:
	@oc apply -f argocd/argo-project.yaml

prepare_ns:
	@cd ./env/base/ && ./updateStudent.sh 

prepare-argocd: 
	@echo $$PREFIX $$GIT_REPO_NAME
	@cd ./argocd/ && ./updateStudent.sh 

argocd: verify-argocd-available define-argocd-project
	@oc apply -k argocd/
	