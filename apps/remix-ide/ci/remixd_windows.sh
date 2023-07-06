#!/usr/bin/env bash
# we don't know which EDGE is installed, could be 112 or 114, it's unclear why the image is not consistent
set -e
TEST_EXITCODE=0
yarn run ganache-cli &
npx http-server -p 9090 --cors='*' ./node_modules &
yarn run serve:production &
yarn run selenium:edge114 &
sleep 5

TESTFILES=$(grep -IRiL "@disabled" "dist/apps/remix-ide-e2e/src/tests" | grep remixd | circleci tests split)
for TESTFILE in $TESTFILES; do
    npx nightwatch --config dist/apps/remix-ide-e2e/nightwatch.js ${TESTFILE} --env=edge || TEST_EXITCODE=1
done

echo "$TEST_EXITCODE"

# kill process
npx -y kill-port 8080
npx -y kill-port 8545
npx -y kill-port 9090
npx -y kill-port 4444

if [ "$TEST_EXITCODE" -eq 1 ]
then

  # if 114 fails, try 112 
  echo "Tests failed Retry"

  TEST_EXITCODE=0
  yarn run ganache-cli &
  npx http-server -p 9090 --cors='*' ./node_modules &
  yarn run serve:production &
  yarn run selenium:edge112 &
  sleep 5

  TESTFILES=$(grep -IRiL "@disabled" "dist/apps/remix-ide-e2e/src/tests" | grep remixd | circleci tests split)
  for TESTFILE in $TESTFILES; do
      npx nightwatch --config dist/apps/remix-ide-e2e/nightwatch.js ${TESTFILE} --env=edge || TEST_EXITCODE=1
  done

  echo "$TEST_EXITCODE"

  # kill process
  npx -y kill-port 8080
  npx -y kill-port 8545
  npx -y kill-port 9090
  npx -y kill-port 4444

  if [ "$TEST_EXITCODE" -eq 1 ]
  then
    echo "Tests failed"
    exit 1
  else
    echo "Tests passed"
    exit 0
  fi

else
  echo "Tests passed"
  exit 0
fi