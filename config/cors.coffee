module.exports = 
  cors:
    allRoutes: true
    headers: 'content-type, authorization, x-http-method-override'
    origin: process.env.ALLOWED_HOST || '*'
    credentials: false
