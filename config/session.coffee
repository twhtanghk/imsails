module.exports = 
  session:
    collection: 'session'
    adapter: 'mongo'
    url: process.env.DB || 'mongodb://im_mongo/im'
    secret: process.env.COOKIE_SECRET
    cookie:
      maxAge: parseInt process.env.COOKIE_EXPIRE || '600000', 10
      httpOnly: true
      secure: false  # assume front end (nginx) directly connected to this app
