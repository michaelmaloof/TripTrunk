
// A new job was added to the queue
// If we have a background job running, then it'll get to this soon.
// If no background job is running, we need to start one to clean out the queue.
Parse.Cloud.afterSave('JobQueue', function(request) {

  // First, check if there's another job for this user queue'd already. 
  // Namely, if a user has a queue'd Private job, and this is a Public job, then let's just remove both.

  //TODO: call job processing.

  return;
});
