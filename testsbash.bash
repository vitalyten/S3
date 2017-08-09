#!/bin/bash -x

if [ $CIRCLE_NODE_INDEX -eq 0 ] then

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
  > $CIRCLE_ARTIFACTS/server_multiple_java.txt
  & bash wait_for_local_port.bash 8000 40
  && cd ./tests/functional/jaws && mvn test

  kill -9 $(lsof -t -i:8000)

  S3BACKEND=mem S3DATA=multiple npm start
  $CIRCLE_ARTIFACTS/server_multiple_fog.txt
  & bash wait_for_local_port.bash 8000 40
  && cd tests/functional/fog && rspec tests.rb

fi

exit 0
