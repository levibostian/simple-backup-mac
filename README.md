# simple-backup-mac
simple solution to backup a folder on your mac to github

# Getting started 

- create a new repo, based on this template. this new repo is what will be stored in the repo. 
- on your computer, open terminal and navigate to the directory that you want to backup. 
- run these commands to setup that directory:
```
git init
git config user.email "you@example.com"
git config user.name "Your Name"
git remote add origin git@github.com:...... <--- this is the repo that you just created 
git pull origin main --allow-unrelated-histories
```

- go ahead and run `./backup.sh` to test it works. You should now see the files backed up to your git repo! 
- rename the `com.simplebackup.foo.plist` file to match your new repo name (e.g. `com.yourname.yourrepo.plist`)
- edit the `.plist` file to your specifications for this backup. Such as the time of day it runs. If you need a more powerful plist file, [this tool seems cool](https://launched.zerowidth.com/). 

> **Important:** launchd has issues with `~/` or `$HOME`. you will need to hard-code the absolute paths in the plist file. 

- there is a log file specified in the `.plist` file for both standard output and standard error. run `touch && chmod a+w` for both of those to make sure they are created. 
- run `./install.sh` to setup the program to run automatically. Anytime you want to update this plist file, just make your changes and run `./install.sh` again.
- let's check if it worked as expected. run a `cat ...` on the log files specified in the `.plist` file. If these files are empty, go to the debugging section of this doc because you probably have an issue. 

# Debugging 

### View logs from the script 

Go to `/tmp` and see if there is a log created. 

### Run the command inside of the plist file manually

run the `.plist` command manually. you might have a typo in the path or a space character that needs fixed. 

### View logs for launchd 

`launchctl print com.simplebackup.foo` to try and view the logs. it might give error but it will give a "Did you mean?" suggestion. do `launchctl print` again with the suggestion. 

**What to look for:**
- `last exit code` - Common codes:
  - `0` = Success
  - `78` = `EX_CONFIG` (configuration error)
  - `127` = Command not found
  - `126` = Permission denied
- `runs` count to see if service attempted to execute
- `state` should show current status
- Verify program path is correct

### Run the launchd service 

`launchctl load ~/Library/LaunchAgents/com.simplebackup.foo.plist`

After you run this, run `cat ...` on the log files specified in the `.plist` file. Repeat this debugging section again if you dont see anything. 