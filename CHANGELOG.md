## (Unreleased)

BACKWARDS INCOMPATIBILITIES:
FEATURES:
- Terraform vars are now fed in via `-var-file` instead of individual `-var` commands. Should be able to leverage the new terraform data types to avoid intermediate serialization of array/hash data.

IMPROVEMENTS:
FIXES:
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
