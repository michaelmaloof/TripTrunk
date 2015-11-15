var _ = require("underscore");

/**
 * AFTER SAVE
 */
Parse.Cloud.afterSave('Photo', function(request) {
  Parse.Cloud.useMasterKey(); // User master key because we want to update the Trip's mostRecentPhoto regardless of the ACL.

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

  // Since Photo.trip is a pointer, we must first fetch the trip object
  trip.fetch().then(function(trip) {

  /*
   * Update the Trip object
   */
    trip.set("mostRecentPhoto", new Date());
    trip.save();

    // Create an Activity for addedPhoto
    var Activity = Parse.Object.extend("Activity");
    var photoActivity = new Activity();
    photoActivity.set("type", "addedPhoto");
    photoActivity.set("photo", request.object);
    photoActivity.set("trip", trip);
    photoActivity.set("fromUser", request.user);
    photoActivity.set("toUser", trip.get("creator"));
    photoActivity.save();

  });

});


/**
 * BEFORE DELETE
 * 
 * Before Deleting a Photo, send a DELETE request to Cloudinary as well.
 */
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