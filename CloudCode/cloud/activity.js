
/**
 * Adds the fromUser to the toUser's friendsOf_ role.
 * 
 * Returns a deferred Promise.
 */
var addToFriendRole = function(fromUserId, toUserId) {
  var promise = new Parse.Promise();
  console.log("addToFriendRole starting");
  console.log("FromUserID: " + fromUserId);
  console.log("toUserId: " + toUserId);

  var userToFriend = new Parse.User();
  userToFriend.id = fromUserId;
  var approvingUser = new Parse.User();
  approvingUser.id = toUserId;

  var roleName = "friendsOf_";
  // If an ApprovingUser is passed in
  if (approvingUser.id) {
    roleName = roleName + approvingUser.id
  }

  var roleQuery = new Parse.Query(Parse.Role);
  roleQuery.equalTo("name", roleName);

  roleQuery.first().then(function(role) {
    if (role) {
      console.log("addToFriendRole found Role");

      role.getUsers().add(userToFriend);

      // Returns role in THIS promise chain.
      return role.save();

    }
    else
    {
      console.log("addToFriendRole no Role found");

      // Returns in THIS promise chain.
      return Parse.Promise.error("No Role found for name: " + roleName);
    }

  }).then(function(role) {
    console.log("addToFriendRole about to resolve");
    // Resolve the whole function's promise (this is a function embedded in a promise chain)
    promise.resolve();

  }, function(error) {
    console.log("addToFriendRole about to reject");
    // Reject the whole function's promise (this is a function embedded in a promise chain)
    promise.reject(error);

  });

  return promise;
}

/*
 * Function to add a User to a Trip. Creates an addToTrip Activity. We're using a cloud function to avoid timeouts.
 * Accepts a "fromUserId" parameter
 */

Parse.Cloud.define("addToTrip", function(request, response) {
  // Create full objects out of the ID's sent as params.
  var fromUser = new Parse.User();
  fromUser.id = request.params.fromUserId;
  
  var toUser = new Parse.User();
  toUser.id = request.params.toUserId;

  var Trip = Parse.Object.extend("Trip");
  var trip = new Trip();
  trip.id = request.params.tripId;

  var content = request.params.content;
  var latitude = request.params.latitude;
  var longitude = request.params.longitude;


  // MAKE SURE THE USER ISN'T BLOCKED
  var blockQuery = new Parse.Query("Block");
  blockQuery.equalTo("blockedUser", fromUser);
  blockQuery.equalTo("fromUser", toUser);

  blockQuery.find()
  .then(function(blocked) {
    if (blocked.length > 0) {
      return Parse.Promise.error("User is blocked from performing this action");
    }

    // USER IS ALLOWED TO DO THIS - NOT BLOCKED.
    
    /*
     * Ensure we aren't adding duplicate users to a Trunk
     * i.e. if the user clicks Next in trunk creation, then goes back to the user screen and clicks next again.
     */
    var query = new Parse.Query("Activity");
    query.equalTo("trip", trip);
    query.equalTo("type", "addToTrip");
    query.equalTo("toUser", toUser);

    return query.first();
  })

  .then(function(addToTripObject) {
    console.log(addToTripObject);
    // If an addToTrip Object, it already exists. 
    if (addToTripObject) {
      console.log("ADD TO TRIP OBJECT FOUND SO ALREADY ADDED");
      return Parse.Promise.error("User already added to trunk");
    }

    // ADD TRUNK MEMBER TO ROLE
    var roleName;
    // If an ApprovingUser is passed in
    if (trip.id) {
      roleName = "trunkMembersOf_" + trip.id;
    }
    else  {
      return Parse.Promise.error("No trip id passed so we have no Role Name");
    }

    var roleQuery = new Parse.Query(Parse.Role);
    roleQuery.equalTo("name", roleName);
    console.log("Looking for role name: " + roleName);

    return roleQuery.first();

  }).then(function(role) {
    console.log("Role Found: " + role);
    if (role) {
      role.getUsers().add(toUser);
      return role.save();
    }
    return Parse.Promise.error("No Role found for name: " + roleName);

  }).then(function() {
    /* SUCCESS */
    console.log("Role Updated, so now save the Activity");

        // Create an Activity for addedPhoto
    var Activity = Parse.Object.extend("Activity");
    var activity = new Activity();
    activity.set("type", "addToTrip");
    activity.set("trip", trip);
    activity.set("fromUser", fromUser);
    activity.set("toUser", toUser);
    activity.set("content", content);
    activity.set("latitude", latitude);
    activity.set("longitude", longitude);

    var acl = new Parse.ACL(fromUser);
    acl.setPublicReadAccess(true); // Initially, we set up the Role to have public
    acl.setWriteAccess(toUser, true); // We give public write access to the role also - Anyone can decide to be someone's friend (aka follow them)
    activity.setACL(acl);
    return activity.save();
    
  })
  .then(function(activity) {
    console.log('Successfully saved Activity');
    return response.success();

  }, function(error) {
    /* ERROR */
    console.error(error);

    return response.error(error);
  });

  
});

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
  blockQuery.equalTo("fromUser", toUser);


