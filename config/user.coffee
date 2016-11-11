domain = process.env.DOMAIN || 'mob.myvnc.com'

module.exports =
  adminUser:
    username: 'imadmin'
    email: "imadmin@#{domain}"
  authGrp: 'Authenticated Users'
