#!/usr/bin/env bash

# /components/example.sh should logically not be sourced

# Now we use 'Condition_File_Must_Be_Present' instead of copy paste this fct
function idempotent_file_exist {
  _file_is="somefile.sh"
  if [[ -f "${_path_components}/${_file_is}" ]]; then
    echo "idempotent checkpoint passed" > /dev/null 2>&1
    source "${_path_components}/${_file_is}"
  
  elif [[ ! -f "${_path_components}/${_file_is}" ]]; then
    my_message="Warning: no file: ${_file_path_is}" && Print_Warning_Stop

  else
    my_message="FATAL: idempotent_file_exist | ${_file_is}" && Print_Fatal
  fi
}

# Now we use 'Condition_Vars_Must_Be_Not_Empty' instead of copy paste this fct
function idempotent_empty_var {
  if [[ -n "${run_id}" ]]; then    #if not empty
    echo "idempotent checkpoint passed" > /dev/null 2>&1
    my_message="SOME_MESSAGE_HERE" && Print_Blue

  elif [[ -z "${run_id}" ]]; then    #if empty
    my_message="Warning: variable is empty" && Print_Warning_Stop

  else
    my_message="FATAL: idempotent_empty_var | ${run_id}" && Print_Fatal
  fi
}

# Now we use 'App_Does_Var_Notset' instead of copy paste this fct
function idempotent_compare_var {
  if [[ "${input_2}" != "not_set" ]]; then
    echo "idempotent checkpoint passed" > /dev/null 2>&1
    my_message="SOME_MESSAGE_HERE" && Print_Blue

  elif [[ "${input_2}" == "not_set" ]]; then
    my_message="Warning: variable is empty" && Print_Warning_Stop

  else
    my_message="FATAL: idempotent_compare_var | ${input_2}" && Print_Fatal
  fi
}

# Example 1: Output a Description for Each Option
function case_a {
  echo && echo "Which color do you like best?"
  my_message="1 - Blue" && Print_Blue
  echo "2 - Red"
  my_message="3 - Yellow" && Print_Warning
  my_message="4 - Green" && Print_Green
  echo "5 - Orange"
  read -r user_input;
  case ${user_input} in
    1) my_message="Blue is a primary color." && Print_Blue;;
    2) echo "Red is a primary color.";;
    3) my_message="Yellow is a primary color." && Print_Yellow;;
    4) my_message="Green is a secondary color." && Print_Green;;
    5) echo "Orange is a secondary color.";;
    *) echo "This color is not available. Please choose a different one.";; 
  esac
}

# Example 2: Using Multiple Patterns
function case_b {
  shopt -s nocasematch
  echo "Enter the name of a month."
  read -r month
  case ${month} in
    February | Feb)
      echo "There are 28/29 days in ${month}.";;
    April | June | September | November)
      echo "There are 30 days in ${month}.";;
    January | March | May | July | August | October | December)
      echo "There are 31 days in ${month}.";;
    *)
      echo "Unknown month. Please check if you entered the correct month name: ${month}";;
  esac
}

# Example 3: for Loops
function case_c {

  for f in *.wav
  do
    [[ -e "$f" ]] || break  # handle the case of no *.wav files
    echo "$f"
  done
}

#Example 4: Create an Address Book
function case_d {
  echo "Choose a contact to display information:"
  echo "[C]hris Ramsey"
  echo "[J]ames Gardner"
  echo "[S]arah Snyder"
  echo "[R]ose Armstrong"
  read -r person
  case "$person" in
    "C" | "c" ) echo "Chris Ramsey"
  echo "cramsey@email.com"
  echo "27 Railroad Dr. Bayside, NY";;
    "J" | "j" ) echo "James Gardner"
  echo "jgardner@email.com"
  echo "31 Green Street, Green Cove Springs, FL";;
    "S" | "s") echo "Sarah Snyder"
  echo "ssnyder@email.com"
  echo "8059 N. Hartford Court, Syosset, NY";;
    "R" | "r") echo "Rose Armstrong"
  echo "rarmstrong@email.com"
  echo "49 Woodside St., Oak Forest, IL";;
    *) echo "Contact doesn't exist.";;
  esac
}

# Read: Asking input from the User
function case_ex1 {
  echo "What is your name?"
  read -r name
  echo "Your name is ${name}!"
}

# Mapfile: Assigning a variable the values of a file's lines
function case_ex2 {
  mapfile -t file_var < ${_path_components}/list.txt

  for i in "${file_var[@]}"; do
    echo "${i}"
  done
}

# Setting the value when a variable isn't set
function case_ex3 {
  echo "What is your name?"
  read -r name
  echo "Your name is ${name}!"
}

# Mapfile: Assigning a variable the values of a file's lines
function case_ex4 {
  echo "Hello ${name:-nobody}!"
}

function var_as_file {
  # sometime it's useful to have a variable as a file
  _my_var=(Yes No Maybe)
  cat <(echo "${_my_var[@]}")
}

function rlwrap_example {
# https://unix.stackexchange.com/questions/278631/bash-script-auto-complete-for-user-input-based-on-array-data#278666
# works but it's not clean 2022-04-28_20h26

  _choice=(Yes No Maybe)

  reply=$(rlwrap -S 'Do you want to continue? ' -H ~/.jakob.history -e '' -i -f <(echo "${_choice[@]}") -o cat)

  echo "reply='$reply'"
}

function lint {
  docker run -it --rm \
    -v "$(pwd)"/Dockerfile:/Dockerfile:ro \
    redcoolbeans/dockerlint
}

function demo_set_var_if_empty {
  # Setting variable value (if unset)
  echo ${country:-Greenland}
  echo ${country:=Greenland}
}
