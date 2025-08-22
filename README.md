# simple-backup-mac
simple solution to backup a folder on your mac to github

# Getting started 

- create a new repo, based on this template. this new repo is what will be stored in the repo. 
- clone the new repo to your local machine
- run `git config user.email "you@example.com"` and `git config user.name "Your Name"`
- go ahead and run `./backup.sh` to test it works. You should now see the files backed up to your git repo! 
- rename the `com.simplebackup.foo.plist` file to match your new repo name (e.g. `com.yourname.yourrepo.plist`)
- edit the `.plist` file to your specifications for this backup. Such as the time of day it runs. If you need a more powerful plist file, [this tool seems cool](https://launched.zerowidth.com/). 
- run `./install.sh` to setup the program to run automatically. Anytime you want to update this plist file, just make your changes and run `./install.sh` again.