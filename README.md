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
ENV['PROMETHEUS_WORKSPACE'] = "#{Dir.pwd}"
ENV['PROMETHEUS_TERRAFORM_DIR'] = "stacks"
ENV['PROMETHEUS_PACKER_DIR'] = "amis"

load 'prometheus/ruby/lib/rake/environment.rake'
```

The complete list of environment variables available are as follows:

| Tool       | ENV Variable             | Default                           | Description                          |
| ---------- | ------------------------ | --------------------------------- | ------------------------------------ |
| Prometheus | PROMETHEUS_WORKSPACE     | "../../../"                       | Root directory of the Rakefile and other assets |
| Prometheus | PROMETHEUS_CONFIG        | "prometheus.yaml"                 | Name of the configuration file located in the workspace |
| Prometheus | PROMETHEUS_RSPEC_DIR     | "spec"                            | Root directory name where rspec tests are located in the workspace |
| Prometheus | PROMETHEUS_PACKER_DIR    | "packer"                          | Root directory name where Packer modules are located in the workspace |
| Prometheus | PROMETHEUS_TERRAFORM_DIR | "terraform"                       | Root directory name where Terraform modules are located in the workspace |
| Terraform  | TF_ENV                   |                                   | Environment variables to be set for calls to Terraform |
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
The main entry point for managing Terraform stacks. Terraform modules are organized into environments and stacks in the Prometheus data store. The location and hierarchy of the data store is driven by the configuration file (prometheus.yaml by default). The configuration is read in by the `Environment` class, which dynamically generates the Rake tasks available.

A complete example is as follows:

**Directory structure**
```
- prometheus.yaml
- data
  - envs
    - ops.yaml
  - stacks
    - ops-openvpn.yaml
```

The hierarchy is driven by the **prometheus.yaml** configuration. It is important to note that it is not a requirement that all directories and files exist, the hierarchy simply dictates an order of priority for looking up values. This is the mechanism that makes managing development data locally in the **dev** directory possible.

**prometheus.yaml**
```yaml
---
:backends:
  - yaml                                          # Data store type. Also supports JSON out-of-the-box. Can support multiple concurrently.

:logger: noop                                     # Suppress Hiera logging. Can be re-enabled by commenting this line out.

:merge_behavior: 'deeper'                         # Merge strategy for Hash lookups.

:hierarchy:                                       # Data store hierarchy. Lookups will traverse the hierarchy in order from top to bottom.
  - "dev/%{environment}-%{stack}"
  - "dev/envs"
  - "stacks/%{environment}-%{stack}"
  - "envs/%{environment}"
  - "global"
  - "envs"

:yaml:                                            # Configuration specific to the YAML backend
   :datadir: data                                 # Root directory of the YAML data store

```

The hierarchy can be changed, but the only two context variables currently supported are the `environment` and `stack` names.

**ops-openvpn.yaml**
```yaml
---
# Operations OpenVPN stack                        # File maps to the 'openvpn' stack of the 'ops' environment, which will be managed as an independent Terraform stack as determined by a single state file.

# Terraform module
openvpn::module: 'vpn'                            # Terraform module directory if different than the stack name. Key is prepended with the stack name, as module assignment is stack specific.

# State storage
openvpn::state:                                   # Terraform remote state storage configuration. Key is prepended with the stack name, as state store configuration is stack specific.
  - atlas:                                        # State store type.
      name: 'unifio/openvpn'
  - consul:
      name: 'unifio/openvpn'
  - s3:
      name: 'unifio/openvpn'
      bucket: 'unifio-terraform'

# Execution targets
vpn::targets:                                     # Resource targeting contexts. Key is prepended with the module name, as target assignment can be shared across contexts.
  az0:                                            # Context name
    - 'module.az0'                                # Resource target (i.e. terraform plan -target=module.az0)
  az1:
    - 'module.az1'

# Additional arguments
vpn::args: -no-color'                             # Additional arguments to be passed to Terraform.

# Input variables
vpn::vars:                                        # Input variables. Key is prepended with the module name, as variable assignment can be shared across contexts.
  instances: 2
  ami:                                            # Variables that are hashes are passed to the plug-in framework for processing
    slug: 'unifio/openvpn/amazon.ami'
    version: 1                                    # Defaults to 'latest'.
```

As indicated in the comments above, keys that are stack specific are prepended with the stack name as opposed to the module name. Currently, this include the `module` and `state` parameters only. All other keys will be prepended with the module name, allowing for data sharing between stacks that are based on the same module, as demonstrated in the **ops.yaml** file.

**ops.yaml**
```yaml
---
# Operations environment

# OpenVPN default input variables
vpn::vars:                                        # Default input variables. This hash will be merged with the hash found in the stack definition.
  app_label: 'ops'
  ami:                                            
    type: 'atlas.artifact'                        # <backend>.<lookup_type>. Supported types vary per backend.
    key: 'region.us-west-2'
```

This configuration yields the following Rake tasks as returned by `rake -T`:

```
rake all:clean                     # Clean all environments
rake all:verify                    # Verify all environments
rake ops:apply                     # Apply changes to the ops environment
rake ops:clean                     # Clean the the ops environment
rake ops:destroy                   # Destroy the ops environment
rake ops:openvpn:az0:apply         # Apply changes to the openvpn stack of the ...
rake ops:openvpn:az0:destroy       # Apply changes to the openvpn stack of the ...
rake ops:openvpn:az0:plan          # Create execution plan for the openvpn stac...
rake ops:openvpn:az0:plan_destroy  # Create destruction plan for the openvpn st...
rake ops:openvpn:az1:apply         # Apply changes to the openvpn stack of the ...
rake ops:openvpn:az1:destroy       # Apply changes to the openvpn stack of the ...
rake ops:openvpn:az1:plan          # Create execution plan for the openvpn stac...
rake ops:openvpn:az1:plan_destroy  # Create destruction plan for the openvpn st...
rake ops:openvpn:clean             # Clean the openvpn stack of the ops environ...
rake ops:openvpn:sync              # Synchronize state stores for the openvpn s...
rake ops:openvpn:verify            # Verify the openvpn stack of the ops enviro...
rake ops:plan                      # Create execution plan for the ops environm...
rake ops:plan_destroy              # Create destruction plan for the ops enviro...
rake ops:sync                      # Synchronize state stores for the ops envir...
rake ops:verify                    # Verify the ops environment
```

Notice that tasks are created for each individual stack context, stack and environment. In the case of environments, stack order is guaranteed.

### RSpec
Unit tests for all tasks and tools.

The suite can be executed with the following task:

`rake spec`

### UAT
User acceptance tests targeting execution in a continuous integration (CI) environment.

The suite can be executed with the following task:

`rake ci`

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

### Hiera
Module for interacting with the Hiera database.

The following capabilities are exposed:

* `Client`
  * `set_scope(env, stack)` - Sets the environment and stack search context for lookups.
  * `lookup(key)` - Performs the default Hiera priority lookup across the data store. See [Lookup Types](https://docs.puppetlabs.com/hiera/3.0/lookup_types.html) for a comprehensive description of the different types of lookups supported.
  * `hash_lookup(key)` - Performs a Hiera Hash lookup accross the data store. See [Lookup Types](https://docs.puppetlabs.com/hiera/3.0/lookup_types.html) for a comprehensive description of the different types of lookups supported.
  * `array_lookup(key)` - Performs a Hiera array lookup across the data store. See [Lookup Types](https://docs.puppetlabs.com/hiera/3.0/lookup_types.html) for a comprehensive description of the different types of lookups supported.
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
