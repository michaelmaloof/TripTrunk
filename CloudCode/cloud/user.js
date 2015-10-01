Parse.Cloud.beforeSave(Parse.User, function(request, response) {
  if (request.object.get("name")) {
    request.object.set("lowercaseName", request.object.get("name").toLowerCase())
  }
  response.success();  
});


/*
 * AFTER SAVE
 */
Parse.Cloud.afterSave(Parse.User, function(request, response) {
	var user = request.object;
	if (user.existed()) { return; } // user already exists (not account creation) so just return

		// First time user is being saved
		// Set up a Role for their friends. 
		// Friend Roles are only used if a user sets their account to Private, but we set it up now so it'll be ready if they ever switch their account

		var roleName = "friendsOf_" + user.id; // Unique role name
		var acl = new Parse.ACL(user);
		acl.setPublicReadAccess(true); // Initially, we set up the Role to have public
		acl.setPublicWriteAccess(true); // We give public write access to the role also - Anyone can decide to be someone's friend (aka follow them)

		// In the future, if the user makes their account Private, the ACL for their role gets changed. This lets existing followers be part of
		// the role still even though they didn't have to "request" to follow

		var friendRole = new Parse.Role(roleName, acl); 
		return friendRole.save(null, {useMasterKey: true}).then(function(friendRole) {
			console.log("Successfully saved new role: " + roleName);
			return;
		}, function(error) {
			console.log("Error saving new role: " + error.description);
		});

});


/*
 * Function that changes the request User's role ACL to be private so they must approve new people joining their role.
 * No Parameters
 */
Parse.Cloud.define("becomePrivate", function(request, response) {
  var user = request.user;

  user.set("private", true);
  user.save();

  var roleName = "friendsOf_" + request.user.id;
  var roleQuery = new Parse.Query("_Role");
  roleQuery.equalTo("name", roleName);

  roleQuery.first().then(function(role) {
    role.setACL(new Parse.ACL(user));
    return role.save();

  }).then(function() {
  	// TODO: Update any objects with this friendsOf role to be read-only for this role, not public.
  	// i.e. Photos will be Public and friendsOf read since not everyone who sees the photos will be this persons friend.
  	// But now only friends can see the photos.
  	// Maybe this should call a Background Job so we aren't limited to a few seconds.
  }).then(function() {
    response.success("Success! - Account Now Private");
  }, function(error) {
    response.error(error);
  });
});

/*
 * Function that changes the request User's role ACL to be Public so anyone can follow them. This is the default for new users already.
 * No Parameters
 */
Parse.Cloud.define("becomePublic", function(request, response) {
  var user = request.user;

    user.set("private", false);
  user.save();

  var roleName = "friendsOf_" + request.user.id;
  var roleQuery = new Parse.Query("_Role");
  roleQuery.equalTo("name", roleName);

  roleQuery.first().then(function(role) {
  	var acl = new Parse.ACL(user);
		acl.setPublicReadAccess(true); // Initially, we set up the Role to have public
		acl.setPublicWriteAccess(true); // We give public write access to the role also - Anyone can decide to be someone's friend (aka follow them)
    role.setACL(acl);
    return role.save();

  }).then(function() {
  	// TODO: Update any objects with this friendsOf role to be public
  	// i.e. Photos will be friendsOf read but needs to be Public read now that their account is public.

  	// Maybe this should call a Background Job so we aren't limited to a few seconds.
  }).then(function() {
    response.success("Success! - Account Now Public");
  }, function(error) {
    response.error(error);
  });
});


