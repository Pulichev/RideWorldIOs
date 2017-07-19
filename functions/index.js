// TIP: I don't know nodejs good, so bad quality of code. Will review it in the future.

// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require("firebase-functions");

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require("firebase-admin");
admin.initializeApp(functions.config().firebase);

// **************************************************************************************
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
        var updates = {};

        snap.forEach(function(childSnapshot) {
          let followerId = childSnapshot.key;

          updates[
            "/MainDataBase/userpostsfeed/" + followerId + "/" + postId
          ] = event.data.val();
        });

        updates[
          "/MainDataBase/userpostsfeed/" + userId + "/" + postId
        ] = event.data.val(); // add post to users post strip

        admin.database().ref().update(updates);
      });
    } else {
      // post was deleted
      followersRef.once("value", function(snap) {
        var updates = {};

        snap.forEach(function(childSnapshot) {
          let followerId = childSnapshot.key;

          updates[
            "/MainDataBase/userpostsfeed/" + followerId + "/" + postId
          ] = null;
        });

        updates["/MainDataBase/userpostsfeed/" + userId + "/" + postId] = null; // remove post from users post strip

        admin.database().ref().update(updates);
      });
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
        var updates = {};

        snap.forEach(function(childSnapshot) {
          let postId = childSnapshot.key;
          updates[
            "/MainDataBase/userpostsfeed/" + followerId + "/" + postId
          ] = childSnapshot.val();
        });

        admin.database().ref().update(updates);
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
            var updates = {};

            snap.forEach(function(childSnapshot) {
              let postId = childSnapshot.key;
              let spotId = childSnapshot.val()["spotId"];

              // if follower with followerId also not following this spot, then delete post from feed
              if (!(listOfFollowedSpots.indexOf(spotId) > -1)) {
                updates[
                  "/MainDataBase/userpostsfeed/" + followerId + "/" + postId
                ] = null;
              }
            });

            admin.database().ref().update(updates);
          });
        } else {
          // if user do not follow spots
          refToUserPosts.once("value", function(snap) {
            var updates = {};

            snap.forEach(function(childSnapshot) {
              let postId = childSnapshot.key;

              updates[
                "/MainDataBase/userpostsfeed/" + followerId + "/" + postId
              ] = null;
            });

            admin.database().ref().update(updates);
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
        var updates = {};

        snap.forEach(function(childSnapshot) {
          let postId = childSnapshot.key;

          updates[
            "/MainDataBase/userpostsfeed/" + userId + "/" + postId
          ] = childSnapshot.val();
        });

        admin.database().ref().update(updates);
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
            var updates = {};

            snap.forEach(function(childSnapshot) {
              let postId = childSnapshot.key;
              let postAuthorId = childSnapshot.val()["addedByUser"];

              // if i'm also not following this user, then delete post from feed
              if (!(listOfFollowedUsers.indexOf(postAuthorId) > -1)) {
                updates[
                  "/MainDataBase/userpostsfeed/" + userId + "/" + postId
                ] = null;
              }
            });

            admin.database().ref().update(updates);
          });
        } else {
          refToSpotPosts.once("value", function(snap) {
            var updates = {};

            snap.forEach(function(childSnapshot) {
              let postId = childSnapshot.key;

              updates[
                "/MainDataBase/userpostsfeed/" + userId + "/" + postId
              ] = null;
            });

            admin.database().ref().update(updates);
          });
        }
      });
    }
  });

// **************************************************************************************

// **************************************************************************************
// COMMENTS PART

