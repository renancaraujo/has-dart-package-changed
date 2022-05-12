# Has dart package changed?

A github action to detect changes in a dart package with local dependencies. This action detects if
the given changes has affected the package itself and all fo its local dependencies, direct or
transitive.

This differs from github's path filters since it is run in a step and dynamically filters workflow
runs given the dependencies of a package. Ideal for monorepos.

### Requirements

This action requires either Dart or Flutter to be available. See Dart ann Flutter actions.

Since this action uses git command to check for changes, the repository must be checked out. See
checkout action.

## Example

Example of usage in a pull request workflow:

```yaml
name: root

on:
  pull_request:
    branches:
      - main
jobs:
  root:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: dart-lang/setup-dart@v1 # Setup Dart or Flutter beforehand
        with:
          sdk: stable
      - uses: renancaraujo/has-dart-package-changed@main
        id: check-changes # Specify an id to retrieve the output
        with:
          package-path: 'packages/root_package'
      - name: "runs only when root package changes"
        if: steps.check-changes.outputs.changed == 'true' # Check for changes in that package
        run: // ... do stuff
```

In that example, if `packages/root_package` has its source or any of its local path dependencies
changed, the out put for `check-changes` will be `'true'`.

## Usage

### Inputs

- `package-path` (required): the path to the package to be evaluated

### Outputs

- `changed`: Either `'true'` or `'false'`, defines if the changes affected the given package.