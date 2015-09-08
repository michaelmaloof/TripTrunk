Parse.Cloud.afterSave('Photo', function(request) {
  // Only send push notifications for new activities
  if (request.object.existed()) {
    return;
  }

  var trip = request.object.get("trip");

// Ensure the trip and user objects exist, otherwise we don't want to send notifications.
  if (!trip) {
    throw "Undefined trip. Skipping push for Photo: " + request.object.id;
    return;
  }

  var user = request.object.get("user");
  if (!user) {
    throw "Undefined user adding the photo. Skipping push for Photo: " + request.object.id;
    return;
  }

  // Since Photo.trip is a pointer, we must first fetch the trip object so we can reference the creator field.
  trip.fetch().then(function(trip){

    // Create the query that finds all members of a trip, except the person who just uploaded the photo
    var memberQuery = new Parse.Query("Activity");
    memberQuery.equalTo('trip', request.object.get("trip"));
    memberQuery.equalTo('type', "addToTrip");
    memberQuery.notEqualTo('toUser', request.user); // creators are members as well, so this line prevents whoever is uploading the photo from getting a push notification for their own photo

    // Find the Installations for all trip members so we know where to send the notification
    var installQuery = new Parse.Query(Parse.Installation);
    installQuery.matchesKeyInQuery('user', 'toUser', memberQuery);

    var pushMessage = request.user.get('username') + ' added a photo to the trunk: ' + trip.get("name");

    // Clip message if it's longer than the APNs limit
    if (pushMessage.length > 140) {
      pushMessage = message.substring(0, 140);
    }

    var payload = {
        alert: pushMessage, // Set our alert message.
        p: 'p', // Payload Type: Photo
        tid: request.object.get('trip').id, // Trip Id
        pid: request.object.id // Photo Id
      };

    // Send the push notification to ALL the users!!
    Parse.Push.send({
      where: installQuery, // Set our Installation query.
      data: payload
    }).then(function() {
      // Push was successful
      console.log('Sent push.');
    }, function(error) {
      throw "Push Error " + error.code + " : " + error.message;
    });
  });

});

// Before Deleting a Photo, send a DELETE request to Cloudinary as well.

Parse.Cloud.beforeDelete('Photo', function(request, response) {

  if (request.object.get("imageUrl")) {

    var index = request.object.get("imageUrl").lastIndexOf("/") + 1;
    var filename = request.object.get("imageUrl").substr(index);
    var publicId = filename.substr(0, filename.lastIndexOf('.')) || filename;

    var url = "https://334349235853935:YZoImSo-gkdMtZPH3OJdZEOvifo@api.cloudinary.com/v1_1/triptrunk/resources/image/upload?public_ids=";

    url = url + publicId;

    Parse.Cloud.httpRequest({
      method: 'DELETE',
      url: url,
      headers: {
        'Content-Type': 'application/json;charset=utf-8'
      }
    }).then(function(httpResponse) {
        console.log(httpResponse.text);
    }, function(httpResponse) {
      response.error("Error " + error.code + " : " + error.message + " when deleting photo from Cloudinary.");
    });

  };
  // Continue with delete no matter what
  response.success();

});