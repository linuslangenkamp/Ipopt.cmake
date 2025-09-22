#------------------------------------------------------------
# Find Git
#------------------------------------------------------------

#   GIT_EXECUTABLE - path to git command line client
#   GIT_FOUND - true if the command line client was found
#   GIT_VERSION_STRING - the version of git found (since CMake 2.8.8)

find_package(Git)

if (NOT GIT_FOUND)
  message(ERROR "Git required to build this tool")
endif ()

if (NOT TARGET git-update)
  add_custom_target(git-update)
endif ()

# Clone a git repository by branch.
# Input variables:
# - Path_repo: the URL of the repo (git@192.168.0.18:NetworkDesignerDemo for example)
# - Path_dest: the URL of the destination directory (/home/me/myclonedrepo/ for example)
# - Repo_branch: the name of the branch to be cloned
# - Repo_commit: the hash tag of the commit to be retrieved (HEAD for example)
# - Rule_name: the name of the rule to update the repo
macro(clone_git_branch Path_repo Path_dest Repo_branch Repo_commit Rule_name)
  if ("${Repo_branch}" STREQUAL "master")
    message(FATAL_ERROR "Can't clone the master branch, use the 'clone_git' macro instead")
  endif ()
  
  if ("${Repo_commit}" STREQUAL "")
    set (Repo_commit "HEAD")
  endif ()
  
  if (NOT EXISTS ${Path_dest})
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${Path_dest})
    execute_process(COMMAND ${GIT_EXECUTABLE} clone -b ${Repo_branch} ${Path_repo} ${Path_dest}
                    OUTPUT_VARIABLE _GIT_CLONE_GIT_BRANCH_OUTPUT
                    ERROR_VARIABLE  _GIT_CLONE_GIT_BRANCH_ERROR)
    if (NOT ${_GIT_CLONE_GIT_BRANCH_ERROR} EQUAL 0)
      message(SEND_ERROR "Command ${GIT_EXECUTABLE} clone failed with output:\n${_GIT_CLONE_GIT_BRANCH_ERROR}")
    endif ()
  endif ()

  add_custom_target(git-update-branch-${Rule_name})
  add_custom_command(TARGET git-update-branch-${Rule_name}
                     COMMAND ${GIT_EXECUTABLE} pull
                     WORKING_DIRECTORY ${Path_dest}
                     COMMENT "clone_git_branch: updating repository branch ${Repo_branch} in ${Path_dest}")
  
  add_dependencies(git-update git-update-branch-${Rule_name})
  
  add_subdirectory(${Path_dest})
endmacro(clone_git_branch)

# Clone a git repository by tag.
# Input variables:
# - Path_repo: the URL of the repo (git@192.168.0.18:NetworkDesignerDemo for example)
# - Path_dest: the URL of the destination directory (/home/me/myclonedrepo/ for example)
# - Repo_branch: the name of the branch to be cloned
# - Repo_commit: the hash tag of the commit to be retrieved (HEAD for example)
# - Rule_name: the name of the rule to update the repo
macro(clone_git_tag Path_repo Path_dest Repo_tag Repo_commit Rule_name)
  if ("${Repo_tag}" STREQUAL "master")
    message(FATAL_ERROR "Can't clone the tag branch, use the 'clone_git' macro instead")
  endif ()
  
  if ("${Repo_commit}" STREQUAL "")
    set (Repo_commit "HEAD")
  endif ()
  
  if (NOT EXISTS ${Path_dest})
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${Path_dest})
    execute_process(COMMAND ${GIT_EXECUTABLE} clone ${Path_repo} ${Path_dest}
                    COMMAND ${GIT_EXECUTABLE} checkout tags/${Repo_tag} ${Repo_commit}
                    WORKING_DIRECTORY ${Path_dest}
                    OUTPUT_VARIABLE _GIT_CLONE_GIT_TAG_OUTPUT
                    ERROR_VARIABLE  _GIT_CLONE_GIT_TAG_ERROR)
    
    if (NOT ${_GIT_CLONE_GIT_TAG_ERROR} EQUAL 0)
      message(SEND_ERROR "Command ${GIT_EXECUTABLE} clone failed with output:\n${_GIT_CLONE_GIT_TAG_ERROR}")
    endif ()
  endif ()

  add_custom_target(git-update-tag-${Rule_name})
  add_custom_command(TARGET git-update-tag-${Rule_name}
                     COMMAND ${GIT_EXECUTABLE} pull
                     WORKING_DIRECTORY ${Path_dest}
                     COMMENT "clone_git_tag: updating repository tag ${Repo_branch} in ${Path_dest}")
  
  add_dependencies(git-update git-update-tag-${Rule_name})
  
  add_subdirectory(${Path_dest})
endmacro(clone_git_tag)

# Clone a git repository
# Input variables:
# - Path_repo: the URL of the repo (git@192.168.0.18:NetworkDesignerDemo for example)
# - Path_dest: the URL of the destination directory (/home/me/myclonedrepo/ for example)
# - Repo_commit: the hash tag of the commit to be retrieved (HEAD for example)
# - Rule_name: the name of the rule to update the repo
macro(clone_git Path_repo Path_dest Repo_commit Rule_name)
  if ("${Repo_commit}" STREQUAL "")
    set (Repo_commit "HEAD")
  endif ()
  
  if (NOT EXISTS ${Path_dest})
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${Path_dest})
    execute_process(COMMAND ${GIT_EXECUTABLE} clone ${Path_repo} ${Path_dest}
                    WORKING_DIRECTORY ${Path_dest}
                    OUTPUT_VARIABLE _GIT_CLONE_GIT_BRANCH_OUTPUT
                    ERROR_VARIABLE  _GIT_CLONE_GIT_BRANCH_ERROR)
    
    if (NOT ${_GIT_CLONE_GIT_BRANCH_ERROR} EQUAL 0)
      message(SEND_ERROR "Command ${GIT_EXECUTABLE} clone failed with output:\n${_GIT_CLONE_GIT_BRANCH_ERROR}")
    endif ()
  endif ()

  add_custom_target(git-update-${Rule_name})
  add_custom_command(TARGET git-update-${Rule_name}
                     COMMAND ${GIT_EXECUTABLE} pull
                     WORKING_DIRECTORY ${Path_dest}
                     COMMENT "clone_git: updating repository tag ${Repo_branch} in ${Path_dest}")
  
  add_dependencies(git-update git-update-${Rule_name})
  
  add_subdirectory(${Path_dest})
endmacro(clone_git)
