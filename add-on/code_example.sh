#!/usr/bin/env bash

# Example 1: Output a Description for Each Option
function case_a {
  echo && echo "Which color do you like best?"
  my_message="1 - Blue" && App_Blue
  echo "2 - Red"
  my_message="3 - Yellow" && App_Warning
  my_message="4 - Green" && App_Green
  echo "5 - Orange"
  read user_input;
  case ${user_input} in
    1) my_message="Blue is a primary color." && App_Blue;;
    2) echo "Red is a primary color.";;
    3) my_message="Yellow is a primary color." && App_Yellow;;
    4) my_message="Green is a secondary color." && App_Green;;
    5) echo "Orange is a secondary color.";;
    *) echo "This color is not available. Please choose a different one.";; 
  esac
}

# Example 2: Using Multiple Patterns
function case_b {
  shopt -s nocasematch
  echo "Enter the name of a month."
  read month
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
  for file in $(ls)
  do
  Extension=${file##*.}
  case "$Extension" in
    sh) echo "Shell script: $file";;
    md) echo "A markdown file: $file";;
    png) echo "PNG image file: $file";;
    txt) echo "A text file: $file";;
    zip) echo "An archive: $file";;
    conf) echo "A configuration file: $file";;
    py) echo "A Python script: $file";;
    *) echo "Unknown file type: $file";;
  esac
  done
}

#Example 4: Create an Address Book
function case_d {
  echo "Choose a contact to display information:"
  echo "[C]hris Ramsey"
  echo "[J]ames Gardner"
  echo "[S]arah Snyder"
  echo "[R]ose Armstrong"
  read person
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
  read name
  echo "Your name is ${name}!"
}

# Mapfile: Assigning a variable the values of a file's lines
function case_ex2 {
  mapfile -t file_var < ${local_bashlava_addon_path}/list.txt

  for i in "${file_var[@]}"; do
    echo "${i}"
  done
}

# Setting the value when a variable isn't set
function case_ex3 {
  echo "What is your name?"
  read name
  echo "Your name is ${name}!"
}

# Mapfile: Assigning a variable the values of a file's lines
function case_ex4 {
  echo "Hello ${name:-nobody}!"
}

function idempotent_compare_var {
  # example only: var needs to be ajusted

  if [[ "${input_2}" != "not-set" ]]; then
    echo "All good and idempotent" > /dev/null 2>&1
    my_message="SOME_MESSAGE_HERE" && App_Blue

  elif [[ "${input_2}" == "not-set" ]]; then
    my_message="Warning: pr_title variable is empty. (WARN_999)" && App_Warning_Stop

  else
    my_message="FATAL: Please open an issue for this behavior (ERR_999)" && App_Fatal
  fi
}

function idempotent_empty_var {
  # example only: var needs to be ajusted

  if [[ -n "${run_id}" ]]; then    #if not empty
    echo "All good and idempotent" > /dev/null 2>&1
    my_message="SOME_MESSAGE_HERE" && App_Blue

  elif [[ -z "${run_id}" ]]; then    #if empty
    my_message="Warning: pr_title variable is empty. (WARN_999)" && App_Warning_Stop

  else
    my_message="FATAL: Please open an issue for this behavior (ERR_999)" && App_Fatal
  fi
}

function idempotent_file_exist {
  # example only: file needs to be ajusted

  if [ -f ${my_path}/somefile.sh ]; then
    echo "All good and idempotent" > /dev/null 2>&1
    my_message="SOME_MESSAGE_HERE" && App_Blue

  elif [ ! -f ${my_path}/somefile.sh ]; then
    my_message="Warning: /somefile.sh is not present. (WARN_999)" && App_Warning_Stop

  else
    my_message="FATAL: Please open an issue for this behavior (ERR_999)" && App_Fatal
  fi
}

function example_array {
  arr=( "hello" "world" "from entrypoint" )
  
  echo
  for i in "${arr[@]}"; do
    my_message="${i}" && App_Green
  done
}

function banner {
  figlet_message="Banner Test"
  App_figlet
}

function passgen {
  docker run --rm devmtl/alpine:3.11_2020-02-26_08H42s20_dec5798 sh "random7.sh"
}

function lint {
  docker run -it --rm \
    -v $(pwd)/Dockerfile:/Dockerfile:ro \
    redcoolbeans/dockerlint
}
