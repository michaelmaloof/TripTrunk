Parse.Cloud.job("processQueue", function(request, status) {
  Parse.Cloud.useMasterKey();

  var jobQuery = new Parse.Query('JobQueue');
  jobQuery.ascending('createdAt'); // Ascending so we get the oldest job first.
  jobQuery.first().then(function(job) {

    // Handle Privacy Job First.
    if (job.name === 'userBecamePrivate') {
      console.log('Handling userBecamePrivate job for user: ' + job.user.id);
      // pass in the status also so we can be kept up to date
      return userBecamePrivate(job.user, status);

    }
    else if (job.name === 'userBecamePublic') {
      console.log('Handling userBecamePublic job for user: ' + job.user.id);
      // pass in the status also so we can be kept up to date
      return userBecamePublic(job.user, status);
    }
    else {
      console.log('Unsupported Job Name: ' + job.name);
      return;
    }
  }).then(function() {
    // Object successfully deleted
    response.success("Successfully Completed Job");
  }, function(error) {
    console.error(error);
  });

});

var userBecamePrivate = function(user, status) {
  Parse.Cloud.useMasterKey();

  var promise = new Parse.Promise();

  var counter = 0;
  // Query for all of the user's photo
  var query = new Parse.Query('Photo');
  query.equalTo('user', user);
  query.find().then(function(photos) {
    var photoPromise = Parse.Promise.as();

    _.each(photos, function(photo) {
      photoPromise = photoPromise.then(function() {
        // Update the photo's ACL to remove public read access
        var acl = photo.acl;
        acl.setPublicReadAccess(false);
        photo.setACL(acl);

        if (counter % 100 === 0) {
          // Set the  job's progress status
          status.message(counter + " photos processed.");
        }
        counter += 1;
        return photo.save();
      });
    });

    return photoPromise;

  }).then(function() {
    // Set the job's success status
    promise.resolve();
  }, function(error) {
    // Set the job's error status
    console.log("Uh oh, something went wrong setting the user's photos to private..");
    promise.reject(error);
  });

  return promise;

}

var userBecamePublic = function(user) {
  Parse.Cloud.useMasterKey();
  var counter = 0;
  // Query for all of the user's photo
  var query = new Parse.Query('Photo');
  query.equalTo('user', user);
  query.find().then(function(photos) {
    var photoPromise = Parse.Promise.as();

    _.each(photos, function(photo) {
      photoPromise = photoPromise.then(function() {
        // Update the photo's ACL to remove public read access
        var acl = photo.acl;
        acl.setPublicReadAccess(true);
        photo.setACL(acl);

        if (counter % 100 === 0) {
          // Set the  job's progress status
          status.message(counter + " photos processed.");
        }
        counter += 1;
        return photo.save();
      });
    });

    return photoPromise;

  }).then(function() {
    // Set the job's success status
    status.success("Photo's set to Private - SUCCESS!");
  }, function(error) {
    // Set the job's error status
    status.error("Uh oh, something went wrong setting the user's photos to private..");
  });

}
