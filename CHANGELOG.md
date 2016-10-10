## (Unreleased)

BACKWARDS INCOMPATIBILITIES:
- In-line shell outputs now have a different format

FEATURES:
- Terraform vars are now fed in via `-var-file` instead of individual `-var` commands. Should be able to leverage the new terraform data types to avoid intermediate serialization of array/hash data.
- Docker env variables can now be set by pointing at a DOCKER_ENV_FILE, which is fed to underlying docker commands via `-env-file`

IMPROVEMENTS:
- Terraform: Nil vars should default to empty hash?

FIXES:

## 0.5.1 (October 10, 2016)

FEATURES:
- Packer build and validate now accept runtime arguments, ie `rake example:packer-module:build -- -var "foo=baz"`

FIXES:
- PopenWrapper issues with mismatching exit-codes for happy path runs.
- Terraform remote config needed to ignore exitcodes in a few places where it was being called as a precaution or for 0.6.x compatibility reasons.

## 0.5.0 (October 5, 2016)

FEATURES:
- Better control of running terraform/packer subprocesses:
  - Ctrl-C breaks out of Terraform/Packer commands (also suppresses the normal debugging output from packer/terraform when they're natively sent a SIGINT)
  - Debug capability built into the rake task runs to manually confirm each step

IMPROVEMENTS:
- Allow packer stacks to standalone
- Finer grain control around terraform exit-codes and when to abort the rake task

FIXES:
- Non-zero error codes now return properly from rake tasks (if the
  underlying CLI command did not choose to ignore error codes)
- Packer runs generate temp JSON files in the packer module directory,
  allows the use of `{{ template_dir }}` for script locations.

## 0.4.3 (September 27, 2016)
FIXES:
- Handle new terraform API output formats for remote inputs

## 0.4.2 (September 26, 2016)
FIXES:
- Terraform remote config now works from the module path instead of a temporary directory, which should ensure that the state gets read correctly when ran from a docker context

## 0.4.1 (September 25, 2016)

FEATURES:
- Terraform rake tasks now accept runtime arguments, ie: `rake example:module_test:plan[1,2] -- --no-drift --help`

IMPROVEMENTS:
- Change COVALENCE_CONFIG to default to covalence.yaml
- Gem spec enforce Ruby version >= 2.0.0

FIXES:
- Terraform path handling when terraform is ran in a docker container context. Volume is mounted at the TERRAFORM_DIR base, workdir is a relative subpath to the TERRAFORM_DIR base.
- Fixed shell interpolation bug for terraform 0.7.x inputs, which currently forces string types.

## 0.4.0 (September 14, 2016)

* Initial release
