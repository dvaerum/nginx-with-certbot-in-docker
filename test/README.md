**NOTE:** There is currently only a test for dns challenge for `acme.sh` not `certbot`  

# Tests

## iDNS Challenge
To use the test export variable
- **ACME_METHOD:** You provider 
- **DOMAIN:** the domain you want to test with
- **DOCKER_ENV:** Need it be something like `'--env PROVIDER_Username=user --env PROVIDER_Password=password'`
