module.exports =
  oauth2:
    verifyURL: process.env.VERIFYURL
    scope: process.env.OAUTH2_SCOPE?.split(' ') || [
      'User'
      'Mobile'
    ]
