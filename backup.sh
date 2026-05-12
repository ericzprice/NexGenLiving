#!/bin/zsh
echo "Pulling from Salesforce..."
sf project retrieve start --manifest manifest/package.xml --target-org nexgen-dev

echo "Staging changes..."
git add .

echo "Enter a commit message:"
read msg

git commit -m "$msg"

echo "Pushing to GitHub..."
git push

echo "Done. Backup complete."