# publish-nuget-action

A GitHub Action which pushes a package to NuGet.org, and also performs [GitHub artefact attestation](https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds) on the result.

If there's already a package in NuGet with that ID and version number, this step results in the "skipped" status.

After this action has run successfully, you should be able to NuGet install the package at the published version, and verify the attestation corresponding to the `.nupkg` file in your NuGet cache.

Preconditions:
* You're running in an image which contains Bash.
* `dotnet` is on the path.
* The GitHub token in scope has `attestations: write`, `id-token: write`, and `contents: read`.

An example invocation is as follows.

```yaml
publish-nuget:
  runs-on: ubuntu-latest
  if: ${{ !github.event.repository.fork && github.ref == 'refs/heads/main' }}
  needs: [all-required-checks-complete]
  environment: main-deploy
  permissions:
    id-token: write
    attestations: write
    contents: read
  steps:
    - uses: actions/checkout@v4
    - name: Set up .NET
      uses: actions/setup-dotnet@v4
    # An earlier build step has produced this and run the tests.
    - name: Download NuGet artifact
      uses: actions/download-artifact@v4
      with:
        name: nuget-package-plugin
        path: packed
    - name: Publish NuGet package
      uses: Smaug123/publish-nuget-action
      with:
        package-name: WoofWare.Myriad.Plugins
        nuget-key: ${{ secrets.NUGET_API_KEY }}
        nupkg-dir: packed/
```

# Inputs

## `package-name`

String name of the NuGet package, e.g. the string "WoofWare.Myriad.Plugins" corresponding to `https://www.nuget.org/packages/WoofWare.Myriad.Plugins`.

## `nuget-key`

A NuGet API key which has permission to push new versions of the package with the given `package-name`.

## `nupkg-dir`

The directory on disk within which, at the top level, contains the `${package-name}.{some-version-number}.nupkg` file to upload.
Make sure there's only one nupkg file with any given package name in here: don't have multiple versions of the same package, because our behaviour is not defined in that case.

# Troubleshooting

## "Unable to get `ACTIONS_ID_TOKEN_REQUEST_URL` env variable"

You've run the action with a GitHub cred with insufficient perms.

```
my-job-name:
  permissions:
    id-token: write
    pages: attestations: write
    contents: read
  steps:
    # ...
```

(Note that it's good practice to run as little code as possible within this elevated-privilege scope; hence, for example, the pattern in the main example where we download the `.nupkg` from an earlier stage rather than building it in the presence of the elevated `GITHUB_TOKEN`.)
