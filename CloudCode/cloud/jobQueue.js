/**
 * CURRENTLY NOT USED AT ALL
 * The goal was to use a Class as a job queue. It's partially implemented but doesn't work.
 */

// A new job was added to the queue
// If we have a background job running, then it'll get to this soon.
// If no background job is running, we need to start one to clean out the queue.
// Parse.Cloud.afterSave('JobQueue', function(request) {

//   // First, check if there's another job for this user queue'd already. 
//   // Namely, if a user has a queue'd Private job, and this is a Public job, then let's just remove both.

//   //TODO: call job processing.

//   var email = request.object.get("email");
//   var phoneNumber = request.object.get("phoneNumber");
//   var facebookId = request.object.get("facebookId");
//   var objectId = request.object.id;

//   Parse.Cloud.httpRequest({
//     method: "POST",
//     url: "https://api.parse.com/1/jobs/processQueue",
//     headers: {
//       "X-Parse-Application-Id": "jyNLO5QRwCCapLfNiTulIDuatHFsBrPkx31xtSGS",
//       "X-Parse-Master-Key": "xXaZ6Q5UgcVdnXSWoXrhMWoCQtQ2xxw8jnO8RTGz",
//       "Content-Type": "application/json"
//     },
//     body: {
//       // No body needed since this just says to process the queue. 
//       // If the queue is backed up, then it's going to take awhile no matter what.
//     },
//     success: function(httpResponse) {
//       console.log('Background Job Call Success');
//       console.log(httpResponse);
//     },
//     error: function(error) {
//       // We may get errors because a job is already running. That's fine. The job will process the whole queue anyways.
//       console.log("ERROR: + " + error); 
//     }
//   });

//   return;
// });



// NOT USED CODE:
// this is code that should be in user.js.
// It's been moved here for possible future use since we aren't using hte Job Queue right now.
// 
// Parse.Cloud.define("becomePrivate", function(request, response) {
//   var user = request.user;

//   user.set("private", true);
//   user.save();

//   var roleName = "friendsOf_" + request.user.id;
//   var roleQuery = new Parse.Query("_Role");
//   roleQuery.equalTo("name", roleName);

//   roleQuery.first().then(function(role) {
//     role.setACL(new Parse.ACL(user));
//     return role.save();

//   }).then(function(role) {

//     // Add a new job to the Job Queue to turn all photos to private.
//     // We use a queue instead of calling it directly because it could take awhile.
//     var JobQueue = Parse.Object.extend("JobQueue");
//     var job = new JobQueue();
//     job.set("name", "userBecamePrivate");
//     job.set("user", user);
//     job.set("action", "changePhotosToPrivate");
//     return job.save();

//   }).then(function(job) {
//     response.success("Success! - Account Now Private");
//   }, function(error) {
//     response.error(error);
//   });
// });


// /*
//  * Function that changes the request User's role ACL to be Public so anyone can follow them. This is the default for new users already.
//  * No Parameters
//  */
// Parse.Cloud.define("becomePublic", function(request, response) {
//   var user = request.user;

//   user.set("private", false);
//   user.save();

//   var roleName = "friendsOf_" + request.user.id;
//   var roleQuery = new Parse.Query("_Role");
//   roleQuery.equalTo("name", roleName);

//   roleQuery.first().then(function(role) {
//     var acl = new Parse.ACL(user);
//     acl.setPublicReadAccess(true); // Initially, we set up the Role to have public
//     acl.setPublicWriteAccess(true); // We give public write access to the role also - Anyone can decide to be someone's friend (aka follow them)
//     role.setACL(acl);
//     return role.save();

//   }).then(function(role) {

//     // Add a new job to the Job Queue to turn all photos to public.
//     // We use a queue instead of calling it directly because it could take awhile.
//     var JobQueue = Parse.Object.extend("JobQueue");
//     var job = new JobQueue();
//     job.set("name", "userBecamePublic");
//     job.set("user", user);
//     job.set("action", "changePhotosToPublic"); 
//     return job.save();

//   }).then(function(job) {
//     response.success("Success! - Account Now Public");
//   }, function(error) {
//     response.error(error);
//   });
// });
