// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require("firebase-functions");

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require("firebase-admin");
admin.initializeApp(functions.config().firebase);

// ************************************************************************************
// POST PART

// add posts to feed of followers
exports.updateFeedOnNewPostAdded = functions.database
  .ref("/MainDataBase/usersposts/{userId}/{postId}")
  .onWrite(event => {
    const userId = event.params.userId;
    const postId = event.params.postId;

    let followersRef = admin
      .database()
      .ref("/MainDataBase/usersfollowers/" + userId);
    if (event.data.val()) {
      // post was added
      followersRef.once("value", function(snap) {
        snap.forEach(function(childSnapshot) {
          let followerId = childSnapshot.key;
          admin
            .database()
            .ref("/MainDataBase/userpostsfeed/" + followerId + "/" + postId)
            .set(event.data.val());
          console.log("Added post to feed of user: " + followerId);
        });
      });

      admin
        .database()
        .ref("/MainDataBase/userpostsfeed/" + userId + "/" + postId)
        .remove(); // remove post from users post strip
    } else {
      // post was deleted
      followersRef.once("value", function(snap) {
        snap.forEach(function(childSnapshot) {
          let followerId = childSnapshot.key;
          admin
            .database()
            .ref("/MainDataBase/userpostsfeed/" + followerId + "/" + postId)
            .remove();
          console.log("Removed post from feed of user: " + followerId);
        });
      });

      admin
        .database()
        .ref("/MainDataBase/userpostsfeed/" + userId + "/" + postId)
        .set(event.data.val()); // add post to users post strip
    }
  });

// add/remove posts to feed on follow/unfollow
exports.addPostsToNewFollowerFeed = functions.database
  .ref("/MainDataBase/usersfollowers/{userId}/{followerId}")
  .onWrite(event => {
    const userId = event.params.userId;
    const followerId = event.params.followerId;

    let refToUserPosts = admin
      .database()
      .ref("/MainDataBase/usersposts/" + userId);
    if (event.data.val()) {
      refToUserPosts.once("value", function(snap) {
        snap.forEach(function(childSnapshot) {
          let postId = childSnapshot.key;
          admin
            .database()
            .ref("/MainDataBase/userpostsfeed/" + followerId + "/" + postId)
            .set(childSnapshot.val());
          console.log("Added post to feed of user: " + followerId);
        });
      });
    } else {
      // get all followed by user spots
      let refToAllFollowedSpots = admin
        .database()
        .ref("/MainDataBase/userspotfollowings/" + followerId);
      refToAllFollowedSpots.once("value", function(followedspotsssnap) {
        let vollowedSpotsSnapValue = followedspotsssnap.val();
        if (vollowedSpotsSnapValue != null) {
          // if user following some spots, we need to make some checks
          var listOfFollowedSpots = Object.keys(vollowedSpotsSnapValue);
          refToUserPosts.once("value", function(snap) {
            snap.forEach(function(childSnapshot) {
              let postId = childSnapshot.key;
              let spotId = childSnapshot.val()["spotId"];
              console.log("Post spotId: " + spotId);
              // if follower with followerId also not following this spot, then delete post from feed
              if (!(listOfFollowedSpots.indexOf(spotId) > -1)) {
                admin
                  .database()
                  .ref(
                    "/MainDataBase/userpostsfeed/" + followerId + "/" + postId
                  )
                  .remove();
                console.log("Removed post from feed of user: " + followerId);
              }
            });
          });
        } else {
          // if user do not follow spots
          refToUserPosts.once("value", function(snap) {
            snap.forEach(function(childSnapshot) {
              let postId = childSnapshot.key;
              admin
                .database()
                .ref("/MainDataBase/userpostsfeed/" + followerId + "/" + postId)
                .remove();
              console.log("Removed post from feed of user: " + followerId);
            });
          });
        }
      });
    }
  });

// posts on spot follow / unfollow
exports.addPostsFromSpotToFeed = functions.database
  .ref("/MainDataBase/userspotfollowings/{userId}/{spotId}")
  .onWrite(event => {
    const userId = event.params.userId;
    const spotId = event.params.spotId;

    let refToSpotPosts = admin
      .database()
      .ref("/MainDataBase/spotsposts/" + spotId);
    if (event.data.val()) {
      refToSpotPosts.once("value", function(snap) {
        snap.forEach(function(childSnapshot) {
          let postId = childSnapshot.key;
          admin
            .database()
            .ref("/MainDataBase/userpostsfeed/" + userId + "/" + postId)
            .set(childSnapshot.val());
          console.log("Added post to feed of user: " + userId);
        });
      });
    } else {
      // getting all userId of followed by me users
      let refToAllFollowings = admin
        .database()
        .ref("/MainDataBase/usersfollowings/" + userId);
      refToAllFollowings.once("value", function(followingssnap) {
        let followingsSnapValue = followingssnap.val();
        if (followingsSnapValue != null) {
          var listOfFollowedUsers = Object.keys(followingsSnapValue);
          listOfFollowedUsers.push(userId); // add current user

          refToSpotPosts.once("value", function(snap) {
            snap.forEach(function(childSnapshot) {
              let postId = childSnapshot.key;
              let postAuthorId = childSnapshot.val()["addedByUser"];
              console.log("Post authorId: " + postAuthorId);
              // if i'm also not following this user, then delete post from feed
              if (!(listOfFollowedUsers.indexOf(postAuthorId) > -1)) {
                admin
                  .database()
                  .ref("/MainDataBase/userpostsfeed/" + userId + "/" + postId)
                  .remove();
                console.log("Removed post from feed of user: " + userId);
              }
            });
          });
        } else {
          refToSpotPosts.once("value", function(snap) {
            snap.forEach(function(childSnapshot) {
              let postId = childSnapshot.key;
              admin
                .database()
                .ref("/MainDataBase/userpostsfeed/" + userId + "/" + postId)
                .remove();
              console.log("Removed post from feed of user: " + userId);
            });
          });
        }
      });
    }
  });

// **************************************************************************************
