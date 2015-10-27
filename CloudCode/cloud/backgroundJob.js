/**
 * CURRENTLY THIS IS NOT USED AT ALL
 */

var _ = require("underscore");

Parse.Cloud.job("processQueue", function(request, status) {
  Parse.Cloud.useMasterKey();
  console.log("Begin Background Job");
  var totalQueueCount = 0;

  var jobQuery = new Parse.Query('JobQueue');
  jobQuery.ascending('createdAt'); // Ascending so we get the oldest job first.

  jobQuery.find().then(function(jobs) {
    totalQueueCount = jobs.length;
    var promises = Parse.Promise.as();
    _.each(jobs, function(job) {
      console.log(job);
      promise = promise.then(function() {
        return processJob(job);
      })

    });
    return promise;
  }).then(function() {
    console.log('QUEUE FINISHED');
    // Check if the WHOLE queue is cleared out. More could have come back in.
    if (totalQueueCount > 0) {
      // Call Queue Again
      setTimeout(function() {
        triggerProcessQueueJob();
        console.log("next job triggered");
      }, 2000);
    }

    status.success("Job Queue Completed Successfully.");

  }, function(error) {
    console.error(error);
    status.error(error);
  });

});

var processJob = function(job) {
  var promise = new Parse.Promise();
  // Handle Privacy Job First.
  if (job.get("name") === 'userBecamePrivate') {
    console.log('Handling userBecamePrivate job for user: ' + job.get("user").id);
    // pass in the status also so we can be kept up to date
    userBecamePrivate(job.get("user")).then(function(){
      console.log('processJob userBecamePrivate Resolving');
      promise.resolve();
    }, function(error) {
      console.log('processJob userBecamePrivate Error: ' + error);
      promise.reject(error);
    });

  }
  else if (job.get("name") === 'userBecamePublic') {
    console.log('Handling userBecamePublic job for user: ' + job.get("user").id);
    // pass in the status also so we can be kept up to date
    userBecamePublic(job.get("user")).then(function(){
      console.log('processJob userBecamePublic Resolving');
      promise.resolve();
    }, function(error) {
      console.log('processJob userBecamePublic Error: ' + error);
      promise.reject(error);
    });
  }
  else {
    console.log('Unsupported Job Name: ' + job.get("user"));
    promise.reject();
  }
  return promise;
}


var userBecamePrivate = function(user) {
  Parse.Cloud.useMasterKey();
  console.log("userBecamePrivate");
  var promise = new Parse.Promise();

  var counter = 0;
  // Query for all of the user's photo
  var query = new Parse.Query('Photo');
  query.equalTo('user', user);
  query.find().then(function(photos) {
    var photoPromise = Parse.Promise.as();
    console.log("found photos: " + photos.length);

    _.each(photos, function(photo) {
      photoPromise = photoPromise.then(function() {
        // Update the photo's ACL to remove public read access
        var acl = photo.acl;
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

  var promise = new Parse.Promise();

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
          console.log(counter + " photos processed.");
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

}

var triggerProcessQueueJob = function() {
  Parse.Cloud.httpRequest({
    method: "POST",
    url: "https://api.parse.com/1/jobs/processQueue",
    headers: {
      "X-Parse-Application-Id": "jyNLO5QRwCCapLfNiTulIDuatHFsBrPkx31xtSGS",
      "X-Parse-Master-Key": "xXaZ6Q5UgcVdnXSWoXrhMWoCQtQ2xxw8jnO8RTGz",
      "Content-Type": "application/json"
    },
    body: {
      // No body needed since this just says to process the queue. 
      // If the queue is backed up, then it's going to take awhile no matter what.
    },
    success: function(httpResponse) {
      console.log('Background Job Called again');
      console.log(httpResponse);
    },
    error: function(error) {
      // We may get errors because a job is already running. That's fine. The job will process the whole queue anyways.
      console.log("ERROR: + " + error); 
    }
  });
}