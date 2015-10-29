/**
 * BEFORE SAVE
 */
Parse.Cloud.beforeSave('Trip', function(request, response) {

// If the trip is private, we need to REMOVE the friendsOf_ role on the Trip's ACL - the app is setting it to READ.
// This fixes an issue that's happening because of a bug in the app.
	var roleName = "friendsOf_" + request.object.get("creator").id;
	console.log("BeforeSaveTrip - friendsOf role name: " + roleName);
	if (request.object.get("isPrivate") === true) {
	  var acl = request.object.getACL();
	  acl.setRoleReadAccess(roleName, false);

	  request.object.setACL(acl);
	}
	
  response.success();

});

/*
 * AFTER SAVE
 */
Parse.Cloud.afterSave('Trip', function(request) {
	var trunk = request.object;
	if (trunk.existed()) { return; } // Trunk already exists (not trunk creation) so just return

		// First time trunk is being saved
		// Set up a Role for their members. 
		// Trunk Roles are only used if a user sets their account to Private, 
		// but we set it up now so it'll be ready if they ever switch their account

		var roleName = "trunkMembersOf_" + trunk.id; // Unique role name
		var acl = new Parse.ACL(request.user); // Only the creator of the trunk gets permission for the Role.
		acl.setRoleReadAccess(roleName, true);
		acl.setRoleWriteAccess(roleName, true);

		var trunkMember = new Parse.Role(roleName, acl); 
		return trunkMember.save(null, {useMasterKey: true}).then(function(trunkRole) {
			console.log("Successfully saved new role: " + roleName);
			return;
		}, function(error) {
			console.log("Error saving new role: " + error.description);
		});

});