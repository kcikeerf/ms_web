var swtk_global_topics = {};
 
jQuery.Topic = function( id ) {
  var callbacks, method,
    topic = id && swtk_global_topics[ id ];
 
  if ( !topic ) {
    callbacks = jQuery.Callbacks();
    topic = {
      publish: callbacks.fire,
      subscribe: callbacks.add,
      unsubscribe: callbacks.remove,
      destroy: function(){
        delete swtk_global_topics[id];
      }
    };
    if ( id ) {
      swtk_global_topics[ id ] = topic;
    }
  }

  return topic;
};