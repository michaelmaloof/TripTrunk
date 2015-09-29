/*
 * BEFORE SAVE - ACTIVITY
 */
Parse.Cloud.beforeSave('Activity', function(request, response) {
  var currentUser = request.user;
  var fromUser = request.object.get('fromUser');
  var toUser = request.object.get('toUser');
  var activity = request.object;

  // MAKE SURE THE USER ISN'T BLOCKED
  var blockQuery = new Parse.Query("Block");
  blockQuery.equalTo("blockedUser", fromUser);
  blockQuery.equalTo("fromUser", touser);

  blockQuery.count().then(function(count) {
    if (count > 0) {
      return Parse.Promise.error("User is blocked from performing this action");
    }

    // USER IS ALLOWED TO DO THIS - NOT BLOCKED.
    return;

  }).then(function() {

    if (activity.get("type") === "addToTrip") {
    /*
     * Ensure we aren't adding duplicate users to a Trunk
     * i.e. if the user clicks Next in trunk creation, then goes back to the user screen and clicks next again.
     */

      var query = new Parse.Query("Activity");
      query.equalTo("trip", activity.get("trip"));
      query.equalTo("toUser", toUser);
      query.first({
        success: function(object) {
          if (object) {
            return Parse.Promise.error("User already added to trunk");
          } 
          return;
        },
        error: function(error) {
          return Parse.Promise.error("Couldn't validate that this user is not already part of the trunk");
        }
      });
    }
    else if (activity.get("type") === "follow") {

      // Let's see if we can Friend the toUser by joining their Role.
      Parse.Cloud.run('approveFriend', {fromUserId: fromUser.id, toUserId, toUser.id}, {
        success: function(response) {
          // SUCCESS - the friend was Approved
          return;
        },
        error: function(error) {
          // ERROR - the friend was NOT approved

          // TODO: 
          // if the approveFriend failed, it could be that they are just REQUESTING to follow the toUser.
          // So we need to actually set the request.
          // Hopefully that is happening from the client, but just in case it should be handled here
          // otherwise we run the risk of a user getting failed-to-follow over and over and never being able to request to follow someone.

          return Parse.Promise.error(error);
        }
      });

    }
    else { 
      return; 
    }

  }).then(function() {
    /* SUCCESS */
    return response.success();

  }, function(error) {
    /* ERROR */
    return response.error(error);
  });

});

/*
 * AFTER SAVE - ACTIVITY
 */

Parse.Cloud.afterSave('Activity', function(request) {
  // Only send push notifications for new activities
  if (request.object.existed()) {
    return;
  }

  var toUser = request.object.get("toUser");
  if (!toUser) {
    throw "Undefined toUser. Skipping push for Activity " + request.object.get('type') + " : " + request.object.id;
    return;
  }

  // If the activity is to the user making the request (i.e. toUser and fromUser are the same), don't send a push notification
  // That happens when we add a "addToTrip" Activity for "self" to aid in querying later, so it shouldn't notify the user.
  if (request.object.get("toUser").id === request.user.id) {
    return;
  };

  var query = new Parse.Query(Parse.Installation);
  query.equalTo('user', toUser);

  Parse.Push.send({
    where: query, // Set our Installation query.
    data: alertPayload(request)
  }).then(function() {
    // Push was successful
    console.log('Sent push.');
  }, function(error) {
    throw "Push Error " + error.code + " : " + error.message;
  });
});

var alertMessage = function(request) {
  var message = "";

  if (request.object.get("type") === "comment") {
    if (request.user.get('username') && request.user.get('name')) {
      message = request.user.get('username') + ' said: ' + request.object.get('content').trim();
    } else {
      message = "Someone commented on your photo.";
    }
  } else if (request.object.get("type") === "like") {
    if (request.user.get('username') && request.user.get('name')) {
      message = request.user.get('username') + ' likes your photo.';
    } else {
      message = 'Someone likes your photo.';
    }
  } else if (request.object.get("type") === "follow") {
    if (request.user.get('username') && request.user.get('name')) {
      message = request.user.get('name') + ' (@' + request.user.get('username') + ')' + ' started following you.';
    } else {
      message = "You have a new follower.";
    }
  } else if (request.object.get("type") === "addToTrip") {
    if (request.user.get('username') && request.user.get('name')) {
      message = request.user.get('username') + ' added you to a trunk.';
    } else {
      message = "You were added to a trunk.";
    }
  }

  // Trim our message to 140 characters.
  if (message.length > 140) {
    message = message.substring(0, 140);
  }

  return message;
}

var alertPayload = function(request) {
  var payload = {};

  if (request.object.get("type") === "comment") {
    return {
      alert: alertMessage(request), // Set our alert message.
      // badge: 'Increment', // Increment the target device's badge count.
      p: 'a', // Payload Type: Activity
      t: 'c', // Activity Type: Comment
      fu: request.object.get('fromUser').id, // From User
      pid: request.object.get('photo').id // Photo Id
    };
  } else if (request.object.get("type") === "like") {
    return {
      alert: alertMessage(request), // Set our alert message.
      p: 'a', // Payload Type: Activity
      t: 'l', // Activity Type: Like
      fu: request.object.get('fromUser').id, // From User
      pid: request.object.get('photo').id // Photo Id
    };
  } else if (request.object.get("type") === "follow") {
    return {
      alert: alertMessage(request), // Set our alert message.
      p: 'a', // Payload Type: Activity
      t: 'f', // Activity Type: Follow
      fu: request.object.get('fromUser').id // From User
    };
  } else if (request.object.get("type") === "addToTrip") {
    return {
      alert: alertMessage(request),
      p: 'a', // Payload Type: Activity
      t: 'a', // Activity Type: addToTrip
      tid: request.object.get('trip').id // Trip Id
    }
  }
}

/*
 * Function to let a user Accept a Follow request - Adds the given user Id into the friend Role for the current User
 * Accepts a userId parameter
 */

Parse.Cloud.define("approveFriend", function(request, response) {
  var userToFriend = new Parse.User();
  userToFriend.id = request.params.fromUserId;
  var approvingUser = new Parse.User();
  approvingUser.id = request.params.toUserId;

  var roleName = "friendsOf_";
  // If an ApprovingUser is passed in, it's CloudCode trying to follow a user to see if they're public
  if (approvingUser.id) {
    roleName = roleName + approvingUser
  }
  // No Approving User passed in, so the currentUser is approving someone.
  else {
    roleName = roleName + request.user.id;
  }

  var roleQuery = new Parse.Query("_Role");
  roleQuery.equalTo("name", roleName);

  roleQuery.first().then(function(role) {
    
    role.getUsers().add(userToFriend);
    return role.save();

  }).then(function() {
    response.success("Success! - Follow Request Approved");
  }, function(error) {
    response.error(error);
  });
});



