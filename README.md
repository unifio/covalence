# Covalence
[![CircleCI](https://circleci.com/gh/unifio/covalence.svg?style=svg)](https://circleci.com/gh/unifio/covalence)
[![Dependency Status](https://gemnasium.com/badges/github.com/unifio/covalence.svg)](https://gemnasium.com/github.com/unifio/covalence)

A tool for the management and orchestration of data used by HashiCorp infrastructure tooling.

<img src="./images/bond.jpg">

# Why Covalence?

## Separation of data and code
Covalence allows for Terraform [Backends](https://www.terraform.io/docs/backends/) and variable inputs to be source agnostic, so your modules aren't hard coded to specific data sources.

## Code / data reuse
No more copying around of tfvars files or creating glue code to tie together modules. Covalence will assemble the proper data inputs and modules for the contexts you want.

## Infrastructure as layers
We have found that there is tremendous value in decoupling our infrastructure into layers and coordinating those layers with data. The overhead of managing layers adds up quickly though and introduces risk for human error in coordinating data and state. Coavalence models each context as an executable stack, so that data and state are always managed properly.

# FAQ

### Does using Covalence impact my ability to use my code with the HashiCorp tools natively?
No. Covalence is a superset of functionality on top of the native HashiCorp tools. While it is opinionated, it does not require any fundamental departure from HashiCorp best practices that would render it unusable with the stand alone products.

### Why Hiera?
Covalence was a tool born of necessity. For those who were early adopters of Terraform, you know what I'm talking about.

The first Covalence data backend was a single YAML file. That quickly failed to scale as we began using the tool to decouple more and more layers. We needed to move to something more flexible. As you might have guessed, the first projects we used Covalence with also included Puppet. Puppet suffered from similar data management issues that impacted code complexity and reusability. Given that our target users were already comfortable with Hiera and we were using Ruby, it was an obvious fit.

If you're not familiar with Hiera, you'll want to read up on it [here](https://puppet.com/docs/puppet/5.4/hiera_intro.html). Covalence uses Hiera v3, as v4 and up are no longer separate from Puppet.

# Requirements

* [Bash](https://www.gnu.org/software/bash/) shell environment. Windows users, you will need the [Linux subsystem](https://docs.microsoft.com/en-us/windows/wsl/install-win10) installed.
* [Docker](https://docs.docker.com/engine/installation/)

# Quick Start

* Securely download [covalence](https://s3.amazonaws.com/unifio-covalence/get_covalence/covalence) and add to the `bin` directory of your infrastructure repository or directory.
* Change the mode of the file to allow execution: `chmod +x bin/covalence`
* Execute `bin/covalence`. This will download the most current version of the launcher script and return a usage statement to the command line. The launcher should be committed to source control.

For example:

```
|-- bin
|   |-- covalence
|   |-- .covalence
|       |-- launcher
...
```

To begin using Covalence, some configuration is required. The following files are required:

```
|-- bin
|   |-- covalence
|-- covalence.yaml
|-- Rakefile
...
```

See [example](./example) for a minimal configuration.

While the `.env.covalence` and `.env.docker` files are not a hard requirement, they are the preferred method of overriding values in the Covalence launcher as well as configuring tools within the container. Sample files have been provided as a reference, but many additional options are available.

# Configure Your Rakefile

The minimal configuration for your Rakefile is as follows:

```ruby
require 'rake'
require 'rspec/core/rake_task'
require 'covalence/environment_tasks'
require 'covalence/spec_tasks'
```

This file is exposed so that you can add other rake tasks as desired. See [example/Rakefile](./example/Rakefile) for an example of extending the Rakefile. Note, if you add dependencies on gems that are not present in the default container, you will need to add them.

## Reserved Namespaces

In addition to avoiding any task names that will overlap your environment names, there are several additional tasks built into Covalence.

### All

The `all` environment allows for the execution of actions against all configured stacks in all configured environments.

For example:

```bash
$ bin/covalence all:format
```

would execute `terraform fmt` on all configured stacks in all configured environments.

Note: Passing a task of the form `<environment>:<action>` will have the same effect on all stacks for the specified environment.

### RSpec

Unit tests for all tasks and tools.

The suite can be executed with the following command:

```bash
$ bin/covalence spec
```

### UAT

User acceptance tests targeting execution in a continuous integration (CI) environment.

The suite can be executed with the following command:

```bash
$ bin/covalence ci
```

# Configure Your Data Hierarchy

If you're not familiar with Hiera, you'll want to start your reading [here](https://puppet.com/docs/hiera/3.3/index.html).

The hierarchy is driven by the **covalence.yaml** configuration. It is important to note that it is not a requirement that all directories and files in the hierarchy exist, the hierarchy simply dictates an order of priority for looking up values.

An exmaple configuration is as follows:

**data/covalence.yaml**
```yaml
---
:backends:
  - yaml                                          # Data store type. Also supports JSON out-of-the-box.
                                                  # Can support multiple concurrently.

:logger: noop                                     # Suppress Hiera logging. Can be re-enabled by
                                                  # commenting this line out.

:merge_behavior: 'deeper'                         # Merge strategy for Hash lookups.

:hierarchy:                                       # Data store hierarchy. Lookups will traverse the
                                                  # hierarchy in order from top to bottom.
  - "environments/%{environment}"
  - "stacks/%{stack}"
  - "global"
  - "environments"

:yaml:                                            # Configuration specific to the YAML backend.
  :datadir: data                                  # Root directory of the YAML data store.

```

The hierarchy can be changed, but the only two context variables currently supported are the `environment` and `stack` names.

# Create a Stack

## Terraform

A Covalence stack is a pairing of data for a single context with a module. A Terraform stack must minimally include a module mapping as well as a state storage configuration.

For example, let's create a stack called vpc. Given our hierarchy above, let's add a `data/stacks/vpc.yaml` file and configure it as follows:

**data/stacks/vpc.yaml**
```yaml
---
# VPC stack

# Terraform module
vpc::module: 'terraform/vpc'                          # Terraform module directory if different than
                                                      # the stack name. The key is prepended with the
                                                      # stack name, as module assignment is stack specific.

# State storage
vpc::state:                                           # Terraform backend configuration. The key is
                                                      # prepended with the stack name, as the backend
                                                      # configuration is stack specific. The `state` map
                                                      # accepts a list of Terraform backend configuration
                                                      # maps. The first in the list is considered the
                                                      # primary backend while subsequent entries are
                                                      # targets for replication. Backend names and
                                                      # parameters map directly to what is supported by
                                                      # Terraform. Covalence will generate the code
                                                      # associated with backend initialization at runtime.

  - s3:                                               # Backend type.
      bucket: "%{alias('tf_state_bucket')}"           # Example for looking up a value from another
                                                      # context within the hierarchy (e.g. data/environments/test.yaml)
      encrypt: true
      name: "%{environment}/%{stack}"                 # Example of interpolating context specific
                                                      # variables.
      region: "%{alias('tf_state_region')}"
      role_arn: "%{alias('cross_acct_role_arn')}"
  - consul:                                           # Secondary backend configuration
      address: 'consul.example.com:8500'
      name: "%{environment}/%{stack}"

# Workspace
vpc::workspace: 'blue'                                # Terraform workspace configuration. The key is
                                                      # prepended with the stack name, as the backend
                                                      # configuration is stack specific.

## Dependencies
vpc::deps:                                            # List of paths to files or directories outside
                                                      # of the module directory that are to be copied
                                                      # into the working directory of the module during
                                                      # Covalence execution. An example of this would be
                                                      # an SSH key for cloning a private Terraform
                                                      # module.
  - '.ssh'

# Execution targets
terraform::vpc::targets:                              # Resource targeting. The key is prepended with
                                                      # the module name, as target assignment can be
                                                      # shared across contexts.

  az0:                                                # Context name
    - 'module.az0'                                    # Resource target (e.g. terraform plan -target=module.az0)
  az1:
    - 'module.az1'

# Additional arguments
terraform::vpc::args: '-no-color'                     # Additional arguments to be passed to Terraform.
                                                      # The key is prepended with the module name, as
                                                      # arguments can be shared across contexts.

# Input variables
terraform::vpc::vars:                                 # Input variables. The key is prepended with the
                                                      # module name, as variable assignment can be shared
                                                      # across contexts.

  region: 'us-east-1'                                 # Short form input string
  stack_item_label: 'testing'
```

As indicated in the comments above, keys that are stack specific are prepended with the stack name as opposed to the module name. Currently, this include the `module` and `state` parameters only. All other keys will be prepended with the module name, allowing for data sharing between stacks that are based on the same module.

To demonstrate this, let's add a `data/environments/test.yaml` file and configure it as follows:

**data/environments/test.yaml**
```yaml
---
# Test environment

# VPC input variables
terraform::vpc::vars:
  region: 'us-west-2'
```

Let's also go ahead and define some environments by adding the following to `data/environments.yaml`:

**data/environments.yaml**
```yaml
---
environments:
  test:
    - vpc
  staging:
    - vpc
```

Our configuration now has two actionable contexts of the VPC stack; `test` and `staging`.

A call to `bin/covalence -l` will now produce output similar to the following:

```bash
$ bin/covalence -l
staging:vpc:apply               # Apply changes to the vpc stack of the staging environment
staging:vpc:destroy             # Destroy the vpc stack of the staging environment
staging:vpc:format              # Format the vpc stack of the staging environment
staging:vpc:plan                # Create execution plan for the vpc stack of the staging environment
staging:vpc:plan_destroy        # Create destruction plan for the vpc stack of the staging environment
staging:vpc:refresh             # Refresh the vpc stack of the staging environment
staging:vpc:sync                # Synchronize state stores for the vpc stack of the staging environment
staging:vpc:verify              # Verify the vpc stack of the staging environment
test:vpc:apply                  # Apply changes to the vpc stack of the test environment
test:vpc:destroy                # Destroy the vpc stack of the test environment
test:vpc:format                 # Format the vpc stack of the test environment
test:vpc:plan                   # Create execution plan for the vpc stack of the test environment
test:vpc:plan_destroy           # Create destruction plan for the vpc stack of the test environment
test:vpc:refresh                # Refresh the vpc stack of the test environment
test:vpc:sync                   # Synchronize state stores for the vpc stack of the test environment
test:vpc:verify                 # Verify the vpc stack of the test environment
```

If we were to execute the `staging:vpc:plan` task, we will see that the VPC is targeted for the `us-east-1` region. However, if we execute the `test:vpc:plan` task, we will see that the VPC is targeted for the `us-west-2` region.

If we review our hierarchy, we see that values in the `environments` directory take precedence over those in the `stacks` directory. With the addition of `data/environments/test.yaml`, we have introduced variable overrides for the stack defaults in the context of the test environment. As there is no `data/environments/staging.yaml`, the stack default of `us-east-1` is the first value discovered when traversing the hierarchy in the context of the staging environment.

## Packer

Packer stacks are managed in the same manner as Terraform stacks within Covalence, but have different configuration requirements. A Packer stack must minimally include a module and build template mapping.

```yaml
---
# ECS artifact defaults

## Module
ecs-artifact::module: 'packer/ecs'                    # Packer module directory if different than
                                                      # the stack name. The key is prepended with the
                                                      # stack name, as module assignment is stack specific.
                                                      # Assets associated with the build (e.g. scripts)
                                                      # should be co-located with the build template within
                                                      # the module path.

## Build template
ecs-artifact::packer-template: 'aws-linux-ecs.json'   # Relative path to the Packer build template
                                                      # from within the module directory.

## Dependencies
ecs-artifact::deps:                                   # List of paths to files or directories outside
                                                      # of the module directory that are to be copied
                                                      # into the working directory of the module during
                                                      # Covalence execution. An example of this would be
                                                      # a common suite of unit tests that exist above
                                                      # the context of each individual Packer build.
  - 'serverspec'

## Input variables
packer::ecs::vars:
  region: "%{alias('region')}"                        # Example for looking up a value from another
                                                      # context within the hierarchy (e.g. data/environments/test.yaml)
  version: '1.0.0'
```

Note: Covalence provides support for YAML based Packer build templates. This capability is not compatible with native Packer, which only supports JSON.

# Complex Inputs

Covalence adds additional data processing capabilities on top of Hiera.

The most basic input is a string. The following is an example of the short form notation for a string input.

```yaml
terraform::example::vars:
  label: 'test'
```

Standard YAML notation for lists and maps will work as expected as well:

```yaml
terraform::example::vars:
  labels:
    - 'test0'
    - 'test1'
    - 'test2'
  samples:
    terraform: 'testing'
    packer: 'testing'
```

The long form for the same inputs are as follows:

```yaml
terraform::example::vars:
  label:
    type: 'string'
    value: 'test'
  labels:
    type: 'list'
    value:
      - 'test0'
      - 'test1'
      - 'test2'
  samples:
    type: 'map'
    value:
      terraform: 'testing'
      packer: 'testing'
```

Maps are processed by Covalence as complex inputs. The `type` parameter is reserved for identifying the type of input. For simple types, like those shown above, the long format is unnecessary in most instances. However, it is the basis for invoking more complex lookups via integrations to other tools.

For example, the following is an example of a lookup from a Terraform state file stored on S3:

```yaml
terraform::ecs::cluster::vars:
  vpc_id:
    type: 's3.state'
    bucket: "%{alias('tf_state_bucket')}"
    document: "%{environment}/vpc/terraform.tfstate"
    key: 'vpc_id'
```

See the Integrations section below for a list of supported lookups.

Covalence will also perform UNIX shell interpolation on inputs of the following form:

```yaml
terraform::ecs::cluster::vars:
  app_label: "$(echo 'this is a test')"
```

# Integrations

## Terraform Enterprise (formerly Atlas)
Module for interacting with the Terraform Enterprise backend.

### Supported operations

| K/V Read | K/V Write | Remote State Read | State Storage Backend |
|:--------:|:---------:|:-----------------:|:---------------------:|
| <img src="./images/checkmark.png"> | | <img src="./images/checkmark.png"> | <img src="./images/checkmark.png"> |

### Configuration parameters

| ENV Variable             | Default                           | Description                          |
| ------------------------ | --------------------------------- | ------------------------------------ |
| ATLAS_TOKEN              |                                   | HTTP authentication token.           |

### Usage

Artifacts:

```yaml
ami:
  type: 'atlas.artifact'
  slug: 'unifio/app/amazon.ami'
  version: 'latest'
  key: 'region.us-east-1'
```

State Outputs:

```yaml
vpc_id:
  type: 'atlas.state'
  stack: 'unifio/vpc'
  key: 'vpc_id'
```

## Consul
Module for interacting with the Consul backend.

### Supported operations

| K/V Read | K/V Write | Remote State Read | State Storage Backend |
|:--------:|:---------:|:-----------------:|:---------------------:|
| <img src="./images/checkmark.png"> | | <img src="./images/checkmark.png"> | <img src="./images/checkmark.png"> |

### Configuration parameters

| ENV Variable             | Default                           | Description                          |
| ------------------------ | --------------------------------- | ------------------------------------ |
| CONSUL_HTTP_ADDR         |                                   | DNS name and port of your Consul endpoint specified in the format dnsname:port. Defaults to the local agent HTTP listener. |
| CONSUL_HTTP_TOKEN        |                                   | HTTP authentication token |

### Usage

Keys:

```yaml
ami:
  type: 'consul.key'
  key: 'unifio/app/amazon.ami'
```

State Outputs:

```yaml
vpc_id:
  type: 'consul.state'
  stack: 'unifio/vpc'
  key: 'vpc_id'
```

## S3
Module for interacting with the AWS Simple Storage Service (S3) backend.

### Supported operations

| K/V Read | K/V Write | Remote State Read | State Storage Backend |
|:--------:|:---------:|:-----------------:|:---------------------:|
| <img src="./images/checkmark.png"> | | <img src="./images/checkmark.png"> | <img src="./images/checkmark.png"> |

### Configuration parameters

| ENV Variable             | Default                           | Description                          |
| ------------------------ | --------------------------------- | ------------------------------------ |
| AWS_ACCESS_KEY_ID        |                                   | AWS access key. |
| AWS_SECRET_ACCESS_KEY    |                                   | AWS secret key. Access and secret key variables override credentials stored in credential and config files. |
| AWS_REGION               |                                   | AWS region. This variable overrides the default region of the in-use profile, if set. |
| AWS_PROFILE              |                                   | AWS profile. For use with with a credential file. |

### Usage

Keys:

```yaml
docker_image:
  type: 's3.key'
  bucket: 'artifact-registry'
  document: 'app-prod.json'
  key: 'id'
```

State Outputs:

```yaml
vpc_id:
  type: 's3.state'
  bucket: 'terraform-state'
  document: 'production/vpc/terraform.tfstate'
  key: 'vpc_id'
```

# Build From Source

Covalence is packaged as a Ruby Gem.

You will probably need the following packages installed locally
- Terraform
- Packer
- Sops

Execute the following to build the gem:

`$ gem build covalence.gemspec`
