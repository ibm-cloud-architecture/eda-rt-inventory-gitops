# Lab to learn how to deploy a event-driven solution

In this lab you will learn how to modify the configuration of the different services of a real-time invnetory demo and fow to deploy it
using OpenShift Gitops.

Each Student will have received a unique identifier and need to modify current settings in this folder with the student id. All the current configurations are for `student_1`.

We assume the following are pre-set in you OpenShift cluster:

* API Connect is installed under `cp4i-apic` project
* Event Streams is installed under `cp4i-eventstreams` project

## pre-requisites

* Have a [git client installed](https://github.com/git-guides/install-git)
* Have make installed. On Mac it should be pre-installed, on Windows [install GnuWin](http://gnuwin32.sourceforge.net/install.html)
* You need the 'oc cli'

## Preparation

As we are using GitOps, you need to have the source of the configuration into your own account.

1. Fork the current repository to your github account: 

    ```sh
    chrome "https://github.com/ibm-cloud-architecture/eda-rt-inventory-gitops"
    ```

1. Then clone it to your laptop

    ```sh
    git clone https://github.com/<github-account>/eda-rt-inventory-gitops
    ```

1. Verify the GitOps Operator is installed.

    Work in the `eda-rt-inventory-gitops/environments/multi-tenancy/student` folder.

    ```sh
    make verify-argocd-available
    ```

    Should get this output if not installed

    ```sh
    Installing
    Complete
    ```

    Or this one if already installed.

    ```sh
    openshift-gitops-operator Installed
    ```

Ready to modify the configurations.


## Modify existing configuration

We will prepare the configuration for the following green components in figure below:

![](../../../docs/images/student_env.png)

The blue components should have been deployed with the Cloud Pak for Integration deployment. 

*If you are student-1 there is nothing to do, you were lucky...*

We propose two ways to do this lab, one using a script that will run everything automatically, one more step by step to understand the modification to be done manually.

1. The demonstration will run on its own namespace. The `env/base` folder includes the definition of the namespace, roles, role binding needed to deploy the demonstration. You need to modify those yaml file according to your student id. Two main naming conventions are used: student-2 and std-2 prefix. So the namespace for Student-2 will be `sdt-2-rt-inventory` namespace. 

    * Automatic way

    ```sh
    export USER_NAME=student-2
    export PREFIX=std-2
    export GIT_REPO_NAME=<your-git-user-id>
    make prepare_ns
    ```

    * Manual way: go over each of the following files `argocd-admin.yaml, service-account.yaml, cp-secret.yaml,	role.yaml, rt-inventory-dev-rolebinding.yaml`  in `env/base` folder to change the namespace value and for the `cp-secret.yaml` modify the `jq -r '.metadata.namespace="std-1-rt-inventory"'` in line 16 with the expected namespace.


1. Prepare the ArgoCD app and project: Each student will have his/her own project in ArgoCD.

    * Automatic way

    ```sh
    # same exported variables as before
    make prepare-argocd
    ```

    * Manual way: update the namespace, project, and repoURL elements in the `argocd/*.yaml` files.

1. Commit and push your change to your gitops repository

    ```sh
    git commit -am "update configuration for my student id"
    git push 
    ```

1. Bootstrap Argocd 

    ```
    
    ```



