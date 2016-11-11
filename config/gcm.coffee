domain = process.env.DOMAIN || 'mob.myvnc.com'

module.exports =
  push:
    url: "https://#{domain}/mobile/api/push"
    data:
      url: '/chat/<%=roster.type%>/<%=roster.user ? roster.user.id : roster.group.id%>'
      title: '<%=roster.name()%>'
      message: '<%=roster.newmsg%> new message(s)'
