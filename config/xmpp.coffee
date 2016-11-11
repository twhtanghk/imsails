domain = process.env.DOMAIN || 'mob.myvnc.com'

module.exports =
  xmpp:
    domain: domain
    muc: "muc.#{domain}"
