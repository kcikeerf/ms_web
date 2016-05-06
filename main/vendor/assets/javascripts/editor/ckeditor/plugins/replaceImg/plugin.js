CKEDITOR.plugins.add( 'replaceImg', {
    init: function( editor ) {
        var pluginName = 'replaceImg';
        editor.addCommand( pluginName, CKEDITOR.plugins.replaceImg.commands.replaceImgs );
        editor.ui.addButton && editor.ui.addButton( pluginName, {
            label: '替换线上图片',
            command: pluginName,
            icon: this.path + 'images/replaceImg.png'
        } );
    }
} );

CKEDITOR.plugins.replaceImg = {
    commands: {
        replaceImgs: {
            exec: function(editor,callBack) {
                var newDom = $("<div></div>");
                newDom.html(editor.getData().replace(/<!--[\w\W\r\n]*?-->/g,""));
                var domImg = newDom.find("img");
                $(".cke_inner iframe").eq(0).contents().find("body>.container img").each(function(i){
                    var thatImg = $(this);
                    domImg.eq(i).data("imgdom",thatImg);
                });
                domImg.each(function(i){
                    $(this).attr("num",i);
                });
                domImg = domImg.filter(function(i){
                    return ($(this).attr("src")||"").substring(0,5)!="data:";
                });
                if(!domImg.length) return;
                var maskDom = $('<div class="actionMask" style="font-family:微软雅黑;font-size:16px;position: fixed;z-index:9999;width: 100%;height: 100%;left: 0;top: 0;background-color: rgba(0,0,0,0.4);"><div class="maskWarp" style="position:absolute;top: 50%;left: 50%;width: 260px;height: 150px;margin:-75px 0 0 -130px; background-color: #fff;border-radius: 4px;"><p style="padding-left: 60px;margin:20px 0;">图片转换中，请稍等....</p><p class="allImgs" style="margin-bottom: 20px;padding-left: 60px;">待转图片总数：<span></span></p><p class="readyImgs" style="padding-left: 60px;">已完成图片数：<span class="readyNum">0</span>/<span class="allNum"></span></p></div></div>');
                maskDom.find(".allImgs span, .readyImgs .allNum").text(domImg.length);
                $("body").append(maskDom);
                changeImg(domImg);
                
                function changeImg(domObj){
                    domObj.each(function(){
                        var that = $(this),
                            src = that.attr("src") || "",
                            imgFormat = src.match(/\.png/g) ? 'image/png' : 'image/jpeg',
                            canvas = document.createElement("canvas"),
                            img = new Image(),
                            thisImg = that.data("imgdom") || $(""),
                            num = that.attr("num")-0,
                            ctx = canvas.getContext('2d');
                        img.src = editor.config.replaceImgcrc + src;
                        img.onload = function() {
                            maskDom.find(".readyImgs .readyNum").text(maskDom.find(".readyImgs .readyNum").text()-0+1);
                            canvas.height = thisImg.height(); 
                            canvas.width = thisImg.width(); 
                            ctx.drawImage(img,0,0); 
                            var dataURL = canvas.toDataURL(imgFormat); 
                            that.attr("src",dataURL);
                            if(newDom.find("img").length-1==num){
                                editor.setData(newDom.html());
                                maskDom.remove();
                                typeof callBack == "function" && callBack();
                            }
                        }                      
                    });
                }
            }
        }
    }

};