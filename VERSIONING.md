# Versioning

Releases use [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`. The
current version is in [`VERSION`](VERSION), and each release has a matching
`vX.Y.Z` Git tag.

| Bump | When | Examples |
|---|---|---|
| `MAJOR` | An update can break a setup or needs the user to act | Dropping a GNOME version, replacing the dock, changing how install or uninstall works |
| `MINOR` | Something new, or a change people will notice | New GNOME support, new behaviour, restyled shell or dock, new upstream pins |
| `PATCH` | Fixes with no intended change of look or behaviour | Installer bugs, broken CSS rules, docs |

Bumping `EXTENSIONS_SHA` or `ICONS_SHA` in `install.sh` is at least `MINOR`,
because the pinned upstream code changes. Regenerate the patches first, or they
won't apply.

## Pull requests

Changes reach `main` through pull requests. The [CI workflow](.github/workflows/ci.yml)
lints the scripts and builds the Qt plugin for every target, and once all of it
passes it rebase-merges the pull request into `main` by itself. Open a pull
request as a draft to hold it back, and mark it ready when it should merge.

## Making a release

1. Update `VERSION` on a branch and commit.
2. Build the Qt title-bar plugin for this machine, which the test needs. This
   requires cmake and the Qt 6 development files:

   ```bash
   qt/build-decoration.sh
   ```

3. Run the test, with `--compare` if this machine runs the theme:

   ```bash
   tests/sandbox.sh --compare
   ```

4. Push the branch and open a pull request. When CI has merged it, tag `main`
   and push the tag:

   ```bash
   git checkout main && git pull
   v=v$(cat VERSION)
   git tag -a "$v" -m "$v"
   git push origin "$v"
   ```

The tag runs the [CI workflow](.github/workflows/ci.yml) again. It builds the Qt
plugin on Arch, Fedora, Debian, Ubuntu and the KDE Flatpak runtimes, adds every
build to the archive, and publishes the release. To try the builds without
releasing, run the workflow by hand from the Actions tab.

The asset must be named `gnome-theme.tar.gz`, because `bootstrap.sh` downloads it
from the latest release. Publishing a release therefore updates what the
one-command installer delivers, so only push tags for tested builds.
