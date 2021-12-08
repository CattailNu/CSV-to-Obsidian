# /bin/bash

#############################################################

# Convert a CSV to an Obsidian vault.

# Created by T. L. Ford, www.Cattail.Nu

# If you find this useful,
# please consider buying or sharing a link to my books.

#############################################################

# creates obsidian md files from csv
# linking all row data
# linking column data to header name
# /'s are replaced with _'s
# duplicates move to the first column/row occurrence

# Steps:
# create a new folder
# copy this script to that folder
# copy the csv to that folder

# in terminal:
# change to the folder
#   cd foldername
# make the script executable
#   chmod +x csvToObsidian.bash
# create an md folder
#   mkdir md
# run the script
#   ./csvToObsidian.bash FILENAME

# csv file requirements:
# first line contains field names
# cells cannot contain carriage returns / line feeds
# no smart quotes as string delimiters

#############################################################


FILENAME=$1

if [ ! $1 ]
then
  echo "Requires file name."
  exit
fi 

echo "Formatting Data"

# swap windows carriage returns to unix
sed $'s/\r$//' "$FILENAME" > 0.txt

# remove ,, (empty cells)
sed 's/^,*$//g' 0.txt > 1.txt

# remove commas at end of line
sed 's/,*$//g' 1.txt > 2.txt

# remove blank lines
sed '/^$/d' 2.txt > 3.txt
sed '/^[[:space:]]*$/d' 3.txt > 4.txt


# get lines in file
LINES=$(cat 4.txt)

# reset md for testing
# echo "Recreating md Directory"
# rm -rf md
# mkdir md

echo "Opening Data"
# split the first line into an array for the vertical linking
IFS="," read -r -a FIRSTLINE <<< "$LINES[0]"

IFS=$'\n'

# loop through lines in file, creating files
for LINE in $LINES
do
  echo "Processing: $LINE"

  # replace commas inside quotes with ~'s
  nocomma=0
  newstr=""
  for (( i=0; i<${#LINE}; i++ ))
  do
    # echo "${LINE:$i:1}"
    if [ "${LINE:$i:1}" == '"' ]
    then
      if [ "$nocomma" == "1" ]
      then
        nocomma=0
      else
        nocomma=1
      fi
    fi
    if [ "$nocomma" == "1" ] && [ "${LINE:$i:1}" == ',' ]
    then
      newstr="${newstr}~tlf~"
    else
      newstr="${newstr}${LINE:$i:1}"
    fi
  done

  OLDLINE=$LINE
  LINE=$newstr

  # split current line into array
  IFS="," read -r -a array <<< "$LINE"
    
  # loop through the array
  # create files if they don't exist

  for ((a=0;a<${#array[@]};a++))
  do
    element="${array[a]}"
    # Restore the commas
    newstr=$(sed -e "s/~tlf~/,/g" <<< "$element")
    element=$newstr

    # Remove outside quotes
    newstr=$(sed -e "s/^\"//" <<< "$element")
    element=$newstr
    newstr=$(sed -e "s/\"$//" <<< "$element")
    element=$newstr

    # Restore single quotes
    newstr=$(sed -e "s/\"\"/\"/" <<< "$element")
    element=$newstr

    # Change / 's to underscores
    newstr=$(sed -e "s/\//_/" <<< "$element")
    element=$newstr


    array[a]="$element"

    if [ ! "$element" == "" ]
    then
      # echo "$element"
      # check if the file doesn't exist
      if [ ! -f "md/${element}.md" ]
      then
        # echo "File is not found"
        # create file
        touch "md/${element}.md"
        #echo "md/${element}.md"
      fi
    fi
  done

  # build horizontal links
  # if word is not equal to file name, add a link

  for element in "${array[@]}"
  do
    if [ ! "$element" == "" ]
    then
      for element2 in "${array[@]}"
      do

        if [ ! "$element2" == "" ]
        then
          el=$(echo "$element" | tr '[:upper:]' '[:lower:]')
          el2=$(echo "$element2" | tr '[:upper:]' '[:lower:]')
          if [ ! "$el" == "$el2" ]
          then
            echo "[[${element2}]]" >> "md/${element}.md"
          fi
        fi
      done
    fi
  done

  # build vertical links
  # if word is not equal to file name, add a link

  # if not on the first line
  if [ "$LINES[0]" != "$OLDLINE" ]
  then
    for ((i=0;i<${#array[@]};i++))
    do
      if [ ! "${array[i]}" == "" ]
      then
        el=$(echo "${array[i]}" | tr '[:upper:]' '[:lower:]')
        el2=$(echo "${FIRSTLINE[i]}" | tr '[:upper:]' '[:lower:]')
        if [ ! "$el" == "$el2" ]
        then
          echo "[[${array[i]}]]" >> "md/${FIRSTLINE[i]}.md"
        fi
      fi
    done
  fi
done

echo "Sorting and Removing Duplicates"

# sort file contents
# remove duplicates in file

# loop through files
for FILE in md/*
do
  # echo $FILE
  sort "$FILE" | uniq > tmp.txt 
  mv tmp.txt "$FILE"
done

echo "Sorting Files into Subdirectories for Columns"

# move column files into subdirectories
IFS=$'\n'

# make some directories
for ((i=0;i<${#FIRSTLINE[@]};i++))
do
  #echo "${FIRSTLINE[i]}"
  mkdir "md/${FIRSTLINE[i]}"
done

# if the line isn't a directory, move the file
for ((i=0;i<${#FIRSTLINE[@]};i++))
do
  # echo "${FIRSTLINE[i]}"
  LINES=$(cat "md/${FIRSTLINE[i]}.md")
  for LINE in $LINES
  do
    # echo $LINE
    # strip the link markers
    newstr=$(sed -e "s/\[\[//g" <<< "$LINE")
    LINE=$(sed -e "s/\]\]//g" <<< "$newstr")
    if [ ! -d "md/$LINE" ]
    then
      mv "md/${LINE}.md" "md/${FIRSTLINE[i]}/" 2>/dev/null
    fi
  done
done


# clean up text files
rm *.txt

echo "Files Created:"
ls -R md

echo "DONE"

# EOF
