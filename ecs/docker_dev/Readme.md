aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 654654507397.dkr.ecr.us-east-1.amazonaws.com

docker build -t web-app .

docker tag web-app:latest 654654507397.dkr.ecr.us-east-1.amazonaws.com/web-app-repository:dev-latest

docker push 654654507397.dkr.ecr.us-east-1.amazonaws.com/web-app-repository:dev-latest
