// Include underscore because we use it's looping functions.
var _ = require("underscore");

/**
 * Takes a User and finds their friendsOf_ role, then adds all of their Followers to that role.
 * @param {PFUser} user User to update the friendsOf_ role for.
 */
var addFollowersToFriendRole = function(user) {
  Parse.Cloud.useMasterKey();
  var promise = new Parse.Promise();

  var userRole;

  var roleName = "friendsOf_" + user.id

  var roleQuery = new Parse.Query(Parse.Role);
  roleQuery.equalTo("name", roleName);
  roleQuery.first()
  .then(function(role) {
    if (role) {
      // console.log("Found Role " + role.get('name'));
      
      // Set the userRole equal to the role so we have access to it in the next function
      userRole = role;

      // Set up the query for finding all Follows & return the results to the next function in the chain.
      var query = new Parse.Query('Activity');
      query.equalTo('toUser', user);
      query.equalTo('type', "follow");
      query.limit(1000); // set a higher limit otherwise it only does 100.
      return query.find();
    }
    else
    {
      // No role. Return an error.
      console.log("No Role found for name " + roleName);
      return Parse.Promise.error("No Role found for name: " + roleName);
    }
  })
  .then(function(activities) {

    // console.log('FOUND ' + activities.length + ' FOLLOWERS FOR USER ' + user.id);
    // console.log('AND we have the role here ' + userRole.get('name'));
    
    // For each Follow Activity
    _.each(activities, function(activity) {
      var userToFriend = activity.get('fromUser');
      userRole.getUsers().add(userToFriend);
    });

    return userRole.save();
  })
  .then(function(role) {
    // console.log("addFollowersToFriendRole about to resolve");
    promise.resolve();
  }, function(error) {
    // console.log(error);
    promise.reject(error);
  })


  return promise;
}

/**
 * Background Job
 * Updates ALL user's friendsOf_ role with ALL of their followers
 * To be used for launching Private accounts since some accounts can be outdated.
 */
Parse.Cloud.job("updateFriendRoles", function(request, status) {
  Parse.Cloud.useMasterKey();
  console.log("Begin Background Job - Updating Friend Roles");
  
  // Query for all users.
  var userQuery = new Parse .Query(Parse.User);
  userQuery.limit(1000); // set a higher limit otherwise it only does 100.
  userQuery.find()
  .then(function(users) {
    console.log("FOUND " + users.length + " USERS");

    var promise = Parse.Promise.as();
    // For every user, add a new step in the Promise Sequence to add their followers to role.
    _.each(users, function(user) {
      promise = promise.then(function() {
        return addFollowersToFriendRole(user);
      });
    });
    // Return a promise so that the next step doesn't execute until everything has been updated.
    return promise;
  })
  .then(function() {
    console.log('updateFriendRole Job function about to complete');
    status.success('ALL user friend roles have been updated with their current followers');
  }, function(error) {
    console.error(error);
    status.error(error);
  });

});

