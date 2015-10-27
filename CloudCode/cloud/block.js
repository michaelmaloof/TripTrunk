/**
 * BEFORE SAVE
 * Handles a lot of the actual logic of blocking a user - using the masterKey to force them to unfollow, etc.
 */
Parse.Cloud.beforeSave('Block', function(request, response) {
  Parse.Cloud.useMasterKey(); // User master key because we want to update the Trip's mostRecentPhoto regardless of the ACL.
  var currentUser = request.user;
  var blockedUser = request.object.get('blockedUser');

  if(!currentUser || !blockedUser) {
    return response.error('Not a valid user when trying to Block');
  } else if (currentUser.id === blockedUser.id) {
    return response.error('Cannot block yourself.');
  }

  // Make sure the user wasn't already blocked.

  var q = new Parse.Query("Block");
  q.equalTo("fromUser", currentUser);
  q.equalTo("blockedUser", blockedUser);

  q.count({
    success: function(count) {
      if (count > 0) {
        return response.success();
      }
      // there's no existing blocked user, so move forward.

      /*
       * Force the Blocked user to unfollow.
       */
      // If the blocked user is following our user, we want to force the unfollow
      var followQuery = new Parse.Query("Activity");
      followQuery.equalTo("fromUser", blockedUser);
      followQuery.equalTo("toUser", currentUser);
      followQuery.equalTo("type", "follow");

      // If the user is following the user they want to block, we should unfollow that person
      var followingQuery = new Parse.Query("Activity");
      followingQuery.equalTo("fromUser", currentUser);
      followingQuery.equalTo("toUser", blockedUser);
      followingQuery.equalTo("type", "follow");

      var query = Parse.Query.or(followQuery, followingQuery);
      query.find({
        success: function(results) {
          Parse.Object.destroyAll(results);
          return response.success();
        },
        error: function(error) {
          // ERROR unfollowing
          response.error("Failed to unfollow");
        }
      });
    },
    error: function(error) {
      response.error("Failed to see if Blocked User already exists. User not blocked.");
    }
  });

});