# imsails

Instant messaging app via rest or websocket API


Server API
---------------------------------------------------------
## user

* attributes

	see [api/models/User.coffee](https://github.com/twhtanghk/imsails/blob/master/api/models/User.coffee)
		
* api

```
    post /api/user - create user by authenticated admin only
    get /api/user - list users for the specified pagination/sorting parameters skip, limit, sort
    get /api/user/:id - read user attributes of the specified id
    get /api/user/profile - get user profiles for email list specified in req.body (e.g. email: ["a@abc.com", "b@abc.com", ...])
    get /user/photo/:id - get user photo 
    get /api/user/me - read user attributes of current login user
    put /api/user/me - update user attributes of current login user excluding attribute id, jid, photoUrl 
```

## group

* attributes
	
	see [api/models/Group.coffee](https://github.com/twhtanghk/imsails/blob/master/api/models/Group.coffee)
	
* api
	```
	post /api/group - create group with the specified attributes excluding id, jid, photoUrl
	post /api/group/:parentid/members/:id - add user with :id into group with :parentid as members
	post /api/group/:parentid/moderators/:id - add user with :id into group with :parentid as moderators
    get /api/group - list all public groups (moderated or unmoderated)
    get /api/group/membersOnly - list private groups (members only) with current login user as member
    get /api/group/me - list groups created by current login user
    get /api/group/name/:name - get group details with specified name created by current login user
    get /api/group/:id - get group details with specified group id
    get /group/photo/:id - get group photo
    put /api/group/:id - update group attributes of the specified id exlcuding id, jid, photoUrl
    del /api/group/:id - delete group of the specified id
    del /api/group/:id/members - remove current login user from  member list of the specified group (leave group)
    del /api/group/:id/moderators - remove current login user from  moderator list of the specified group (leave group)
	```

## roster
   
* attributes

	see [api/models/Roster.coffee](https://github.com/twhtanghk/imsails/blob/master/api/models/Roster.coffee)

* api

	``` 
    post /api/roster - create a roster item with the specified attributes excluding id, jid
    get /api/roster - list all roster items for current login user
    del /api/roster/:id - delete roster item of the specified jid
	```

## msg

* attributes
	
	see [api/models/Msg.coffee](https://github.com/twhtanghk/imsails/blob/master/api/models/Msg.coffee)

* api
	```
    get /api/msg - read message history for the specified chat type (type) and target user or group jid (to) (e.g. {type: 'chat', to: 'user@mob.myvnc.com'} or {type: 'groupchat', to: 'news@muc.mob.myvnc.com'})
    get /api/msg/file/:id - get file attachment for the specified message id
    post /api/msg - send message with the specified attributes
    post /api/msg/file - send file attachment with the specified attributes
	```

Configuration
=============

* download .env and docker-compose.yml
* cusotomize values defined in .env
* docker-compose -f docker-compose.yml up -d

Compile android package
=======================
```
apt-get update
apt-get install vim -y
mkdir -p /home/twhtang/.android
mv /tmp/release.keystore /home/twhtang/.android
/opt/android/tools/bin/sdkmanager 'extras;android;m2repository'
vi build.json
node_modules/.bin/gulp android
cp -a res platforms/android/
cordova build android
```
