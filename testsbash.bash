#!/bin/bash -x
set -x #echo on

if [ $CIRCLE_NODE_INDEX -eq 0 ]
then

  npm run --silent lint -- --max-warnings 0

  npm run --silent lint_md

  flake8 $(git ls-files "*.py")

  yamllint $(git ls-files "*.yml")

  mkdir -p $CIRCLE_TEST_REPORTS/unit

  npm run unit_coverage

  npm run start_dmd &
  bash wait_for_local_port.bash 9990 40 &&
  npm run multiple_backend_test

  S3BACKEND=mem S3DATA=multiple npm start
  > $CIRCLE_ARTIFACTS/server_multiple_java.txt &
  bash wait_for_local_port.bash 8000 40 && cd ./tests/functional/jaws &&
  mvn test

  kill -9 $(lsof -t -i:8000)

  S3BACKEND=mem S3DATA=multiple npm start
  > $CIRCLE_ARTIFACTS/server_multiple_fog.txt &
  bash wait_for_local_port.bash 8000 40 && cd tests/functional/fog &&
  rspec tests.rb

  kill -9 $(lsof -t -i:8000)

  S3BACKEND=mem MPU_TESTING=yes S3DATA=multiple npm start
  > $CIRCLE_ARTIFACTS/server_multiple_awssdk.txt
  bash wait_for_local_port.bash 8000 40 && S3DATA=multiple npm run ft_awssdk

  kill -9 $(lsof -t -i:8000)

  S3BACKEND=mem MPU_TESTING=yes S3DATA=multiple npm start
  > $CIRCLE_ARTIFACTS/server_multiple_kms_awssdk.txt &
  bash wait_for_local_port.bash 8000 40 &&
  S3DATA=multiple ENABLE_KMS_ENCRYPTION=true npm run ft_awssdk

  kill -9 $(lsof -t -i:8000)

fi

if [ $CIRCLE_NODE_INDEX -eq 1 ]
then

  S3BACKEND=mem MPU_TESTING=yes S3DATA=multiple npm start
  > $CIRCLE_ARTIFACTS/server_multiple_kms_awssdk.txt &
  bash wait_for_local_port.bash 8000 40 &&
  S3DATA=multiple ENABLE_KMS_ENCRYPTION=true npm run ft_awssdk

  kill -9 $(lsof -t -i:8000)

  S3BACKEND=mem npm start
  > $CIRCLE_ARTIFACTS/server_mem_java.txt &
  bash wait_for_local_port.bash 8000 40 &&
  cd ./tests/functional/jaws && mvn test

  kill -9 $(lsof -t -i:8000)

  S3BACKEND=mem npm start
  > $CIRCLE_ARTIFACTS/server_mem_fog.txt &
  bash wait_for_local_port.bash 8000 40 &&
  cd tests/functional/fog && rspec tests.rb

  kill -9 $(lsof -t -i:8000)

  S3BACKEND=mem MPU_TESTING=yes npm start
  > $CIRCLE_ARTIFACTS/server_mem_awssdk.txt &
  bash wait_for_local_port.bash 8000 40 &&
  npm run ft_awssdk

  kill -9 $(lsof -t -i:8000)

  S3BACKEND=mem npm start
  > $CIRCLE_ARTIFACTS/server_mem_s3cmd.txt &
  bash wait_for_local_port.bash 8000 40 &&
  npm run ft_s3cmd

  kill -9 $(lsof -t -i:8000)

fi

exit 0
