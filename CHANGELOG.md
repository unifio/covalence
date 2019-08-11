## 0.9.0 (Aug 11, 2019)

BACKWARDS INCOMPATIBILITIES:
- The legacy Atlas Artifact backend is no longer supported.

IMPROVEMENTS:
* Ability to toggle primary state store
* Environment variable interpolation for input variables
* Support for sops encryption / decryption of hierarchy data
* Support for Terraform 0.12
* Support for parallel execution of process.
* A tool [prefixout](https://github.com/unifio/prefixout/releases/tag/v0.1.0) was added for additional logging.

## 0.7.8 (May 9, 2018)
IMPROVEMENTS:
- Added support for Terraform workspaces

## 0.7.7 (May 6, 2018)
BACKWARDS INCOMPATIBILITIES:
- Versions of Terraform prior to v0.11.4 are no longer supported.

IMPROVEMENTS:
- Extended shell interpolation for input values to support nesting and escaping
- Improved support for Terraform plugin caching
- Replaced deprecated `-force` option for Terraform `destroy` task with `-auto-approve=true`.

FIXES:
- Updated input processing to support nested complex types properly.
- Updated input processing to properly handle non-string values for non-complex input types.

## 0.7.6 (December 6, 2017)
IMPROVEMENTS:
- Terraform init failures were not being reported.  Update spec tests to catch errors with 'terraform init'.

## 0.7.5 (October 12, 2017)
IMPROVEMENTS:
- Fix the sync command to call Terraform get prior to init command.  This is required with new version of Terraform.

## 0.7.4 (September 26, 2017)
IMPROVEMENTS:
- Updated Covalence to work with Terraform 0.10.x.  Updates were made in 0.10.x that requires all variables set for validate to run.
- Also added setting for the apply to auto approve.  This will be required in upcoming releases and will prompt for input from user.

## 0.7.3 (June 20, 2017)
IMPROVEMENTS:
- Tasks within the 'ci' and 'spec' namespaces will no longer load all individual stack tasks like the 'all' namespace.

FIXES:
- Tasks in the reserved 'ci' and 'spec' namespaces were failing in the environments filter logic. These namespaces are not properly ignored.

## 0.7.2 (June 17, 2017)
IMPROVEMENTS:
- Added input logging for Packer stacks.
- Removed logic for driving Docker containers with Covalence. Default mode of operation is now within a container.
- Further merged Terraform and Packer internal structures.
- Various performance improvements in the way in which stacks are loaded and processed.

FIXES:
- Fixed Terraform `refresh` task.

## 0.7.1 (May 15, 2017)
IMPROVEMENTS:
- Updated Hiera to 3.3.1 to enable `list` and `map` lookups from within the data using the alias lookup function.

FIXES:
- Updated Packer `inspect` task to operate in a temporary directory, so that any generated assets are cleaned up after execution.

## 0.7.0 (May 15. 2017)
BACKWARDS INCOMPATIBILITIES:
- Terraform `apply` and `destroy` tasks will no longer include `plan` and `plan_destroy` respectively.
- The Packer stack `packer-module` parameter has been replaced by `module` for standardization with Terraform stacks.
- The Packer namespace `packer-template` parameter has been moved to the stack scope and is now a relative path to the module (e.g. `packer::build::packer-template: 'fully/qualified/path/template.json'` would become `mystack::packer-template: 'template.json'` for `mystack::module: 'fully/qualified/path'`)
- The Packer namespace `packer-targets` parameter has been removed.
- The Packer namespace `packer-vars` parameter has been replaced by `vars` for standardization with Terraform stacks.
- The `COVALENCE_TERRAFORM_DIR` and `COVALENCE_PACKER_DIR` environment variables now default to the same value as `COVALENCE_WORKSPACE` and are now deprecated.

FEATURES:
- Terraform input variables are now fed in via `-var-file` instead of individual `-var` arguments.
- Dependencies can now be specified at the stack scope using `<stack>::deps`, which is an Array of directory paths that are to be made available in the working directory. Paths are relative to the Covalence root directory.
- Added support for `list` and `map` input types.

IMPROVEMENTS:
- Exposed Terraform `refresh` command.
- Added `refresh` command at the environment and global scope.
- Added `format` command at the environment and global scope (#33).
- Added `plan` command at the global scope (#40).

FIXES:
- The `targets` namespace parameter is now properly ignored for Packer stacks.
- Environment spec tasks now properly account for execution errors (#43)

## 0.6.1 (April 8, 2017)
IMPROVEMENTS:
- Stack sync no longer sources modules when retrieving state.

FIXES:
- Fixed regression in sourcing modules from relative paths.

## 0.6.0 (April 8, 2017)
BACKWARDS INCOMPATIBILITIES:
- Versions of Terraform prior to v0.9.0 are no longer supported.

FEATURES:
- Added support for remote backends.

IMPROVEMENTS:
- Log level now configurable via the COVALENCE_LOG environment variable.

## 0.5.3 (October 19, 2016)
FIXES:
- terraform destroy tasks receive the `-force` param instead of `-input=false`.
- `env:spec` only does format checking on the specific path module, not the dependent modules referenced underneath.

## 0.5.2 (October 12, 2016)
FEATURES:
- Packer can now be ran from docker containers. Follows the same conventions as terraform by specifying `PACKER_IMG`, `PACKER_CMD`

FIXES:
- More minor PopenWrapper return code fixes
- Allow packer to deal with shell interpolation values via the same terraform shell interpolation prefix: `$(...`


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
