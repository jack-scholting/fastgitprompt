#==============================================================================
# Author: Jack Scholting
# Date: 2013-01-20
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
    "DivergentColor"   = [ConsoleColor]::White
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
        $short_branch, $full_branch      = find_git_branch
        $branch_color                    = find_repo_state_color
        $operation_msg, $is_in_operation = find_git_operation
        $divergence_msg, $is_diverged    = find_divergence $branch_name 

        # Build the prompt.
        Write-Host $settings["StartDelimiter"] -ForegroundColor $settings["DelimiterColor"] -NoNewLine
        if( $is_diverged )
        {
            Write-Host $divergence_msg             -ForegroundColor $settings["DivergentColor"] -NoNewLine
            Write-Host $settings["SplitDelimiter"] -ForegroundColor $settings["DelimiterColor"] -NoNewLine
        }
        Write-Host $short_branch -ForegroundColor $branch_color -NoNewLine
        if( $is_in_operation )
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
function is_new_git_repo
{
  # The .git/refs/ folder contains all commits that have names, such as tags 
  #   and branches. A new repository won't have any commits, so the heads
  #   folder will be empty.
  return ( !( Test-Path $global:git_path/refs/heads/* ) )
}

#------------------------------------------------------------------------------
function find_git_branch
{
    # Find the full branch name.
    $full_branch = $(git symbolic-ref -q HEAD) 
    
    if( is_new_git_repo )
    {
        $short_branch = "Fresh Repo"
    }
    elseif( $full_branch -ne $null )
    {
        # Extract the short branch name.
        $short_branch = $( $full_branch -replace 'refs/heads/', '' )
    }
    else
    {
        $short_branch = "No Branch"
    }

    return $short_branch, $full_branch
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

    # Check for staged (but uncommitted) changes.
    git diff --cached --quiet
    if( $? -eq $FALSE ) 
    { 
        return $settings["StagedColor"]
    }

    # Check for untracked files.
    $untracked = $( git ls-files --other --exclude-standard --directory )
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
    if( Test-Path "$global:git_path/MERGE_HEAD" ) 
    {
    	$operation_msg = "MERGING"
    }
    elseif( ( Test-Path "$global:git_path/rebase-merge" ) -OR 
            ( Test-Path "$global:git_path/rebase-apply" ) )
    {
    	$operation_msg = "REBASING"
    }
    elseif( Test-Path "$global:git_path/CHERRY_PICK_HEAD" ) 
    {
    	$operation_msg = "CHERRY-PICKING"
    }
    elseif( Test-Path "$global:git_path/BISECT_LOG" ) 
    {
    	$operation_msg = "BISECTING"
    }
    else
    {
        $operation_msg = "NO OPERATION"
    }

    return( $operation_msg, ( $operation_msg -ne "NO OPERATION" ) )
}

#------------------------------------------------------------------------------
function find_divergence( $full_branch )
{
    # Initialize the return value.
    $divergence_msg = $null

    # It is not possible to diverge from a branch, if we aren't on a branch, or 
    # this is a new repository. 
    if( ( $full_branch -ne $null ) -and !( is_new_git_repo ) )
    {
        # Find upstream branch
        $tracking_branch = $( git for-each-ref --format='%(upstream:short)' $full_branch )

        # Find the upstream divergence.
        # Note: --count only compatible with recent git versions.
        $divergence = $( git rev-list --left-right --count "$tracking_branch...HEAD" )

        # Parse output.
        $div_split = $divergence.Split( "`t" )
        $behind = $div_split[0] 
        $ahead  = $div_split[1]

        if( ( $behind -ne 0 ) -OR
    	    ( $ahead  -ne 0 ) )
        {
            # Add indicators.
            $behind = $behind + "<<"
            $ahead  = $ahead  + ">>"

            # Return output.
            $divergence_msg = "$behind $ahead"
        }
    }

    return( $divergence_msg, ( $divergence_msg -ne $null ) )
}

# Make the following function available for use outside this file.
#Export-ModuleMember __fast_git_prompt

# Use the following command while debugging to export all functions defined in this file.
Export-ModuleMember -Function *