// update comments count in every mention of post
exports.updateCommentsCountInEachPost = functions.database
  .ref("/MainDataBase/postscomments/{postId}/{commentId}")
  .onWrite(event => {
    const postId = event.params.postId;
    const commentId = event.params.commentId;

    let refToPostsComments = admin
      .database()
      .ref("/MainDataBase/postscomments/" + postId);

    refToPostsComments.once("value", function(commentsSnap) {
      let commentsCount = commentsSnap.numChildren();

      // update comments count in each post mention
      // first step - we need spot id to also update this post in spotposts
      // the easiest way is to get post from posts -> postId -> ...

      let refToPost = admin.database().ref("MainDataBase/posts/" + postId);

      refToPost.once("value", function(postSnap) {
        let spotId = postSnap.val()["spotId"];
        let postAddedByUser = postSnap.val()["addedByUser"];
        console.log("spotId: " + spotId);

        var updates = {};

        // add update of post author posts feed
        updates[
          "/MainDataBase/userpostsfeed/" +
            postAddedByUser +
            "/" +
            postId +
            "/commentsCount"
        ] = commentsCount;
        // of usersposts
        updates[
          "/MainDataBase/usersposts/" +
            postAddedByUser +
            "/" +
            postId +
            "/commentsCount"
        ] = commentsCount;
        // of spotposts
        updates[
          "/MainDataBase/spotsposts/" + spotId + "/" + postId + "/commentsCount"
        ] = commentsCount;
        // of posts node
        updates[
          "/MainDataBase/posts/" + postId + "/commentsCount"
        ] = commentsCount;

        admin.database().ref().update(updates);

        // clear previous array
        // user can have no followers
        updates = {};

        let followersRef = admin
          .database()
          .ref("/MainDataBase/usersfollowers/" + postAddedByUser);

        followersRef.once("value", function(snap) {
          snap.forEach(function(childSnapshot) {
            let followerId = childSnapshot.key;
            // add update of followers posts feed
            updates[
              "/MainDataBase/userpostsfeed/" +
                followerId +
                "/" +
                postId +
                "/commentsCount"
            ] = commentsCount;
          });

          admin.database().ref().update(updates);
        });
      });
    });
  });

// **************************************************************************************

// **************************************************************************************
// LIKES PART

// update likes count in every mention of post
// easiest way to catch it is from userlikes. 
// lowest count of nodes
exports.updateLikesCountInEachPost = functions.database
  .ref("/MainDataBase/userslikes/{userId}/onposts/{postId}")
  .onWrite(event => {
    const postId = event.params.postId;
    const userId = event.params.userId;

    let refToPostsLikes = admin
      .database()
      .ref("/MainDataBase/postslikes/" + postId);

    refToPostsLikes.once("value", function(likesSnap) {
      let likesCount = likesSnap.numChildren();

      // update likes count in each post mention
      // first step - we need spot id to also update this post in spotposts
      // the easiest way is to get post from posts -> postId -> ...

      let refToPost = admin.database().ref("MainDataBase/posts/" + postId);

      refToPost.once("value", function(postSnap) {
        let spotId = postSnap.val()["spotId"];
        let postAddedByUser = postSnap.val()["addedByUser"];
        console.log("spotId: " + spotId);

        var updates = {};

        // add update of post author posts feed
        updates[
          "/MainDataBase/userpostsfeed/" +
            postAddedByUser +
            "/" +
            postId +
            "/likesCount"
        ] = likesCount;
        // of usersposts
        updates[
          "/MainDataBase/usersposts/" +
            postAddedByUser +
            "/" +
            postId +
            "/likesCount"
        ] = likesCount;
        // of spotposts
        updates[
          "/MainDataBase/spotsposts/" + spotId + "/" + postId + "/likesCount"
        ] = likesCount;
        // of posts node
        updates[
          "/MainDataBase/posts/" + postId + "/likesCount"
        ] = likesCount;

        admin.database().ref().update(updates);

        // clear previous array
        // user can have no followers
        updates = {};

        let followersRef = admin
          .database()
          .ref("/MainDataBase/usersfollowers/" + postAddedByUser);

        followersRef.once("value", function(snap) {
          snap.forEach(function(childSnapshot) {
            let followerId = childSnapshot.key;
            // add update of followers posts feed
            updates[
              "/MainDataBase/userpostsfeed/" +
                followerId +
                "/" +
                postId +
                "/likesCount"
            ] = likesCount;
          });

          admin.database().ref().update(updates);
        });
      });
    });
  });

// **************************************************************************************