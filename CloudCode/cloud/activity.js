Parse.Cloud.beforeSave('Activity', function(request, response) {
  var currentUser = request.user;
  var objectUser = request.object.get('fromUser');

  // if(!currentUser || !objectUser) {
  //   return response.error('An Activity should have a valid fromUser.');
  // } else if (currentUser.id !== objectUser.id) {
  //   return response.error('Cannot set fromUser on Activity to a user other than the current user.');
  // }

  /*
   * Ensure we aren't adding duplicate users to a Trunk
   * i.e. if the user clicks Next in trunk creation, then goes back to the user screen and clicks next again.
   */

  if (request.object.get("type") === "addToTrip") {
    var query = new Parse.Query("Activity");
    query.equalTo("trip", request.object.get("trip"));
    query.equalTo("toUser", request.object.get("toUser"));
    query.first({
      success: function(object) {
        if (object) {
          response.error("User already added to trunk");
        } else {
          response.success();
        }
      },
      error: function(error) {
        response.error("Couldn't validate that this user is not already part of the trunk");
      }
    });
  }
  else {
      return response.success();
  }


});

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
