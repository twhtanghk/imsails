module.exports = 
  cors:
    allRoutes: true
    headers: 'content-type, authorization'
    origin: process.env.ALLOWED_HOST || '*'
    credentials: false
