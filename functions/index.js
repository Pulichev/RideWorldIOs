// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// ************************************************************************************
// POST PART

// add posts to feed of followers
exports.updateFeed = functions.database.ref('/MainDataBase/usersposts/{userId}/{postId}')
.onWrite(event => {
         const userId = event.params.userId;
         const postId = event.params.postId;
         
         let followersRef = admin.database().ref('/MainDataBase/usersfollowers/' + userId);
         if(!event.data.val()){
         // post was deleted
         followersRef.once("value", function(snap) {
                           snap.forEach(function(childSnapshot) {
                                        let followerId = childSnapshot.key;
                                        admin.database().ref('/MainDataBase/userpostsfeed/' + followerId + '/' + postId).remove();
                                        console.log('Removed post from feed of user: '+ followerId);
                                        });
                           });
         
         admin.database().ref('/MainDataBase/userpostsfeed/' + userId + '/' + postId).remove(); // remove post from users post strip
         } else {
         // post was added
         followersRef.once("value", function(snap) {
                           snap.forEach(function(childSnapshot) {
                                        let followerId = childSnapshot.key;
                                        admin.database().ref('/MainDataBase/userpostsfeed/' + followerId + '/' + postId).set(event.data.val());
                                        console.log('Added post to feed of user: '+ followerId);
                                        });
                           });
         
         admin.database().ref('/MainDataBase/userpostsfeed/' + userId + '/' + postId).set(event.data.val()); // add post to users post strip
         }
         });














// add posts to feed on follow starting
exports.addPostsToNewFollowerFeed = functions.database.ref('/MainDataBase/usersfollowers/{userId}/{followerId}')
.onWrite(event => {
         const userId = event.params.userId;
         const followerId = event.params.followerId;
         
         let refToUserPosts = admin.database().ref('/MainDataBase/usersposts/' + userId);
         refToUserPosts.once("value", function(snap) {
                             snap.forEach(function(childSnapshot) {
                                          let postId = childSnapshot.key;
                                          admin.database().ref('/MainDataBase/userpostsfeed/' + followerId + '/' + postId).set(childSnapshot.val());
                                          console.log('Added post to feed of user: '+ followerId);
                                          });
                             });
         });

// remove posts from feed on follow ending

// **************************************************************************************
