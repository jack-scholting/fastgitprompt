# FastGitPrompt #

Normal Clean Repo
![normal](/../screenshots/screenshots/normal.PNG?raw=true)

Uncommited changes
![uncommited](/../screenshots/screenshots/uncommited.PNG?raw=true)

Changes staged but not committed
![indexed](/../screenshots/screenshots/indexed.PNG?raw=true)

Ahead by 1 commit
![ahead](/../screenshots/screenshots/ahead.PNG?raw=true)

Ahead by 3 commits with untracked changes
![ahead3](/../screenshots/screenshots/ahead3.PNG?raw=true)

During a Bisect with uncommited changes
![bisecting](/../screenshots/screenshots/bisecting.PNG?raw=true)

## Overview ##

FastGitPrompt provides critical information about the state of a Git repository while using the Powershell command line. It was created because the existing solutions didn't meet my needs. I was working with very large Git repos with many submodules, other status scripts would take minutes to return a status. FastGitPrompt is very configurable, just change the 'settings' variable at the top of the function to change how the status looks.

## Installation ##

1. Place this module in the directory $PROFILE\Modules\FastGitPrompt.

2. Place the command "Import-Module FastGitPrompt" in your Powershell profile.

3. Place the function call "__fast_git_prompt" in your prompt{} function in your profile where you want the status to be displayed.

## Usage ##

Use Git through Powershell as normal and enjoy the extra information.

## Credits ##

I used the follow resources to answer many of my questions.

* [Git Internals Book](http://git-scm.com/book/en/Git-Internals)

* [Posh-Git](https://github.com/dahlbyk/posh-git)

* [git-completion.bash](https://github.com/git/git/blob/master/contrib/completion/git-completion.bash)
