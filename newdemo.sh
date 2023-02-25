#!/bin/bash

cat <<'END_BANNER'
 ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄    ▄▄▄▄▄▄  ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄▄▄▄▄▄
█       █  █▄█  █   █       █      █  █      ██       █  █▄█  █       █
█   ▄   █       █   █   ▄▄▄▄█  ▄   █  █  ▄    █    ▄▄▄█       █   ▄   █
█  █▄█  █       █   █  █  ▄▄█ █▄█  █  █ █ █   █   █▄▄▄█       █  █ █  █
█       █       █   █  █ █  █      █  █ █▄█   █    ▄▄▄█       █  █▄█  █
█   ▄   █ ██▄██ █   █  █▄▄█ █  ▄   █  █       █   █▄▄▄█ ██▄██ █       █
█▄▄█ █▄▄█▄█   █▄█▄▄▄█▄▄▄▄▄▄▄█▄█ █▄▄█  █▄▄▄▄▄▄██▄▄▄▄▄▄▄█▄█   █▄█▄▄▄▄▄▄▄█
     ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄▄▄▄▄▄ ▄▄▄     ▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄
    █       █       █  █▄█  █       █   █   █      █       █       █
    █▄     ▄█    ▄▄▄█       █    ▄  █   █   █  ▄   █▄     ▄█    ▄▄▄█
      █   █ █   █▄▄▄█       █   █▄█ █   █   █ █▄█  █ █   █ █   █▄▄▄
      █   █ █    ▄▄▄█       █    ▄▄▄█   █▄▄▄█      █ █   █ █    ▄▄▄█
      █   █ █   █▄▄▄█ ██▄██ █   █   █       █  ▄   █ █   █ █   █▄▄▄
      █▄▄▄█ █▄▄▄▄▄▄▄█▄█   █▄█▄▄▄█   █▄▄▄▄▄▄▄█▄█ █▄▄█ █▄▄▄█ █▄▄▄▄▄▄▄█
                          (c) 2023 Rich/Defekt

END_BANNER

PLATFORM="$(uname)"

read -p "Enter your new production's name : " PROD_NAME
read -p "Enter the git remote (eg. git@github.com:yourname/${PROD_NAME}.git or just press enter if not using git) : " GIT_REMOTE

echo -e "\nCopying files..."

cd ..
cp -R AmigaDemoTemplate "${PROD_NAME}"

cd "${PROD_NAME}"
rm newdemo.sh
rm LICENSE
rm -rf .git

cd .vscode
if [[ "$PLATFORM" == "Darwin" ]]; then
  sed -i '' "s/AmigaDemoTemplate/$PROD_NAME/g;" launch.json
  sed -i '' "s/AmigaDemoTemplate/$PROD_NAME/g;" tasks.json
else
  sed -i "s/AmigaDemoTemplate/$PROD_NAME/g;" launch.json
  sed -i "s/AmigaDemoTemplate/$PROD_NAME/g;" tasks.json
fi
cd ..
echo "; Based on AmigaDemoTemplate (c)2023 Rich/Defekt" > "${PROD_NAME}.s"
tail -n +16 AmigaDemoTemplate.s >> "${PROD_NAME}.s"
rm AmigaDemoTemplate.s
if [[ "$PLATFORM" == "Darwin" ]]; then
  sed -i '' "s/AmigaDemoTemplate/$PROD_NAME/g;" uae/dh0/s/startup-sequence
else
  sed -i "s/AmigaDemoTemplate/$PROD_NAME/g;" uae/dh0/s/startup-sequence
fi

echo -n '# ' > README.md
echo $PROD_NAME >> README.md

if [[ "$GIT_REMOTE" != "" ]]; then
  echo "Setting up git repo..."

  git init &> /dev/null &&
  git add . &> /dev/null &&
  git commit -m "Initial commit" &> /dev/null &&
  git branch -M main &> /dev/null &&
  git remote add origin $GIT_REMOTE &> /dev/null &&
  git push -u origin main &> /dev/null || echo "Error setting up git!"
fi

echo "Finished!"
