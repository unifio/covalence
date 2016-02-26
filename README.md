# Prometheus
[![Circle CI](https://circleci.com/gh/unifio/prometheus.svg?style=svg&circle-token=42737f88bb5153c24dce3ecc2550a6aee7eb8283)](https://circleci.com/gh/unifio/prometheus)

Ruby orchestration framework for HashiCorp based deployment pipelines.

<img src="./images/prometheus.jpg">

Brother of Atlas. The name derives from the Greek word meaning 'forethought'.

## Overview
The goal of this project is to codify and coordinate data between HashiCorp tools while remaining agnostic to the backends in use.

## Getting started
To begin using Prometheus you must include it in your HashiCorp code repository using something like a Git [submodule](https://git-scm.com/docs/git-submodule) or [subtree](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.txt).

You will then need to add a Rakefile to your workspace, which will be used to configure the environment as well as import the desired tasks for your project.

For example:

```
ENV['PROMETHEUS_WORKSPACE'] = "/Users/unifio/git/infrastructure"
ENV['PROMETHEUS_TERRAFORM_DIR'] = "stacks"
ENV['PROMETHEUS_PACKER_DIR'] = "amis"

load 'prometheus/ruby/lib/rake/environment.rake'
```

The complete list of environment variables available are as follows:

| Tool       | ENV Variable             | Default                           | Description                          |
| ---------- | ------------------------ | --------------------------------- | ------------------------------------ |
| Prometheus | PROMETHEUS_WORKSPACE     | "../../../"                       | Root directory of the Rakefile and other assets |
| Prometheus | PROMETHEUS_CONFIG        | "prometheus.yml"                  | Name of the configuration file located in the workspace |
| Prometheus | PROMETHEUS_PACKER_DIR    | "packer"                          | Root directory name where Packer modules are located in the workspace |
| Prometheus | PROMETHEUS_TERRAFORM_DIR | "terraform"                       | Root directory name where Terraform modules are located in the workspace |
| Terraform  | TF_ENV                   | "TF_VAR_atlas_token=$ATLAS_TOKEN" | Environment variables to be set for calls to Terraform |
| Terraform  | TF_CMD                   | "terraform"                       | Terraform command to be used. Can be substituted for use of Docker containers, etc. |
| Terraform  | TF_MODE                  | ""                                | Terraform module mode. A value of "test" will put the module into a stub mode |
| Atlas      | ATLAS_TOKEN              |                                   | HTTP authentication token. |
| Consul     | CONSUL_HTTP_ADDR         |                                   | DNS name and port of your Consul endpoint specified in the format dnsname:port. Defaults to the local agent HTTP listener. |
| Consul     | CONSUL_HTTP_SSL          |                                   | Specifies what protocol to use when talking to the given address, either http or https. |
| Consul     | CONSUL_HTTP_AUTH         |                                   | HTTP Basic Authentication credentials to be used when communicating with Consul, in the format of either user or user:pass. |
| Consul     | CONSUL_HTTP_TOKEN        |                                   | HTTP authentication token |
| S3         | AWS_ACCESS_KEY_ID        |                                   | AWS access key. |
| S3         | AWS_SECRET_ACCESS_KEY    |                                   | AWS secret key. Access and secret key variables override credentials stored in credential and config files. |
| S3         | AWS_REGION               |                                   | AWS region. This variable overrides the default region of the in-use profile, if set. |

## Rake Tasks

### Environments
The main entry point for managing Terraform stacks. Terraform modules are organized into environments and stacks in the Prometheus configuration file. The configuration is read in by the `Environment` class, which dynamically generates the Rake tasks available.

An example **prometheus.yml** is as follows:

```
environments:
  ops:                                                    // Environment name. Contains an ordered Array of Terraform stacks.
    - openvpn:                                            // Stack name. Independent Terraform stack.
        module: 'vpn'                                     // Terraform module directory if different than the stack name.
        state:                                            // Terraform state stores. The first is used as the primary with others as targets for synchronization
          - atlas:                                        // State store type.
              name: 'unifio/openvpn'
          - consul:
              name: 'unifio/openvpn'
          - s3:
              name: 'unifio/openvpn'
              bucket: 'unifio-terraform'
        vars:                                             // Input variables
          app_label: 'ops'
          instances: 2
          ami:                                            // Variables that are hashes are passed to the plug-in framework for processing
            type: 'atlas.artifact'                        // <backend>.<lookup_type>. Supported types vary per backend.
            slug: 'unifio/openvpn/amazon.ami'
            version: 1                                    // Defaults to 'latest'.
            metadata: 'region.us-west-2'
        args: '-target=test'                              // Additional arguments to be passed to Terraform
```

This configuration yields the following Rake tasks as returned by `rake -T`:

```
rake all:verify                # Verify all environments
rake ops:apply                 # Apply change to the ops environment
rake ops:destroy               # Destroy the ops environment
rake ops:openvpn:apply         # Apply changes to the openvpn stack of the ...
rake ops:openvpn:destroy       # Apply changes to the openvpn stack of the ...
rake ops:openvpn:plan          # Create execution plan for the openvpn stac...
rake ops:openvpn:plan_destroy  # Create destruction plan for the openvpn st...
rake ops:openvpn:sync          # Synchronize state stores for the openvpn s...
rake ops:openvpn:verify        # Verify the openvpn stack of the ops enviro...
rake ops:plan                  # Create execution plan for the ops environment
rake ops:plan_destroy          # Create destruction plan for the ops enviro...
rake ops:verify                # Verify the ops environment
```

Notice that tasks are created for each individual stack as well as each environment. In the case of environments, stack order is guaranteed.

### RSpec
Unit tests for all tasks and tools.

The suite can be executed with the following task:

`rake spec`

## Tools

### Atlas
Module for interacting with the HashiCorp Atlas backend.

The following operations are currently supported:

| K/V Read | K/V Write | Remote State Read | State Storage Backend |
|:--------:|:---------:|:-----------------:|:---------------------:|
| <img src="./images/checkmark.png"> | | <img src="./images/checkmark.png"> | <img src="./images/checkmark.png"> |

* `get_artifact(slug, version, region)` - Retrieves an Atlas artifact ID. Geared to non-file artifacts, such as Amazon AMIs.
* `get_output(name, stack)` - Retrieves a Terraform root module output from a stack state document stored in Atlas.
* `get_state_store(name)` - Constructs the expected input string required by Terraform for configuring remote state storage in Atlas.

### Consul
Module for interacting with the HashiCorp Consul backend.

The following operations are currently supported:

| K/V Read | K/V Write | Remote State Read | State Storage Backend |
|:--------:|:---------:|:-----------------:|:---------------------:|
| <img src="./images/checkmark.png"> | | <img src="./images/checkmark.png"> | <img src="./images/checkmark.png"> |

* `get_key(name)` - Retrieves and decodes a value from the Consul K/V store.
* `get_output(name, stack)` - Retrieves a Terraform root module output from a stack state document stored in the Consul K/V store.
* `get_state_store(name)` - Constructs the expected input string required by Terraform for configuring remote stack state storage in Consul.

### S3
Module for interacting with the AWS Simple Storage Service (S3).

The following operations are currently supported:

| K/V Read | K/V Write | Remote State Read | State Storage Backend |
|:--------:|:---------:|:-----------------:|:---------------------:|
| <img src="./images/checkmark.png"> | | <img src="./images/checkmark.png"> | <img src="./images/checkmark.png"> |

* `Client`
  * `initialize(region)` - Instantiates a new S3 client. Requires AWS_REGION to be set.
  * `get_doc(bucket, document)` - Retrieves a JSON document from an S3 bucket.
  * `get_key(bucket, document, name)` - Retrieves a value from a JSON document.
* `get_state_store(name)` - Constructs the expected input string required by Terraform for configuring remote stack state storage in Consul.

### Terraform
Module for interacting with the HashiCorp Terraform tool.

The following capabilities are exposed:

* `remote_config(args)` - Calls to the Terraform `remote` command for configuration of remote state storage.
* `remote_pull` - Calls to the Terraform `remote` command for pulling the state of an already configured remote state store.
* `remote_push` - Calls to the Terraform `remote` command for pushing the state of an already configured remote state store.
* `get(args)` - Calls to the Terraform `get` command for retrieving modules into the working stack directory.
* `plan(args)` - Calls to the Terraform `plan` command for generation of an execution plan.
* `apply(args)` - Calls to the Terraform `apply` command for execution of a stack.
* `destroy(args)` - Call to the Terraform `destroy` command for destruction of a stack.
* `clean` - Call to the system to remove existing Terraform state from the working stack directory.
* `parse_vars(vars)` - Constructs the expected input string required by Terraform from a hash.
