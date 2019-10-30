# flight-info

Compacts key FlightAware info down to a JSON. Check out the unit tests to see how it should work.
Designed to run on Lambda.

Pull requests welcome!

# Deploying to Lambda

1. Copy `.env.example` to `.env`. Fill in the values.
2. Run `scripts/unit` to verify that everything is functional. It uses a saved copy of a sample
   FlightAware flight and does not use the Internet at all.
3. Run `scripts/integration` to ensure that the scripts work on Lambda for your AWS account.
4. Run `ENVIRONMENT=production scripts/deploy` to deploy the scripts into a domain that you own.

# Caveats

1. Unfortunately CI/CD is pretty manual at the moment.
2. You might get `ObsoleteNodeErrors` sometimes. Not sure why this happens. Sending another request
   should work.
3. It uses PhantomJS/Poltergeist under the hood due to it being more compatible with Lambda. I
   attempted to use a Lambda-optimized version of Chromium and ChromeDriver but ran into lots of
   issues. If you'd like to try getting this to work, check out the `feature/use-chrome` branch.
4. The `flightInfo` method is private to avoid scraping and abuse. Until I get around to using a
   Cognito custom authorizer, you'll need to add `x-api-key: $KEY_FROM_SERVERLESS` to your requests
   for this to work.
