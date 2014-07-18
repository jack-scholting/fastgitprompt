#==============================================================================
# Author: Jack Scholting
# Date: 2013-01-20 Sun 11:21 AM
# Purpose: Display important git information in the powershell prompt. It must
#  perform quickly even in repos with hundreds of submodules. Therefore all 
#  git commands should be "plumbing" commands, not "porcelain" commands.
# Current Runtime: 
#  Small repo - 124 milliseconds
#  Medium repo - 200 milliseconds
# Credits: I used git-completion.bash and Posh-Git to find the answers to many
#  of my questions.
# Usage:
#  Place this module in $PROFILE/Modules/FastGitPrompt.
#  Place "Import-Module FastGitPrompt" in profile. 
#  Place "__fast_git_prompt" in your prompt{} function in your profile.
#==============================================================================

# Settings for the prompt. Feel free to customize.
$settings = @{
    "StartDelimiter"   = " ["
    "EndDelimiter"     = "]"
    "SplitDelimiter"   = "|"
    "DelimiterColor"   = [ConsoleColor]::Gray
    "BehindAheadColor" = [ConsoleColor]::White
    "OperationColor"   = [ConsoleColor]::White
    "CleanColor"       = [ConsoleColor]::Green
    "UncommittedColor" = [ConsoleColor]::Red
    "StagedColor"      = [ConsoleColor]::Yellow
    "UntrackedColor"   = [ConsoleColor]::Magenta
}

#------------------------------------------------------------------------------
function __fast_git_prompt
{
    # Do not waste any resources if this isn't a git repo.
    if( is_git_repo )
    {
        # Find the interesting information.
        $branch_name   = find_git_branch
        $branch_color  = find_repo_state_color
        $git_operation = find_git_operation
        $behind_ahead  = find_behind_ahead( $branch_name )

        # Build the prompt.
        Write-Host $settings["StartDelimiter"] -ForegroundColor $settings["DelimiterColor"] -NoNewLine
        if( $global:is_diverged )
        {
            Write-Host $behind_ahead               -ForegroundColor $settings["BehindAheadColor"] -NoNewLine
            Write-Host $settings["SplitDelimiter"] -ForegroundColor $settings["DelimiterColor"]   -NoNewLine
        }
        Write-Host $branch_name -ForegroundColor $branch_color -NoNewLine
        if( $global:is_in_operation )
        {
            Write-Host $settings["SplitDelimiter"] -ForegroundColor $settings["DelimiterColor"] -NoNewLine
            Write-Host $git_operation              -ForegroundColor $settings["OperationColor"] -NoNewLine
        }
        Write-Host $settings["EndDelimiter"] -ForegroundColor $settings["DelimiterColor"] -NoNewLine  
    }
}

#------------------------------------------------------------------------------
function is_git_repo
{
    # Test current directory.
    if( Test-Path ".git" ) 
    {
        $global:git_path = ".git"
        return $TRUE
    }
     
    # Test parent directories.
    $checkIn = (Get-Item .).parent
    while( $checkIn -ne $NULL ) 
    {
        $pathToTest = $checkIn.fullname + '/.git'
        if( Test-Path $pathToTest ) 
        {
            $global:git_path = $pathToTest
            return $TRUE
        } 
        else 
        {
            $checkIn = $checkIn.parent
        }
    }
     
    return $FALSE
}

#------------------------------------------------------------------------------
function find_git_branch
{
    # Find the full branch name.
    $global:full_branch = $(git symbolic-ref -q HEAD) 
    
    if( $global:full_branch -ne $null )
    {
        # Extract the short branch name.
        return $( $global:full_branch -replace 'refs/heads/', '' )
    }

    return "No Branch" 
}

#------------------------------------------------------------------------------
function find_repo_state_color
{
    # Check for regular uncommitted changes.
    git diff-files --quiet
    if( $? -eq $FALSE ) 
    { 
    	return $settings["UncommittedColor"]
    }

    # Check for staged(but uncommitted) changes.
    git diff --cached --quiet
    if( $? -eq $FALSE ) 
    { 
        return $settings["StagedColor"]
    }

    # Check for untracked files.
    $untracked = $(git ls-files --other --exclude-standard --directory )
    if( $untracked -ne $null ) 
    { 
    	return $settings["UntrackedColor"]
    }

    # Repo is clean.
    return $settings["CleanColor"]
}

#------------------------------------------------------------------------------
function find_git_operation
{
    # Merge
    if( Test-Path "$global:git_path/MERGE_HEAD" ) 
    {
    	$global:is_in_operation = $TRUE
    	return "MERGING"
    }

    # Rebase
    if( (Test-Path "$global:git_path/rebase-merge") -OR 
    	(Test-Path "$global:git_path/rebase-apply") )
    {
    	$global:is_in_operation = $TRUE
    	return "REBASING"
    }
   
    # Cherry pick
    if( Test-Path "$global:git_path/CHERRY_PICK_HEAD" ) 
    {
    	$global:is_in_operation = $TRUE
    	return "CHERRY-PICKING"
    }
    
    # Bisect
    if( Test-Path "$global:git_path/BISECT_LOG" ) 
    {
    	$global:is_in_operation = $TRUE
    	return "BISECTING"
    }

    # Set flag for prompt.
    $global:is_in_operation = $FALSE
}

#------------------------------------------------------------------------------
function find_behind_ahead
{
    if( $global:full_branch -ne $null )
    {
        # Find upstream branch
        $tracking_branch = $(git for-each-ref --format='%(upstream:short)' $global:full_branch)

        # Find the upstream divergence.
        # Note: --count only compatible with recent git versions
        $divergence = $(git rev-list --left-right --count "$tracking_branch...HEAD")

        # Parse output.
        $div_split = $divergence.Split("`t")
        $behind = $div_split[0] 
        $ahead  = $div_split[1]

        if( ($behind -ne 0) -OR
    	    ($ahead  -ne 0) )
        {
            # Add indicators.
            $behind = $behind + "<<"
            $ahead  = $ahead  + ">>"

            # Set flag for prompt.
            $global:is_diverged = $TRUE
            
            # Return output.
            return "$behind $ahead"
        }
    }

    # Set flag for prompt.
    $global:is_diverged = $FALSE
}

# Make the following function available for use outside this file.
#Export-ModuleMember __fast_git_prompt
Export-ModuleMember -Function *

