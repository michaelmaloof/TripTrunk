/*
 * AFTER SAVE - ACTIVITY
 */

Parse.Cloud.afterSave('PendingActivity', function(request) {
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

  if (request.object.get("type") === "follow") {
    if (request.user.get('username') && request.user.get('name')) {
      message = request.user.get('name') + ' (@' + request.user.get('username') + ')' + ' requested to follow you.';
    } else {
      message = "You have a new follower request.";
    }
  } 
  // TODO: Add pending functionality for Add To Trip - this is left in here because we'll need it later, 
  // but right now it's just copied from the Activity class.
  else if (request.object.get("type") === "addToTrip") {
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

  if (request.object.get("type") === "follow") {
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