/*
 * FOLLOW ACTIVITY FLOW
 */ 
  if (activity.get("type") === "follow") {
    blockQuery.find()
    .then(function(blocked) {
      if (blocked.length > 0) {
        return Parse.Promise.error("User is blocked from performing this action");
      }
      // USER IS ALLOWED TO DO THIS - NOT BLOCKED.
      
      /* Commented out by mattschoch 11/23
       * We no longer are adding to friend roles when the follow happens.
       * Users will be added to the role ONLY when a user switches their account type.
       * Instead of returning addToFriendRole (promise), we'll just return the success here.
      
      return addToFriendRole(fromUser.id, toUser.id)

      }).then(function() {
        console.log("beforeSave Activity Follow - about to finish");
        return response.success();
      */
     
       return response.success();

    }, function(error) {
      /* ERROR */
      return response.error(error);
    });
  }

  /*
   * ADD TO TRIP ACTIVITY FLOW
   */ 
  else if (activity.get("type") === "addToTrip") {
    console.log("Activity Type = AddToTrip");

    if (!activity.isNew()) {
      // Not a new activity, so we're doing an update.
      return response.success();
    }

    if (activity.get("latitude") && activity.get("longitude")) {
      console.log("> Version 1.3, meaning Cloud Function is used for adding user to trip.");
      return response.success();
    }
    // Otherwise, this is a new activity.
    
/* We commented out the blockQuery because this request times out. Eventually, users need to be able to block people */

    // blockQuery.find()
    // .then(function(blocked) {
    //   if (blocked.length > 0) {
    //     return Parse.Promise.error("User is blocked from performing this action");
    //   }

    //   // USER IS ALLOWED TO DO THIS - NOT BLOCKED.

    /*
     * Ensure we aren't adding duplicate users to a Trunk
     * i.e. if the user clicks Next in trunk creation, then goes back to the user screen and clicks next again.
     */

    var query = new Parse.Query("Activity");
    query.equalTo("trip", activity.get("trip"));
    query.equalTo("type", "addToTrip");
    query.equalTo("toUser", toUser);

    query.first()
    .then(function(addToTripObject) {
      console.log(addToTripObject);
      // If an addToTrip Object, it already exists. 
      if (addToTripObject) {
        console.log("ADD TO TRIP OBJECT FOUND SO ALREADY ADDED");
        return Parse.Promise.error("User already added to trunk");
      }

      // ADD TRUNK MEMBER TO ROLE
      var roleName = "trunkMembersOf_";
      // If an ApprovingUser is passed in
      if (activity.get("trip").id) {
        roleName = roleName + activity.get("trip").id
      }

      var roleQuery = new Parse.Query(Parse.Role);
      roleQuery.equalTo("name", roleName);
      console.log("Looking for role name: " + roleName);

      return roleQuery.first();

    }).then(function(role) {
      console.log("Role FOund: " + role);
      if (role) {
        role.getUsers().add(toUser);
        return role.save();
      }
      return Parse.Promise.error("No Role found for name: " + roleName);

    }).then(function() {
      /* SUCCESS */
      console.log("Success Block");
      return response.success();

    }, function(error) {
      /* ERROR */
      console.log(error);

      return response.error(error);
    });

  }
  else {
    return response.success();
  }

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
  if (!request.object.get("toUser") || request.object.get("toUser").id === request.user.id) {
    return;
  };

  var query = new Parse.Query(Parse.Installation);
  query.equalTo('user', toUser);

  var trip;

  // If it's addToTrip, we'll populate the Trip before we call the Push Notification.
  // It's redundant code, but it saves refactoring everything right now.
  if (request.object.get('type') === 'addToTrip') {
      // Check if the trunk is private or not.
      request.object.get('trip').fetch().then(function(thisTrip) {
        request.object.set('trip', thisTrip);
        console.log(trip);

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
  }
  else {
    Parse.Push.send({
      where: query, // Set our Installation query.
      data: alertPayload(request)
    }).then(function() {
      // Push was successful
      console.log('Sent push.');
    }, function(error) {
      throw "Push Error " + error.code + " : " + error.message;
    });
  }
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

        if(request.object.get('trip').get('isPrivate')) {
          message = request.user.get('username') + ' added you to a private trunk.';
        }
        else {
          message = request.user.get('username') + ' added you to a trunk.';
        }

    } else {
      message = "You were added to a trunk.";
    }
  } else if (request.object.get("type") === "pending_follow") {
    if (request.user.get('username') && request.user.get('name')) {
      message = request.user.get('name') + ' (@' + request.user.get('username') + ')' + ' requested to follow you.';
    } else {
      message = "You have a new follower request.";
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
  } else if (request.object.get("type") === "pending_follow") {
    return {
      alert: alertMessage(request), // Set our alert message.
      p: 'a', // Payload Type: Activity
      t: 'f', // Activity Type: Pending_Follow
      fu: request.object.get('fromUser').id // From User
    };
  }
}

