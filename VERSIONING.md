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

## Making a release

1. Update `VERSION` and commit.
2. If the Qt version on the build machine changed, rebuild the prebuilt Qt
   title-bar plugin and commit it. It needs cmake and the Qt 6 development files:

   ```bash
   qt/build-decoration.sh
   ```

   The plugin only loads on the Qt version in
   `qt/wayland-decoration-client/BUILT_FOR`. Users on other Qt versions keep their
   own Qt title bars.
3. Run the test, with `--compare` if this machine runs the theme:

   ```bash
   tests/sandbox.sh --compare
   ```

4. Tag and push:

   ```bash
   v=v$(cat VERSION)
   git tag -a "$v" -m "$v"
   git push origin main "$v"
   ```

5. Build the archive and publish:

   ```bash
   git archive --prefix=tahoe-gnome/ -o tahoe-gnome.tar.gz "$v"
   gh release create "$v" tahoe-gnome.tar.gz --title "$v" --generate-notes
   ```

The asset must be named `tahoe-gnome.tar.gz`, because `bootstrap.sh` downloads it
from the latest release. Publishing a release therefore updates what the
one-command installer delivers, so only mark tested builds as latest.
