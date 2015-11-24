/*
 * This file is just for including all of the files needed in the app.
 */

require('cloud/installation.js');
require('cloud/activity.js');
require('cloud/photo.js');
require('cloud/user.js');
require('cloud/report.js');
require('cloud/block.js');
require('cloud/trunk.js');
require('cloud/updateFriendRoles.js');

/*
TODO: timeouts happen on Follows.
Instead of using the beforeSave Activity hook, we should call a cloud Function instead, because that gives us like 10 seconds.
The other option, is to not worry about adding roles on Follows, instead just add all Followers to the friendsOf_ role when a
user switchings to a private account.
 */