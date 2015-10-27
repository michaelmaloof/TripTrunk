
// TODO: This should probalby be re-implemented.
// It was in the Parse tutorial, but didn't seem to work.

// Make sure all installations point to the current user.
// Parse.Cloud.beforeSave(Parse.Installation, function(request, response) {
//   Parse.Cloud.useMasterKey();
//   if (request.user) {
// 	  request.object.set('user', request.user);
//   } else {
//   	request.object.unset('user');
//   }
//   response.success();
// });
