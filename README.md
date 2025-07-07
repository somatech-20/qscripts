[↩️Back](https://github.com/somatech-20/qscrpits/tree/main)
---
# git-reauth.sh
Small utility to rewrite Git commit author and committer info: email, name, or both across history. Useful when someone committed with the wrong auth.

## What It Does
This script updates old author/committer emails and names in your Git history. You can fix multiple identities at once. It uses git filter-branch, which rewrites history so use with care.

## 📦 Usage
```
./git-reauth.sh old_email1:new_name1:new_email1 [old_email2:new_name2:new_email2 ...]
```
### Example
```
./git-reauth.sh \
  "bob@oldmail.com:Bob Smith:bob@newmail.com" \
  "alice@bad.com:Alice Dwyne:alice@good.com"
```
> 😎 Only, use quotes if there's a space.

## ⚠️ Notes & Warnings
This rewrites Git history. Use on **local clones only**.

After running, you'll need to **force push** your changes:

```
git push --force --all
git push --force --tags
```
If `refs/original/` exists from a previous run, the script will offer to clean it up.

`git filter-branch` is considered deprecated for large repos, consider `git-filter-repo`.

## 🛠 Requirements
- Bash
- Git

## 🙃 Why did i create this script?
Because everyone commits with the wrong email at least once.