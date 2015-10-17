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

  }).then(function(role) {

    // Add a new job to the Job Queue to turn all photos to private.
    // We use a queue instead of calling it directly because it could take awhile.
    var JobQueue = Parse.Object.extend("JobQueue");
    var job = new JobQueue();
    job.set("name", "userBecamePrivate");
    job.set("user", user);
    job.set("action", "changePhotosToPrivate");
    return job.save();

  }).then(function(job) {
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

  }).then(function(role) {

    // Add a new job to the Job Queue to turn all photos to public.
    // We use a queue instead of calling it directly because it could take awhile.
    var JobQueue = Parse.Object.extend("JobQueue");
    var job = new JobQueue();
    job.set("name", "userBecamePublic");
    job.set("user", user);
    job.set("action", "changePhotosToPublic"); 
    return job.save();

  }).then(function(job) {
    response.success("Success! - Account Now Public");
  }, function(error) {
    response.error(error);
  });
});


