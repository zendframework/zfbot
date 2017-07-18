# TODO

## [ ] Github Stretch Goals

- [ ] Write functionality for the `push` event that, on a push to master, triggers
  a build of the documentation. 

### Documentation build workflow

- If repo org is not "zendframework", abort
- If repo build path exists, abort: `if [ -d <tmp_path>/<repo> ];then exit 1; fi`
- Clone master branch of repo in question, using `git clone git://github.com/<repo>.git <tmp_path>/<repo>`
- If `mkdocs.yml` does not exist, clean-up and abort
- Descend into repo: `cd <tmp_path>/<repo>`
- Clone zf-mkdoc-theme repo into zf-mkdoc-theme directory, using `git clone git://github.com/zendframework/zf-mkdoc-theme.git`
- Run:
  ```bash
  $ ./zf-mkdoc-theme/deploy.sh \
  > -n "<username>" \
  > -e "<user email>" \
  > -t "<user token>" \
  > -r "github.com/${FULL_REPO}.git" \
  > -u "https://docs.zendframework.com/${SHORT_REPO}" \
  ```
- Return to previous working directory
- Remove checkout of repo: `rm -Rf <tmp_path/<repo>`
