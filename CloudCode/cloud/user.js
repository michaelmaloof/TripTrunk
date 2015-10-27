var _ = require("underscore");


/**
 * BEFORE SAVE
 */
Parse.Cloud.beforeSave(Parse.User, function(request, response) {

  // Save the user's name in lowercase also so we can search easier.
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
		// Friend Roles are only used if a user sets their account to Private, 
    // but we set it up now so it'll be ready if they ever switch their account

		var roleName = "friendsOf_" + user.id; // Unique role name
		var acl = new Parse.ACL(user);
		acl.setPublicReadAccess(true); // Initially, we set up the Role to have public
		acl.setPublicWriteAccess(true); // We give public write access to the role also - Anyone can decide to be someone's friend (aka follow them)

		// In the future, if the user makes their account Private, 
    // the ACL for their role gets changed. This lets existing followers be part of
		// the role still even though they didn't have to "request" to follow

		var friendRole = new Parse.Role(roleName, acl); 
		return friendRole.save(null, {useMasterKey: true}).then(function(friendRole) {
			console.log("Successfully saved new role: " + roleName);
			return;
		}, function(error) {
			console.log("Error saving new role: " + error.description);
		});

});


/**
 * Cloud Function that changes the request User's role ACL to be private so they must approve new people joining their role.
 * No Parameters
 */
Parse.Cloud.define("becomePrivate", function(request, response) {
  Parse.Cloud.useMasterKey();

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
  
    console.log("userBecamePrivate");
    // Query for all of the user's photo
    var query = new Parse.Query('Photo');
    query.equalTo('user', user);
    return query.find()

  }).then(function(photos) {

    var counter = 0;
    var photoPromise = Parse.Promise.as();
    console.log("found photos: " + photos.length);

    _.each(photos, function(photo) {
      console.log('photo process');
      photoPromise = photoPromise.then(function() {
        // Update the photo's ACL to remove public read access
        var acl = photo.getACL();
        acl.setPublicReadAccess(false);
        photo.setACL(acl);

        if (counter % 100 === 0) {
          // Set the  job's progress status
          console.log(counter + " photos processed.");
        }
        counter += 1;
        return photo.save();
      });
    });

    return photoPromise;
  }).then(function() {
    response.success("Success! - Account Now Private");
  }, function(error) {
    response.error(error);
  });
});

/*
 * Function that changes the request User's role ACL to be Public so anyone can follow them. 
 * This is the default for new users already.
 * No Parameters
 */
Parse.Cloud.define("becomePublic", function(request, response) {
  Parse.Cloud.useMasterKey();
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

    // Query for all of the user's photo
    var query = new Parse.Query('Photo');
    query.equalTo('user', user);
    return query.find();

  }).then(function(photos) {
    var photoPromise = Parse.Promise.as();
    var counter = 0;

    _.each(photos, function(photo) {
      photoPromise = photoPromise.then(function() {
        // Update the photo's ACL to remove public read access
        var acl = photo.getACL();
        acl.setPublicReadAccess(true);
        photo.setACL(acl);

        if (counter % 100 === 0) {
          // Set the  job's progress status
          console.log(counter + " photos processed.");
        }
        counter += 1;
        return photo.save();
      });
    });

    return photoPromise;
  }).then(function() {
    response.success("Success! - Account Now Public");
  }, function(error) {
    response.error(error);
  });
});



