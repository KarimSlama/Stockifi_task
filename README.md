# stockifi

inventory made easy.

## Repository Branches

The git repository should have main (master), staging, develop, and feature branches.

## Branch Naming

Task and bugfix branches can be derived from Trello cards. We could put card numbers in Trello cards for easier referencing.

branch types - task, feat, bug

[branch_type]/[trello-card-number]-[description]

For example:

- **task/123-do-something**
- **bug/124-fix-something**

## Atomic Commits

“[A] commit that commits one and only one thing.”

- build: changes that affect the build system or external dependencies (i.e. pub, npm)
- ci: changes to CI configuration files and scripts (i.e. Travis, Circle, BrowserStack)
- chore: changes which doesn't change source code or tests - changes to the build process, auxiliary tools, libraries
- docs: documentation only changes
- feat: a new feature
- fix: a bug fix
- perf: a code change that improves performance
- refactor: a code change that neither fixes a bug nor adds a feature
- revert: revert something
- style: changes that do not affect the meaning of the code (i.e. white-space, formatting, missing semicolons, etc.)
- test: adding missing tests or correcting existing tests
- fix(scope): bug in scope
- chore(deps): update dependencies

## Pull Requests

1. Pull latest develop
   1. git checkout develop
   2. git pull
2. Rebase Branch to develop
   1. git checkout feature-branch
   2. git rebase -i develop [fix conflicts]
   3. squash commits
   4. git push -f (NOTE: only do this on your branch)
3. Once approved, rebase again to develop to get develop branch changes
   1. git checkout feature-branch
   2. git rebase develop
   3. git push -f (NOTE: only do this on your branch)

## Setup

- Run `flutter packages pub run build_runner build --delete-conflicting-outputs` in the project directory to run dev_dependencies

## Firebase Flavors

flutterfire config \
 --project=<firebase project> \
 --out=lib/firebase_options_dev.dart \
 --ios-bundle-id=<io.stockl.stocklio> \
 --macos-bundle-id=<io.stockl.stocklio> \
 --android-app-id=<io.stockl.stocklio>