/*
 * Activity AFTER DELETE
 * used to handle Role Change for an Unfollow activity
 * It's an AfterDelete because in the case of a failure to either Delete the Activity or Update the Role, it's better to delete the activity
 * and leave the role (unfollowed user but old follower still has read permission) than to update the role but still have the activity
 * (still following but can't read data). Hopefully failure doesn't occur, but we use an afterDelete to be safe.
 */
Parse.Cloud.afterDelete('Activity', function(request) {
Parse.Cloud.useMasterKey();
  // If it's deleting a Follow then it's an Unfollow, so we need to remove them from that user's role as well.
  if (request.object.get("type") === "follow") {
    var userToUnfollow = request.object.get("toUser");

    var roleName = "friendsOf_" + userToUnfollow.id;
    console.log("Unfollowing user and removing role name: " + roleName);

    var roleQuery = new Parse.Query(Parse.Role);
    roleQuery.equalTo("name", roleName);
    roleQuery.first({
      success:function(role) {
        console.log("Attempt to remove user: " + request.user.id);
        var currentUser = new Parse.User();
        currentUser.id = request.user.id;
        role.getUsers().remove(currentUser);

        console.log(role.getUsers());
        return role.save();
      },
      error: function(error) {
        console.error("Error updating role: " + error);
      },
      useMasterKey: true
    });
  }
  /* REMOVE FROM TRIP */
  else if (request.object.get("type") === "addToTrip") {
    var userLeaving = request.object.get("toUser");

    var roleName = "trunkMembersOf_" + request.object.get("trip").id;
    console.log("Leaving trunk with role name: " + roleName);

    var roleQuery = new Parse.Query(Parse.Role);
    roleQuery.equalTo("name", roleName);
    roleQuery.first({
      success:function(role) {
        role.getUsers().remove(userLeaving);

        return role.save();
      },
      error: function(error) {
        console.error("Error updating role: " + error);
      },
      useMasterKey: true
    });
  }
});

/*
 * Function to let a user Accept a Follow request - Adds the given user Id into the friend Role for the current User
 * Accepts a "fromUserId" parameter and a "accepted" parameter
 */

Parse.Cloud.define("approveFriend", function(request, response) {
  var userToFriend = new Parse.User();
  userToFriend.id = request.params.fromUserId;
  var didApprove = request.params.accepted;

  if (!didApprove) {
    // REJECTED
    // Delete the pending request.
    // Get the Pending Follow and change it to a follow
    var query = new Parse.Query("Activity");
        query.equalTo("fromUser", userToFriend);
        query.equalTo("toUser", request.user);
        query.equalTo("type", "pending_follow");
        query.first().then(function(activity) {
          if (activity) {
            return activity.destroy();
          }
          else {
            return Parse.Promise.error("No Pending Follow Activity Found");
          }
          
        }).then(function() {
          // Object successfully deleted
          response.success("Successfully rejected");
        }, function(error) {
          response.error(error);
        });
  }
  else {
    // ACCEPTED
    // Get the Pending Follow and change it to a follow
    var query = new Parse.Query("Activity");
        query.equalTo("fromUser", userToFriend);
        query.equalTo("toUser", request.user);
        query.equalTo("type", "pending_follow");
        query.first().then(function(activity) {
          if (activity) {
            activity.set("type", "follow");
            return activity.save();
          }
          else {
            return Parse.Promise.error("No Pending Follow Activity Found");
          }
          
        })
        .then(function(activity) {

          var promises = [];
          promises.push(addToFriendRole(activity.get("fromUser").id, request.user.id));
          promises.push(sendPushNotificationForAcceptedFollowRequest(activity, request));

          return Parse.Promise.when(promises);
        })
        .then(function() {
          console.log("addToFriendRole AND push notification finished in accept request");
          console.log("Responding success");
          response.success();
        }, function(error) {
          response.error(error);
      });
  }
});

// THIS FUNCTION DOESN"T WORK YET
function sendPushNotificationForAcceptedFollowRequest(activity, request) {

  var promise = new Parse.Promise();
    // Send the fromUser a push notification telling them that their request was accepted.
  var  pushMessage = request.user.get('name') + ' (@' + request.user.get('username') + ')' + ' accepted your follow request.';
  // Trim our message to 140 characters.
  if (pushMessage.length > 140) {
    pushMessage = pushMessage.substring(0, 140);
  }
  var query = new Parse.Query(Parse.Installation);
  console.log("sending push to: " + activity.get('fromUser').id);
  query.equalTo('user', activity.get('fromUser'));
  Parse.Push.send({
    where: query, // Set our Installation query.
    data: {
      alert: pushMessage, // Set our alert message.
      p: 'a', // Payload Type: Activity
      t: 'f', // Activity Type: Follow
      fu: request.user.id // From User - it's actually the toUser in this case since it's an "accepted" notificaiton.
    }
  }).then(function() {
    // Push was successful
    console.log('Sent push for acceptance.');
    promise.resolve();
  }, function(error) {
    promise.reject(error);
  });

  return promise;
}


